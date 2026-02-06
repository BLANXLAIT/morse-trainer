import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Character Speed")
                            Spacer()
                            Text("\(Int(progressManager.settings.characterWPM)) WPM")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { progressManager.settings.characterWPM },
                                set: {
                                    progressManager.settings.characterWPM = $0
                                    progressManager.save()
                                }
                            ),
                            in: 15...35,
                            step: 1
                        )
                        Text("How fast each character sounds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Farnsworth Spacing")
                            Spacer()
                            Text("\(Int(progressManager.settings.farnsworthWPM)) WPM")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { progressManager.settings.farnsworthWPM },
                                set: {
                                    progressManager.settings.farnsworthWPM = $0
                                    progressManager.save()
                                }
                            ),
                            in: 3...20,
                            step: 1
                        )
                        Text("Time between characters (lower = more time to think)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Speed")
                } footer: {
                    Text("Farnsworth method: Fast characters with slow spacing helps build pattern recognition without counting.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tone Frequency")
                            Spacer()
                            Text("\(Int(progressManager.settings.toneFrequency)) Hz")
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { progressManager.settings.toneFrequency },
                                set: {
                                    progressManager.settings.toneFrequency = $0
                                    progressManager.save()
                                }
                            ),
                            in: 400...1000,
                            step: 50
                        )
                        Text("Lower = deeper tone, higher = sharper tone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Audio")
                }

                Section {
                    Toggle(
                        "Haptic Feedback",
                        isOn: Binding(
                            get: { progressManager.settings.hapticFeedback },
                            set: {
                                progressManager.settings.hapticFeedback = $0
                                progressManager.save()
                            }
                        )
                    )

                    Toggle(
                        "Audio Feedback Tones",
                        isOn: Binding(
                            get: { progressManager.settings.audioFeedback },
                            set: {
                                progressManager.settings.audioFeedback = $0
                                progressManager.save()
                            }
                        )
                    )

                    Toggle(
                        "Speak Correct Answer",
                        isOn: Binding(
                            get: { progressManager.settings.speakAnswer },
                            set: {
                                progressManager.settings.speakAnswer = $0
                                progressManager.save()
                            }
                        )
                    )
                } header: {
                    Text("Feedback")
                } footer: {
                    Text("Audio feedback helps with eyes-closed practice.")
                }

                Section {
                    Toggle(
                        isOn: Binding(
                            get: { progressManager.settings.eyesClosedMode },
                            set: {
                                progressManager.settings.eyesClosedMode = $0
                                progressManager.save()
                            }
                        )
                    ) {
                        HStack {
                            Image(systemName: "eye.slash")
                            Text("Eyes-Closed Mode")
                        }
                    }
                } header: {
                    Text("Practice Mode")
                } footer: {
                    Text("Hides answer buttons. Use keyboard (K, M, etc.) to answer. Audio feedback tells you if you're correct.")
                }

                Section {
                    Button("Reset Progress", role: .destructive) {
                        showingResetAlert = true
                    }
                } footer: {
                    Text("This will reset all learned characters and statistics.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Progress?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    progressManager.resetProgress()
                }
            } message: {
                Text("This will delete all your progress and start over with just K and M. This cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProgressManager())
}
