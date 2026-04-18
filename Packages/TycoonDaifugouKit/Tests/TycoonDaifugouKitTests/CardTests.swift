import Testing
@testable import TycoonDaifugouKit

// MARK: - Rank ordering
//
// These are plain unit tests: they verify isolated properties of a single
// type (`Rank`) with no dependency on game state. They run in microseconds
// and should never flake. This is the pattern you should follow for every
// model type — a small, focused file of `@Test` functions with descriptive
// names that spell out the invariant being checked.

@Suite("Rank ordering")
struct RankOrderingTests {

    @Test("3 is the weakest rank")
    func threeIsWeakest() {
        #expect(Rank.three < Rank.four)
        #expect(Rank.three < Rank.two)
        #expect(Rank.three < Rank.ace)
        #expect(Rank.allCases.min() == .three)
    }

    @Test("2 is the strongest non-Joker rank")
    func twoIsStrongest() {
        #expect(Rank.two > Rank.ace)
        #expect(Rank.two > Rank.king)
        #expect(Rank.allCases.max() == .two)
    }

    @Test("Ace is the second-strongest rank")
    func aceIsSecondStrongest() {
        #expect(Rank.ace < Rank.two)
        #expect(Rank.ace > Rank.king)
    }

    // Parameterized test — Swift Testing's answer to "run this same test
    // for every case in a set of inputs." Much cleaner than a for-loop.
    @Test("All ranks are strictly ordered by raw value", arguments: [
        (Rank.three, Rank.four),
        (.four,  .five),
        (.five,  .six),
        (.six,   .seven),
        (.seven, .eight),
        (.eight, .nine),
        (.nine,  .ten),
        (.ten,   .jack),
        (.jack,  .queen),
        (.queen, .king),
        (.king,  .ace),
        (.ace,   .two),
    ])
    func strictOrdering(lower: Rank, higher: Rank) {
        #expect(lower < higher)
        #expect(higher > lower)
        #expect(lower != higher)
    }
}

// MARK: - Card identity

@Suite("Card identity and properties")
struct CardIdentityTests {

    @Test("Regular cards expose their rank and suit")
    func regularCardProperties() {
        let card = Card.regular(.king, .hearts)
        #expect(card.rank == .king)
        #expect(card.suit == .hearts)
        #expect(card.isJoker == false)
    }

    @Test("Jokers have no rank or suit")
    func jokerProperties() {
        let joker = Card.joker(index: 0)
        #expect(joker.rank == nil)
        #expect(joker.suit == nil)
        #expect(joker.isJoker == true)
    }

    @Test("Two identical regular cards compare equal")
    func regularCardEquality() {
        #expect(Card.regular(.five, .clubs) == Card.regular(.five, .clubs))
        #expect(Card.regular(.five, .clubs) != Card.regular(.five, .diamonds))
        #expect(Card.regular(.five, .clubs) != Card.regular(.six, .clubs))
    }

    @Test("Jokers with different indices are distinct cards")
    func jokersDistinctByIndex() {
        #expect(Card.joker(index: 0) != Card.joker(index: 1))
        #expect(Card.joker(index: 0) == Card.joker(index: 0))
    }
}

// MARK: - Deck construction

@Suite("Deck construction")
struct DeckTests {

    @Test("Standard 52-card deck has the right count")
    func standardDeckCount() {
        #expect(Deck.standard52().count == 52)
    }

    @Test("Standard deck contains each rank-suit combination exactly once")
    func standardDeckCompleteness() {
        let deck = Deck.standard52()
        let uniqueCards = Set(deck.map { "\($0)" })
        #expect(uniqueCards.count == 52, "Deck must contain no duplicates")

        for suit in Suit.allCases {
            for rank in Rank.allCases {
                #expect(
                    deck.contains(.regular(rank, suit)),
                    "Deck missing \(rank) of \(suit)"
                )
            }
        }
    }

    @Test("Deck with Jokers adds them to the end", arguments: [0, 1, 2])
    func deckWithJokers(jokerCount: Int) {
        let deck = Deck.deck(withJokers: jokerCount)
        #expect(deck.count == 52 + jokerCount)
        let jokerCards = deck.filter(\.isJoker)
        #expect(jokerCards.count == jokerCount)
    }
}
