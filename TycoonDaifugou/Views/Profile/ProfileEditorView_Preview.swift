import SwiftUI

private let previewBorders: [ProfileBorder] = [
    ProfileBorder(id: "bronze", name: "Bronze", color: Color(hex: "#CD7F32"), isAnimated: false),
    ProfileBorder(id: "royal_red_border", name: "Royal Red", color: Color(hex: "#AC2317"), isAnimated: false),
    ProfileBorder(id: "silver", name: "Silver", color: Color(hex: "#C0C0C0"), isAnimated: false),
]

#Preview("Unlocked borders (Level 13)") {
    NavigationStack {
        ProfileEditorView(
            initialEmoji: "😎",
            initialUsername: "daifugō_king",
            currentLevel: 13,
            unlockedBorders: previewBorders,
            currentBorderID: "silver",
            onBorderSelect: { _ in },
            onSave: { _, _ in }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked border (Level 4)") {
    NavigationStack {
        ProfileEditorView(
            initialEmoji: "🎴",
            initialUsername: "newbie",
            currentLevel: 4,
            unlockedBorders: [],
            currentBorderID: nil,
            onBorderSelect: { _ in },
            onSave: { _, _ in }
        )
    }
    .preferredColorScheme(.dark)
}
