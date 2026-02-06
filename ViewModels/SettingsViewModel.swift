import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    private let progressManager: ProgressManager

    init(progressManager: ProgressManager) {
        self.progressManager = progressManager
    }

    var characterWPM: Double {
        get { progressManager.settings.characterWPM }
        set {
            progressManager.settings.characterWPM = newValue
            progressManager.save()
        }
    }

    var farnsworthWPM: Double {
        get { progressManager.settings.farnsworthWPM }
        set {
            progressManager.settings.farnsworthWPM = newValue
            progressManager.save()
        }
    }

    var toneFrequency: Double {
        get { progressManager.settings.toneFrequency }
        set {
            progressManager.settings.toneFrequency = newValue
            progressManager.save()
        }
    }

    var hapticFeedback: Bool {
        get { progressManager.settings.hapticFeedback }
        set {
            progressManager.settings.hapticFeedback = newValue
            progressManager.save()
        }
    }

    func resetProgress() {
        progressManager.resetProgress()
    }

    func resetSettings() {
        progressManager.resetSettings()
    }

    func resetAll() {
        progressManager.resetAll()
    }
}
