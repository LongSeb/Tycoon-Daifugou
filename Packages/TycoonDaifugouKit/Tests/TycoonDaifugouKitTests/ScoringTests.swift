import Testing
@testable import TycoonDaifugouKit

@Suite("Scoring")
struct ScoringTests {

    // MARK: - Title mapping by player count

    @Test("3-player finish order maps to correct titles")
    func titleMapping3Players() {
        #expect(Scoring.title(forFinishPosition: 0, playerCount: 3) == .millionaire)
        #expect(Scoring.title(forFinishPosition: 1, playerCount: 3) == .commoner)
        #expect(Scoring.title(forFinishPosition: 2, playerCount: 3) == .beggar)
    }

    @Test("4-player finish order maps to correct titles")
    func titleMapping4Players() {
        #expect(Scoring.title(forFinishPosition: 0, playerCount: 4) == .millionaire)
        #expect(Scoring.title(forFinishPosition: 1, playerCount: 4) == .rich)
        #expect(Scoring.title(forFinishPosition: 2, playerCount: 4) == .poor)
        #expect(Scoring.title(forFinishPosition: 3, playerCount: 4) == .beggar)
    }

    @Test("5-player finish order maps to correct titles")
    func titleMapping5Players() {
        #expect(Scoring.title(forFinishPosition: 0, playerCount: 5) == .millionaire)
        #expect(Scoring.title(forFinishPosition: 1, playerCount: 5) == .rich)
        #expect(Scoring.title(forFinishPosition: 2, playerCount: 5) == .commoner)
        #expect(Scoring.title(forFinishPosition: 3, playerCount: 5) == .poor)
        #expect(Scoring.title(forFinishPosition: 4, playerCount: 5) == .beggar)
    }

    // MARK: - XP per title bracket

    @Test("XP for 3-player bracket matches scoring table (total = 6)")
    func xpBracket3Players() {
        #expect(Scoring.xp(for: .millionaire) == 4)
        #expect(Scoring.xp(for: .commoner) == 2)
        #expect(Scoring.xp(for: .beggar) == 0)
        #expect(Scoring.totalXP(playerCount: 3) == 6)
    }

    @Test("XP for 4-player bracket matches scoring table (total = 8)")
    func xpBracket4Players() {
        #expect(Scoring.xp(for: .millionaire) == 4)
        #expect(Scoring.xp(for: .rich) == 3)
        #expect(Scoring.xp(for: .poor) == 1)
        #expect(Scoring.xp(for: .beggar) == 0)
        #expect(Scoring.totalXP(playerCount: 4) == 8)
    }

    @Test("XP for 5-player bracket matches scoring table (total = 10)")
    func xpBracket5Players() {
        #expect(Scoring.xp(for: .millionaire) == 4)
        #expect(Scoring.xp(for: .rich) == 3)
        #expect(Scoring.xp(for: .commoner) == 2)
        #expect(Scoring.xp(for: .poor) == 1)
        #expect(Scoring.xp(for: .beggar) == 0)
        #expect(Scoring.totalXP(playerCount: 5) == 10)
    }

    // MARK: - Round ends when all titles are assigned

    @Test("Round transitions to .roundEnded and every player has a title")
    func roundEndsWhenAllTitlesAssigned() {
        let players = ["P0", "P1", "P2", "P3"].map { Player(displayName: $0) }
        let initial = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 1_000)
        let states = SimulatedPlaythrough.states(from: initial)

        guard let final = states.last else {
            Issue.record("No states generated")
            return
        }

        #expect(final.phase == .roundEnded)
        #expect(final.players.allSatisfy { $0.currentTitle != nil })
    }

    // MARK: - Total XP conservation

    @Test("Total XP awarded per 4-player round equals the scoring table sum (8)")
    func totalXPConservation4Players() {
        let players = ["P0", "P1", "P2", "P3"].map { Player(displayName: $0) }
        let initial = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 1_000)
        let states = SimulatedPlaythrough.states(from: initial)

        guard let final = states.last, final.phase == .roundEnded else {
            Issue.record("Game did not reach .roundEnded")
            return
        }

        let totalXP = final.scoresByPlayer.values.reduce(0, +)
        #expect(totalXP == Scoring.totalXP(playerCount: 4))
    }
}
