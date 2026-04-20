import Observation
import TycoonDaifugouKit

/// Wraps GameState for SwiftUI consumption. Exactly one human player is supported per instance.
@Observable
@MainActor
final class GameController {
    private(set) var state: GameState
    let humanPlayerID: PlayerID
    private let opponents: [PlayerID: any Opponent]

    init(
        players: [Player],
        ruleSet: RuleSet,
        seed: UInt64,
        humanPlayerID: PlayerID,
        opponents: [PlayerID: any Opponent]
    ) {
        self.state = GameState.newGame(players: players, ruleSet: ruleSet, seed: seed)
        self.humanPlayerID = humanPlayerID
        self.opponents = opponents
    }

    var humanHand: [Card] {
        state.players.first { $0.id == humanPlayerID }?.hand ?? []
    }

    var currentTrick: [Hand] {
        state.currentTrick
    }

    var activePlayer: Player {
        state.players[state.currentPlayerIndex]
    }

    func canPlay(cards: [Card]) -> Bool {
        state.validMoves(for: humanPlayerID).contains {
            guard case .play(let moveCards, _) = $0 else { return false }
            return Set(moveCards) == Set(cards)
        }
    }

    var canPass: Bool {
        state.validMoves(for: humanPlayerID).contains {
            if case .pass = $0 { return true }
            return false
        }
    }

    func play(_ cards: [Card]) throws {
        state = try state.apply(.play(cards: cards, by: humanPlayerID))
    }

    func pass() throws {
        state = try state.apply(.pass(by: humanPlayerID))
    }

    /// Runs AI moves on @MainActor, inserting a 0.4 s pause between each so animations have time to play.
    func resolveAITurnsIfNeeded() async {
        while state.phase == .playing && activePlayer.id != humanPlayerID {
            guard let opponent = opponents[activePlayer.id] else { break }
            let move = opponent.move(for: activePlayer.id, in: state)
            guard let next = try? state.apply(move) else { break }
            state = next
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
    }
}
