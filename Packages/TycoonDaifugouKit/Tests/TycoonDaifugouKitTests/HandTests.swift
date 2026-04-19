import Testing
@testable import TycoonDaifugouKit

// MARK: - HandType

@Suite("HandType raw values")
struct HandTypeTests {

    @Test("HandType raw values match card count", arguments: [
        (HandType.single, 1),
        (HandType.pair,   2),
        (HandType.triple, 3),
        (HandType.quad,   4),
    ])
    func rawValues(handType: HandType, count: Int) {
        #expect(handType.rawValue == count)
    }

    @Test("HandType initialises from valid card counts", arguments: [1, 2, 3, 4])
    func validCounts(count: Int) {
        #expect(HandType(rawValue: count) != nil)
    }

    @Test("HandType returns nil for invalid card counts", arguments: [0, 5, 6, 100])
    func invalidCounts(count: Int) {
        #expect(HandType(rawValue: count) == nil)
    }
}

// MARK: - Valid constructions

@Suite("Hand valid constructions")
struct HandValidConstructionTests {

    @Test("Single card produces a .single hand")
    func singleCard() throws {
        let hand = try Hand(cards: [.regular(.king, .hearts)])
        #expect(hand.type == .single)
        #expect(hand.rank == .king)
    }

    @Test("Two same-rank cards produce a .pair hand")
    func pair() throws {
        let hand = try Hand(cards: [.regular(.five, .clubs), .regular(.five, .diamonds)])
        #expect(hand.type == .pair)
        #expect(hand.rank == .five)
    }

    @Test("Three same-rank cards produce a .triple hand")
    func triple() throws {
        let hand = try Hand(cards: [
            .regular(.ace, .spades),
            .regular(.ace, .hearts),
            .regular(.ace, .clubs),
        ])
        #expect(hand.type == .triple)
        #expect(hand.rank == .ace)
    }

    @Test("Four same-rank cards produce a .quad hand")
    func quad() throws {
        let hand = try Hand(cards: [
            .regular(.two, .clubs),
            .regular(.two, .diamonds),
            .regular(.two, .hearts),
            .regular(.two, .spades),
        ])
        #expect(hand.type == .quad)
        #expect(hand.rank == .two)
    }
}

// MARK: - Rejection

@Suite("Hand rejects invalid inputs")
struct HandRejectionTests {

    @Test("Empty array throws wrongCount(0)")
    func emptyInput() {
        #expect(throws: HandError.wrongCount(0)) {
            try Hand(cards: [])
        }
    }

    @Test("Five-card array throws wrongCount(5)")
    func fiveCards() {
        #expect(throws: HandError.wrongCount(5)) {
            try Hand(cards: [
                .regular(.three, .clubs),
                .regular(.three, .diamonds),
                .regular(.three, .hearts),
                .regular(.three, .spades),
                .regular(.four,  .clubs),
            ])
        }
    }

    @Test("Mixed-rank pair throws mixedRanks")
    func mixedRankPair() {
        #expect(throws: HandError.mixedRanks) {
            try Hand(cards: [.regular(.three, .clubs), .regular(.four, .clubs)])
        }
    }

    @Test("Mixed-rank triple throws mixedRanks")
    func mixedRankTriple() {
        #expect(throws: HandError.mixedRanks) {
            try Hand(cards: [
                .regular(.queen, .clubs),
                .regular(.queen, .hearts),
                .regular(.king,  .spades),
            ])
        }
    }

    @Test("Single Joker produces a valid .single hand with isSoloJoker set")
    func singleJoker() throws {
        let hand = try Hand(cards: [.joker(index: 0)])
        #expect(hand.type == .single)
        #expect(hand.isSoloJoker)
    }

    @Test("Two Jokers throw allJokers")
    func twoJokers() {
        #expect(throws: HandError.allJokers) {
            try Hand(cards: [.joker(index: 0), .joker(index: 1)])
        }
    }
}

// MARK: - Joker wildcarding

@Suite("Joker wildcarding")
struct HandJokerTests {

    @Test("Joker + regular card is a valid pair anchored to the regular card's rank")
    func jokerPair() throws {
        let hand = try Hand(cards: [.joker(index: 0), .regular(.king, .hearts)])
        #expect(hand.type == .pair)
        #expect(hand.rank == .king)
    }

    @Test("Joker + two same-rank cards is a valid triple")
    func jokerTriple() throws {
        let hand = try Hand(cards: [
            .joker(index: 0),
            .regular(.seven, .clubs),
            .regular(.seven, .spades),
        ])
        #expect(hand.type == .triple)
        #expect(hand.rank == .seven)
    }

    @Test("Joker + three same-rank cards is a valid quad")
    func jokerQuad() throws {
        let hand = try Hand(cards: [
            .joker(index: 0),
            .regular(.ace, .clubs),
            .regular(.ace, .diamonds),
            .regular(.ace, .hearts),
        ])
        #expect(hand.type == .quad)
        #expect(hand.rank == .ace)
    }

    @Test("Joker among mixed-rank non-Jokers throws mixedRanks")
    func jokerWithMixedRanks() {
        #expect(throws: HandError.mixedRanks) {
            try Hand(cards: [
                .joker(index: 0),
                .regular(.three, .clubs),
                .regular(.four,  .clubs),
            ])
        }
    }
}

// MARK: - Comparable

@Suite("Hand Comparable ordering")
struct HandComparableTests {

    @Test("Singles are ordered by rank")
    func singleOrdering() throws {
        let threes = try Hand(cards: [.regular(.three, .clubs)])
        let fours  = try Hand(cards: [.regular(.four,  .clubs)])
        let twos   = try Hand(cards: [.regular(.two,   .clubs)])
        #expect(threes < fours)
        #expect(fours  < twos)
        #expect(threes < twos)
    }

    @Test("Pairs are ordered by rank", arguments: [
        (Rank.three, Rank.four),
        (.four,  .five),
        (.king,  .ace),
        (.ace,   .two),
    ])
    func pairOrdering(lower: Rank, higher: Rank) throws {
        let lowerPair  = try Hand(cards: [.regular(lower,  .clubs), .regular(lower,  .diamonds)])
        let higherPair = try Hand(cards: [.regular(higher, .clubs), .regular(higher, .diamonds)])
        #expect(lowerPair  < higherPair)
        #expect(higherPair > lowerPair)
    }

    @Test("Hands of the same rank are not ordered relative to each other")
    func sameRankEquivalence() throws {
        let clubJack  = try Hand(cards: [.regular(.jack, .clubs)])
        let heartJack = try Hand(cards: [.regular(.jack, .hearts)])
        #expect(!(clubJack < heartJack))
        #expect(!(heartJack < clubJack))
    }
}
