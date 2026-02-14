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

    /// Session correct answers (persisted across app restarts)
    var sessionCorrect: Int

    /// Session total attempts (persisted across app restarts)
    var sessionTotal: Int

    /// When the current session started
    var lastSessionDate: Date?

    init() {
        self.unlockedCount = KochSequence.minimumCharacters
        self.characterHistory = [:]
        self.totalCorrect = 0
        self.totalAttempts = 0
        self.currentStreak = 0
        self.bestStreak = 0
        self.sessionCorrect = 0
        self.sessionTotal = 0
        self.lastSessionDate = nil
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

    /// Average accuracy across all unlocked characters that have history
    var poolAccuracy: Double {
        let unlockedChars = KochSequence.order.prefix(unlockedCount)
        let accuracies = unlockedChars.compactMap { char -> Double? in
            guard let history = characterHistory[String(char)], !history.isEmpty else { return nil }
            return accuracy(for: char)
        }
        guard !accuracies.isEmpty else { return 0.0 }
        return accuracies.reduce(0, +) / Double(accuracies.count)
    }

    /// Whether the user has scored 100% on their last 5 attempts across all characters
    var hasMomentum: Bool {
        // Collect the most recent attempts across all characters, ordered by recency
        // Since we only store per-character history, check if the global streak is >= 5
        return currentStreak >= 5
    }

    /// Determine how many characters to unlock (0, 1, or 2)
    func charactersToUnlock() -> Int {
        guard unlockedCount < KochSequence.totalCharacters else { return 0 }

        let newestChar = KochSequence.order[unlockedCount - 1]
        let newestHistory = characterHistory[String(newestChar)] ?? []
        let newestAcc = accuracy(for: newestChar)
        let pool = poolAccuracy

        // Momentum bonus: relax newest-character gate
        if hasMomentum && newestHistory.count >= 5 && newestAcc >= 70.0 && pool >= 75.0 {
            return 1
        }

        // Primary gate: newest character readiness
        guard newestHistory.count >= 8 && newestAcc >= 80.0 else { return 0 }

        // Pool health: all unlocked characters must average ≥75%
        guard pool >= 75.0 else { return 0 }

        // Multi-unlock: experienced operator advancing fast
        if pool >= 95.0 && newestAcc >= 90.0 && unlockedCount + 1 < KochSequence.totalCharacters {
            return 2
        }

        return 1
    }

    /// Legacy compatibility — true if at least one character should unlock
    func shouldUnlockNextCharacter() -> Bool {
        return charactersToUnlock() > 0
    }

    /// Unlock the next n characters in Koch sequence (clamped to max)
    mutating func unlockNextCharacters(_ count: Int = 1) {
        let newCount = min(unlockedCount + count, KochSequence.totalCharacters)
        unlockedCount = newCount
    }

    /// Unlock the next character in Koch sequence
    mutating func unlockNextCharacter() {
        unlockNextCharacters(1)
    }

    /// Record a session attempt (updates session counters)
    mutating func recordSessionAttempt(correct: Bool) {
        if lastSessionDate == nil {
            lastSessionDate = Date()
        }
        sessionTotal += 1
        if correct {
            sessionCorrect += 1
        }
    }

    /// Reset session stats for a new session
    mutating func resetSession() {
        sessionCorrect = 0
        sessionTotal = 0
        lastSessionDate = Date()
    }

    /// Session accuracy percentage
    var sessionAccuracy: Double {
        guard sessionTotal > 0 else { return 0.0 }
        return Double(sessionCorrect) / Double(sessionTotal) * 100.0
    }

    /// Whether the session is stale (4+ hours old)
    var isSessionStale: Bool {
        guard let date = lastSessionDate else { return false }
        return Date().timeIntervalSince(date) >= 4 * 60 * 60
    }

    /// Get the characters currently available for practice
    var availableCharacters: [MorseCharacter] {
        KochSequence.characters(upTo: unlockedCount)
    }
}
