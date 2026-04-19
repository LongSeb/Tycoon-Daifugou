import Foundation

/// Xoshiro256** — fast, high-quality seeded PRNG. State is initialized from a
/// single UInt64 seed via SplitMix64.
struct Xoshiro256StarStar {
    private struct State {
        var w0: UInt64
        var w1: UInt64
        var w2: UInt64
        var w3: UInt64
    }

    private var state: State

    init(seed: UInt64) {
        var seedValue = seed
        state = State(
            w0: Self.splitmix64(&seedValue),
            w1: Self.splitmix64(&seedValue),
            w2: Self.splitmix64(&seedValue),
            w3: Self.splitmix64(&seedValue)
        )
    }

    mutating func next() -> UInt64 {
        let result = Self.rotl(state.w1 &* 5, shift: 7) &* 9
        let temp = state.w1 << 17
        state.w2 ^= state.w0
        state.w3 ^= state.w1
        state.w1 ^= state.w2
        state.w0 ^= state.w3
        state.w2 ^= temp
        state.w3 = Self.rotl(state.w3, shift: 45)
        return result
    }

    mutating func shuffle<T>(_ array: inout [T]) {
        for idx in stride(from: array.count - 1, through: 1, by: -1) {
            let swapIdx = Int(next() % UInt64(idx + 1))
            array.swapAt(idx, swapIdx)
        }
    }

    private static func rotl(_ value: UInt64, shift: Int) -> UInt64 {
        (value << shift) | (value >> (64 - shift))
    }

    private static func splitmix64(_ seedValue: inout UInt64) -> UInt64 {
        seedValue &+= 0x9e3779b97f4a7c15
        var mixed = seedValue
        mixed = (mixed ^ (mixed >> 30)) &* 0xbf58476d1ce4e5b9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94d049bb133111eb
        return mixed ^ (mixed >> 31)
    }
}
