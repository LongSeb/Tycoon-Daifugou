import Foundation

public enum RuleSetError: Error, Sendable, Equatable {
    case jokersEnabledButCountIsZero
}

public struct RuleSet: Sendable, Codable, Equatable {
    public var revolution: Bool
    public var eightStop: Bool
    public var jokers: Bool
    public var threeSpadeReversal: Bool
    public var bankruptcy: Bool
    /// Number of Joker cards to include in the deck. Must be 0–2.
    public var jokerCount: Int

    public init(
        revolution: Bool = false,
        eightStop: Bool = false,
        jokers: Bool = false,
        threeSpadeReversal: Bool = false,
        bankruptcy: Bool = false,
        jokerCount: Int = 0
    ) {
        self.revolution = revolution
        self.eightStop = eightStop
        self.jokers = jokers
        self.threeSpadeReversal = threeSpadeReversal
        self.bankruptcy = bankruptcy
        self.jokerCount = jokerCount
    }

    public static let baseOnly = RuleSet()

    /// All house rules enabled, two Jokers. Used for stress-testing the engine.
    public static let allRules = RuleSet(
        revolution: true,
        eightStop: true,
        jokers: true,
        threeSpadeReversal: true,
        bankruptcy: true,
        jokerCount: 2
    )

    /// Throws if the rule configuration is internally inconsistent.
    public func validate() throws(RuleSetError) {
        if jokers && jokerCount == 0 {
            throw .jokersEnabledButCountIsZero
        }
    }
}
