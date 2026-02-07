import SwiftUI

@main
struct MorseTrainerApp: App {
    @StateObject private var progressManager = ProgressManager()
    @State private var shouldShowDrill = false
    @State private var characterToShow: Character?

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(progressManager)
                .onOpenURL { url in
                    handleURL(url)
                }
                .sheet(isPresented: $shouldShowDrill) {
                    DrillView()
                        .environmentObject(progressManager)
                }
        }
    }
    
    private func handleURL(_ url: URL) {
        // Handle deep links from widgets
        // morsetrainer://quickstart - starts a drill session
        // morsetrainer://character/X - shows info about character X
        
        guard url.scheme == "morsetrainer" else { return }
        
        if url.host == "quickstart" {
            // Start a quick 2-minute practice session
            shouldShowDrill = true
        } else if url.host == "character", let character = url.pathComponents.last?.first {
            // Show character info and start drill
            characterToShow = character
            shouldShowDrill = true
        }
    }
}
