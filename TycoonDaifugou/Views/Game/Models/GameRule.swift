import Foundation

struct GameRule: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let badge: RuleBadge
}

enum RuleBadge {
    case star
    case arrows
    case joker
    case threeSpade
    case eight
    case clock
}

extension GameRule {
    static let all: [GameRule] = [
        GameRule(
            title: "Revolution",
            description: "Play four-of-a-kind to invert card strength for the rest of the round.",
            badge: .star
        ),
        GameRule(
            title: "Reverse Revolution",
            description: "Play another four-of-a-kind during a Revolution to restore normal card order.",
            badge: .arrows
        ),
        GameRule(
            title: "Joker",
            description: "Wild card that beats almost anything. Only the 3♠ can beat it.",
            badge: .joker
        ),
        GameRule(
            title: "3-Spade Reversal",
            description: "The only card that beats a Joker. Reverses the round when played on top.",
            badge: .threeSpade
        ),
        GameRule(
            title: "8 Stop",
            description: "Playing an 8 immediately ends the current round. Next player leads fresh.",
            badge: .eight
        ),
        GameRule(
            title: "Bankruptcy",
            description: "Reach Tycoon then lose a following round — demoted to Beggar and eliminated.",
            badge: .clock
        ),
    ]
}
