import Foundation
import SwiftUI
import Combine

@MainActor
class DrillViewModel: ObservableObject {
    @Published var currentCharacter: MorseCharacter?
    @Published var feedbackState: FeedbackState = .none
    @Published var showingAnswer = false
    @Published var sessionCorrect = 0
    @Published var sessionTotal = 0
    @Published var justUnlockedCharacter: Character?
    @Published var isPlaying = false

    private var audioEngine: AudioEngine?
    private var progressManager: ProgressManager?
    private var cancellables = Set<AnyCancellable>()

    enum FeedbackState {
        case none
        case correct
        case incorrect
    }

    init() {
        // Empty init - call setup() with progressManager
    }

    func setup(progressManager: ProgressManager) {
        self.progressManager = progressManager
        self.audioEngine = AudioEngine()
        updateAudioSettings()

        // Observe audio engine's isPlaying state
        audioEngine?.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                self?.isPlaying = playing
            }
            .store(in: &cancellables)
    }

    var availableCharacters: [MorseCharacter] {
        progressManager?.progress.availableCharacters ?? []
    }

    var sessionAccuracy: Double {
        guard sessionTotal > 0 else { return 0 }
        return Double(sessionCorrect) / Double(sessionTotal) * 100.0
    }

    func updateAudioSettings() {
        guard let progressManager = progressManager, let audioEngine = audioEngine else { return }
        audioEngine.characterWPM = progressManager.settings.characterWPM
        audioEngine.farnsworthWPM = progressManager.settings.farnsworthWPM
        audioEngine.frequency = progressManager.settings.toneFrequency
        audioEngine.hapticsEnabled = progressManager.settings.hapticFeedback
    }

    func startNewRound() {
        feedbackState = .none
        showingAnswer = false
        justUnlockedCharacter = nil

        // Pick a random character from unlocked set
        currentCharacter = availableCharacters.randomElement()

        // Play it
        Task {
            await playCurrentCharacter()
        }
    }

    func playCurrentCharacter() async {
        guard let character = currentCharacter, let audioEngine = audioEngine else { return }
        await audioEngine.playCharacter(character)
    }

    func replay() {
        Task {
            await playCurrentCharacter()
        }
    }

    func submitAnswer(_ character: Character) {
        guard let current = currentCharacter, let progressManager = progressManager else { return }
        guard feedbackState == .none else { return } // Already answered
        guard !isPlaying else { return } // Don't accept answers while audio is playing

        let correct = character == current.character
        sessionTotal += 1

        if correct {
            sessionCorrect += 1
            feedbackState = .correct
        } else {
            feedbackState = .incorrect
        }

        // Haptic feedback
        if progressManager.settings.hapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(correct ? .success : .error)
        }

        // Audio feedback
        Task {
            if progressManager.settings.audioFeedback {
                await audioEngine?.playFeedbackTone(correct: correct)
            }

            // Speak the correct answer
            if progressManager.settings.speakAnswer {
                // Small delay after feedback tone
                try? await Task.sleep(nanoseconds: 200_000_000)
                audioEngine?.speakCharacter(current.character)
            }
        }

        // Record the attempt
        let previousUnlockedCount = progressManager.progress.unlockedCount
        progressManager.recordAttempt(character: current.character, correct: correct)

        // Check if a new character was unlocked
        if progressManager.progress.unlockedCount > previousUnlockedCount {
            let newCharIndex = progressManager.progress.unlockedCount - 1
            justUnlockedCharacter = KochSequence.order[newCharIndex]
        }

        showingAnswer = true

        // Auto-advance after delay (longer if speaking answer)
        let delay: UInt64 = progressManager.settings.speakAnswer ? 2_000_000_000 : 1_500_000_000
        Task {
            try? await Task.sleep(nanoseconds: delay)
            if feedbackState != .none { // Still showing feedback
                startNewRound()
            }
        }
    }

    /// Check if a character is valid for answering (in the unlocked set)
    func isValidAnswer(_ character: Character) -> Bool {
        let upperChar = Character(character.uppercased())
        return availableCharacters.contains { $0.character == upperChar }
    }

    /// Handle keyboard input
    func handleKeyboardInput(_ character: Character) {
        let upperChar = Character(character.uppercased())
        if isValidAnswer(upperChar) {
            submitAnswer(upperChar)
        }
    }

    func skipToNext() {
        startNewRound()
    }

    func resetSession() {
        sessionCorrect = 0
        sessionTotal = 0
        feedbackState = .none
        showingAnswer = false
        currentCharacter = nil
        justUnlockedCharacter = nil
    }

    func stop() {
        audioEngine?.stop()
    }
}
