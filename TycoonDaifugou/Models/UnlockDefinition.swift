import SwiftUI

enum UnlockType {
    case title(String)
    case cardSkin(CardSkin)
    case profileBorder(ProfileBorder)
    case featureGate(String)
    case prestigeBadge
}

struct UnlockDefinition {
    let level: Int
    let type: UnlockType
    let displayName: String
}

struct CardSkin: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let isFoil: Bool
    var isDark: Bool = false

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CardSkin, rhs: CardSkin) -> Bool { lhs.id == rhs.id }
}

struct ProfileBorder: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let isAnimated: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ProfileBorder, rhs: ProfileBorder) -> Bool { lhs.id == rhs.id }
}
