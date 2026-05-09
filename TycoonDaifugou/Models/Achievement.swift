import Foundation

enum AchievementCategory: String {
    case milestone
    case gameplay
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let iconName: String
    var isUnlocked: Bool = false
    var dateUnlocked: Date? = nil
}

enum AchievementDefinitions {
    static let all: [Achievement] = [
        Achievement(
            id: "first_win",
            title: "First of Many",
            description: "Win your first game",
            category: .milestone,
            iconName: "trophy.fill"
        ),
        Achievement(
            id: "spade_sniper",
            title: "Sneaky Spade",
            description: "Win a hand using the 3 of Spades",
            category: .gameplay,
            iconName: "suit.spade.fill"
        ),
        Achievement(
            id: "tycoon_dynasty",
            title: "The Real Tycoon",
            description: "Finish as Tycoon in all 3 rounds of a single game",
            category: .gameplay,
            iconName: "crown.fill"
        ),
        Achievement(
            id: "rags_to_riches",
            title: "Climbing The Ladder",
            description: "Win a game after entering a round as Beggar",
            category: .gameplay,
            iconName: "arrow.up.circle.fill"
        ),
        Achievement(
            id: "full_send",
            title: "Protecting Your Wealth",
            description: "Empty your entire hand in a single turn",
            category: .gameplay,
            iconName: "rectangle.stack.fill"
        ),
        Achievement(
            id: "no_hesitation",
            title: "Money Hungry",
            description: "Win a game without passing a single time",
            category: .gameplay,
            iconName: "bolt.fill"
        ),
        Achievement(
            id: "revolutionary",
            title: "Revolutionary",
            description: "Trigger a Revolution",
            category: .gameplay,
            iconName: "arrow.clockwise.circle.fill"
        ),
        Achievement(
            id: "counter_strike",
            title: "Aggressive Striker",
            description: "Trigger a Counter-Revolution",
            category: .gameplay,
            iconName: "arrow.counterclockwise.circle.fill"
        ),
        Achievement(
            id: "wild_finish",
            title: "A Trick Up Your Sleeve",
            description: "Win a hand by playing a Joker",
            category: .gameplay,
            iconName: "sparkles"
        ),
        Achievement(
            id: "veteran",
            title: "One True Millionaire",
            description: "Win 20 games",
            category: .milestone,
            iconName: "medal.fill"
        ),
    ]
}
