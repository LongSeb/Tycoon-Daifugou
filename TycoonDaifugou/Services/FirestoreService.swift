import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Cloud snapshots

/// Plain value types used as the wire format between Firestore and SwiftData.
/// Keeping these out of the Firebase namespace lets the engine package stay clean
/// and makes encoding/decoding trivial through Codable + Firestore's encoder.

struct CloudPlayerSnapshot: Codable, Sendable {
    var username: String
    var emoji: String
    var totalXP: Int
    var currentLevel: Int
    var memberSince: Date

    var equippedTitleID: String
    var equippedSkinID: String
    var equippedBorderID: String?
    var hasPrestigeBadge: Bool
    var hardModeWins: Int
    var prestigeLevel: Int
    var prestigeXP: Int

    var jokersPlayed: Int
    var jokersWonTrick: Int
    var roundFinishPositions: [Int]
    var comebackCount: Int
    var comebackOpportunities: Int
    var sweepsAchieved: Int
    var multiRoundGamesPlayed: Int
    var tricksLed: Int
    var tricksWon: Int
    var totalPasses: Int
    var totalTurns: Int
    var revolutionsTriggered: Int
    var eightStopsTotal: Int
    var threeSpadesTotal: Int
    var gamesPlayedCount: Int
    var gamesWonCount: Int
    var totalDuration: Double
    var totalRoundsPlayed: Int

    var settings: CloudSettings?
}

struct CloudSettings: Codable, Sendable {
    var ruleSetJSON: String
    var opponentCount: Int
    var roundsPerGame: Int
    var soundEffectsEnabled: Bool
    var hapticsEnabled: Bool
    var foilEffectsEnabled: Bool
    var difficulty: String
}

struct CloudOpponentSnapshot: Codable, Sendable {
    var name: String
    var emoji: String
    var finishRank: String
    var xpEarned: Int
}

struct CloudGameSnapshot: Codable, Sendable {
    var id: UUID
    var date: Date
    var finishRank: String
    var xpEarned: Int
    var difficulty: String
    var roundsPlayed: Int
    var roundsWon: Int
    var cardsPlayed: Int
    var duration: Double
    var highlight: String
    var revolutionCount: Int
    var eightStopCount: Int
    var jokerPlayCount: Int
    var threeSpadeCount: Int
    var roundPointsTotal: Int
    var opponentBestPoints: Int
    var ruleSetUsed: Data
    var opponents: [CloudOpponentSnapshot]
}

// MARK: - Service

@MainActor
final class FirestoreService {
    private let db: Firestore

    init() {
        self.db = Firestore.firestore()
    }

    // MARK: Player document

    private func playerDoc(_ uid: String) -> DocumentReference {
        db.collection("players").document(uid)
    }

    private func gamesCollection(_ uid: String) -> CollectionReference {
        playerDoc(uid).collection("games")
    }

    /// Reads the player document. Returns nil when the doc doesn't exist (first sign-in
    /// on a new account / a wiped account).
    func fetchPlayer(uid: String) async throws -> CloudPlayerSnapshot? {
        let doc = try await playerDoc(uid).getDocument()
        guard doc.exists else { return nil }
        return try doc.data(as: CloudPlayerSnapshot.self)
    }

    /// Writes (or overwrites) the player document. Adds a server timestamp under
    /// `updatedAt` so we can debug staleness later without touching the snapshot type.
    func writePlayer(uid: String, snapshot: CloudPlayerSnapshot) async throws {
        try playerDoc(uid).setData(from: snapshot, merge: false) { _ in }
        try await playerDoc(uid).setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)
    }

    /// Creates the player document only if it doesn't already exist (new device,
    /// re-install, etc.). Returns true if a new document was created.
    @discardableResult
    func createPlayerIfMissing(uid: String, snapshot: CloudPlayerSnapshot) async throws -> Bool {
        if try await fetchPlayer(uid: uid) != nil { return false }
        try await writePlayer(uid: uid, snapshot: snapshot)
        return true
    }

    // MARK: Games subcollection

    /// Pulls the full set of cloud games. Limit is intentionally generous —
    /// players will rarely cross it, and the SDK's offline cache makes the
    /// repeated reads cheap.
    func fetchGames(uid: String, limit: Int = 500) async throws -> [CloudGameSnapshot] {
        let snapshot = try await gamesCollection(uid)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: CloudGameSnapshot.self) }
    }

    /// Writes a single game document keyed by its UUID — idempotent on retries.
    func writeGame(uid: String, snapshot: CloudGameSnapshot) async throws {
        try gamesCollection(uid)
            .document(snapshot.id.uuidString)
            .setData(from: snapshot, merge: false) { _ in }
    }

    /// Batch-writes a group of games. Used when a guest signs in and we push
    /// their backlog all at once. Firestore batches cap at 500 ops; we chunk
    /// to stay well under that.
    func writeGames(uid: String, snapshots: [CloudGameSnapshot]) async throws {
        for chunk in snapshots.chunked(into: 400) {
            let batch = db.batch()
            for snap in chunk {
                let ref = gamesCollection(uid).document(snap.id.uuidString)
                try batch.setData(from: snap, forDocument: ref, merge: false)
            }
            try await batch.commit()
        }
    }

    // MARK: Account deletion

    /// Deletes the player document and every doc in the `games` subcollection.
    /// Must be called while the user is still authenticated — security rules
    /// require `request.auth.uid == uid` for all writes.
    func deletePlayerData(uid: String) async throws {
        let games = try await gamesCollection(uid).getDocuments()
        for chunk in games.documents.chunked(into: 400) {
            let batch = db.batch()
            for doc in chunk {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
        }
        try await playerDoc(uid).delete()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
