import FirebaseAuth
import Foundation
import Observation
import SwiftData
import TycoonDaifugouKit

/// Bridges the local SwiftData store and Firestore. Owns the merge policy,
/// post-sign-in import, post-game push, and guest-to-signed-in upload.
///
/// Conflict policy:
///  - Player profile: Firestore wins on first sync of a session (the cloud is the
///    long-lived source of truth across devices). Subsequent local mutations
///    are pushed back via `pushPlayer`.
///  - Game records: union by UUID. Cloud-only records get inserted into SwiftData;
///    local-only records get pushed up. No record is ever overwritten.
@MainActor
@Observable
final class SyncManager {
    enum SyncState: Equatable {
        case idle
        case syncing
        case synced(Date)
        case failed(String)
    }

    private(set) var state: SyncState = .idle

    private let firestore: FirestoreService
    private weak var store: GameRecordStore?

    init(store: GameRecordStore? = nil) {
        self.firestore = FirestoreService()
        self.store = store
    }

    func attach(store: GameRecordStore) {
        self.store = store
    }

    // MARK: - Entry points

    /// Called on app launch (or whenever auth flips to authenticated).
    /// Pulls the cloud profile + games, inserts cloud-only games locally,
    /// and pushes any local-only games up.
    func syncOnSignIn() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let store else { return }
        state = .syncing

        do {
            // 1. Pull cloud player + games.
            let cloudPlayer = try await firestore.fetchPlayer(uid: uid)
            let cloudGames = try await firestore.fetchGames(uid: uid)

            // 2. Apply cloud player to local profile if cloud has data;
            //    otherwise treat the local profile as the source of truth.
            if let cloudPlayer {
                store.applyCloudProfile(cloudPlayer)
            } else {
                // First sign-in on this account — create the cloud doc from local state.
                try await firestore.createPlayerIfMissing(
                    uid: uid,
                    snapshot: makePlayerSnapshot(from: store.profile)
                )
            }

            // 3. Merge games by UUID.
            let localIDs = store.localRecordIDs
            let cloudIDs = Set(cloudGames.map(\.id))
            let cloudOnly = cloudGames.filter { !localIDs.contains($0.id) }
            for snap in cloudOnly {
                store.importCloudGame(snap)
            }

            let localOnly = store.records.filter { !cloudIDs.contains($0.id) }
            if !localOnly.isEmpty {
                let snapshots = localOnly.map(Self.makeGameSnapshot(from:))
                try await firestore.writeGames(uid: uid, snapshots: snapshots)
            }

            // 4. If we just imported cloud games and the cloud profile was missing,
            //    push the merged profile so future devices see the union.
            if cloudPlayer == nil {
                try await firestore.writePlayer(
                    uid: uid,
                    snapshot: makePlayerSnapshot(from: store.profile)
                )
            }

            state = .synced(Date())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Called after every game completes. Always succeeds locally (caller already
    /// wrote to SwiftData). The Firestore write is fire-and-forget — Firestore's
    /// offline persistence queues it if there's no network.
    func didSaveGameLocally(_ record: GameRecord) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let store else { return }
        let gameSnap = Self.makeGameSnapshot(from: record)
        let playerSnap = makePlayerSnapshot(from: store.profile)
        Task { [firestore] in
            do {
                try await firestore.writeGame(uid: uid, snapshot: gameSnap)
                try await firestore.writePlayer(uid: uid, snapshot: playerSnap)
            } catch {
                // Persistence layer queues the write; nothing useful to do here.
            }
        }
    }

    /// Wipes the signed-in user's Firestore footprint. Call BEFORE
    /// `AuthService.deleteAccount()` so the writes still pass security rules
    /// (rules require `request.auth.uid == uid`). Throws on partial failure so
    /// callers can decide whether to proceed with the auth deletion.
    func deleteCloudData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await firestore.deletePlayerData(uid: uid)
    }

    /// Called when the user mutates profile-shaped state outside of game completion
    /// (equipping a new title, changing their emoji, etc.). Same fire-and-forget
    /// semantics as `didSaveGameLocally`.
    func pushProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let store else { return }
        let playerSnap = makePlayerSnapshot(from: store.profile)
        Task { [firestore] in
            try? await firestore.writePlayer(uid: uid, snapshot: playerSnap)
        }
    }

    // MARK: - Snapshot mapping

    private func makePlayerSnapshot(from p: PlayerProfile) -> CloudPlayerSnapshot {
        CloudPlayerSnapshot(
            username: p.username,
            emoji: p.emoji,
            totalXP: p.totalXP,
            currentLevel: p.currentLevel,
            memberSince: p.memberSince,
            equippedTitleID: p.equippedTitleID,
            equippedSkinID: p.equippedSkinID,
            equippedBorderID: p.equippedBorderID,
            hasPrestigeBadge: p.hasPrestigeBadge,
            hardModeWins: p.hardModeWins,
            prestigeLevel: p.prestigeLevel,
            prestigeXP: p.prestigeXP,
            jokersPlayed: p.jokersPlayed,
            jokersWonTrick: p.jokersWonTrick,
            roundFinishPositions: p.roundFinishPositions,
            comebackCount: p.comebackCount,
            comebackOpportunities: p.comebackOpportunities,
            sweepsAchieved: p.sweepsAchieved,
            multiRoundGamesPlayed: p.multiRoundGamesPlayed,
            tricksLed: p.tricksLed,
            tricksWon: p.tricksWon,
            totalPasses: p.totalPasses,
            totalTurns: p.totalTurns,
            revolutionsTriggered: p.revolutionsTriggered,
            eightStopsTotal: p.eightStopsTotal,
            threeSpadesTotal: p.threeSpadesTotal,
            gamesPlayedCount: p.gamesPlayedCount,
            gamesWonCount: p.gamesWonCount,
            totalDuration: p.totalDuration,
            totalRoundsPlayed: p.totalRoundsPlayed,
            settings: Self.currentSettingsSnapshot()
        )
    }

    private static func makeGameSnapshot(from r: GameRecord) -> CloudGameSnapshot {
        CloudGameSnapshot(
            id: r.id,
            date: r.date,
            finishRank: r.finishRank,
            xpEarned: r.xpEarned,
            difficulty: r.difficulty,
            roundsPlayed: r.roundsPlayed,
            roundsWon: r.roundsWon,
            cardsPlayed: r.cardsPlayed,
            duration: r.duration,
            highlight: r.highlight,
            revolutionCount: r.revolutionCount,
            eightStopCount: r.eightStopCount,
            jokerPlayCount: r.jokerPlayCount,
            threeSpadeCount: r.threeSpadeCount,
            roundPointsTotal: r.roundPointsTotal,
            opponentBestPoints: r.opponentBestPoints,
            ruleSetUsed: r.ruleSetUsed,
            opponents: r.opponents.map {
                CloudOpponentSnapshot(name: $0.name, emoji: $0.emoji,
                                      finishRank: $0.finishRank, xpEarned: $0.xpEarned)
            }
        )
    }

    private static func currentSettingsSnapshot() -> CloudSettings {
        let defaults = UserDefaults.standard
        return CloudSettings(
            ruleSetJSON: defaults.string(forKey: AppSettings.Key.ruleSetJSON) ?? "",
            opponentCount: AppSettings.loadOpponentCount(),
            roundsPerGame: AppSettings.loadRoundsPerGame(),
            soundEffectsEnabled: defaults.object(forKey: AppSettings.Key.soundEffectsEnabled) as? Bool ?? true,
            hapticsEnabled: defaults.object(forKey: AppSettings.Key.hapticsEnabled) as? Bool ?? true,
            foilEffectsEnabled: defaults.object(forKey: AppSettings.Key.foilEffectsEnabled) as? Bool ?? true,
            difficulty: AppSettings.loadDifficulty().rawValue
        )
    }
}
