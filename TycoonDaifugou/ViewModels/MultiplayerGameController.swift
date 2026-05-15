import Foundation
import Observation

@Observable
@MainActor
final class MultiplayerGameController {
    private(set) var state: RTDBGameState?
    private(set) var selectedCards: Set<String> = []
    private(set) var isSubmitting: Bool = false
    private(set) var error: String?

    let lobbyId: String
    let myUID: String

    private let service: MultiplayerService

    init(lobbyId: String, myUID: String, service: MultiplayerService) {
        self.lobbyId = lobbyId
        self.myUID = myUID
        self.service = service
    }

    // MARK: - Derived state

    var isMyTurn: Bool { state?.currentPlayerUid == myUID }

    var myHand: [String] { state?.players[myUID]?.handSafe ?? [] }

    var isGameOver: Bool { state?.isFinished ?? false }
    var isAbandoned: Bool { state?.isAbandoned ?? false }
    var abandonedByName: String? { state?.abandonedBy }

    var currentTrick: [[String]] { state?.currentTrickSafe ?? [] }

    var topPlay: [String]? { currentTrick.last }

    func displayName(for uid: String) -> String {
        state?.players[uid]?.displayName ?? uid
    }

    func cardCount(for uid: String) -> Int {
        state?.players[uid]?.handSafe.count ?? 0
    }

    func finishRank(for uid: String) -> Int? {
        state?.players[uid]?.finishRank
    }

    // MARK: - Listening

    func startListening() {
        service.listenToGame(lobbyId: lobbyId) { [weak self] newState in
            guard let self else { return }
            self.state = newState
            if newState?.currentPlayerUid != self.myUID {
                self.selectedCards = []
            }
        }
    }

    func stopListening() {
        service.stopListeningToGame()
    }

    // MARK: - Card selection

    func toggleCard(_ cardString: String) {
        guard isMyTurn else { return }
        if selectedCards.contains(cardString) {
            selectedCards.remove(cardString)
        } else {
            selectedCards.insert(cardString)
        }
    }

    func clearSelection() {
        selectedCards = []
    }

    // MARK: - Actions

    func submitPlay() async {
        guard isMyTurn, !selectedCards.isEmpty, !isSubmitting else { return }
        let cards = Array(selectedCards).sorted()
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submitAction(lobbyId: lobbyId, action: .play(cards: cards))
            selectedCards = []
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submitPass() async {
        guard isMyTurn, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.submitAction(lobbyId: lobbyId, action: .pass)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() { error = nil }

    func abandon() async {
        do {
            try await service.abandonGame(lobbyId: lobbyId)
        } catch {
            // Ignore — we're leaving regardless
        }
    }
}
