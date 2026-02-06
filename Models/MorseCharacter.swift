import Foundation

enum MorseElement {
    case dit
    case dah
}

struct MorseCharacter: Identifiable, Equatable {
    let id: Character
    let character: Character
    let pattern: [MorseElement]

    var displayString: String {
        String(character)
    }

    static func == (lhs: MorseCharacter, rhs: MorseCharacter) -> Bool {
        lhs.character == rhs.character
    }
}

extension MorseCharacter {
    static let allCharacters: [MorseCharacter] = [
        // Letters
        MorseCharacter(id: "A", character: "A", pattern: [.dit, .dah]),
        MorseCharacter(id: "B", character: "B", pattern: [.dah, .dit, .dit, .dit]),
        MorseCharacter(id: "C", character: "C", pattern: [.dah, .dit, .dah, .dit]),
        MorseCharacter(id: "D", character: "D", pattern: [.dah, .dit, .dit]),
        MorseCharacter(id: "E", character: "E", pattern: [.dit]),
        MorseCharacter(id: "F", character: "F", pattern: [.dit, .dit, .dah, .dit]),
        MorseCharacter(id: "G", character: "G", pattern: [.dah, .dah, .dit]),
        MorseCharacter(id: "H", character: "H", pattern: [.dit, .dit, .dit, .dit]),
        MorseCharacter(id: "I", character: "I", pattern: [.dit, .dit]),
        MorseCharacter(id: "J", character: "J", pattern: [.dit, .dah, .dah, .dah]),
        MorseCharacter(id: "K", character: "K", pattern: [.dah, .dit, .dah]),
        MorseCharacter(id: "L", character: "L", pattern: [.dit, .dah, .dit, .dit]),
        MorseCharacter(id: "M", character: "M", pattern: [.dah, .dah]),
        MorseCharacter(id: "N", character: "N", pattern: [.dah, .dit]),
        MorseCharacter(id: "O", character: "O", pattern: [.dah, .dah, .dah]),
        MorseCharacter(id: "P", character: "P", pattern: [.dit, .dah, .dah, .dit]),
        MorseCharacter(id: "Q", character: "Q", pattern: [.dah, .dah, .dit, .dah]),
        MorseCharacter(id: "R", character: "R", pattern: [.dit, .dah, .dit]),
        MorseCharacter(id: "S", character: "S", pattern: [.dit, .dit, .dit]),
        MorseCharacter(id: "T", character: "T", pattern: [.dah]),
        MorseCharacter(id: "U", character: "U", pattern: [.dit, .dit, .dah]),
        MorseCharacter(id: "V", character: "V", pattern: [.dit, .dit, .dit, .dah]),
        MorseCharacter(id: "W", character: "W", pattern: [.dit, .dah, .dah]),
        MorseCharacter(id: "X", character: "X", pattern: [.dah, .dit, .dit, .dah]),
        MorseCharacter(id: "Y", character: "Y", pattern: [.dah, .dit, .dah, .dah]),
        MorseCharacter(id: "Z", character: "Z", pattern: [.dah, .dah, .dit, .dit]),

        // Numbers
        MorseCharacter(id: "0", character: "0", pattern: [.dah, .dah, .dah, .dah, .dah]),
        MorseCharacter(id: "1", character: "1", pattern: [.dit, .dah, .dah, .dah, .dah]),
        MorseCharacter(id: "2", character: "2", pattern: [.dit, .dit, .dah, .dah, .dah]),
        MorseCharacter(id: "3", character: "3", pattern: [.dit, .dit, .dit, .dah, .dah]),
        MorseCharacter(id: "4", character: "4", pattern: [.dit, .dit, .dit, .dit, .dah]),
        MorseCharacter(id: "5", character: "5", pattern: [.dit, .dit, .dit, .dit, .dit]),
        MorseCharacter(id: "6", character: "6", pattern: [.dah, .dit, .dit, .dit, .dit]),
        MorseCharacter(id: "7", character: "7", pattern: [.dah, .dah, .dit, .dit, .dit]),
        MorseCharacter(id: "8", character: "8", pattern: [.dah, .dah, .dah, .dit, .dit]),
        MorseCharacter(id: "9", character: "9", pattern: [.dah, .dah, .dah, .dah, .dit]),

        // Punctuation
        MorseCharacter(id: ".", character: ".", pattern: [.dit, .dah, .dit, .dah, .dit, .dah]),
        MorseCharacter(id: ",", character: ",", pattern: [.dah, .dah, .dit, .dit, .dah, .dah]),
        MorseCharacter(id: "?", character: "?", pattern: [.dit, .dit, .dah, .dah, .dit, .dit]),
        MorseCharacter(id: "/", character: "/", pattern: [.dah, .dit, .dit, .dah, .dit]),
    ]

    static func character(for char: Character) -> MorseCharacter? {
        allCharacters.first { $0.character == char }
    }

    static let characterMap: [Character: MorseCharacter] = {
        Dictionary(uniqueKeysWithValues: allCharacters.map { ($0.character, $0) })
    }()
}
