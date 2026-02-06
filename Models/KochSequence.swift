import Foundation

struct KochSequence {
    /// Standard Koch method character order
    /// Characters are ordered by distinctiveness - most distinctive sounds first
    /// This helps build pattern recognition by starting with easily distinguishable characters
    static let order: [Character] = [
        "K", "M", "R", "S", "U", "A", "P", "T", "L", "O",
        "W", "I", ".", "N", "J", "E", "F", "0", "Y", "V",
        ",", "G", "5", "/", "Q", "9", "Z", "H", "3", "8",
        "B", "?", "4", "2", "7", "C", "1", "D", "6", "X"
    ]

    /// Get the MorseCharacter objects for the first n characters in Koch sequence
    static func characters(upTo count: Int) -> [MorseCharacter] {
        let chars = Array(order.prefix(count))
        return chars.compactMap { MorseCharacter.character(for: $0) }
    }

    /// Get a random character from the first n characters in Koch sequence
    static func randomCharacter(fromFirst count: Int) -> MorseCharacter? {
        let available = characters(upTo: count)
        return available.randomElement()
    }

    /// Get the index of a character in the Koch sequence
    static func index(of character: Character) -> Int? {
        order.firstIndex(of: character)
    }

    /// Minimum number of characters to start with (K and M)
    static let minimumCharacters = 2

    /// Total number of characters in the sequence
    static let totalCharacters = order.count
}
