import SwiftUI

enum GradientCardStyle {
    case cream
    case blushCream
    case lavenderMint

    var gradient: LinearGradient {
        switch self {
        case .cream:
            return LinearGradient(
                colors: [.cardCream, .cardCream.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .blushCream:
            return LinearGradient(
                colors: [.cardBlush, .cardCream],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .lavenderMint:
            return LinearGradient(
                colors: [.cardLavender, .cardMint],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

struct GradientCard<Content: View>: View {
    let style: GradientCardStyle
    @ViewBuilder let content: Content

    init(style: GradientCardStyle = .cream, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .background(style.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        GradientCard(style: .cream) {
            Text("Cream")
                .font(.tycoonTitle)
                .padding(24)
        }
        GradientCard(style: .blushCream) {
            Text("Blush → Cream")
                .font(.tycoonTitle)
                .padding(24)
        }
        GradientCard(style: .lavenderMint) {
            Text("Lavender → Mint")
                .font(.tycoonTitle)
                .padding(24)
        }
    }
    .padding()
    .background(Color.tycoonBlack)
}
