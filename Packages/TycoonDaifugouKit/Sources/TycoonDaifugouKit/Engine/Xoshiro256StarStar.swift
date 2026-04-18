/// Xoshiro256** — a fast, high-quality 64-bit PRNG. Used for deterministic
/// deck shuffling so the same seed always produces the same game.
/// Seeded via SplitMix64 to expand a single UInt64 into 256 bits of state.
struct Xoshiro256StarStar {
    private var stateA: UInt64
    private var stateB: UInt64
    private var stateC: UInt64
    private var stateD: UInt64

    init(seed: UInt64) {
        var accumulator = seed
        func splitMix() -> UInt64 {
            accumulator &+= 0x9E3779B97F4A7C15
            var mixed = accumulator
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58476D1CE4E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D049BB133111EB
            return mixed ^ (mixed >> 31)
        }
        stateA = splitMix()
        stateB = splitMix()
        stateC = splitMix()
        stateD = splitMix()
    }

    private static func rotl(_ value: UInt64, _ shift: Int) -> UInt64 {
        (value << shift) | (value >> (64 - shift))
    }

    mutating func nextUInt64() -> UInt64 {
        let result = Self.rotl(stateB &* 5, 7) &* 9
        let temp = stateB << 17
        stateC ^= stateA
        stateD ^= stateB
        stateB ^= stateC
        stateA ^= stateD
        stateC ^= temp
        stateD = Self.rotl(stateD, 45)
        return result
    }

    /// Fisher-Yates shuffle using this PRNG's output.
    mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for index in stride(from: array.count - 1, through: 1, by: -1) {
            let swapIndex = Int(nextUInt64() % UInt64(index + 1))
            array.swapAt(index, swapIndex)
        }
    }
}
