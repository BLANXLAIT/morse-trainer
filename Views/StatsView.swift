import SwiftUI

struct StatsView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Characters",
                            value: "\(progressManager.progress.unlockedCount)",
                            subtitle: "of \(KochSequence.totalCharacters)"
                        )

                        StatCard(
                            title: "Accuracy",
                            value: "\(Int(progressManager.progress.overallAccuracy))%",
                            subtitle: "overall"
                        )

                        StatCard(
                            title: "Best Streak",
                            value: "\(progressManager.progress.bestStreak)",
                            subtitle: "in a row"
                        )
                    }
                    .padding(.horizontal)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Koch Method Progress")
                            .font(.headline)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.2))

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * progressFraction)
                            }
                        }
                        .frame(height: 24)

                        Text("\(progressManager.progress.unlockedCount) characters learned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Character grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Character Accuracy")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5),
                            spacing: 8
                        ) {
                            ForEach(Array(KochSequence.order.enumerated()), id: \.offset) { index, char in
                                CharacterProgressCell(
                                    character: char,
                                    accuracy: progressManager.progress.accuracy(for: char),
                                    isUnlocked: index < progressManager.progress.unlockedCount,
                                    isNext: index == progressManager.progress.unlockedCount
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.headline)

                        VStack(spacing: 8) {
                            StatRow(label: "Total Attempts", value: "\(progressManager.progress.totalAttempts)")
                            StatRow(label: "Correct Answers", value: "\(progressManager.progress.totalCorrect)")
                            StatRow(label: "Current Streak", value: "\(progressManager.progress.currentStreak)")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var progressFraction: CGFloat {
        CGFloat(progressManager.progress.unlockedCount) / CGFloat(KochSequence.totalCharacters)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct CharacterProgressCell: View {
    let character: Character
    let accuracy: Double
    let isUnlocked: Bool
    let isNext: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(String(character))
                .font(.headline)
                .fontWeight(.semibold)

            if isUnlocked {
                Text("\(Int(accuracy))%")
                    .font(.caption2)
                    .foregroundStyle(accuracyColor)
            }
        }
        .frame(width: 56, height: 56)
        .background(backgroundColor)
        .foregroundStyle(isUnlocked ? .primary : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isNext {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue, lineWidth: 2)
            }
        }
    }

    private var backgroundColor: Color {
        if !isUnlocked {
            return Color.secondary.opacity(0.1)
        }
        if accuracy >= 90 {
            return Color.green.opacity(0.2)
        } else if accuracy >= 70 {
            return Color.yellow.opacity(0.2)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }

    private var accuracyColor: Color {
        if accuracy >= 90 {
            return .green
        } else if accuracy >= 70 {
            return .orange
        } else {
            return .secondary
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(ProgressManager())
}
