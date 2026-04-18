import Testing
@testable import TycoonDaifugouKit

@Suite("GameState setup")
struct GameStateSetupTests {

    // MARK: - Helpers

    private func makePlayers(_ count: Int) -> [Player] {
        (0..<count).map { Player(displayName: "P\($0)") }
    }

    // MARK: - Card distribution

    @Test("4 players, no jokers — 13 cards each")
    func dealCount_4players_noJokers() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        let totals = state.players.map { $0.hand.count }
        #expect(totals.reduce(0, +) == 52)
        #expect(totals.allSatisfy { $0 == 13 })
    }

    @Test("3 players, no jokers — first player gets the extra card")
    func dealCount_3players_noJokers() {
        // 52 / 3 = 17 remainder 1 → player 0 gets 18, others get 17
        let state = GameState.newGame(players: makePlayers(3), ruleSet: .baseOnly, seed: 42)
        #expect(state.players.map { $0.hand.count }.reduce(0, +) == 52)
        #expect(state.players[0].hand.count == 18)
        #expect(state.players[1].hand.count == 17)
        #expect(state.players[2].hand.count == 17)
    }

    @Test("5 players, no jokers — first two get the extra cards")
    func dealCount_5players_noJokers() {
        // 52 / 5 = 10 remainder 2 → players 0 and 1 get 11
        let state = GameState.newGame(players: makePlayers(5), ruleSet: .baseOnly, seed: 42)
        #expect(state.players.map { $0.hand.count }.reduce(0, +) == 52)
        #expect(state.players[0].hand.count == 11)
        #expect(state.players[1].hand.count == 11)
        #expect(state.players[2].hand.count == 10)
        #expect(state.players[3].hand.count == 10)
        #expect(state.players[4].hand.count == 10)
    }

    @Test("2 jokers — total dealt is 54 cards")
    func dealCount_withTwoJokers() {
        let rules = RuleSet(jokerCount: 2)
        let state = GameState.newGame(players: makePlayers(4), ruleSet: rules, seed: 42)
        #expect(state.players.map { $0.hand.count }.reduce(0, +) == 54)
    }

    @Test("No card is dealt twice — every dealt card is unique")
    func noDuplicateCards() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 99)
        let allCards = state.players.flatMap { $0.hand }
        #expect(Set(allCards).count == allCards.count)
    }

    // MARK: - Determinism

    @Test("Same seed produces identical initial states")
    func determinism_sameSeed() {
        let players = makePlayers(4)
        let s1 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 12345)
        let s2 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 12345)
        #expect(s1 == s2)
    }

    @Test("Different seeds produce different first-player hands")
    func determinism_differentSeeds() {
        let players = makePlayers(4)
        let s1 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 1)
        let s2 = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 2)
        #expect(s1.players[0].hand != s2.players[0].hand)
    }

    // MARK: - Starting player

    @Test("Round 1 currentPlayerIndex holds the 3 of Diamonds")
    func starterHasThreeOfDiamonds() {
        for seed: UInt64 in [0, 1, 42, 9999, .max / 2] {
            let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: seed)
            let starter = state.players[state.currentPlayerIndex]
            #expect(starter.hand.contains(.regular(.three, .diamonds)))
        }
    }

    // MARK: - Initial field values

    @Test("Phase is .playing at the start of round 1")
    func initialPhaseIsPlaying() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.phase == .playing)
    }

    @Test("currentTrick is empty at game start")
    func initialTrickIsEmpty() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.currentTrick.isEmpty)
    }

    @Test("isRevolutionActive is false at game start")
    func noRevolutionAtStart() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.isRevolutionActive == false)
    }

    @Test("round is 1 at game start")
    func roundIsOne() {
        let state = GameState.newGame(players: makePlayers(4), ruleSet: .baseOnly, seed: 42)
        #expect(state.round == 1)
    }

    @Test("scoresByPlayer initialises every player to 0")
    func initialScoresAreZero() {
        let players = makePlayers(4)
        let state = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 42)
        for player in players {
            #expect(state.scoresByPlayer[player.id] == 0)
        }
    }

    // MARK: - RuleSet.baseOnly

    @Test("RuleSet.baseOnly has all flags false and jokerCount 0")
    func ruleSetBaseOnly() {
        let rs = RuleSet.baseOnly
        #expect(rs.revolution == false)
        #expect(rs.eightStop == false)
        #expect(rs.jokers == false)
        #expect(rs.threeSpadeReversal == false)
        #expect(rs.bankruptcy == false)
        #expect(rs.jokerCount == 0)
    }
}
