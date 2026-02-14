import SwiftUI

struct DrillView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var viewModel = DrillViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showingUnlockAlert = false
    @State private var isSetup = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Session stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.sessionCorrect)/\(viewModel.sessionTotal)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if let date = progressManager.progress.lastSessionDate {
                            Text("started \(date, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("this session")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if viewModel.sessionTotal > 0 {
                        Text("\(Int(viewModel.sessionAccuracy))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.sessionAccuracy >= 90 ? .green : .primary)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Feedback area
                VStack(spacing: 16) {
                    if progressManager.settings.eyesClosedMode {
                        // Eyes-closed mode: minimal visual feedback
                        Circle()
                            .fill(feedbackColor)
                            .frame(width: 100, height: 100)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.feedbackState)
                    } else {
                        // Normal mode: show character
                        if viewModel.showingAnswer, let current = viewModel.currentCharacter {
                            Text(current.displayString)
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.feedbackState == .correct ? .green : .red)
                                .frame(width: 120, height: 100)
                        } else {
                            Text("?")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 120, height: 100)
                        }
                    }

                    // Replay button
                    Button {
                        viewModel.replay()
                    } label: {
                        Label("Replay", systemImage: "speaker.wave.2.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(viewModel.isPlaying ? .gray.opacity(0.2) : .blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .disabled(viewModel.isPlaying)
                    .keyboardShortcut("r", modifiers: [])
                }

                Spacer()

                // Answer buttons grid (hidden in eyes-closed mode on smaller screens)
                if !progressManager.settings.eyesClosedMode {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.availableCharacters) { character in
                            CharacterButton(
                                character: character,
                                state: buttonState(for: character),
                                action: {
                                    viewModel.submitAnswer(character.character)
                                }
                            )
                            .disabled(viewModel.showingAnswer || viewModel.isPlaying)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Eyes-closed mode hint
                    VStack(spacing: 8) {
                        Text("Eyes-Closed Mode")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Use keyboard to answer")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Text("Available: \(availableCharactersString)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }

                // Skip button — always reserve space to prevent layout shift
                Button("Skip") {
                    viewModel.skipToNext()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .disabled(viewModel.isPlaying)
                .keyboardShortcut(.space, modifiers: [])
                .opacity(viewModel.currentCharacter != nil && !viewModel.showingAnswer ? 1 : 0)
                .allowsHitTesting(viewModel.currentCharacter != nil && !viewModel.showingAnswer)

                Spacer()
            }
            .focusable()
            .focused($isFocused)
            .onKeyPress { keyPress in
                handleKeyPress(keyPress)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        viewModel.stop()
                        dismiss()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }

                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Drill")
                            .font(.headline)
                        if progressManager.settings.eyesClosedMode {
                            Image(systemName: "eye.slash")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetSession()
                        viewModel.startNewRound()
                    } label: {
                        Label("New Session", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .onAppear {
                if !isSetup {
                    viewModel.setup(progressManager: progressManager)
                    isSetup = true
                }
                viewModel.startNewRound()
                isFocused = true
            }
            .onDisappear {
                viewModel.stop()
            }
            .onChange(of: viewModel.justUnlockedCharacter) { _, newValue in
                if newValue != nil {
                    showingUnlockAlert = true
                }
            }
            .alert("New Character Unlocked!", isPresented: $showingUnlockAlert) {
                Button("Continue") {
                    viewModel.justUnlockedCharacter = nil
                }
            } message: {
                if let char = viewModel.justUnlockedCharacter {
                    Text("You've unlocked '\(String(char))'!\nKeep up the great work.")
                }
            }
        }
    }

    private var feedbackColor: Color {
        switch viewModel.feedbackState {
        case .none:
            return .gray.opacity(0.3)
        case .correct:
            return .green
        case .incorrect:
            return .red
        }
    }

    private var availableCharactersString: String {
        viewModel.availableCharacters.map { String($0.character) }.joined(separator: ", ")
    }

    private func buttonState(for character: MorseCharacter) -> CharacterButton.ButtonState {
        guard viewModel.showingAnswer, let current = viewModel.currentCharacter else {
            return .normal
        }

        if character == current {
            return viewModel.feedbackState == .correct ? .correct : .incorrect
        }

        return .normal
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Don't handle if already showing answer or playing
        guard !viewModel.showingAnswer && !viewModel.isPlaying else {
            return .ignored
        }

        let char = keyPress.characters.uppercased()
        guard let firstChar = char.first else {
            return .ignored
        }

        // Check if it's a valid character in our unlocked set
        if viewModel.isValidAnswer(firstChar) {
            viewModel.handleKeyboardInput(firstChar)
            return .handled
        }

        return .ignored
    }
}

#Preview {
    DrillView()
        .environmentObject(ProgressManager())
}
