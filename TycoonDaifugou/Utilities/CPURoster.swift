import Foundation

struct CPUProfile {
    let name: String
    let emoji: String
}

enum CPURoster {
    static let names: [String] = [
        "Ann", "Yuki", "Makoto", "Yu", "Ren",
        "Genji", "Luna", "Jason", "Amelia", "Omar",
        "Jess", "Leo", "Mia", "Ryo", "Kai",
        "Hana", "Sora", "Emir", "Mei",
        "Remi", "Sam", "Marc", "Jake", "Shiomi", "Tatsuya", "Igor", "Paige",
    ]

    static let emojis: [String] = [
        "😎", "🤖", "👻", "🐯", "🦊",
        "🐸", "🦁", "🐼", "🎭", "🃏",
        "🌙", "⚡️", "🔥", "🌊", "🍀",
        "👾", "🎪", "🦋", "🌸",
    ]

    /// Returns N unique randomly sampled CPUProfiles using a deterministic seed.
    static func sample(count: Int, seed: UInt64) -> [CPUProfile] {
        let safeCount = max(1, min(count, min(names.count, emojis.count)))
        var rng = SeededRNG(seed: seed)
        var shuffledNames = names
        var shuffledEmojis = emojis
        shuffledNames.shuffle(using: &rng)
        shuffledEmojis.shuffle(using: &rng)
        return zip(shuffledNames, shuffledEmojis)
            .prefix(safeCount)
            .map { CPUProfile(name: $0.0, emoji: $0.1) }
    }
}

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed  // xorshift64 requires non-zero state
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
