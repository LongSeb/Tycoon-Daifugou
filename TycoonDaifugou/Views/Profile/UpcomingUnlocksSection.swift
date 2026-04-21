import SwiftUI

struct UpcomingUnlocksSection: View {
    let unlocks: [UnlockItem]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isExpanded.toggle() } }) {
                HStack {
                    Text("UPCOMING UNLOCKS")
                        .font(.sectionLabel)
                        .foregroundStyle(Color.white.opacity(0.2))
                        .tracking(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.top, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(unlocks) { item in
                        row(for: item)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func row(for item: UnlockItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .frame(width: 26, height: 26)

                UnlockIconView(icon: item.icon, size: 12)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textSecondary)

                Text(item.description)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("Lvl \(item.level)")
                .font(.ruleCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(10)
        .background(Color.tycoonCard)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
