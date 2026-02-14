import SwiftUI

struct HeadCopyView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @StateObject private var viewModel = HeadCopyViewModel()
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

                // Input slots display
                if !viewModel.currentSequence.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(0..<viewModel.sequenceLength, id: \.self) { index in
                            slotView(at: index)
                        }
                    }
                    .padding(.horizontal)
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

                Spacer()

                // Character buttons grid (hidden in eyes-closed mode)
                if !progressManager.settings.eyesClosedMode {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.availableCharacters) { character in
                            CharacterButton(
                                character: character,
                                state: .normal,
                                action: {
                                    viewModel.appendInput(character.character)
                                }
                            )
                            .disabled(viewModel.isSubmitted || viewModel.isPlaying || viewModel.userInput.count >= viewModel.sequenceLength)
                        }
                    }
                    .padding(.horizontal)
                } else {
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

                // Backspace + Skip row
                HStack(spacing: 24) {
                    Button {
                        viewModel.deleteLastInput()
                    } label: {
                        Label("Delete", systemImage: "delete.left")
                            .font(.subheadline)
                    }
                    .disabled(viewModel.isSubmitted || viewModel.userInput.isEmpty || viewModel.isPlaying)
                    .keyboardShortcut(.delete, modifiers: [])

                    Button("Skip") {
                        viewModel.skipToNext()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .disabled(viewModel.isPlaying)
                    .keyboardShortcut(.space, modifiers: [])
                }
                .opacity(viewModel.currentSequence.isEmpty ? 0 : 1)
                .allowsHitTesting(!viewModel.currentSequence.isEmpty)

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
                        Text("Head Copy")
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

    @ViewBuilder
    private func slotView(at index: Int) -> some View {
        let hasInput = index < viewModel.userInput.count
        let char = hasInput ? String(viewModel.userInput[index]) : ""

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(slotBackground(at: index))
                .frame(width: 52, height: 52)

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(slotBorder(at: index), lineWidth: 2)
                .frame(width: 52, height: 52)

            if viewModel.isSubmitted {
                // Show the correct answer if incorrect, user's answer if correct
                let isCorrect = viewModel.feedbackResults.indices.contains(index) && viewModel.feedbackResults[index] == true
                if isCorrect {
                    Text(char)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    VStack(spacing: 0) {
                        if hasInput {
                            Text(char)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.7))
                                .strikethrough()
                        }
                        Text(String(viewModel.currentSequence[index].character))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(char)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitted)
    }

    private func slotBackground(at index: Int) -> Color {
        guard viewModel.isSubmitted,
              viewModel.feedbackResults.indices.contains(index),
              let result = viewModel.feedbackResults[index] else {
            return index < viewModel.userInput.count ? .secondary.opacity(0.15) : .clear
        }
        return result ? .green : .red
    }

    private func slotBorder(at index: Int) -> Color {
        guard viewModel.isSubmitted,
              viewModel.feedbackResults.indices.contains(index),
              let result = viewModel.feedbackResults[index] else {
            // Highlight the "active" slot (next to fill)
            if index == viewModel.userInput.count && !viewModel.isSubmitted {
                return .blue
            }
            return .secondary.opacity(0.3)
        }
        return result ? .green : .red
    }

    private var availableCharactersString: String {
        viewModel.availableCharacters.map { String($0.character) }.joined(separator: ", ")
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard !viewModel.isPlaying else { return .ignored }

        // Handle backspace
        if keyPress.key == .delete {
            if !viewModel.isSubmitted && !viewModel.userInput.isEmpty {
                viewModel.deleteLastInput()
                return .handled
            }
            return .ignored
        }

        guard !viewModel.isSubmitted else { return .ignored }

        let char = keyPress.characters.uppercased()
        guard let firstChar = char.first else { return .ignored }

        if viewModel.isValidAnswer(firstChar) {
            viewModel.handleKeyboardInput(firstChar)
            return .handled
        }

        return .ignored
    }
}

#Preview {
    HeadCopyView()
        .environmentObject(ProgressManager())
}
