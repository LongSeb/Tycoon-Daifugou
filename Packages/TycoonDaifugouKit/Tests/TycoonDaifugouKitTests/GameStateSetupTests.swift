import Testing
@testable import TycoonDaifugouKit

@Suite("GameState setup")
struct GameStateSetupTests {

    // MARK: - Helpers

    private func makePlayers(_ count: Int) -> [Player] {
        (0..<count).map { Player(displayName: "P\($0)") }
    }

    // MARK: - Card distribution

    @Test("newGame deals correct total cards for each player count", arguments: [2, 3, 4, 5, 6])
    func dealCountMatchesExpected(playerCount: Int) {
        let players = makePlayers(playerCount)
        let state = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 42)

        let total = 52
        let base = total / playerCount
        let leftover = total % playerCount

        for (i, player) in state.players.enumerated() {
            let expected = base + (i < leftover ? 1 : 0)
            #expect(player.hand.count == expected, "Player \(i) should have \(expected) cards")
        }
    }

    @Test("newGame conserves all cards across all players")
    func cardConservation() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 7)
        let totalDealt = state.players.reduce(0) { $0 + $1.hand.count }
        #expect(totalDealt == 52)
    }

    @Test("newGame includes jokers in deal when jokerCount > 0", arguments: [1, 2])
    func jokerCountIncludedInDeal(jokerCount: Int) {
        let ruleSet = RuleSet(jokers: true, jokerCount: jokerCount)
        let state = GameState.newGame(players: makePlayers(4), ruleSet: ruleSet, seed: 42)
        let totalDealt = state.players.reduce(0) { $0 + $1.hand.count }
        #expect(totalDealt == 52 + jokerCount)

        let totalJokers = state.players.flatMap(\.hand).filter(\.isJoker).count
        #expect(totalJokers == jokerCount)
    }

    @Test("Each card appears in exactly one player's hand")
    func noCardDuplication() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 13)
        let allDealt = state.players.flatMap(\.hand)
        let unique = Set(allDealt)
        #expect(allDealt.count == unique.count, "No card should appear twice")
    }

    // MARK: - Determinism

    @Test("Same seed and inputs produce identical GameState")
    func deterministicWithSameSeed() {
        let players = makePlayers(4)
        let s1 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 99)
        let s2 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 99)
        #expect(s1 == s2)
    }

    @Test("Different seeds produce different initial hands")
    func differentSeedsDifferentHands() {
        let players = makePlayers(4)
        let s1 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 1)
        let s2 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 2)
        #expect(s1 != s2)
    }

    // MARK: - First player

    @Test("Round 1 currentPlayerIndex holds the 3 of Diamonds")
    func startsWithThreeDiamonds() {
        for seed in [0, 1, 42, 999, 12345] as [UInt64] {
            let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: seed)
            let startPlayer = state.players[state.currentPlayerIndex]
            #expect(
                startPlayer.hand.contains(.regular(.three, .diamonds)),
                "Seed \(seed): starting player must hold 3♦"
            )
        }
    }

    // MARK: - Initial state properties

    @Test("Phase is .playing and round is 1 after newGame")
    func initialPhaseAndRound() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.phase == .playing)
        #expect(state.round == 1)
    }

    @Test("isRevolutionActive is false at game start")
    func revolutionInactive() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.isRevolutionActive == false)
    }

    @Test("currentTrick is empty at game start")
    func emptyTrick() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.currentTrick.isEmpty)
    }

    @Test("All player scores initialised to zero")
    func scoresAreZero() {
        let players = makePlayers(4)
        let state = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 42)
        for player in state.players {
            #expect(state.scoresByPlayer[player.id] == 0)
        }
    }

    // MARK: - RuleSet.baseOnly

    @Test("RuleSet.baseOnly has every flag false and jokerCount 0")
    func baseOnlyAllFalse() {
        let rs = RuleSet.baseOnly
        #expect(rs.revolution == false)
        #expect(rs.eightStop == false)
        #expect(rs.jokers == false)
        #expect(rs.threeSpadeReversal == false)
        #expect(rs.bankruptcy == false)
        #expect(rs.jokerCount == 0)
    }
}
