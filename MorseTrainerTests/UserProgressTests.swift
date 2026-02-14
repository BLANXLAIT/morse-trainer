import XCTest
@testable import MorseTrainer

final class UserProgressTests: XCTestCase {
    
    func testInitialization() {
        let progress = UserProgress()
        
        XCTAssertEqual(progress.unlockedCount, KochSequence.minimumCharacters)
        XCTAssertEqual(progress.totalCorrect, 0)
        XCTAssertEqual(progress.totalAttempts, 0)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 0)
        XCTAssertEqual(progress.sessionCorrect, 0)
        XCTAssertEqual(progress.sessionTotal, 0)
        XCTAssertNil(progress.lastSessionDate)
        XCTAssertTrue(progress.characterHistory.isEmpty)
    }
    
    func testRecordAttempt_Correct() {
        var progress = UserProgress()
        
        progress.recordAttempt(character: "K", correct: true)
        
        XCTAssertEqual(progress.totalCorrect, 1)
        XCTAssertEqual(progress.totalAttempts, 1)
        XCTAssertEqual(progress.currentStreak, 1)
        XCTAssertEqual(progress.bestStreak, 1)
        XCTAssertEqual(progress.characterHistory["K"], [true])
    }
    
    func testRecordAttempt_Incorrect() {
        var progress = UserProgress()
        
        progress.recordAttempt(character: "K", correct: false)
        
        XCTAssertEqual(progress.totalCorrect, 0)
        XCTAssertEqual(progress.totalAttempts, 1)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 0)
        XCTAssertEqual(progress.characterHistory["K"], [false])
    }
    
    func testRecordAttempt_StreakTracking() {
        var progress = UserProgress()
        
        // Build a streak
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "M", correct: true)
        progress.recordAttempt(character: "K", correct: true)
        
        XCTAssertEqual(progress.currentStreak, 3)
        XCTAssertEqual(progress.bestStreak, 3)
        
        // Break the streak
        progress.recordAttempt(character: "M", correct: false)
        
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 3) // Best streak should remain
    }
    
    func testRecordAttempt_LimitsHistory() {
        var progress = UserProgress()
        
        // Record 15 attempts (more than the 10 limit)
        for i in 0..<15 {
            progress.recordAttempt(character: "K", correct: i % 2 == 0)
        }
        
        // Should only keep last 10
        XCTAssertEqual(progress.characterHistory["K"]?.count, 10)
    }
    
    func testAccuracy_NoHistory() {
        let progress = UserProgress()
        
        XCTAssertEqual(progress.accuracy(for: "K"), 0.0)
    }
    
    func testAccuracy_WithHistory() {
        var progress = UserProgress()
        
        // 3 correct, 2 incorrect = 60%
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: false)
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: false)
        
        XCTAssertEqual(progress.accuracy(for: "K"), 60.0)
    }
    
    func testOverallAccuracy() {
        var progress = UserProgress()
        
        // No attempts
        XCTAssertEqual(progress.overallAccuracy, 0.0)
        
        // 3 correct out of 5 = 60%
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "M", correct: true)
        progress.recordAttempt(character: "K", correct: false)
        progress.recordAttempt(character: "M", correct: true)
        progress.recordAttempt(character: "K", correct: false)
        
        XCTAssertEqual(progress.overallAccuracy, 60.0)
    }
    
    func testPoolAccuracy() {
        var progress = UserProgress()
        
        // No history - should return 0
        XCTAssertEqual(progress.poolAccuracy, 0.0)
        
        // Add history for unlocked characters (K and M)
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: true)
        progress.recordAttempt(character: "K", correct: true) // K = 100%
        
        progress.recordAttempt(character: "M", correct: true)
        progress.recordAttempt(character: "M", correct: true)
        progress.recordAttempt(character: "M", correct: false)
        progress.recordAttempt(character: "M", correct: false) // M = 50%
        
        // Pool accuracy = (100 + 50) / 2 = 75%
        XCTAssertEqual(progress.poolAccuracy, 75.0)
    }
    
    func testHasMomentum() {
        var progress = UserProgress()
        
        // No momentum initially
        XCTAssertFalse(progress.hasMomentum)
        
        // Build momentum with 5 consecutive correct
        for _ in 0..<5 {
            progress.recordAttempt(character: "K", correct: true)
        }
        
        XCTAssertTrue(progress.hasMomentum)
        
        // Break momentum
        progress.recordAttempt(character: "K", correct: false)
        
        XCTAssertFalse(progress.hasMomentum)
    }
    
    func testCharactersToUnlock_NotReady() {
        var progress = UserProgress()
        
        // Not enough history
        XCTAssertEqual(progress.charactersToUnlock(), 0)
        
        // Not enough correct answers
        for _ in 0..<8 {
            progress.recordAttempt(character: "M", correct: false)
        }
        
        XCTAssertEqual(progress.charactersToUnlock(), 0)
    }
    
    func testCharactersToUnlock_Ready() {
        var progress = UserProgress()
        
        // Make newest character ready (M - index 1 in Koch sequence)
        // Need 8+ attempts at 80%+ accuracy
        for _ in 0..<8 {
            progress.recordAttempt(character: "M", correct: true)
        }
        
        // Need good pool accuracy too
        for _ in 0..<8 {
            progress.recordAttempt(character: "K", correct: true)
        }
        
        XCTAssertEqual(progress.charactersToUnlock(), 1)
    }
    
    func testCharactersToUnlock_MultiUnlock() {
        var progress = UserProgress()

        // Create conditions for multi-unlock: pool >= 95%, newest >= 90%
        // Must break streak so momentum check doesn't short-circuit to 1
        progress.recordAttempt(character: "K", correct: false) // break streak
        for _ in 0..<10 {
            progress.recordAttempt(character: "K", correct: true)
        }
        for _ in 0..<10 {
            progress.recordAttempt(character: "M", correct: true)
        }
        // Break streak at end so hasMomentum is false
        progress.recordAttempt(character: "K", correct: false)

        // Pool accuracy: K=10/10 (last 10), M=10/10 = 100% >= 95%
        // Newest (M) accuracy: 10/10 = 100% >= 90%
        // hasMomentum: false (streak broken), so momentum gate doesn't fire
        XCTAssertEqual(progress.charactersToUnlock(), 2)
    }
    
    func testCharactersToUnlock_MomentumBonus() {
        var progress = UserProgress()
        
        // Build momentum (5+ streak)
        for _ in 0..<5 {
            progress.recordAttempt(character: "K", correct: true)
        }
        
        // For newest character (M), only need 5+ attempts at 70%+ with pool 75%+
        for _ in 0..<5 {
            progress.recordAttempt(character: "M", correct: true)
        }
        
        // Should unlock with momentum bonus
        XCTAssertEqual(progress.charactersToUnlock(), 1)
    }
    
    func testUnlockNextCharacter() {
        var progress = UserProgress()
        let initialCount = progress.unlockedCount
        
        progress.unlockNextCharacter()
        
        XCTAssertEqual(progress.unlockedCount, initialCount + 1)
    }
    
    func testUnlockNextCharacters() {
        var progress = UserProgress()
        let initialCount = progress.unlockedCount
        
        progress.unlockNextCharacters(3)
        
        XCTAssertEqual(progress.unlockedCount, initialCount + 3)
    }
    
    func testUnlockNextCharacters_ClampsToMax() {
        var progress = UserProgress()
        
        // Try to unlock more than total available
        progress.unlockNextCharacters(100)
        
        XCTAssertEqual(progress.unlockedCount, KochSequence.totalCharacters)
    }
    
    func testRecordSessionAttempt() {
        var progress = UserProgress()
        
        XCTAssertNil(progress.lastSessionDate)
        
        progress.recordSessionAttempt(correct: true)
        
        XCTAssertNotNil(progress.lastSessionDate)
        XCTAssertEqual(progress.sessionCorrect, 1)
        XCTAssertEqual(progress.sessionTotal, 1)
        
        progress.recordSessionAttempt(correct: false)
        
        XCTAssertEqual(progress.sessionCorrect, 1)
        XCTAssertEqual(progress.sessionTotal, 2)
    }
    
    func testResetSession() {
        var progress = UserProgress()
        
        // Add some session data
        progress.recordSessionAttempt(correct: true)
        progress.recordSessionAttempt(correct: false)
        
        progress.resetSession()
        
        XCTAssertEqual(progress.sessionCorrect, 0)
        XCTAssertEqual(progress.sessionTotal, 0)
        XCTAssertNotNil(progress.lastSessionDate)
    }
    
    func testSessionAccuracy() {
        var progress = UserProgress()
        
        XCTAssertEqual(progress.sessionAccuracy, 0.0)
        
        progress.recordSessionAttempt(correct: true)
        progress.recordSessionAttempt(correct: true)
        progress.recordSessionAttempt(correct: false)
        
        // 2 out of 3 = 66.67%
        XCTAssertEqual(progress.sessionAccuracy, 66.66666666666667, accuracy: 0.01)
    }
    
    func testIsSessionStale() {
        var progress = UserProgress()
        
        // No session date - not stale
        XCTAssertFalse(progress.isSessionStale)
        
        // Recent session - not stale
        progress.lastSessionDate = Date()
        XCTAssertFalse(progress.isSessionStale)
        
        // Old session (5 hours ago) - stale
        progress.lastSessionDate = Date(timeIntervalSinceNow: -5 * 60 * 60)
        XCTAssertTrue(progress.isSessionStale)
    }
    
    func testAvailableCharacters() {
        var progress = UserProgress()
        
        let available = progress.availableCharacters
        
        XCTAssertEqual(available.count, progress.unlockedCount)
        XCTAssertTrue(available.contains { $0.character == "K" })
        XCTAssertTrue(available.contains { $0.character == "M" })
    }
}
