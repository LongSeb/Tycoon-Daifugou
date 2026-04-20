import SwiftUI

enum AvatarSize {
    case small, medium, large

    var dimension: CGFloat {
        switch self {
        case .small: 28
        case .medium: 40
        case .large: 56
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: 14
        case .medium: 20
        case .large: 28
        }
    }
}

struct PlayerAvatar: View {
    let emoji: String
    let size: AvatarSize

    init(_ emoji: String, size: AvatarSize = .medium) {
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: size.fontSize))
            .frame(width: size.dimension, height: size.dimension)
            .background(Color.tycoonSurface)
            .clipShape(Circle())
    }
}

#Preview {
    HStack(spacing: 16) {
        PlayerAvatar("🐱", size: .small)
        PlayerAvatar("🦊", size: .medium)
        PlayerAvatar("🐼", size: .large)
    }
    .padding()
    .background(Color.tycoonBlack)
}
