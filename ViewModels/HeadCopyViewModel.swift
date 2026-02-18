import Foundation
import SwiftUI
import Combine

@MainActor
class HeadCopyViewModel: ObservableObject {
    @Published var currentSequence: [MorseCharacter] = []
    @Published var userInput: [Character] = []
    @Published var feedbackResults: [Bool?] = [] // nil = not yet scored, true = correct, false = incorrect
    @Published var isSubmitted = false
    @Published var sessionCorrect = 0
    @Published var sessionTotal = 0
    @Published var justUnlockedCharacter: Character?
    @Published var isPlaying = false

    private var audioEngine: AudioEngine?
    private(set) var progressManager: ProgressManager?
    private var cancellables = Set<AnyCancellable>()
    var activeTasks: [Task<Void, Never>] = []

    var sequenceLength: Int {
        currentSequence.count
    }

    /// Whether to speak the answer aloud after submission. Override in subclasses to disable.
    var shouldSpeakAnswer: Bool { true }

    init() {}

    func setup(progressManager: ProgressManager) {
        self.progressManager = progressManager
        self.audioEngine = AudioEngine()
        updateAudioSettings()

        if progressManager.progress.isSessionStale {
            progressManager.resetSession()
        }
        sessionCorrect = progressManager.progress.sessionCorrect
        sessionTotal = progressManager.progress.sessionTotal

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
        isSubmitted = false
        userInput = []
        feedbackResults = []
        justUnlockedCharacter = nil

        let length = Int.random(in: 3...5)
        currentSequence = (0..<length).compactMap { _ in
            progressManager?.progress.weightedRandomCharacter(from: availableCharacters)
                ?? availableCharacters.randomElement()
        }

        let task = Task {
            await playCurrentSequence()
        }
        activeTasks.append(task)
    }

    func playCurrentSequence() async {
        guard let audioEngine = audioEngine, !currentSequence.isEmpty else { return }
        await audioEngine.playSequence(currentSequence)
    }

    func replay() {
        let task = Task {
            await playCurrentSequence()
        }
        activeTasks.append(task)
    }

    func appendInput(_ character: Character) {
        guard !isSubmitted else { return }
        guard !isPlaying else { return }
        guard userInput.count < sequenceLength else { return }

        userInput.append(character)

        if userInput.count == sequenceLength {
            submitSequence()
        }
    }

    func deleteLastInput() {
        guard !isSubmitted else { return }
        guard !userInput.isEmpty else { return }
        userInput.removeLast()
    }

    func submitSequence() {
        guard !isSubmitted else { return }
        guard let progressManager = progressManager else { return }

        isSubmitted = true

        let previousUnlockedCount = progressManager.progress.unlockedCount

        // Score each position
        feedbackResults = (0..<sequenceLength).map { index in
            if index < userInput.count {
                let correct = userInput[index] == currentSequence[index].character
                progressManager.recordAttempt(character: currentSequence[index].character, correct: correct)
                sessionTotal += 1
                if correct { sessionCorrect += 1 }
                return correct
            } else {
                // Unanswered positions count as incorrect
                progressManager.recordAttempt(character: currentSequence[index].character, correct: false)
                sessionTotal += 1
                return false
            }
        }

        // Sync from persisted state
        sessionCorrect = progressManager.progress.sessionCorrect
        sessionTotal = progressManager.progress.sessionTotal

        // Check for new unlock
        if progressManager.progress.unlockedCount > previousUnlockedCount {
            let newCharIndex = progressManager.progress.unlockedCount - 1
            justUnlockedCharacter = KochSequence.order[newCharIndex]
        }

        // Haptic feedback
        let allCorrect = feedbackResults.allSatisfy { $0 == true }
        if progressManager.settings.hapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(allCorrect ? .success : .error)
        }

        // Audio feedback
        let shouldSpeak = shouldSpeakAnswer
        let feedbackTask = Task {
            if progressManager.settings.audioFeedback {
                await audioEngine?.playFeedbackTone(correct: allCorrect)
            }

            if shouldSpeak && progressManager.settings.speakAnswer {
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                let answer = currentSequence.map { String($0.character) }.joined(separator: ", ")
                audioEngine?.speak(answer)
            }
        }
        activeTasks.append(feedbackTask)

        // Auto-advance
        let delay: UInt64 = (shouldSpeak && progressManager.settings.speakAnswer) ? 3_000_000_000 : 2_000_000_000
        let advanceTask = Task {
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            if isSubmitted {
                startNewRound()
            }
        }
        activeTasks.append(advanceTask)
    }

    func isValidAnswer(_ character: Character) -> Bool {
        let upperChar = Character(character.uppercased())
        return availableCharacters.contains { $0.character == upperChar }
    }

    func handleKeyboardInput(_ character: Character) {
        let upperChar = Character(character.uppercased())
        if isValidAnswer(upperChar) {
            appendInput(upperChar)
        }
    }

    func skipToNext() {
        startNewRound()
    }

    func resetSession() {
        progressManager?.resetSession()
        sessionCorrect = 0
        sessionTotal = 0
        isSubmitted = false
        currentSequence = []
        userInput = []
        feedbackResults = []
        justUnlockedCharacter = nil
    }

    func stop() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
        audioEngine?.stop()
    }
}
