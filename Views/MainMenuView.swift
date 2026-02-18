import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @State private var showingDrill = false
    @State private var showingLiveCopy = false
    @State private var showingHeadCopy = false
    @State private var showingSettings = false
    @State private var showingProgress = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // App Title
                VStack(spacing: 8) {
                    Text("Morse Trainer")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Learn CW the right way")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Progress summary
                VStack(spacing: 4) {
                    Text("\(progressManager.progress.unlockedCount) / \(KochSequence.totalCharacters)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("characters learned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                // Main buttons
                VStack(spacing: 16) {
                    Button {
                        showingDrill = true
                    } label: {
                        Label("Start Drill", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityIdentifier("StartDrill")

                    Button {
                        showingLiveCopy = true
                    } label: {
                        Label("Live Copy", systemImage: "waveform")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityIdentifier("LiveCopy")

                    Button {
                        showingHeadCopy = true
                    } label: {
                        Label("Head Copy", systemImage: "brain.head.profile")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.indigo)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityIdentifier("HeadCopy")

                    HStack(spacing: 16) {
                        Button {
                            showingProgress = true
                        } label: {
                            Label("Progress", systemImage: "chart.bar.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityIdentifier("Progress")

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityIdentifier("Settings")
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Speed info
                HStack {
                    VStack(alignment: .leading) {
                        Text("Character: \(Int(progressManager.settings.characterWPM)) WPM")
                            .font(.caption)
                        Text("Spacing: \(Int(progressManager.settings.farnsworthWPM)) WPM")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .fullScreenCover(isPresented: $showingDrill) {
                DrillView()
                    .environmentObject(progressManager)
            }
            .fullScreenCover(isPresented: $showingLiveCopy) {
                LiveCopyView()
                    .environmentObject(progressManager)
            }
            .fullScreenCover(isPresented: $showingHeadCopy) {
                HeadCopyView()
                    .environmentObject(progressManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(progressManager)
            }
            .sheet(isPresented: $showingProgress) {
                StatsView()
                    .environmentObject(progressManager)
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(ProgressManager())
}
