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

enum CardSkinCustomAnimation {
    case subway
}

struct CardSkin: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let isFoil: Bool
    var isDark: Bool = false
    var jokerImageName: String = "JokerCard"
    var jokerImagePadding: CGFloat = 2
    var numberFontName: String = "Fraunces-9ptBlackItalic"
    var selectionColor: Color? = nil
    var overlayImageName: String? = nil
    var inkColorOverride: Color? = nil
    var showBorder: Bool = true
    var showTextShadow: Bool = false
    var foilColor: Color? = nil
    var jokerImageUseTemplate: Bool = false
    var cornerPaddingOverride: CGFloat? = nil
    var cornerLabelSpacing: CGFloat? = nil
    var showTextOutline: Bool = false
    var strongTextShadow: Bool = false
    var textShadowColor: Color = .black
    var customAnimation: CardSkinCustomAnimation? = nil
    var showKanjiCorners: Bool = false
    var textShadowOpacity: Double? = nil
    var showFallingPetals: Bool = false

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
