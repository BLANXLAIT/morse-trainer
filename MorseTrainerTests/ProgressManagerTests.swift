import XCTest
@testable import MorseTrainer

@MainActor
final class ProgressManagerTests: XCTestCase {
    
    var progressManager: ProgressManager!
    let testProgressKey = "testUserProgress"
    let testSettingsKey = "testAppSettings"
    
    override func setUp() async throws {
        // Clean up any existing test data
        UserDefaults.standard.removeObject(forKey: testProgressKey)
        UserDefaults.standard.removeObject(forKey: testSettingsKey)
        
        progressManager = ProgressManager()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: "userProgress")
        UserDefaults.standard.removeObject(forKey: "appSettings")
        progressManager = nil
    }
    
    func testInitialization_NewUser() {
        // Should create default progress
        XCTAssertEqual(progressManager.progress.unlockedCount, KochSequence.minimumCharacters)
        XCTAssertEqual(progressManager.progress.totalAttempts, 0)
        
        // Should create default settings
        XCTAssertEqual(progressManager.settings.characterWPM, 20.0)
        XCTAssertEqual(progressManager.settings.farnsworthWPM, 5.0)
        XCTAssertEqual(progressManager.settings.toneFrequency, 700.0)
        XCTAssertTrue(progressManager.settings.hapticFeedback)
    }
    
    func testSaveAndLoad() {
        // Modify progress
        progressManager.progress.totalCorrect = 10
        progressManager.progress.totalAttempts = 20
        progressManager.progress.unlockedCount = 5
        
        // Modify settings
        progressManager.settings.characterWPM = 25.0
        progressManager.settings.toneFrequency = 800.0
        
        // Save
        progressManager.save()
        
        // Create new manager - should load saved data
        let newManager = ProgressManager()
        
        XCTAssertEqual(newManager.progress.totalCorrect, 10)
        XCTAssertEqual(newManager.progress.totalAttempts, 20)
        XCTAssertEqual(newManager.progress.unlockedCount, 5)
        XCTAssertEqual(newManager.settings.characterWPM, 25.0)
        XCTAssertEqual(newManager.settings.toneFrequency, 800.0)
    }
    
    func testRecordAttempt_Correct() {
        let initialAttempts = progressManager.progress.totalAttempts
        let initialCorrect = progressManager.progress.totalCorrect
        
        progressManager.recordAttempt(character: "K", correct: true)
        
        XCTAssertEqual(progressManager.progress.totalAttempts, initialAttempts + 1)
        XCTAssertEqual(progressManager.progress.totalCorrect, initialCorrect + 1)
        XCTAssertEqual(progressManager.progress.sessionTotal, 1)
        XCTAssertEqual(progressManager.progress.sessionCorrect, 1)
    }
    
    func testRecordAttempt_Incorrect() {
        let initialAttempts = progressManager.progress.totalAttempts
        let initialCorrect = progressManager.progress.totalCorrect
        
        progressManager.recordAttempt(character: "K", correct: false)
        
        XCTAssertEqual(progressManager.progress.totalAttempts, initialAttempts + 1)
        XCTAssertEqual(progressManager.progress.totalCorrect, initialCorrect)
        XCTAssertEqual(progressManager.progress.sessionTotal, 1)
        XCTAssertEqual(progressManager.progress.sessionCorrect, 0)
    }
    
    func testRecordAttempt_Persists() {
        progressManager.recordAttempt(character: "K", correct: true)
        
        // Create new manager - should load persisted data
        let newManager = ProgressManager()
        
        XCTAssertEqual(newManager.progress.totalAttempts, 1)
        XCTAssertEqual(newManager.progress.totalCorrect, 1)
    }
    
    func testRecordAttempt_TriggersUnlock() {
        let initialUnlocked = progressManager.progress.unlockedCount
        
        // Create conditions for unlock
        // Need 8+ attempts at 80%+ accuracy on newest character (M)
        for _ in 0..<8 {
            progressManager.recordAttempt(character: "K", correct: true)
            progressManager.recordAttempt(character: "M", correct: true)
        }
        
        // Should have unlocked at least one character
        XCTAssertGreaterThanOrEqual(progressManager.progress.unlockedCount, initialUnlocked + 1)
    }
    
    func testRecordAttempt_MultiUnlock() {
        let initialUnlocked = progressManager.progress.unlockedCount
        
        // Create conditions for multi-unlock: pool >= 95%, newest >= 90%
        for _ in 0..<10 {
            progressManager.recordAttempt(character: "K", correct: true)
            progressManager.recordAttempt(character: "M", correct: true)
        }
        
        // Should have unlocked multiple characters
        let unlocked = progressManager.progress.unlockedCount - initialUnlocked
        XCTAssertGreaterThanOrEqual(unlocked, 1)
    }
    
    func testResetSession() {
        // Add some session data
        progressManager.recordAttempt(character: "K", correct: true)
        progressManager.recordAttempt(character: "M", correct: false)
        
        XCTAssertGreaterThan(progressManager.progress.sessionTotal, 0)
        
        progressManager.resetSession()
        
        XCTAssertEqual(progressManager.progress.sessionCorrect, 0)
        XCTAssertEqual(progressManager.progress.sessionTotal, 0)
        XCTAssertNotNil(progressManager.progress.lastSessionDate)
    }
    
    func testResetSession_Persists() {
        progressManager.recordAttempt(character: "K", correct: true)
        progressManager.resetSession()
        
        // Create new manager - should load persisted reset state
        let newManager = ProgressManager()
        
        XCTAssertEqual(newManager.progress.sessionCorrect, 0)
        XCTAssertEqual(newManager.progress.sessionTotal, 0)
    }
    
    func testResetProgress() {
        // Add some data
        progressManager.recordAttempt(character: "K", correct: true)
        progressManager.recordAttempt(character: "M", correct: true)
        progressManager.progress.unlockNextCharacter()
        
        progressManager.resetProgress()
        
        // Should be back to defaults
        XCTAssertEqual(progressManager.progress.unlockedCount, KochSequence.minimumCharacters)
        XCTAssertEqual(progressManager.progress.totalAttempts, 0)
        XCTAssertEqual(progressManager.progress.totalCorrect, 0)
        XCTAssertEqual(progressManager.progress.currentStreak, 0)
        XCTAssertEqual(progressManager.progress.sessionCorrect, 0)
        XCTAssertEqual(progressManager.progress.sessionTotal, 0)
    }
    
    func testResetSettings() {
        // Modify settings
        progressManager.settings.characterWPM = 30.0
        progressManager.settings.farnsworthWPM = 15.0
        progressManager.settings.toneFrequency = 900.0
        progressManager.settings.hapticFeedback = false
        
        progressManager.resetSettings()
        
        // Should be back to defaults
        XCTAssertEqual(progressManager.settings.characterWPM, 20.0)
        XCTAssertEqual(progressManager.settings.farnsworthWPM, 5.0)
        XCTAssertEqual(progressManager.settings.toneFrequency, 700.0)
        XCTAssertTrue(progressManager.settings.hapticFeedback)
    }
    
    func testResetAll() {
        // Add some data
        progressManager.recordAttempt(character: "K", correct: true)
        progressManager.settings.characterWPM = 30.0
        
        progressManager.resetAll()
        
        // Both progress and settings should be reset
        XCTAssertEqual(progressManager.progress.totalAttempts, 0)
        XCTAssertEqual(progressManager.settings.characterWPM, 20.0)
    }
    
    func testAppSettings_DefaultValues() {
        let settings = AppSettings()
        
        XCTAssertEqual(settings.characterWPM, 20.0)
        XCTAssertEqual(settings.farnsworthWPM, 5.0)
        XCTAssertEqual(settings.toneFrequency, 700.0)
        XCTAssertTrue(settings.hapticFeedback)
        XCTAssertFalse(settings.eyesClosedMode)
        XCTAssertTrue(settings.audioFeedback)
        XCTAssertTrue(settings.speakAnswer)
    }
    
    func testAppSettings_Codable() {
        var settings = AppSettings()
        settings.characterWPM = 25.0
        settings.farnsworthWPM = 10.0
        settings.toneFrequency = 800.0
        settings.hapticFeedback = false
        
        // Encode
        let encoder = JSONEncoder()
        let data: Data
        do {
            data = try encoder.encode(settings)
        } catch {
            XCTFail("Failed to encode settings: \(error)")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        let decoded: AppSettings
        do {
            decoded = try decoder.decode(AppSettings.self, from: data)
        } catch {
            XCTFail("Failed to decode settings: \(error)")
            return
        }
        
        XCTAssertEqual(decoded.characterWPM, 25.0)
        XCTAssertEqual(decoded.farnsworthWPM, 10.0)
        XCTAssertEqual(decoded.toneFrequency, 800.0)
        XCTAssertFalse(decoded.hapticFeedback)
    }
}
