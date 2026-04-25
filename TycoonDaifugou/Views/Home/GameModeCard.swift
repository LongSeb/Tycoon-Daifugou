import SwiftUI

enum GameMode: Hashable {
    case classic
    case custom
}

struct GameModeCard: View {
    let mode: GameMode
    let width: CGFloat
    let onTap: () -> Void
    var onEditTapped: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            GradientCard(style: .featurePlay) {
                HStack(spacing: 14) {
                    Text(emoji)
                        .font(.system(size: 26))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.cardTitle)
                            .foregroundStyle(Color.tycoonBlack)
                            .tracking(-0.4)

                        Text(subtitle)
                            .font(.tycoonCaption)
                            .foregroundStyle(Color.tycoonBlack.opacity(0.5))
                    }

                    Spacer()

                    trailingAccessory
                }
                .padding(20)
                .frame(minWidth: width, maxWidth: width, minHeight: 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if mode == .custom, let onEdit = onEditTapped {
            Button(action: onEdit) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.tycoonBlack.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.tycoonBlack.opacity(0.3))
        }
    }

    private var emoji: String {
        switch mode {
        case .classic: return "👑"
        case .custom:  return "✨"
        }
    }

    private var title: String {
        switch mode {
        case .classic: return "Classic"
        case .custom:  return "Custom"
        }
    }

    private var subtitle: String {
        switch mode {
        case .classic: return "Standard rules"
        case .custom:  return "Your rules"
        }
    }
}
