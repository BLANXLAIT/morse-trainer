import SwiftUI

struct InputSlotsView: View {
    let currentSequence: [MorseCharacter]
    let userInput: [Character]
    let isSubmitted: Bool
    let feedbackResults: [Bool?]
    let style: SlotStyle

    @State private var animatingSlotIndex: Int?
    @State private var animationTask: Task<Void, Never>?

    enum SlotStyle {
        case compact  // 36pt slots — live copy (many characters)
        case regular  // 52pt slots — head copy (few characters)

        var size: CGFloat {
            switch self {
            case .compact: return 36
            case .regular: return 52
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: return 6
            case .regular: return 12
            }
        }

        var mainFont: Font {
            switch self {
            case .compact: return .title3
            case .regular: return .title2
            }
        }

        var wrongInputFont: Font {
            switch self {
            case .compact: return .caption2
            case .regular: return .caption
            }
        }

        var correctAnswerFont: Font {
            switch self {
            case .compact: return .subheadline
            case .regular: return .title3
            }
        }
    }

    private var sequenceLength: Int { currentSequence.count }

    var body: some View {
        GeometryReader { geometry in
            let maxColumns = max(1, Int((geometry.size.width + style.spacing) / (style.size + style.spacing)))
            let columns = min(sequenceLength, maxColumns)
            let gridColumns = Array(repeating: GridItem(.fixed(style.size), spacing: style.spacing), count: max(columns, 1))

            LazyVGrid(columns: gridColumns, spacing: style.spacing) {
                ForEach(0..<sequenceLength, id: \.self) { index in
                    slotView(at: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: gridHeight)
        .onChange(of: userInput.count) { oldCount, newCount in
            if newCount > oldCount {
                animationTask?.cancel()
                animatingSlotIndex = newCount - 1
                animationTask = Task {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    if !Task.isCancelled {
                        animatingSlotIndex = nil
                    }
                }
            } else {
                animationTask?.cancel()
                animatingSlotIndex = nil
            }
        }
    }

    /// Estimate grid height so GeometryReader doesn't collapse or expand greedily.
    private var gridHeight: CGFloat {
        // Use a conservative column count estimate (8 for compact, 5 for regular)
        // The actual layout will compute the real columns from GeometryReader width
        let estimatedColumns: Int
        switch style {
        case .compact: estimatedColumns = 8
        case .regular: estimatedColumns = 5
        }
        let rows = max(1, Int(ceil(Double(sequenceLength) / Double(estimatedColumns))))
        return CGFloat(rows) * style.size + CGFloat(rows - 1) * style.spacing
    }

    @ViewBuilder
    private func slotView(at index: Int) -> some View {
        let hasInput = index < userInput.count
        let char = hasInput ? String(userInput[index]) : ""

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(slotBackground(at: index))
                .frame(width: style.size, height: style.size)

            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(slotBorder(at: index), lineWidth: 2)
                .frame(width: style.size, height: style.size)

            if isSubmitted {
                let isCorrect = feedbackResults.indices.contains(index) && feedbackResults[index] == true
                if isCorrect {
                    Text(char)
                        .font(style.mainFont)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    VStack(spacing: 0) {
                        if hasInput {
                            Text(char)
                                .font(style.wrongInputFont)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.7))
                                .strikethrough()
                        }
                        Text(String(currentSequence[index].character))
                            .font(style.correctAnswerFont)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text(char)
                    .font(style.mainFont)
                    .fontWeight(.bold)
            }
        }
        .scaleEffect(animatingSlotIndex == index ? 1.2 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSubmitted)
        .animation(.spring(duration: 0.2, bounce: 0.4), value: animatingSlotIndex)
        .accessibilityIdentifier("InputSlot_\(index)")
    }

    private func slotBackground(at index: Int) -> Color {
        guard isSubmitted,
              feedbackResults.indices.contains(index),
              let result = feedbackResults[index] else {
            if animatingSlotIndex == index {
                return .blue.opacity(0.3)
            }
            return index < userInput.count ? .secondary.opacity(0.15) : .clear
        }
        return result ? .green : .red
    }

    private func slotBorder(at index: Int) -> Color {
        guard isSubmitted,
              feedbackResults.indices.contains(index),
              let result = feedbackResults[index] else {
            if index == userInput.count && !isSubmitted {
                return .blue
            }
            return .secondary.opacity(0.3)
        }
        return result ? .green : .red
    }
}
