# Morse Trainer

A SwiftUI-based iOS application for learning Morse code using the Koch method.

## Recent Features

### Haptic Enhancement
The app now uses the iOS Taptic Engine (UIImpactFeedbackGenerator) to provide haptic feedback during Morse code playback:
- **Dit patterns** produce light, short haptic taps
- **Dah patterns** produce medium, longer haptic taps
- This helps users "feel" the rhythm of Morse code, making it an excellent accessibility feature
- Haptic feedback can be enabled/disabled in settings

### Lock Screen Widgets
Added iOS Lock Screen widgets for convenient access:
- **Character of the Day**: Shows a daily rotating character from the Koch sequence
- **Quick Start**: One-tap access to start a 2-minute practice session
- Widgets support both small and medium sizes
- Deep linking integrates widgets with the main app

### Background Audio Support
The audio engine now supports background playback:
- Morse code tones continue playing when the app is backgrounded
- Uses AVAudioSession with `.playback` category and `.mixWithOthers` option
- Properly configured background audio modes in Info.plist
- Allows users to practice while using other apps

## Technical Implementation

### Haptic Feedback
- `HapticManager.swift`: Centralized haptic feedback service
- Integrated with `AudioEngine.swift` for synchronized audio and haptic output
- Uses UIImpactFeedbackGenerator with different intensities for dit/dah patterns

### Widget Extension
- `MorseTrainerWidget/`: Separate widget extension target
- Timeline provider generates daily character updates
- Supports URL schemes for deep linking: `morsetrainer://quickstart` and `morsetrainer://character/X`

### Background Audio
- AVAudioSession configured with background audio capability
- Info.plist includes `audio` background mode
- Audio continues seamlessly when app moves to background

## Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Development

### Running Tests
The project includes comprehensive unit test coverage for core logic components:
- Run tests in Xcode: `⌘U` or Product > Test
- Run tests from command line: `xcodebuild test -project MorseTrainer.xcodeproj -scheme MorseTrainer -destination 'platform=iOS Simulator,name=iPhone 15'`

### Test Coverage
- **UserProgressTests**: Progress tracking, accuracy calculations, unlock logic
- **DrillViewModelTests**: Drill state management, answer submission
- **ProgressManagerTests**: Persistence and settings management
- **AudioEngineTests**: Timing calculations and configuration

### Continuous Integration
Tests are configured to run with Xcode Cloud. The test plan (`MorseTrainerTests.xctestplan`) is included in the project for CI configuration through App Store Connect.

## Settings
- Character WPM: Adjustable speed for individual characters
- Farnsworth WPM: Adjustable spacing between characters
- Tone Frequency: Customizable audio frequency
- Haptic Feedback: Enable/disable haptic patterns
- Audio Feedback: Enable/disable audio tones
- Eyes-Closed Mode: Minimal visual feedback for accessibility

## License
[Add your license here]
