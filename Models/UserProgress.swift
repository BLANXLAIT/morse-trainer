import Foundation

struct UserProgress: Codable {
    /// Number of characters unlocked in Koch sequence (minimum 2)
    var unlockedCount: Int

    /// Recent accuracy for each character (last 10 attempts)
    /// Key is the character as a String, value is array of bools (true = correct)
    var characterHistory: [String: [Bool]]

    /// Total correct answers
    var totalCorrect: Int

    /// Total attempts
    var totalAttempts: Int

    /// Current streak of correct answers
    var currentStreak: Int

    /// Best streak achieved
    var bestStreak: Int

    init() {
        self.unlockedCount = KochSequence.minimumCharacters
        self.characterHistory = [:]
        self.totalCorrect = 0
        self.totalAttempts = 0
        self.currentStreak = 0
        self.bestStreak = 0
    }

    /// Get accuracy percentage for a specific character (last 10 attempts)
    func accuracy(for character: Character) -> Double {
        guard let history = characterHistory[String(character)], !history.isEmpty else {
            return 0.0
        }
        let correct = history.filter { $0 }.count
        return Double(correct) / Double(history.count) * 100.0
    }

    /// Get overall accuracy percentage
    var overallAccuracy: Double {
        guard totalAttempts > 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalAttempts) * 100.0
    }

    /// Record an attempt for a character
    mutating func recordAttempt(character: Character, correct: Bool) {
        let key = String(character)
        var history = characterHistory[key] ?? []
        history.append(correct)

        // Keep only last 10 attempts
        if history.count > 10 {
            history.removeFirst()
        }
        characterHistory[key] = history

        totalAttempts += 1
        if correct {
            totalCorrect += 1
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
    }

    /// Check if ready to unlock next character (90% accuracy on current set)
    func shouldUnlockNextCharacter() -> Bool {
        guard unlockedCount < KochSequence.totalCharacters else { return false }

        // Need at least 10 attempts on the newest character
        let newestChar = KochSequence.order[unlockedCount - 1]
        guard let history = characterHistory[String(newestChar)], history.count >= 10 else {
            return false
        }

        // Check if accuracy is 90% or better on newest character
        return accuracy(for: newestChar) >= 90.0
    }

    /// Unlock the next character in Koch sequence
    mutating func unlockNextCharacter() {
        if unlockedCount < KochSequence.totalCharacters {
            unlockedCount += 1
        }
    }

    /// Get the characters currently available for practice
    var availableCharacters: [MorseCharacter] {
        KochSequence.characters(upTo: unlockedCount)
    }
}
