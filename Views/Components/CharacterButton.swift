import SwiftUI

struct CharacterButton: View {
    let character: MorseCharacter
    let state: ButtonState
    let action: () -> Void

    enum ButtonState {
        case normal
        case correct
        case incorrect
    }

    var body: some View {
        Button(action: action) {
            Text(character.displayString)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch state {
        case .normal:
            return Color.secondary.opacity(0.2)
        case .correct:
            return Color.green
        case .incorrect:
            return Color.red
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .normal:
            return .primary
        case .correct, .incorrect:
            return .white
        }
    }
}

#Preview {
    HStack {
        CharacterButton(
            character: MorseCharacter(id: "A", character: "A", pattern: [.dit, .dah]),
            state: .normal,
            action: {}
        )
        CharacterButton(
            character: MorseCharacter(id: "B", character: "B", pattern: [.dah, .dit, .dit, .dit]),
            state: .correct,
            action: {}
        )
        CharacterButton(
            character: MorseCharacter(id: "C", character: "C", pattern: [.dah, .dit, .dah, .dit]),
            state: .incorrect,
            action: {}
        )
    }
}
