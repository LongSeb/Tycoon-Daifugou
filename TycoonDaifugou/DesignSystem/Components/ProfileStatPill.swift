import SwiftUI

struct ProfileStatPill: View {
    let value: String
    let label: String
    var valueColor: Color = .textPrimary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.brandTitle)
                .foregroundStyle(valueColor)
                .lineLimit(1)

            Text(label.uppercased())
                .font(.sectionLabel)
                .foregroundStyle(Color.textTertiary)
                .tracking(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    HStack(spacing: 8) {
        ProfileStatPill(value: "47", label: "Wins")
        ProfileStatPill(value: "128", label: "Games")
        ProfileStatPill(value: "37%", label: "Win rate", valueColor: .cardBlush)
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
