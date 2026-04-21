import SwiftUI

struct XPChip: View {
    let label: String
    let amount: Int

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.resultMeta)
                .foregroundStyle(Color.white.opacity(0.35))
            Text("+\(amount)")
                .font(.resultMetaStrong)
                .foregroundStyle(Color.cardBlush.opacity(0.7))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    HStack(spacing: 6) {
        XPChip(label: "Millionaire finish", amount: 200)
        XPChip(label: "Revolution", amount: 60)
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
