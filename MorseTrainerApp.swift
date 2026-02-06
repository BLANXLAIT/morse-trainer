import SwiftUI

@main
struct MorseTrainerApp: App {
    @StateObject private var progressManager = ProgressManager()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(progressManager)
        }
    }
}
