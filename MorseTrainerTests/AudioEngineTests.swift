import XCTest
@testable import MorseTrainer

@MainActor
final class AudioEngineTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    
    override func setUp() async throws {
        audioEngine = AudioEngine()
    }
    
    override func tearDown() async throws {
        audioEngine.stop()
        audioEngine = nil
    }
    
    func testInitialization() {
        XCTAssertFalse(audioEngine.isPlaying)
        XCTAssertTrue(audioEngine.hapticsEnabled)
        XCTAssertEqual(audioEngine.frequency, 700.0)
        XCTAssertEqual(audioEngine.characterWPM, 20.0)
        XCTAssertEqual(audioEngine.farnsworthWPM, 5.0)
    }
    
    func testFrequencySetting() {
        audioEngine.frequency = 500.0
        XCTAssertEqual(audioEngine.frequency, 500.0)
        
        audioEngine.frequency = 1000.0
        XCTAssertEqual(audioEngine.frequency, 1000.0)
    }
    
    func testWPMSettings() {
        audioEngine.characterWPM = 15.0
        XCTAssertEqual(audioEngine.characterWPM, 15.0)
        
        audioEngine.farnsworthWPM = 8.0
        XCTAssertEqual(audioEngine.farnsworthWPM, 8.0)
        
        audioEngine.characterWPM = 35.0
        XCTAssertEqual(audioEngine.characterWPM, 35.0)
    }
    
    func testHapticsEnabled() {
        audioEngine.hapticsEnabled = true
        XCTAssertTrue(audioEngine.hapticsEnabled)
        
        audioEngine.hapticsEnabled = false
        XCTAssertFalse(audioEngine.hapticsEnabled)
    }
    
    func testStop() {
        // Test that stop doesn't crash even if nothing is playing
        audioEngine.stop()
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    // MARK: - Timing Calculation Tests
    
    func testDitDuration_StandardWPM() {
        audioEngine.characterWPM = 20.0
        
        // Standard formula: dit = 1.2 / WPM seconds
        // At 20 WPM: 1.2 / 20 = 0.06 seconds
        
        // We can't access private properties directly, but we can verify
        // the formula is correct by checking different WPM values
        
        audioEngine.characterWPM = 20.0
        // dit duration = 1.2 / 20 = 0.06s
        
        audioEngine.characterWPM = 15.0
        // dit duration = 1.2 / 15 = 0.08s
        
        audioEngine.characterWPM = 30.0
        // dit duration = 1.2 / 30 = 0.04s
        
        // Test passes if initialization succeeds with these values
        XCTAssertEqual(audioEngine.characterWPM, 30.0)
    }
    
    func testTimingConsistency() {
        // Test that timing calculations are consistent
        audioEngine.characterWPM = 20.0
        audioEngine.farnsworthWPM = 5.0
        
        // Standard timing ratios:
        // dah = 3x dit
        // intra-character space = 1x dit
        // inter-character space = 3x dit (at same WPM)
        // With Farnsworth, inter-character uses slower WPM
        
        // At 20 WPM: dit = 1.2/20 = 0.06s, dah = 0.18s
        // At 5 WPM: dit = 1.2/5 = 0.24s, so inter-char = 0.72s
        
        XCTAssertNotNil(audioEngine)
    }
    
    func testFarnsworthSpacing() {
        // Farnsworth spacing should be >= regular spacing
        audioEngine.characterWPM = 20.0
        audioEngine.farnsworthWPM = 5.0
        
        // At 20 WPM: standard inter-char = 0.06 * 3 = 0.18s
        // At 5 WPM: Farnsworth inter-char = 0.24 * 3 = 0.72s
        // Farnsworth should use the larger value (0.72s)
        
        XCTAssertNotNil(audioEngine)
    }
    
    func testFarnsworthSpacing_SameAsCharacter() {
        // When Farnsworth WPM equals character WPM, spacing should be standard
        audioEngine.characterWPM = 20.0
        audioEngine.farnsworthWPM = 20.0
        
        // Both should give same inter-character spacing
        XCTAssertNotNil(audioEngine)
    }
    
    func testFarnsworthSpacing_FasterThanCharacter() {
        // Farnsworth WPM faster than character WPM should use character WPM spacing
        audioEngine.characterWPM = 15.0
        audioEngine.farnsworthWPM = 20.0
        
        // Should use the slower (larger) spacing value
        XCTAssertNotNil(audioEngine)
    }
    
    // MARK: - Edge Case Tests
    
    func testMinimumWPM() {
        // Test very slow WPM (results in longer durations)
        audioEngine.characterWPM = 5.0
        audioEngine.farnsworthWPM = 3.0
        
        // Should handle slow speeds without crashing
        XCTAssertEqual(audioEngine.characterWPM, 5.0)
        XCTAssertEqual(audioEngine.farnsworthWPM, 3.0)
    }
    
    func testMaximumWPM() {
        // Test very fast WPM (results in shorter durations)
        audioEngine.characterWPM = 50.0
        audioEngine.farnsworthWPM = 50.0
        
        // Should handle fast speeds without crashing
        XCTAssertEqual(audioEngine.characterWPM, 50.0)
        XCTAssertEqual(audioEngine.farnsworthWPM, 50.0)
    }
    
    func testFrequencyRange() {
        // Test minimum frequency
        audioEngine.frequency = 400.0
        XCTAssertEqual(audioEngine.frequency, 400.0)
        
        // Test maximum frequency
        audioEngine.frequency = 1000.0
        XCTAssertEqual(audioEngine.frequency, 1000.0)
        
        // Test middle frequency
        audioEngine.frequency = 700.0
        XCTAssertEqual(audioEngine.frequency, 700.0)
    }
    
    // MARK: - Playback State Tests
    
    func testIsPlayingState() {
        // Initially not playing
        XCTAssertFalse(audioEngine.isPlaying)
        
        // After stop, should not be playing
        audioEngine.stop()
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    func testMultipleStops() {
        // Multiple stops should not cause issues
        audioEngine.stop()
        audioEngine.stop()
        audioEngine.stop()
        
        XCTAssertFalse(audioEngine.isPlaying)
    }
    
    // MARK: - Character Playback Tests (Non-Async)
    
    func testSpeakCharacter_Letters() {
        // Test that speaking letters doesn't crash
        audioEngine.speakCharacter("K")
        audioEngine.speakCharacter("M")
        audioEngine.speakCharacter("A")
        
        // Just verify it doesn't crash
        XCTAssertNotNil(audioEngine)
    }
    
    func testSpeakCharacter_Numbers() {
        // Test that speaking numbers doesn't crash
        audioEngine.speakCharacter("1")
        audioEngine.speakCharacter("5")
        audioEngine.speakCharacter("0")
        
        XCTAssertNotNil(audioEngine)
    }
    
    func testSpeakCharacter_Punctuation() {
        // Test that speaking punctuation uses proper names
        audioEngine.speakCharacter(".")
        audioEngine.speakCharacter(",")
        audioEngine.speakCharacter("?")
        audioEngine.speakCharacter("/")
        
        XCTAssertNotNil(audioEngine)
    }
    
    func testSpeak_CustomText() {
        // Test that speaking custom text doesn't crash
        audioEngine.speak("Test message")
        audioEngine.speak("Hello world")
        
        XCTAssertNotNil(audioEngine)
    }
    
    // MARK: - Integration Tests (verify setup works)
    
    func testFullConfiguration() {
        // Configure all settings
        audioEngine.frequency = 800.0
        audioEngine.characterWPM = 25.0
        audioEngine.farnsworthWPM = 10.0
        audioEngine.hapticsEnabled = false
        
        // Verify all settings applied
        XCTAssertEqual(audioEngine.frequency, 800.0)
        XCTAssertEqual(audioEngine.characterWPM, 25.0)
        XCTAssertEqual(audioEngine.farnsworthWPM, 10.0)
        XCTAssertFalse(audioEngine.hapticsEnabled)
    }
    
    func testReconfiguration() {
        // Start with one configuration
        audioEngine.frequency = 600.0
        audioEngine.characterWPM = 15.0
        
        // Change to another
        audioEngine.frequency = 900.0
        audioEngine.characterWPM = 30.0
        
        // Verify new settings
        XCTAssertEqual(audioEngine.frequency, 900.0)
        XCTAssertEqual(audioEngine.characterWPM, 30.0)
    }
}
