import Testing
@testable import TycoonDaifugouKit

// MARK: - GamePhasePosition

@Suite("GamePhasePosition.from(handSize:)")
struct GamePhasePositionTests {

    @Test("Hand size > 8 → early")
    func earlyBucket() {
        #expect(GamePhasePosition.from(handSize: 13) == .early)
        #expect(GamePhasePosition.from(handSize: 9) == .early)
    }

    @Test("Hand size 4–8 → mid")
    func midBucket() {
        #expect(GamePhasePosition.from(handSize: 8) == .mid)
        #expect(GamePhasePosition.from(handSize: 6) == .mid)
        #expect(GamePhasePosition.from(handSize: 4) == .mid)
    }

    @Test("Hand size ≤ 3 → endgame")
    func endgameBucket() {
        #expect(GamePhasePosition.from(handSize: 3) == .endgame)
        #expect(GamePhasePosition.from(handSize: 1) == .endgame)
        #expect(GamePhasePosition.from(handSize: 0) == .endgame)
    }
}

// MARK: - PhaseModifier.identity

@Suite("PhaseModifier.identity")
struct PhaseModifierIdentityTests {

    @Test("All multipliers are 1.0 across phases")
    func allOnes() {
        let modifier = PhaseModifier.identity
        for phase in [GamePhasePosition.early, .mid, .endgame] {
            let m = modifier.multipliers(for: phase)
            #expect(m.cardsCleared == 1.0)
            #expect(m.winLikelihood == 1.0)
            #expect(m.comboIntegrity == 1.0)
            #expect(m.cardValueSpent == 1.0)
            #expect(m.passBias == 1.0)
            #expect(m.effectiveRank == 1.0)
            #expect(m.eightStopValue == 1.0)
            #expect(m.jokerHoarding == 1.0)
        }
    }

    @Test("Explicit identity modifier scores identically to default (no modifier)")
    func explicitIdentityMatchesDefault() {
        let cards: [Card] = [.regular(.three, .clubs), .regular(.king, .hearts)]
        let player = Player(displayName: "P", hand: cards)
        let state = GameState(
            players: [player], deck: [], currentPlayerIndex: 0,
            phase: .playing, ruleSet: .baseOnly, round: 1,
            scoresByPlayer: [player.id: 0]
        )
        let move = Move.play(cards: [.regular(.three, .clubs)], by: player.id)

        let defaultPolicy = Policy(id: .balanced, weights: .balanced)
        let explicitIdentity = Policy(
            id: .balanced, weights: .balanced, phaseModifier: .identity
        )

        #expect(
            defaultPolicy.score(move, in: state, hand: cards)
                == explicitIdentity.score(move, in: state, hand: cards)
        )
    }
}

// MARK: - PhaseModifier.endgameRusher

@Suite("PhaseModifier.endgameRusher")
struct EndgameRusherModifierTests {

    @Test("Endgame multipliers amplify cardsCleared and dampen passBias")
    func endgameAmplification() {
        let modifier = PhaseModifier.endgameRusher
        let early = modifier.multipliers(for: .early)
        let endgame = modifier.multipliers(for: .endgame)

        #expect(endgame.cardsCleared > early.cardsCleared)
        #expect(endgame.passBias < early.passBias)
        #expect(endgame.cardValueSpent < early.cardValueSpent)
    }

    @Test(".endgameRusher policy values cardsCleared higher in endgame than early game")
    func endgameRusherScoresShift() {
        // 2-card hand puts us in the endgame bucket; 12-card hand puts us in early.
        let endgameHand: [Card] = [.regular(.three, .clubs), .regular(.king, .hearts)]
        let earlyHand: [Card] = (0..<12).map { i in
            // A mix of ranks so cards are distinct
            .regular(Rank.allCases[i], [.clubs, .diamonds, .hearts, .spades][i % 4])
        }

        let endgamePlayer = Player(displayName: "End", hand: endgameHand)
        let earlyPlayer = Player(displayName: "Early", hand: earlyHand)

        let endgameState = GameState(
            players: [endgamePlayer], deck: [], currentPlayerIndex: 0,
            phase: .playing, ruleSet: .baseOnly, round: 1,
            scoresByPlayer: [endgamePlayer.id: 0]
        )
        let earlyState = GameState(
            players: [earlyPlayer], deck: [], currentPlayerIndex: 0,
            phase: .playing, ruleSet: .baseOnly, round: 1,
            scoresByPlayer: [earlyPlayer.id: 0]
        )
        let move = Move.play(cards: [.regular(.three, .clubs)], by: endgamePlayer.id)

        let endgameScore = Policy.endgameRusher.score(move, in: endgameState, hand: endgameHand)
        let earlyScore = Policy.endgameRusher.score(
            .play(cards: [.regular(.three, .clubs)], by: earlyPlayer.id),
            in: earlyState, hand: earlyHand
        )

        // Endgame multiplier on cardsCleared is 2.0 vs 0.6 in early — same play
        // should score notably higher in endgame.
        #expect(endgameScore > earlyScore)
    }
}

// MARK: - FeatureWeights.multiplied(by:)

@Suite("FeatureWeights.multiplied(by:)")
struct FeatureWeightsMultipliedTests {

    @Test("Component-wise multiplication")
    func componentWise() {
        let base = FeatureWeights(
            cardsCleared: 2.0, winLikelihood: 3.0, comboIntegrity: 4.0,
            cardValueSpent: 5.0, passBias: 6.0,
            effectiveRank: 7.0, eightStopValue: 8.0, jokerHoarding: 9.0
        )
        let multiplier = FeatureWeights(
            cardsCleared: 0.5, winLikelihood: 1.0, comboIntegrity: 2.0,
            cardValueSpent: 0.0, passBias: -1.0,
            effectiveRank: 0.5, eightStopValue: 1.5, jokerHoarding: 0.0
        )
        let result = base.multiplied(by: multiplier)

        #expect(result.cardsCleared == 1.0)
        #expect(result.winLikelihood == 3.0)
        #expect(result.comboIntegrity == 8.0)
        #expect(result.cardValueSpent == 0.0)
        #expect(result.passBias == -6.0)
        #expect(result.effectiveRank == 3.5)
        #expect(result.eightStopValue == 12.0)
        #expect(result.jokerHoarding == 0.0)
    }

    @Test("Multiplying by .ones is the identity")
    func multipliedByOnesIsIdentity() {
        let base = FeatureWeights.balanced
        let result = base.multiplied(by: .ones)

        #expect(result == base)
    }
}
