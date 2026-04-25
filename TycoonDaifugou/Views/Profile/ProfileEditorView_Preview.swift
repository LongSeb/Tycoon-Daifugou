import SwiftUI

#Preview("Default") {
    NavigationStack {
        ProfileEditorView(
            initialEmoji: "😎",
            initialUsername: "daifugō_king",
            onSave: { _, _ in }
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Long username") {
    NavigationStack {
        ProfileEditorView(
            initialEmoji: "🎴",
            initialUsername: "superlong_name_here",
            onSave: { _, _ in }
        )
    }
    .preferredColorScheme(.dark)
}
