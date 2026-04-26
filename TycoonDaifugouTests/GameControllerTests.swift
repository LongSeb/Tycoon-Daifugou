import Testing
@testable import TycoonDaifugou
import TycoonDaifugouKit

@Suite("GameController")
@MainActor
struct GameControllerTests {

    // MARK: - Helpers

    private func makeController() -> GameController {
        let humanID = PlayerID()
        let aiID = PlayerID()
        let players = [
            Player(id: humanID, displayName: "Human"),
            Player(id: aiID, displayName: "AI"),
        ]
        return GameController(
            players: players,
            ruleSet: .baseOnly,
            seed: 42,
            humanPlayerID: humanID,
            opponents: [aiID: PolicyOpponent(policy: .greedy, temperature: 0, seed: 42)],
            playerEmojis: [humanID: "😎", aiID: "🤖"]
        )
    }

    /// Plays the weakest legal move for the human if it's their turn; returns the played cards.
    @discardableResult
    private func playHumanMove(_ controller: GameController) throws -> [Card]? {
        guard controller.activePlayer.id == controller.humanPlayerID else { return nil }
        let moves = controller.state.validMoves(for: controller.humanPlayerID)
        guard let first = moves.first(where: { if case .play = $0 { return true }; return false }),
              case .play(let cards, _) = first else { return nil }
        try controller.play(cards)
        return cards
    }

    // MARK: - State reflection

    @Test("humanHand mirrors the human player's cards in GameState")
    func humanHandMirrorsState() {
        let controller = makeController()
        let expected = controller.state.players.first { $0.id == controller.humanPlayerID }?.hand ?? []
        #expect(controller.humanHand == expected)
    }

    @Test("humanHand shrinks after a valid play")
    func humanPlayReducesHandCount() throws {
        let controller = makeController()
        guard controller.activePlayer.id == controller.humanPlayerID else { return }
        let before = controller.humanHand.count
        guard let played = try playHumanMove(controller) else { return }
        #expect(controller.humanHand.count == before - played.count)
        #expect(played.allSatisfy { !controller.humanHand.contains($0) })
    }

    // MARK: - canPlay

    @Test("canPlay returns false for an empty selection")
    func canPlayFalseForEmptySelection() {
        #expect(makeController().canPlay(cards: []) == false)
    }

    @Test("canPlay returns false for cards not in the human's hand")
    func canPlayFalseForCardsNotInHand() {
        let controller = makeController()
        // Jokers are absent from a baseOnly deck, so this card is guaranteed invalid.
        #expect(controller.canPlay(cards: [.joker(index: 0)]) == false)
    }

    // MARK: - Error handling

    @Test("play throws and leaves state unchanged when cards not in hand")
    func invalidPlayThrowsWithoutMutatingState() {
        let controller = makeController()
        let before = controller.state
        #expect(throws: (any Error).self) {
            try controller.play([.joker(index: 0)])
        }
        #expect(controller.state == before)
    }

    // MARK: - AI resolution

    @Test("resolveAITurnsIfNeeded returns control to the human")
    func aiResolutionReturnsToHuman() async throws {
        let controller = makeController()

        // Ensure it's the human's turn before handing off to AI.
        if controller.activePlayer.id == controller.humanPlayerID {
            try playHumanMove(controller)
        }

        await controller.resolveAITurnsIfNeeded()

        let isHumanTurn = controller.activePlayer.id == controller.humanPlayerID
        let roundOver = controller.state.phase != .playing
        #expect(isHumanTurn || roundOver)
    }

    @Test("resolveAITurnsIfNeeded mutates state when AI must act")
    func aiResolutionMutatesState() async throws {
        let controller = makeController()

        // Give the human a turn so next turn belongs to AI.
        if controller.activePlayer.id == controller.humanPlayerID {
            try playHumanMove(controller)
        }

        let before = controller.state
        await controller.resolveAITurnsIfNeeded()
        #expect(controller.state != before)
    }
}
