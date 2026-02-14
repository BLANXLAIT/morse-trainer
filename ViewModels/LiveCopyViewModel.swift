import Foundation
import SwiftUI

@MainActor
class LiveCopyViewModel: HeadCopyViewModel {

    override var shouldSpeakAnswer: Bool { false }

    override func startNewRound() {
        isSubmitted = false
        userInput = []
        feedbackResults = []
        justUnlockedCharacter = nil

        guard !availableCharacters.isEmpty else { return }

        // Scale sequence length with unlocked character count
        let charCount = availableCharacters.count
        let maxLength = min(20, 5 + charCount)
        let length = Int.random(in: 5...maxLength)
        currentSequence = (0..<length).map { _ in
            availableCharacters.randomElement()!
        }

        let task = Task {
            await playCurrentSequence()
            // Grace period after playback ends for user to finish typing
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            if !isSubmitted {
                submitSequence()
            }
        }
        activeTasks.append(task)
    }

    override func appendInput(_ character: Character) {
        guard !isSubmitted else { return }
        // Allow input during playback (no isPlaying guard)
        guard userInput.count < sequenceLength else { return }

        userInput.append(character)

        if userInput.count == sequenceLength {
            submitSequence()
        }
    }

    override func skipToNext() {
        stop()
        startNewRound()
    }
}
