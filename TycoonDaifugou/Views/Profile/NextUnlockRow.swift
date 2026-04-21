import SwiftUI

struct NextUnlockRow: View {
    let item: UnlockItem

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.cardBlush.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color.cardBlush.opacity(0.15), lineWidth: 1)
                    )
                    .frame(width: 28, height: 28)

                UnlockIconView(icon: item.icon, size: 13)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT UNLOCK · LEVEL \(item.level)")
                    .font(.sectionLabel)
                    .foregroundStyle(Color.cardBlush.opacity(0.45))
                    .tracking(1.5)

                Text(item.name)
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.white.opacity(0.7))

                Text(item.description)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.tycoonCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
