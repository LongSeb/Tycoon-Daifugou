import Foundation
import Testing
@testable import TycoonDaifugouKit

// MARK: - PlayerID

@Suite("PlayerID")
struct PlayerIDTests {

    @Test("Two PlayerIDs created from the same UUID are equal")
    func equalityFromSameUUID() {
        let uuid = UUID()
        let a = PlayerID(uuid)
        let b = PlayerID(uuid)
        #expect(a == b)
    }

    @Test("Two PlayerIDs created from distinct UUIDs are not equal")
    func distinctUUIDsAreDistinct() {
        let a = PlayerID()
        let b = PlayerID()
        #expect(a != b)
    }

    @Test("PlayerID description is the UUID string")
    func descriptionIsUUIDString() {
        let uuid = UUID()
        let pid = PlayerID(uuid)
        #expect(pid.description == uuid.uuidString)
    }

    @Test("PlayerID round-trips through Codable")
    func codableRoundTrip() throws {
        let original = PlayerID()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PlayerID.self, from: data)
        #expect(decoded == original)
    }

    @Test("PlayerID is usable as a Dictionary key")
    func hashableAsKey() {
        let id = PlayerID()
        var dict: [PlayerID: String] = [:]
        dict[id] = "Alice"
        #expect(dict[id] == "Alice")
    }
}

// MARK: - Player hand mutations

@Suite("Player hand mutations")
struct PlayerHandTests {

    private let alice = Player(displayName: "Alice")
    private let threeOfClubs = Card.regular(.three, .clubs)
    private let fiveOfHearts = Card.regular(.five, .hearts)
    private let kingOfSpades = Card.regular(.king, .spades)

    @Test("adding cards produces a player with those cards appended")
    func addingCards() {
        let updated = alice.adding([threeOfClubs, fiveOfHearts])
        #expect(updated.hand == [threeOfClubs, fiveOfHearts])
        #expect(updated.id == alice.id)
        #expect(updated.displayName == alice.displayName)
    }

    @Test("adding cards does not mutate the original player")
    func addingIsNonMutating() {
        _ = alice.adding([threeOfClubs])
        #expect(alice.hand.isEmpty)
    }

    @Test("removing a card the player holds produces the correct remaining hand")
    func removingHeldCard() throws {
        let dealt = alice.adding([threeOfClubs, fiveOfHearts, kingOfSpades])
        let played = try dealt.removing([fiveOfHearts])
        #expect(played.hand == [threeOfClubs, kingOfSpades])
    }

    @Test("removing all cards leaves an empty hand")
    func removingAllCards() throws {
        let dealt = alice.adding([threeOfClubs, fiveOfHearts])
        let empty = try dealt.removing([threeOfClubs, fiveOfHearts])
        #expect(empty.hand.isEmpty)
    }

    @Test("removing preserves duplicate cards correctly")
    func removingOneCopyOfDuplicate() throws {
        let dealt = alice.adding([threeOfClubs, threeOfClubs])
        let afterPlay = try dealt.removing([threeOfClubs])
        #expect(afterPlay.hand == [threeOfClubs])
    }

    @Test("removing a card not in the hand throws missingCards")
    func removingAbsentCardThrows() throws {
        let dealt = alice.adding([threeOfClubs])
        #expect(throws: PlayerError.missingCards([kingOfSpades])) {
            try dealt.removing([kingOfSpades])
        }
    }

    @Test("removing multiple absent cards reports all of them in one throw")
    func removingMultipleAbsentCardsReportsAll() throws {
        let dealt = alice.adding([threeOfClubs])
        #expect(throws: PlayerError.missingCards([fiveOfHearts, kingOfSpades])) {
            try dealt.removing([fiveOfHearts, kingOfSpades])
        }
    }

    @Test("removing does not mutate the original player")
    func removingIsNonMutating() throws {
        let dealt = alice.adding([threeOfClubs])
        _ = try dealt.removing([threeOfClubs])
        #expect(dealt.hand == [threeOfClubs])
    }
}

// MARK: - Title

@Suite("Title")
struct TitleTests {

    @Test("Player starts with no title")
    func noTitleByDefault() {
        #expect(Player(displayName: "Bob").currentTitle == nil)
    }

    @Test("All Title cases exist")
    func allTitlesExist() {
        let all = Title.allCases
        #expect(all.contains(.millionaire))
        #expect(all.contains(.rich))
        #expect(all.contains(.commoner))
        #expect(all.contains(.poor))
        #expect(all.contains(.beggar))
        #expect(all.count == 5)
    }
}
