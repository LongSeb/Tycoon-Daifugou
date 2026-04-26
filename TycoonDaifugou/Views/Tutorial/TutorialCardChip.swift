import SwiftUI

struct TutorialCardChip: View {
    let label: String
    var highlighted: Bool = false

    var body: some View {
        Text(label)
            .font(.custom("Fraunces-9ptBlackItalic", size: 14))
            .foregroundStyle(highlighted ? Color.tycoonBlack : Color.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(highlighted ? Color.tycoonMint : Color.tycoonCard)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        highlighted ? Color.tycoonMint.opacity(0.4) : Color.tycoonBorder,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
