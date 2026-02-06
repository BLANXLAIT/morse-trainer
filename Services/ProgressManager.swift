import Foundation
import SwiftUI

@MainActor
class ProgressManager: ObservableObject {
    @Published var progress: UserProgress
    @Published var settings: AppSettings

    private let progressKey = "userProgress"
    private let settingsKey = "appSettings"

    init() {
        // Load progress from UserDefaults
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.progress = decoded
        } else {
            self.progress = UserProgress()
        }

        // Load settings from UserDefaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func recordAttempt(character: Character, correct: Bool) {
        progress.recordAttempt(character: character, correct: correct)

        // Check if we should unlock next character
        if progress.shouldUnlockNextCharacter() {
            progress.unlockNextCharacter()
        }

        save()
    }

    func resetProgress() {
        progress = UserProgress()
        save()
    }

    func resetSettings() {
        settings = AppSettings()
        save()
    }

    func resetAll() {
        resetProgress()
        resetSettings()
    }
}

struct AppSettings: Codable {
    /// Character speed in WPM (how fast individual characters sound)
    var characterWPM: Double = 20.0

    /// Effective/Farnsworth speed in WPM (spacing between characters)
    var farnsworthWPM: Double = 5.0

    /// Tone frequency in Hz
    var toneFrequency: Double = 700.0

    /// Whether haptic feedback is enabled
    var hapticFeedback: Bool = true

    /// Eyes-closed mode - audio feedback instead of visual
    var eyesClosedMode: Bool = false

    /// Whether to play audio feedback tones for correct/incorrect
    var audioFeedback: Bool = true

    /// Whether to speak the correct answer aloud
    var speakAnswer: Bool = true
}
