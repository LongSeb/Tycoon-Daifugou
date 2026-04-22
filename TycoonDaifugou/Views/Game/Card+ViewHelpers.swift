import SwiftUI
import TycoonDaifugouKit

extension Card {
    var displayValue: String {
        if isJoker { return "JKR" }
        switch rank! {
        case .three: return "3"
        case .four:  return "4"
        case .five:  return "5"
        case .six:   return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine:  return "9"
        case .ten:   return "10"
        case .jack:  return "J"
        case .queen: return "Q"
        case .king:  return "K"
        case .ace:   return "A"
        case .two:   return "2"
        }
    }

    var displaySuit: String {
        guard let suit else { return "" }
        switch suit {
        case .clubs:    return "♣"
        case .diamonds: return "♦"
        case .hearts:   return "♥"
        case .spades:   return "♠"
        }
    }

    var suitColor: Color {
        guard let suit else { return .cardSuitRed }
        switch suit {
        case .hearts, .diamonds: return .cardSuitRed
        case .clubs, .spades:    return .cardSuitBlack
        }
    }
}

extension Title {
    var displayName: String {
        switch self {
        case .millionaire: return "Millionaire"
        case .rich:        return "Rich"
        case .commoner:    return "Commoner"
        case .poor:        return "Poor"
        case .beggar:      return "Beggar"
        }
    }
}

extension HandType {
    var displayName: String {
        switch self {
        case .single: return "Single"
        case .pair:   return "Pair"
        case .triple: return "Triple"
        case .quad:   return "Quad"
        }
    }
}
