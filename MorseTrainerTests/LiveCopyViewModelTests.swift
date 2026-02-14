import XCTest
@testable import MorseTrainer

@MainActor
final class LiveCopyViewModelTests: XCTestCase {
    
    var viewModel: LiveCopyViewModel!
    var progressManager: ProgressManager!
    
    override func setUp() async throws {
        // Create fresh progress manager for each test
        progressManager = ProgressManager()
        progressManager.resetProgress()
        
        viewModel = LiveCopyViewModel()
        viewModel.setup(progressManager: progressManager)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        progressManager = nil
    }
    
    func testInitialization() {
        XCTAssertTrue(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertTrue(viewModel.feedbackResults.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
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
        viewModel.sessionCorrect = 7
        viewModel.sessionTotal = 10
        
        // 7/10 = 70%
        XCTAssertEqual(viewModel.sessionAccuracy, 70.0)
    }
    
    func testStartNewRound() {
        viewModel.startNewRound()
        
        XCTAssertFalse(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertTrue(viewModel.feedbackResults.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
        XCTAssertNil(viewModel.justUnlockedCharacter)
    }
    
    func testStartNewRound_SequenceLengthInRange() {
        viewModel.startNewRound()
        
        // Live copy uses longer sequences (5-20 characters)
        XCTAssertGreaterThanOrEqual(viewModel.sequenceLength, 5)
        XCTAssertLessThanOrEqual(viewModel.sequenceLength, 20)
    }
    
    func testStartNewRound_SelectsFromAvailableCharacters() {
        viewModel.startNewRound()
        
        // All characters in sequence should be from available characters
        for morseChar in viewModel.currentSequence {
            XCTAssertTrue(viewModel.availableCharacters.contains(morseChar))
        }
    }
    
    func testAppendInput_AcceptsDuringPlayback() {
        viewModel.startNewRound()
        
        // Simulate audio playing (KEY DIFFERENCE from HeadCopy)
        viewModel.isPlaying = true
        
        let char = viewModel.availableCharacters.first!.character
        viewModel.appendInput(char)
        
        // Should accept input even while playing
        XCTAssertEqual(viewModel.userInput.count, 1)
        XCTAssertEqual(viewModel.userInput[0], char)
    }
    
    func testAppendInput_LimitsToSequenceLength() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Try to add more inputs than sequence length
        let char = viewModel.availableCharacters.first!.character
        for _ in 0..<(sequenceLength + 5) {
            viewModel.appendInput(char)
        }
        
        // Should only accept up to sequence length
        XCTAssertEqual(viewModel.userInput.count, sequenceLength)
    }
    
    func testAppendInput_IgnoresAfterSubmission() {
        viewModel.startNewRound()
        viewModel.isSubmitted = true
        
        let char = viewModel.availableCharacters.first!.character
        viewModel.appendInput(char)
        
        // Should not accept input after submission
        XCTAssertEqual(viewModel.userInput.count, 0)
    }
    
    func testAppendInput_AutoSubmitsWhenComplete() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Fill in all positions with correct answers
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        // Should auto-submit
        XCTAssertTrue(viewModel.isSubmitted)
    }
    
    func testDeleteLastInput() {
        viewModel.startNewRound()
        
        let char1 = viewModel.availableCharacters[0].character
        let char2 = viewModel.availableCharacters[1].character
        
        viewModel.appendInput(char1)
        viewModel.appendInput(char2)
        XCTAssertEqual(viewModel.userInput.count, 2)
        
        viewModel.deleteLastInput()
        XCTAssertEqual(viewModel.userInput.count, 1)
        XCTAssertEqual(viewModel.userInput[0], char1)
    }
    
    func testDeleteLastInput_IgnoresWhenEmpty() {
        viewModel.startNewRound()
        
        viewModel.deleteLastInput()
        
        XCTAssertEqual(viewModel.userInput.count, 0)
    }
    
    func testDeleteLastInput_IgnoresAfterSubmission() {
        viewModel.startNewRound()
        
        let char = viewModel.availableCharacters.first!.character
        viewModel.appendInput(char)
        viewModel.isSubmitted = true
        
        viewModel.deleteLastInput()
        
        // Should not delete after submission
        XCTAssertEqual(viewModel.userInput.count, 1)
    }
    
    func testSubmitSequence_AllCorrect() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Submit all correct answers
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        XCTAssertTrue(viewModel.isSubmitted)
        XCTAssertEqual(viewModel.sessionTotal, sequenceLength)
        XCTAssertEqual(viewModel.sessionCorrect, sequenceLength)
        XCTAssertEqual(viewModel.feedbackResults.count, sequenceLength)
        XCTAssertTrue(viewModel.feedbackResults.allSatisfy { $0 == true })
    }
    
    func testSubmitSequence_SomeIncorrect() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Submit first correct, then all wrong
        viewModel.appendInput(viewModel.currentSequence[0].character)
        for i in 1..<sequenceLength {
            let wrongChar = viewModel.currentSequence[i].character == "K" ? "M" : "K"
            viewModel.appendInput(wrongChar)
        }
        
        XCTAssertTrue(viewModel.isSubmitted)
        XCTAssertEqual(viewModel.sessionTotal, sequenceLength)
        XCTAssertEqual(viewModel.sessionCorrect, 1)
        XCTAssertEqual(viewModel.feedbackResults[0], true)
        for i in 1..<sequenceLength {
            XCTAssertEqual(viewModel.feedbackResults[i], false)
        }
    }
    
    func testSubmitSequence_MissedCharacters() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Only submit half the answers (user fell behind)
        let halfLength = sequenceLength / 2
        for i in 0..<halfLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        viewModel.submitSequence()
        
        XCTAssertTrue(viewModel.isSubmitted)
        XCTAssertEqual(viewModel.sessionTotal, sequenceLength)
        XCTAssertEqual(viewModel.sessionCorrect, halfLength)
        
        // First half should be correct
        for i in 0..<halfLength {
            XCTAssertEqual(viewModel.feedbackResults[i], true)
        }
        
        // Second half should be marked as incorrect (missed)
        for i in halfLength..<sequenceLength {
            XCTAssertEqual(viewModel.feedbackResults[i], false)
        }
    }
    
    func testSubmitSequence_IgnoresDuplicates() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        // Fill sequence
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        let firstTotal = viewModel.sessionTotal
        
        // Try to submit again
        viewModel.submitSequence()
        
        // Should not count twice
        XCTAssertEqual(viewModel.sessionTotal, firstTotal)
    }
    
    func testSubmitSequence_UpdatesProgressManager() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        
        let initialAttempts = progressManager.progress.totalAttempts
        
        // Submit all correct answers
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        XCTAssertEqual(progressManager.progress.totalAttempts, initialAttempts + sequenceLength)
    }
    
    func testIsValidAnswer() {
        // Available characters should be valid
        for char in viewModel.availableCharacters {
            XCTAssertTrue(viewModel.isValidAnswer(char.character))
        }
        
        // Locked characters should be invalid if not unlocked
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
        
        let char = viewModel.availableCharacters.first!.character
        
        // Test lowercase input
        viewModel.handleKeyboardInput(Character(char.lowercased()))
        
        XCTAssertEqual(viewModel.userInput.count, 1)
        XCTAssertEqual(viewModel.userInput[0], char)
    }
    
    func testHandleKeyboardInput_IgnoresInvalid() {
        viewModel.startNewRound()
        
        // Try to submit an invalid character (not unlocked)
        let invalidChar = KochSequence.order.last!
        
        // Only test if it's actually not available
        if !viewModel.availableCharacters.contains(where: { $0.character == invalidChar }) {
            viewModel.handleKeyboardInput(invalidChar)
            
            // Should not register
            XCTAssertEqual(viewModel.userInput.count, 0)
        }
    }
    
    func testSkipToNext() {
        viewModel.startNewRound()
        let firstSequenceLength = viewModel.sequenceLength
        
        viewModel.skipToNext()
        
        // Should have a new sequence
        XCTAssertFalse(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
    }
    
    func testResetSession() {
        // Set up some session state
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }
        
        XCTAssertGreaterThan(viewModel.sessionTotal, 0)
        
        // Reset
        viewModel.resetSession()
        
        XCTAssertEqual(viewModel.sessionCorrect, 0)
        XCTAssertEqual(viewModel.sessionTotal, 0)
        XCTAssertFalse(viewModel.isSubmitted)
        XCTAssertTrue(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertTrue(viewModel.feedbackResults.isEmpty)
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
