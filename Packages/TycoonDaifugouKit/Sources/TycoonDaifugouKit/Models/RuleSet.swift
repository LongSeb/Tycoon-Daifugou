/// The active House Rule configuration for a game session. All flags default
/// to false so callers opt in explicitly. Pass this into the engine at game
/// creation — it never changes mid-game.
public struct RuleSet: Sendable, Hashable, Equatable, Codable {
    /// Four-of-a-kind reverses the rank order for the remainder of the game.
    public var revolution: Bool
    /// Playing an 8 ends the current trick immediately.
    public var eightStop: Bool
    /// Joker cards are included and act as wildcards.
    public var jokers: Bool
    /// The 3 of Spades can beat a single Joker.
    public var threeSpadeReversal: Bool
    /// A player who cannot legally play is eliminated (goes bankrupt).
    public var bankruptcy: Bool
    /// How many Joker cards to include in the deck (0, 1, or 2).
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

    /// Base Tycoon with no House Rules enabled.
    public static let baseOnly = RuleSet()
}
