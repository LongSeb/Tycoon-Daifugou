import Foundation
import TycoonDaifugouKit

// MARK: - Lobby types (Firestore)

struct LobbySettings: Codable {
    var jokerCount: Int?
    var revolutionEnabled: Bool?
    var eightStopEnabled: Bool?
    var threeSpadeReversalEnabled: Bool?
    var bankruptcyEnabled: Bool?
    var roundsPerGame: Int?
}

struct LobbyPlayer: Codable {
    var uid: String
    var displayName: String
    var ready: Bool
    var emoji: String?
    var title: String?
    var borderID: String?
}

struct Lobby: Codable {
    var status: String
    var matchType: String
    var inviteCode: String?
    var hostUid: String
    var players: [LobbyPlayer]
    var maxPlayers: Int
    var settings: LobbySettings?
}

// MARK: - RTDB game types

struct RTDBPlayer: Codable {
    var displayName: String
    var hand: [String]?
    var finishRank: Int?
    var connected: Bool?

    var handSafe: [String] { hand ?? [] }
    var isFinished: Bool { finishRank != nil }
}

struct RTDBGameState: Codable {
    var phase: String
    var round: Int
    var currentPlayerIndex: Int
    var currentPlayerUid: String
    var playerOrder: [String]
    var players: [String: RTDBPlayer]
    var currentTrick: [[String]]?
    var passCountSinceLastPlay: Int
    var isRevolutionActive: Bool
    var lastPlayedByIndex: Int?
    var matchType: String
    var settings: LobbySettings?
    var status: String
    var updatedAt: Double

    var abandonedBy: String?
    var eightStopEventCount: Int?
    var revolutionEventCount: Int?
    var threeSpadeEventCount: Int?

    var currentTrickSafe: [[String]] { currentTrick ?? [] }
    var isFinished: Bool { status == "finished" }
    var isAbandoned: Bool { status == "abandoned" }
}

// MARK: - Action

enum MultiplayerAction {
    case play(cards: [String])
    case pass

    var asDict: [String: Any] {
        switch self {
        case .play(let cards):
            return ["type": "play", "cards": cards]
        case .pass:
            return ["type": "pass"]
        }
    }
}

// MARK: - Card string parsing

extension Card {
    /// Parses a server-format card string ("3D", "10H", "KS", "JKR0") into a Card.
    init?(serverString: String) {
        if serverString.hasPrefix("JKR") {
            let index = Int(serverString.dropFirst(3)) ?? 0
            self = .joker(index: index)
            return
        }

        guard let suitChar = serverString.last else { return nil }
        let rankStr = String(serverString.dropLast())

        let suit: Suit
        switch suitChar {
        case "C": suit = .clubs
        case "D": suit = .diamonds
        case "H": suit = .hearts
        case "S": suit = .spades
        default: return nil
        }

        let rank: Rank
        switch rankStr {
        case "3":  rank = .three
        case "4":  rank = .four
        case "5":  rank = .five
        case "6":  rank = .six
        case "7":  rank = .seven
        case "8":  rank = .eight
        case "9":  rank = .nine
        case "10": rank = .ten
        case "J":  rank = .jack
        case "Q":  rank = .queen
        case "K":  rank = .king
        case "A":  rank = .ace
        case "2":  rank = .two
        default: return nil
        }

        self = .regular(rank, suit)
    }
}

// MARK: - Errors

enum MultiplayerError: LocalizedError {
    case unexpectedResponse
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse: return "Unexpected server response."
        case .notAuthenticated:   return "You must be signed in to play online."
        }
    }
}
