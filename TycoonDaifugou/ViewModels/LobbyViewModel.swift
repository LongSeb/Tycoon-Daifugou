import Foundation
import Observation

@Observable
@MainActor
final class LobbyViewModel {
    enum Phase: Equatable {
        case idle
        case searching
        case inLobby(lobbyId: String, inviteCode: String?)
        case error(String)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.searching, .searching): return true
            case (.inLobby(let a, _), .inLobby(let b, _)): return a == b
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    var phase: Phase = .idle
    var currentLobby: Lobby?
    var playerCount: Int = 2
    var inviteCodeInput: String = ""
    var isReady: Bool = false

    private let service: MultiplayerService
    let myUID: String?
    let playerDisplayName: String
    let playerEmoji: String
    let playerTitle: String
    let playerBorderID: String?

    init(service: MultiplayerService, myUID: String?, displayName: String = "Player", emoji: String = "😎", title: String = "Commoner", borderID: String? = nil) {
        self.service = service
        self.myUID = myUID
        self.playerDisplayName = displayName
        self.playerEmoji = emoji
        self.playerTitle = title
        self.playerBorderID = borderID
    }

    var lobbyId: String? {
        if case .inLobby(let id, _) = phase { return id }
        return nil
    }

    var inviteCode: String? {
        if case .inLobby(_, let code) = phase { return code }
        return nil
    }

    var isInLobby: Bool {
        if case .inLobby = phase { return true }
        return false
    }

    // MARK: - Actions

    func joinQuickPlay() async {
        phase = .searching
        do {
            let id = try await service.joinQueue(maxPlayers: playerCount, displayName: playerDisplayName, emoji: playerEmoji, title: playerTitle, borderID: playerBorderID)
            phase = .inLobby(lobbyId: id, inviteCode: nil)
            service.listenToLobby(lobbyId: id) { [weak self] lobby in
                self?.currentLobby = lobby
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func createPrivateRoom() async {
        phase = .searching
        do {
            let (id, code) = try await service.createLobby(maxPlayers: playerCount, displayName: playerDisplayName, emoji: playerEmoji, title: playerTitle, borderID: playerBorderID)
            phase = .inLobby(lobbyId: id, inviteCode: code)
            service.listenToLobby(lobbyId: id) { [weak self] lobby in
                self?.currentLobby = lobby
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func joinWithCode() async {
        let code = inviteCodeInput.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
        phase = .searching
        do {
            let id = try await service.joinWithCode(code, displayName: playerDisplayName, emoji: playerEmoji, title: playerTitle, borderID: playerBorderID)
            phase = .inLobby(lobbyId: id, inviteCode: nil)
            service.listenToLobby(lobbyId: id) { [weak self] lobby in
                self?.currentLobby = lobby
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func setReady() async {
        guard let id = lobbyId else { return }
        do {
            try await service.setReady(lobbyId: id)
            isReady = true
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // Called when the local user taps Leave — cancels the lobby server-side for everyone.
    func leave() {
        if let id = lobbyId {
            Task { try? await service.leaveLobby(lobbyId: id) }
        }
        cleanupLocally()
    }

    // Called when the lobby is cancelled externally (someone else left).
    func cleanupLocally() {
        service.stopListeningToLobby()
        currentLobby = nil
        isReady = false
        phase = .idle
    }

    func clearError() {
        if case .error = phase { phase = .idle }
    }
}
