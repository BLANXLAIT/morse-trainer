import XCTest

final class MorseTrainerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Navigation Tests

    func testNavigateToDrillAndBack() {
        app.buttons["StartDrill"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))
        app.buttons["DoneButton"].tap()
        XCTAssertTrue(app.buttons["StartDrill"].waitForExistence(timeout: 3))
    }

    func testNavigateToLiveCopyAndBack() {
        app.buttons["LiveCopy"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))
        app.buttons["DoneButton"].tap()
        XCTAssertTrue(app.buttons["LiveCopy"].waitForExistence(timeout: 3))
    }

    func testNavigateToHeadCopyAndBack() {
        app.buttons["HeadCopy"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))
        app.buttons["DoneButton"].tap()
        XCTAssertTrue(app.buttons["HeadCopy"].waitForExistence(timeout: 3))
    }

    func testNavigateToProgressAndBack() {
        app.buttons["Progress"].tap()
        // StatsView is presented as a sheet
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testNavigateToSettingsAndBack() {
        app.buttons["Settings"].tap()
        // SettingsView is presented as a sheet
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    // MARK: - Live Copy Flow

    func testLiveCopyShowsInputSlots() {
        app.buttons["LiveCopy"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))

        // Input slots appear after sequence generation; search all element types
        let predicate = NSPredicate(format: "identifier == 'InputSlot_0'")
        let firstSlot = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(firstSlot.waitForExistence(timeout: 15))
    }

    func testLiveCopyReplayButton() {
        app.buttons["LiveCopy"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))

        let replayButton = app.buttons["ReplayButton"]
        XCTAssertTrue(replayButton.waitForExistence(timeout: 3))
    }

    // MARK: - Head Copy Flow

    func testHeadCopyShowsInputSlots() {
        app.buttons["HeadCopy"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))

        let predicate = NSPredicate(format: "identifier == 'InputSlot_0'")
        let firstSlot = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(firstSlot.waitForExistence(timeout: 15))
    }

    // MARK: - Drill Flow

    func testDrillShowsReplayButton() {
        app.buttons["StartDrill"].tap()
        XCTAssertTrue(app.buttons["DoneButton"].waitForExistence(timeout: 3))

        let replayButton = app.buttons["ReplayButton"]
        XCTAssertTrue(replayButton.waitForExistence(timeout: 3))
    }
}
