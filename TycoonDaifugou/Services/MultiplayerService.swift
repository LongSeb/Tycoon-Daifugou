import FirebaseDatabase
import FirebaseFirestore
import FirebaseFunctions
import Foundation

@MainActor
final class MultiplayerService {
    private let functions: Functions
    private let rtdb: Database
    private let firestore: Firestore

    private var gameObserverHandle: UInt?
    private var gameRef: DatabaseReference?
    private var lobbyListener: ListenerRegistration?

    init() {
        self.functions = Functions.functions()
        self.rtdb = Database.database()
        self.firestore = Firestore.firestore()
        // Emulator configuration is applied globally in TycoonDaifugouApp.init().
    }

    // MARK: - Callable functions

    func createLobby(maxPlayers: Int, displayName: String, emoji: String, title: String, borderID: String?) async throws -> (lobbyId: String, inviteCode: String) {
        var params: [String: Any] = ["maxPlayers": maxPlayers, "displayName": displayName, "emoji": emoji, "title": title]
        if let borderID { params["borderID"] = borderID }
        let result = try await functions.httpsCallable("createLobby").call(params)
        guard let data = result.data as? [String: Any],
              let lobbyId = data["lobbyId"] as? String,
              let inviteCode = data["inviteCode"] as? String
        else { throw MultiplayerError.unexpectedResponse }
        return (lobbyId, inviteCode)
    }

    func joinWithCode(_ code: String, displayName: String, emoji: String, title: String, borderID: String?) async throws -> String {
        var params: [String: Any] = ["inviteCode": code, "displayName": displayName, "emoji": emoji, "title": title]
        if let borderID { params["borderID"] = borderID }
        let result = try await functions.httpsCallable("joinWithCode").call(params)
        guard let data = result.data as? [String: Any],
              let lobbyId = data["lobbyId"] as? String
        else { throw MultiplayerError.unexpectedResponse }
        return lobbyId
    }

    func joinQueue(maxPlayers: Int, displayName: String, emoji: String, title: String, borderID: String?) async throws -> String {
        var params: [String: Any] = ["maxPlayers": maxPlayers, "displayName": displayName, "emoji": emoji, "title": title]
        if let borderID { params["borderID"] = borderID }
        let result = try await functions.httpsCallable("joinQueue").call(params)
        guard let data = result.data as? [String: Any],
              let lobbyId = data["lobbyId"] as? String
        else { throw MultiplayerError.unexpectedResponse }
        return lobbyId
    }

    func setReady(lobbyId: String) async throws {
        _ = try await functions.httpsCallable("setReady").call(["lobbyId": lobbyId])
    }

    func submitAction(lobbyId: String, action: MultiplayerAction) async throws {
        _ = try await functions.httpsCallable("submitAction").call([
            "lobbyId": lobbyId,
            "action":  action.asDict,
        ])
    }

    func leaveLobby(lobbyId: String) async throws {
        _ = try await functions.httpsCallable("leaveLobby").call(["lobbyId": lobbyId])
    }

    func abandonGame(lobbyId: String) async throws {
        _ = try await functions.httpsCallable("abandonGame").call(["lobbyId": lobbyId])
    }

    // MARK: - Firestore lobby listener

    func listenToLobby(lobbyId: String, onChange: @escaping (Lobby?) -> Void) {
        lobbyListener?.remove()
        lobbyListener = firestore
            .collection("lobbies")
            .document(lobbyId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard self != nil else { return }
                let lobby = snapshot.flatMap { snap in
                    snap.exists ? try? snap.data(as: Lobby.self) : nil
                }
                Task { @MainActor in onChange(lobby) }
            }
    }

    func stopListeningToLobby() {
        lobbyListener?.remove()
        lobbyListener = nil
    }

    // MARK: - RTDB game listener

    func listenToGame(lobbyId: String, onChange: @escaping (RTDBGameState?) -> Void) {
        stopListeningToGame()

        let ref = rtdb.reference(withPath: "games/\(lobbyId)")
        gameRef = ref
        gameObserverHandle = ref.observe(.value) { snapshot in
            guard let value = snapshot.value, !(value is NSNull) else {
                Task { @MainActor in onChange(nil) }
                return
            }
            if let data = try? JSONSerialization.data(withJSONObject: value),
               let state = try? JSONDecoder().decode(RTDBGameState.self, from: data) {
                Task { @MainActor in onChange(state) }
            }
        }
    }

    func stopListeningToGame() {
        if let ref = gameRef, let handle = gameObserverHandle {
            ref.removeObserver(withHandle: handle)
        }
        gameRef = nil
        gameObserverHandle = nil
    }

    func stopAll() {
        stopListeningToLobby()
        stopListeningToGame()
    }
}
