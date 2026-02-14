import XCTest
@testable import MorseTrainer

@MainActor
final class DrillViewModelTests: XCTestCase {
    
    var viewModel: DrillViewModel!
    var progressManager: ProgressManager!
    
    override func setUp() async throws {
        // Create fresh progress manager for each test
        progressManager = ProgressManager()
        progressManager.resetProgress()
        
        viewModel = DrillViewModel()
        viewModel.setup(progressManager: progressManager)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        progressManager = nil
    }
    
    func testInitialization() {
        XCTAssertNil(viewModel.currentCharacter)
        XCTAssertEqual(viewModel.feedbackState, .none)
        XCTAssertFalse(viewModel.showingAnswer)
        XCTAssertEqual(viewModel.sessionCorrect, 0)
        XCTAssertEqual(viewModel.sessionTotal, 0)
        XCTAssertNil(viewModel.justUnlockedCharacter)
        XCTAssertFalse(viewModel.isPlaying)
    }
    
    func testAvailableCharacters() {
        let available = viewModel.availableCharacters
        
        // Should have at least the minimum Koch characters (K and M)
        XCTAssertGreaterThanOrEqual(available.count, KochSequence.minimumCharacters)
        
        // Should contain the first Koch characters
        XCTAssertTrue(available.contains { $0.character == "K" })
        XCTAssertTrue(available.contains { $0.character == "M" })
    }
    
    func testSessionAccuracy_NoAttempts() {
        XCTAssertEqual(viewModel.sessionAccuracy, 0.0)
    }
    
    func testSessionAccuracy_WithAttempts() {
        viewModel.sessionCorrect = 3
        viewModel.sessionTotal = 5
        
        // 3/5 = 60%
        XCTAssertEqual(viewModel.sessionAccuracy, 60.0)
    }
    
    func testStartNewRound() {
        viewModel.startNewRound()
        
        XCTAssertNotNil(viewModel.currentCharacter)
        XCTAssertEqual(viewModel.feedbackState, .none)
        XCTAssertFalse(viewModel.showingAnswer)
        XCTAssertNil(viewModel.justUnlockedCharacter)
    }
    
    func testStartNewRound_SelectsFromAvailableCharacters() {
        viewModel.startNewRound()
        
        let currentChar = viewModel.currentCharacter
        XCTAssertNotNil(currentChar)
        
        // Should be one of the available characters
        XCTAssertTrue(viewModel.availableCharacters.contains(currentChar!))
    }
    
    func testSubmitAnswer_Correct() {
        viewModel.startNewRound()
        let correctAnswer = viewModel.currentCharacter!.character
        
        // Submit correct answer
        viewModel.submitAnswer(correctAnswer)
        
        XCTAssertEqual(viewModel.feedbackState, .correct)
        XCTAssertTrue(viewModel.showingAnswer)
        XCTAssertEqual(viewModel.sessionCorrect, 1)
        XCTAssertEqual(viewModel.sessionTotal, 1)
    }
    
    func testSubmitAnswer_Incorrect() {
        viewModel.startNewRound()
        let currentChar = viewModel.currentCharacter!.character
        
        // Find a different character to submit as wrong answer
        let wrongAnswer: Character = currentChar == "K" ? "M" : "K"
        
        viewModel.submitAnswer(wrongAnswer)
        
        XCTAssertEqual(viewModel.feedbackState, .incorrect)
        XCTAssertTrue(viewModel.showingAnswer)
        XCTAssertEqual(viewModel.sessionCorrect, 0)
        XCTAssertEqual(viewModel.sessionTotal, 1)
    }
    
    func testSubmitAnswer_IgnoresWhilePlaying() {
        viewModel.startNewRound()
        
        // Simulate audio playing
        viewModel.isPlaying = true
        
        let correctAnswer = viewModel.currentCharacter!.character
        viewModel.submitAnswer(correctAnswer)
        
        // Should not register the answer
        XCTAssertEqual(viewModel.sessionTotal, 0)
        XCTAssertEqual(viewModel.feedbackState, .none)
    }
    
    func testSubmitAnswer_IgnoresDuplicates() {
        viewModel.startNewRound()
        let correctAnswer = viewModel.currentCharacter!.character
        
        // Submit answer twice
        viewModel.submitAnswer(correctAnswer)
        viewModel.submitAnswer(correctAnswer)
        
        // Should only count once
        XCTAssertEqual(viewModel.sessionTotal, 1)
        XCTAssertEqual(viewModel.sessionCorrect, 1)
    }
    
    func testSubmitAnswer_UpdatesProgressManager() {
        viewModel.startNewRound()
        let correctAnswer = viewModel.currentCharacter!.character
        
        let initialAttempts = progressManager.progress.totalAttempts
        
        viewModel.submitAnswer(correctAnswer)
        
        XCTAssertEqual(progressManager.progress.totalAttempts, initialAttempts + 1)
        XCTAssertEqual(progressManager.progress.totalCorrect, 1)
    }
    
    func testSubmitAnswer_DetectsUnlock() {
        // Set up conditions for unlock
        // Need 8+ attempts at 80%+ accuracy on newest character
        for _ in 0..<8 {
            progressManager.recordAttempt(character: "K", correct: true)
            progressManager.recordAttempt(character: "M", correct: true)
        }
        
        let initialUnlocked = progressManager.progress.unlockedCount
        
        viewModel.startNewRound()
        let correctAnswer = viewModel.currentCharacter!.character
        viewModel.submitAnswer(correctAnswer)
        
        // Check if unlock occurred
        if progressManager.progress.unlockedCount > initialUnlocked {
            XCTAssertNotNil(viewModel.justUnlockedCharacter)
        }
    }
    
    func testIsValidAnswer() {
        // Available characters should be valid
        for char in viewModel.availableCharacters {
            XCTAssertTrue(viewModel.isValidAnswer(char.character))
        }
        
        // Unlocked characters beyond available should be invalid if not unlocked
        if progressManager.progress.unlockedCount < KochSequence.totalCharacters {
            let lastChar = KochSequence.order.last!
            XCTAssertFalse(viewModel.isValidAnswer(lastChar))
        }
    }
    
    func testIsValidAnswer_CaseInsensitive() {
        XCTAssertTrue(viewModel.isValidAnswer("k"))
        XCTAssertTrue(viewModel.isValidAnswer("K"))
        XCTAssertTrue(viewModel.isValidAnswer("m"))
        XCTAssertTrue(viewModel.isValidAnswer("M"))
    }
    
    func testHandleKeyboardInput() {
        viewModel.startNewRound()
        let correctAnswer = viewModel.currentCharacter!.character
        
        // Test lowercase input
        viewModel.handleKeyboardInput(Character(correctAnswer.lowercased()))
        
        XCTAssertEqual(viewModel.sessionTotal, 1)
        XCTAssertEqual(viewModel.feedbackState, .correct)
    }
    
    func testHandleKeyboardInput_IgnoresInvalid() {
        viewModel.startNewRound()
        
        // Try to submit an invalid character (not unlocked)
        let invalidChar = KochSequence.order.last!
        
        // Only submit if it's actually not available
        if !viewModel.availableCharacters.contains(where: { $0.character == invalidChar }) {
            viewModel.handleKeyboardInput(invalidChar)
            
            // Should not register
            XCTAssertEqual(viewModel.sessionTotal, 0)
        }
    }
    
    func testSkipToNext() {
        viewModel.startNewRound()
        let firstChar = viewModel.currentCharacter
        
        viewModel.skipToNext()
        
        // Should have a new character (may be the same by random chance)
        XCTAssertNotNil(viewModel.currentCharacter)
        XCTAssertEqual(viewModel.feedbackState, .none)
        XCTAssertFalse(viewModel.showingAnswer)
    }
    
    func testResetSession() {
        // Set up some session state
        viewModel.startNewRound()
        viewModel.submitAnswer(viewModel.currentCharacter!.character)
        
        XCTAssertGreaterThan(viewModel.sessionTotal, 0)
        
        // Reset
        viewModel.resetSession()
        
        XCTAssertEqual(viewModel.sessionCorrect, 0)
        XCTAssertEqual(viewModel.sessionTotal, 0)
        XCTAssertEqual(viewModel.feedbackState, .none)
        XCTAssertFalse(viewModel.showingAnswer)
        XCTAssertNil(viewModel.currentCharacter)
        XCTAssertNil(viewModel.justUnlockedCharacter)
    }
    
    func testUpdateAudioSettings() {
        // Change settings
        progressManager.settings.characterWPM = 25.0
        progressManager.settings.farnsworthWPM = 10.0
        progressManager.settings.toneFrequency = 800.0
        progressManager.save()
        
        // Update audio settings should apply these
        viewModel.updateAudioSettings()
        
        // We can't directly test AudioEngine properties from here,
        // but we can verify the method doesn't crash
        XCTAssertNotNil(viewModel)
    }
}
