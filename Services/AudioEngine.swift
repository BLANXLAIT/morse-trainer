import AVFoundation
import Foundation
import UIKit

/// Thread-safe state for the audio render callback.
/// Uses `nonisolated(unsafe)` so the real-time audio thread can read/write
/// without going through MainActor, avoiding the "unsafeForcedSync" warning.
private final class AudioRenderState: @unchecked Sendable {
    /// Whether the tone is currently on
    var toneOn: Bool = false
    /// Current phase for sine wave generation
    var phase: Double = 0.0
    /// Active frequency for the render callback
    var frequency: Double = 700.0
}

@MainActor
class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let synthesizer = AVSpeechSynthesizer()
    private let hapticManager = HapticManager.shared

    @Published var isPlaying = false

    /// Whether haptic feedback is enabled
    var hapticsEnabled: Bool = true

    /// Tone frequency in Hz (default 700 Hz - pleasant middle tone)
    var frequency: Double = 700.0

    /// Frequency for correct answer feedback tone
    private let correctToneFrequency: Double = 880.0  // A5 - higher, pleasant

    /// Frequency for incorrect answer feedback tone
    private let incorrectToneFrequency: Double = 220.0  // A3 - lower, distinct

    /// Character speed in WPM (how fast individual characters sound)
    var characterWPM: Double = 20.0

    /// Effective/Farnsworth speed in WPM (spacing between characters)
    var farnsworthWPM: Double = 5.0

    /// Sample rate for audio generation
    private let sampleRate: Double = 44100.0

    /// Audio thread state — accessed from the real-time render callback,
    /// so kept outside of actor isolation to avoid data races.
    private let renderState = AudioRenderState()

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Enable background audio with .playback category and .mixWithOthers option
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let mainMixer = audioEngine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        let state = self.renderState
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = 2.0 * Double.pi * state.frequency / sampleRate

            for frame in 0..<Int(frameCount) {
                let value: Float
                if state.toneOn {
                    value = Float(sin(state.phase)) * 0.3
                    state.phase += phaseIncrement
                    if state.phase >= 2.0 * Double.pi {
                        state.phase -= 2.0 * Double.pi
                    }
                } else {
                    value = 0.0
                }

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = value
                }
            }

            return noErr
        }

        guard let sourceNode = sourceNode else { return }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: format)
    }

    // MARK: - Timing Calculations

    /// Duration of a dit in seconds at the character WPM
    private var ditDuration: Double {
        // Standard: dit = 1200 / WPM milliseconds
        1.2 / characterWPM
    }

    /// Duration of a dah in seconds (3x dit)
    private var dahDuration: Double {
        ditDuration * 3.0
    }

    /// Duration of intra-character spacing (between dits/dahs within a character)
    private var intraCharacterSpace: Double {
        ditDuration // 1 dit length
    }

    /// Duration of inter-character spacing (Farnsworth adjusted)
    private var interCharacterSpace: Double {
        // Farnsworth timing: use slower WPM for spacing
        // Standard inter-character space is 3 dits
        // We calculate based on farnsworthWPM to give more thinking time
        let standardSpace = ditDuration * 3.0
        let farnsworthDit = 1.2 / farnsworthWPM
        let farnsworthSpace = farnsworthDit * 3.0
        return max(standardSpace, farnsworthSpace)
    }

    // MARK: - Playback

    /// Play a single Morse character
    func playCharacter(_ character: MorseCharacter) async {
        await startEngine()

        isPlaying = true
        defer {
            isPlaying = false
            stopEngine()
        }

        for (index, element) in character.pattern.enumerated() {
            guard !Task.isCancelled else { return }

            // Play haptic feedback at the start of the tone
            if hapticsEnabled {
                if element == .dit {
                    hapticManager.playDit()
                } else {
                    hapticManager.playDah()
                }
            }

            // Play the tone
            renderState.toneOn = true
            let duration = element == .dit ? ditDuration : dahDuration
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            renderState.toneOn = false

            // Add intra-character space (except after last element)
            if index < character.pattern.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(intraCharacterSpace * 1_000_000_000))
            }
        }
    }

    /// Play a sequence of characters (for future word practice)
    func playSequence(_ characters: [MorseCharacter]) async {
        await startEngine()

        isPlaying = true
        defer {
            isPlaying = false
            stopEngine()
        }

        for (charIndex, character) in characters.enumerated() {
            for (index, element) in character.pattern.enumerated() {
                guard !Task.isCancelled else { return }

                // Play haptic feedback at the start of the tone
                if hapticsEnabled {
                    if element == .dit {
                        hapticManager.playDit()
                    } else {
                        hapticManager.playDah()
                    }
                }

                renderState.toneOn = true
                let duration = element == .dit ? ditDuration : dahDuration
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                renderState.toneOn = false

                if index < character.pattern.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(intraCharacterSpace * 1_000_000_000))
                }
            }

            // Add inter-character space (except after last character)
            if charIndex < characters.count - 1 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: UInt64(interCharacterSpace * 1_000_000_000))
            }
        }
    }

    private func startEngine() async {
        renderState.frequency = frequency
        setupEngine()
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func stopEngine() {
        renderState.toneOn = false
        audioEngine?.stop()
        if let sourceNode = sourceNode {
            audioEngine?.detach(sourceNode)
        }
        sourceNode = nil
        audioEngine = nil
        renderState.phase = 0.0
    }

    /// Stop any currently playing audio
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        stopEngine()
        isPlaying = false
    }

    // MARK: - Feedback Audio

    /// Play a feedback tone for correct/incorrect answer
    func playFeedbackTone(correct: Bool) async {
        let savedFrequency = frequency
        frequency = correct ? correctToneFrequency : incorrectToneFrequency
        renderState.frequency = frequency

        await startEngine()

        isPlaying = true
        defer {
            isPlaying = false
            frequency = savedFrequency
            renderState.frequency = savedFrequency
            stopEngine()
        }

        guard !Task.isCancelled else { return }

        // Play a short beep
        renderState.toneOn = true
        let duration = correct ? 0.15 : 0.3  // Correct is short chirp, incorrect is longer
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        renderState.toneOn = false

        // For incorrect, add a second lower beep
        if !correct {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s gap
            frequency = incorrectToneFrequency * 0.75  // Even lower
            renderState.frequency = frequency
            renderState.toneOn = true
            try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
            renderState.toneOn = false
        }
    }

    /// Speak the character name using text-to-speech
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 0.8
        synthesizer.speak(utterance)
    }

    /// Speak the correct answer character
    func speakCharacter(_ character: Character) {
        // For letters, just speak the letter
        // For numbers and punctuation, speak the name
        let text: String
        switch character {
        case ".":
            text = "period"
        case ",":
            text = "comma"
        case "?":
            text = "question mark"
        case "/":
            text = "slash"
        default:
            text = String(character)
        }
        speak(text)
    }
}
