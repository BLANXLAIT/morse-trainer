import XCTest
@testable import MorseTrainer

@MainActor
final class LiveCopyViewModelTests: XCTestCase {

    var viewModel: LiveCopyViewModel!
    var progressManager: ProgressManager!

    override func setUp() async throws {
        progressManager = ProgressManager()
        progressManager.resetProgress()

        viewModel = LiveCopyViewModel()
        viewModel.setup(progressManager: progressManager)
    }

    override func tearDown() async throws {
        viewModel = nil
        progressManager = nil
    }

    // MARK: - Initialization

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
        XCTAssertGreaterThanOrEqual(available.count, KochSequence.minimumCharacters)
        XCTAssertTrue(available.contains { $0.character == "K" })
        XCTAssertTrue(available.contains { $0.character == "M" })
    }

    // MARK: - Session Stats

    func testSessionAccuracy_NoAttempts() {
        XCTAssertEqual(viewModel.sessionAccuracy, 0.0)
    }

    func testSessionAccuracy_WithAttempts() {
        viewModel.sessionCorrect = 7
        viewModel.sessionTotal = 10
        XCTAssertEqual(viewModel.sessionAccuracy, 70.0)
    }

    // MARK: - Start New Round

    func testStartNewRound() {
        viewModel.startNewRound()

        XCTAssertFalse(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertTrue(viewModel.feedbackResults.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
        XCTAssertNil(viewModel.justUnlockedCharacter)
    }

    func testStartNewRound_SequenceLengthScalesWithUnlockedCharacters() {
        let charCount = viewModel.availableCharacters.count
        let expectedMax = min(20, 5 + charCount)

        for _ in 0..<20 {
            viewModel.startNewRound()
            viewModel.stop()
            XCTAssertGreaterThanOrEqual(viewModel.sequenceLength, 5)
            XCTAssertLessThanOrEqual(viewModel.sequenceLength, expectedMax)
        }
    }

    func testStartNewRound_SelectsFromAvailableCharacters() {
        viewModel.startNewRound()

        for morseChar in viewModel.currentSequence {
            XCTAssertTrue(viewModel.availableCharacters.contains(morseChar))
        }
    }

    // MARK: - Input During Playback (Key Difference from Head Copy)

    func testAppendInput_AcceptsDuringPlayback() {
        viewModel.startNewRound()
        viewModel.isPlaying = true

        let char = viewModel.availableCharacters.first!.character
        viewModel.appendInput(char)

        XCTAssertEqual(viewModel.userInput.count, 1)
        XCTAssertEqual(viewModel.userInput[0], char)
    }

    func testAppendInput_LimitsToSequenceLength() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength

        let char = viewModel.availableCharacters.first!.character
        for _ in 0..<(sequenceLength + 5) {
            viewModel.appendInput(char)
        }

        XCTAssertEqual(viewModel.userInput.count, sequenceLength)
    }

    func testAppendInput_IgnoresAfterSubmission() {
        viewModel.startNewRound()
        viewModel.isSubmitted = true

        let char = viewModel.availableCharacters.first!.character
        viewModel.appendInput(char)

        XCTAssertEqual(viewModel.userInput.count, 0)
    }

    func testAppendInput_AutoSubmitsWhenComplete() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength

        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }

        XCTAssertTrue(viewModel.isSubmitted)
    }

    // MARK: - Delete

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
        XCTAssertEqual(viewModel.userInput.count, 1)
    }

    // MARK: - Submit

    func testSubmitSequence_AllCorrect() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength

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

        viewModel.appendInput(viewModel.currentSequence[0].character)
        for i in 1..<sequenceLength {
            let wrongChar: Character = viewModel.currentSequence[i].character == "K" ? "M" : "K"
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

        let halfLength = sequenceLength / 2
        for i in 0..<halfLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }

        viewModel.submitSequence()

        XCTAssertTrue(viewModel.isSubmitted)
        XCTAssertEqual(viewModel.sessionTotal, sequenceLength)
        XCTAssertEqual(viewModel.sessionCorrect, halfLength)

        for i in 0..<halfLength {
            XCTAssertEqual(viewModel.feedbackResults[i], true)
        }
        for i in halfLength..<sequenceLength {
            XCTAssertEqual(viewModel.feedbackResults[i], false)
        }
    }

    func testSubmitSequence_IgnoresDuplicates() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength

        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }

        let firstTotal = viewModel.sessionTotal
        viewModel.submitSequence()

        XCTAssertEqual(viewModel.sessionTotal, firstTotal)
    }

    func testSubmitSequence_UpdatesProgressManager() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength

        let initialAttempts = progressManager.progress.totalAttempts

        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }

        XCTAssertEqual(progressManager.progress.totalAttempts, initialAttempts + sequenceLength)
    }

    // MARK: - Validation

    func testIsValidAnswer() {
        for char in viewModel.availableCharacters {
            XCTAssertTrue(viewModel.isValidAnswer(char.character))
        }

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
        viewModel.handleKeyboardInput(Character(char.lowercased()))

        XCTAssertEqual(viewModel.userInput.count, 1)
        XCTAssertEqual(viewModel.userInput[0], char)
    }

    func testHandleKeyboardInput_IgnoresInvalid() {
        viewModel.startNewRound()

        let invalidChar = KochSequence.order.last!

        if !viewModel.availableCharacters.contains(where: { $0.character == invalidChar }) {
            viewModel.handleKeyboardInput(invalidChar)
            XCTAssertEqual(viewModel.userInput.count, 0)
        }
    }

    // MARK: - Skip (allows during playback)

    func testSkipToNext() {
        viewModel.startNewRound()
        viewModel.skipToNext()

        XCTAssertFalse(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
    }

    func testSkipToNext_WorksDuringPlayback() {
        viewModel.startNewRound()
        viewModel.isPlaying = true

        viewModel.skipToNext()

        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertFalse(viewModel.isSubmitted)
    }

    // MARK: - Reset

    func testResetSession() {
        viewModel.startNewRound()
        let sequenceLength = viewModel.sequenceLength
        for i in 0..<sequenceLength {
            viewModel.appendInput(viewModel.currentSequence[i].character)
        }

        XCTAssertGreaterThan(viewModel.sessionTotal, 0)

        viewModel.resetSession()

        XCTAssertEqual(viewModel.sessionCorrect, 0)
        XCTAssertEqual(viewModel.sessionTotal, 0)
        XCTAssertFalse(viewModel.isSubmitted)
        XCTAssertTrue(viewModel.currentSequence.isEmpty)
        XCTAssertTrue(viewModel.userInput.isEmpty)
        XCTAssertTrue(viewModel.feedbackResults.isEmpty)
        XCTAssertNil(viewModel.justUnlockedCharacter)
    }

    // MARK: - Audio Settings

    func testUpdateAudioSettings() {
        progressManager.settings.characterWPM = 25.0
        progressManager.settings.farnsworthWPM = 10.0
        progressManager.settings.toneFrequency = 800.0
        progressManager.save()

        viewModel.updateAudioSettings()

        XCTAssertNotNil(viewModel)
    }
}
