import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makePlayer(_ name: String, cards: [Card], title: Title? = nil) -> Player {
    Player(displayName: name, hand: cards, currentTitle: title)
}

private func makeScores(_ players: [Player]) -> [PlayerID: Int] {
    Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
}

/// Constructs a GameState in `.trading` phase with the given players and pending trades.
private func makeTradingState(players: [Player], pendingTrades: [RequiredTrade]) -> GameState {
    GameState(
        players: players,
        deck: [],
        currentTrick: [],
        currentPlayerIndex: 0,
        phase: .trading,
        ruleSet: .baseOnly,
        isRevolutionActive: false,
        round: 2,
        scoresByPlayer: makeScores(players),
        pendingTrades: pendingTrades
    )
}

/// Constructs a GameState in `.roundEnded` phase with the given players (titles set).
private func makeRoundEndedState(players: [Player]) -> GameState {
    GameState(
        players: players,
        deck: [],
        currentTrick: [],
        currentPlayerIndex: 0,
        phase: .roundEnded,
        ruleSet: .baseOnly,
        isRevolutionActive: false,
        round: 1,
        scoresByPlayer: makeScores(players)
    )
}

private func tradingStrength(_ card: Card) -> Int {
    switch card {
    case .joker: return Int.max
    case .regular(let rank, _): return rank.rawValue
    }
}

private func strongest(_ n: Int, from player: Player) -> [Card] {
    Array(player.hand.sorted { tradingStrength($0) > tradingStrength($1) }.prefix(n))
}

// MARK: - Suite

@Suite("Trading phase")
struct TradingTests {

    // MARK: startNextRound scheduling

    @Test("4-player: schedules 4 trades in correct order with correct card counts")
    func fourPlayerTradeSchedule() {
        let mill = makePlayer("Mill", cards: [], title: .millionaire)
        let rich = makePlayer("Rich", cards: [], title: .rich)
        let poor = makePlayer("Poor", cards: [], title: .poor)
        let beg  = makePlayer("Beg",  cards: [], title: .beggar)
        let state = makeRoundEndedState(players: [mill, rich, poor, beg])
        let round2 = state.startNextRound(seed: 42)

        #expect(round2.phase == .trading)

        let trades = requiredTrades(for: round2)
        #expect(trades.count == 4)

        // Lower-ranked give first
        #expect(trades[0] == RequiredTrade(from: beg.id, to: mill.id, cardCount: 2, mustGiveStrongest: true))
        #expect(trades[1] == RequiredTrade(from: poor.id, to: rich.id, cardCount: 1, mustGiveStrongest: true))
        // Upper-ranked give back
        #expect(trades[2] == RequiredTrade(from: mill.id, to: beg.id, cardCount: 2, mustGiveStrongest: false))
        #expect(trades[3] == RequiredTrade(from: rich.id, to: poor.id, cardCount: 1, mustGiveStrongest: false))
    }

    @Test("3-player: only Millionaire↔Beggar trades, no Rich↔Poor")
    func threePlayerTradeSchedule() {
        let mill = makePlayer("Mill", cards: [], title: .millionaire)
        let comm = makePlayer("Comm", cards: [], title: .commoner)
        let beg  = makePlayer("Beg",  cards: [], title: .beggar)
        let state = makeRoundEndedState(players: [mill, comm, beg])
        let round2 = state.startNextRound(seed: 42)

        #expect(round2.phase == .trading)

        let trades = requiredTrades(for: round2)
        #expect(trades.count == 2)
        #expect(trades[0] == RequiredTrade(from: beg.id, to: mill.id, cardCount: 2, mustGiveStrongest: true))
        #expect(trades[1] == RequiredTrade(from: mill.id, to: beg.id, cardCount: 2, mustGiveStrongest: false))
    }

    // MARK: Beggar / Poor must give strongest

    @Test("Beggar giving non-strongest card throws mustGiveStrongestCards")
    func beggarMustGiveStrongest() throws {
        let beg  = makePlayer("Beg",  cards: [.regular(.three, .clubs), .regular(.king, .spades)], title: .beggar)
        let mill = makePlayer("Mill", cards: [.regular(.two, .hearts), .regular(.ace, .diamonds)], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 1, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 1, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        #expect(throws: GameError.mustGiveStrongestCards) {
            // 3♣ is the weakest card; King♠ is strongest
            try state.apply(.trade(cards: [.regular(.three, .clubs)], from: beg.id, to: mill.id))
        }
    }

    @Test("Beggar giving strongest card succeeds")
    func beggarGivingStrongest() throws {
        let beg  = makePlayer("Beg",  cards: [.regular(.three, .clubs), .regular(.king, .spades)], title: .beggar)
        let mill = makePlayer("Mill", cards: [.regular(.two, .hearts), .regular(.ace, .diamonds)], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 1, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 1, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        let next = try state.apply(.trade(cards: [.regular(.king, .spades)], from: beg.id, to: mill.id))

        #expect(next.phase == .trading)
        // Beg's hand should no longer contain King♠
        let begPlayer = next.players.first { $0.id == beg.id }!
        #expect(!begPlayer.hand.contains(.regular(.king, .spades)))
        // Mill's hand should now include King♠
        let millPlayer = next.players.first { $0.id == mill.id }!
        #expect(millPlayer.hand.contains(.regular(.king, .spades)))
    }

    @Test("Beggar giving strongest 2 cards succeeds when both are equal-rank")
    func beggarGivesStrongestTwoEqualRank() throws {
        // Both Aces are equally strong — giving either pair is valid
        let beg  = makePlayer("Beg",  cards: [.regular(.ace, .spades), .regular(.ace, .hearts), .regular(.three, .clubs)], title: .beggar)
        let mill = makePlayer("Mill", cards: [.regular(.two, .diamonds)], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 2, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 2, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        // Both Aces are the strongest 2 — giving [Ace♠, Ace♥] should succeed
        let next = try state.apply(
            .trade(cards: [.regular(.ace, .spades), .regular(.ace, .hearts)], from: beg.id, to: mill.id)
        )
        #expect(next.phase == .trading)
    }

    // MARK: Millionaire / Rich may give any cards

    @Test("Millionaire can give weakest cards")
    func millionaireCanGiveAnyCards() throws {
        let mill = makePlayer("Mill", cards: [.regular(.three, .clubs), .regular(.king, .spades)], title: .millionaire)
        let beg  = makePlayer("Beg",  cards: [.regular(.ace, .hearts)], title: .beggar)
        // Beg→Mill trade already done (not in pending)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: mill.id, to: beg.id, cardCount: 1, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        // Millionaire gives the weakest card (3♣) — should succeed
        let next = try state.apply(.trade(cards: [.regular(.three, .clubs)], from: mill.id, to: beg.id))
        #expect(next.phase == .playing)
    }

    // MARK: Ordering enforcement

    @Test("Millionaire cannot give before Beggar gives")
    func upperMustWaitForLower() throws {
        let mill = makePlayer("Mill", cards: [.regular(.three, .clubs), .regular(.four, .diamonds)], title: .millionaire)
        let beg  = makePlayer("Beg",  cards: [.regular(.king, .spades), .regular(.ace, .hearts)], title: .beggar)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 2, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 2, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        // Millionaire tries to give before Beggar
        #expect(throws: GameError.mustCompletePartnerTrade) {
            try state.apply(.trade(
                cards: [.regular(.three, .clubs), .regular(.four, .diamonds)],
                from: mill.id, to: beg.id
            ))
        }
    }

    // MARK: Phase transitions

    @Test("Phase transitions to .playing after all 4 trades complete")
    func phaseTransitionsAfterAllTrades() throws {
        let mill = makePlayer("Mill", cards: [.regular(.three, .clubs), .regular(.four, .clubs)], title: .millionaire)
        let rich = makePlayer("Rich", cards: [.regular(.five, .clubs)], title: .rich)
        let poor = makePlayer("Poor", cards: [.regular(.six, .clubs)], title: .poor)
        let beg  = makePlayer("Beg",  cards: [.regular(.king, .spades), .regular(.ace, .hearts)], title: .beggar)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 2, mustGiveStrongest: true),
            RequiredTrade(from: poor.id, to: rich.id, cardCount: 1, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 2, mustGiveStrongest: false),
            RequiredTrade(from: rich.id, to: poor.id, cardCount: 1, mustGiveStrongest: false),
        ]
        var state = makeTradingState(players: [mill, rich, poor, beg], pendingTrades: pending)

        // 1. Beg gives strongest 2 to Mill
        state = try state.apply(.trade(
            cards: [.regular(.king, .spades), .regular(.ace, .hearts)],
            from: beg.id, to: mill.id
        ))
        #expect(state.phase == .trading)

        // 2. Poor gives strongest 1 to Rich
        state = try state.apply(.trade(cards: [.regular(.six, .clubs)], from: poor.id, to: rich.id))
        #expect(state.phase == .trading)

        // 3. Mill gives back 2 (any)
        let millNow = state.players.first { $0.id == mill.id }!
        state = try state.apply(.trade(
            cards: Array(millNow.hand.prefix(2)),
            from: mill.id, to: beg.id
        ))
        #expect(state.phase == .trading)

        // 4. Rich gives back 1 (any)
        let richNow = state.players.first { $0.id == rich.id }!
        state = try state.apply(.trade(
            cards: Array(richNow.hand.prefix(1)),
            from: rich.id, to: poor.id
        ))
        #expect(state.phase == .playing)

        // Titles are cleared after trading
        #expect(state.players.allSatisfy { $0.currentTitle == nil })
    }

    // MARK: Error cases

    @Test("Trade with wrong card count throws wrongCardCount")
    func wrongCardCount() throws {
        let beg  = makePlayer("Beg",  cards: [.regular(.king, .spades), .regular(.ace, .hearts), .regular(.two, .clubs)], title: .beggar)
        let mill = makePlayer("Mill", cards: [], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 2, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 2, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        #expect(throws: GameError.wrongCardCount(expected: 2, got: 1)) {
            try state.apply(.trade(cards: [.regular(.two, .clubs)], from: beg.id, to: mill.id))
        }
    }

    @Test("Trade with no pending trade for (from, to) throws noSuchTrade")
    func noSuchTrade() throws {
        let beg  = makePlayer("Beg",  cards: [.regular(.king, .spades), .regular(.ace, .hearts)], title: .beggar)
        let mill = makePlayer("Mill", cards: [], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id, to: mill.id, cardCount: 2, mustGiveStrongest: true),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        // Mill→Beg direction has no pending trade
        #expect(throws: GameError.noSuchTrade) {
            try state.apply(.trade(cards: [.regular(.king, .spades), .regular(.ace, .hearts)], from: mill.id, to: beg.id))
        }
    }

    @Test("Trade with cards not in hand throws cardsNotInHand")
    func cardsNotInHand() throws {
        let beg  = makePlayer("Beg",  cards: [.regular(.three, .clubs)], title: .beggar)
        let mill = makePlayer("Mill", cards: [], title: .millionaire)
        let pending: [RequiredTrade] = [
            RequiredTrade(from: beg.id,  to: mill.id, cardCount: 1, mustGiveStrongest: true),
            RequiredTrade(from: mill.id, to: beg.id,  cardCount: 1, mustGiveStrongest: false),
        ]
        let state = makeTradingState(players: [mill, beg], pendingTrades: pending)

        #expect(throws: GameError.cardsNotInHand) {
            try state.apply(.trade(cards: [.regular(.king, .spades)], from: beg.id, to: mill.id))
        }
    }
}
