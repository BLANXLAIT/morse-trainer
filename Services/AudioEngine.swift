import AVFoundation
import Foundation
import UIKit

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

    /// Current phase for sine wave generation
    private var phase: Double = 0.0

    /// Whether the tone is currently on
    private var toneOn = false

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

        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let phaseIncrement = 2.0 * Double.pi * self.frequency / sampleRate

            for frame in 0..<Int(frameCount) {
                let value: Float
                if self.toneOn {
                    value = Float(sin(self.phase)) * 0.3 // 0.3 amplitude to avoid clipping
                    self.phase += phaseIncrement
                    if self.phase >= 2.0 * Double.pi {
                        self.phase -= 2.0 * Double.pi
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
        defer { isPlaying = false }

        for (index, element) in character.pattern.enumerated() {
            // Play haptic feedback at the start of the tone
            if hapticsEnabled {
                if element == .dit {
                    hapticManager.playDit()
                } else {
                    hapticManager.playDah()
                }
            }
            
            // Play the tone
            toneOn = true
            let duration = element == .dit ? ditDuration : dahDuration
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            toneOn = false

            // Add intra-character space (except after last element)
            if index < character.pattern.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(intraCharacterSpace * 1_000_000_000))
            }
        }

        stopEngine()
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
                // Play haptic feedback at the start of the tone
                if hapticsEnabled {
                    if element == .dit {
                        hapticManager.playDit()
                    } else {
                        hapticManager.playDah()
                    }
                }
                
                toneOn = true
                let duration = element == .dit ? ditDuration : dahDuration
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                toneOn = false

                if index < character.pattern.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(intraCharacterSpace * 1_000_000_000))
                }
            }

            // Add inter-character space (except after last character)
            if charIndex < characters.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(interCharacterSpace * 1_000_000_000))
            }
        }
    }

    private func startEngine() async {
        setupEngine()
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func stopEngine() {
        toneOn = false
        audioEngine?.stop()
        if let sourceNode = sourceNode {
            audioEngine?.detach(sourceNode)
        }
        sourceNode = nil
        audioEngine = nil
        phase = 0.0
    }

    /// Stop any currently playing audio
    func stop() {
        stopEngine()
        isPlaying = false
    }

    // MARK: - Feedback Audio

    /// Play a feedback tone for correct/incorrect answer
    func playFeedbackTone(correct: Bool) async {
        let savedFrequency = frequency
        frequency = correct ? correctToneFrequency : incorrectToneFrequency

        await startEngine()

        isPlaying = true
        defer {
            isPlaying = false
            frequency = savedFrequency
        }

        // Play a short beep
        toneOn = true
        let duration = correct ? 0.15 : 0.3  // Correct is short chirp, incorrect is longer
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        toneOn = false

        // For incorrect, add a second lower beep
        if !correct {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s gap
            frequency = incorrectToneFrequency * 0.75  // Even lower
            toneOn = true
            try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
            toneOn = false
        }

        stopEngine()
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
