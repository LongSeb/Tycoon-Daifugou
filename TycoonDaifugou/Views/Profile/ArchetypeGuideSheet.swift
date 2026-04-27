import SwiftUI

private struct ArchetypeInfo {
    let archetype: PlayingStyleArchetype
    let emoji: String
    let axes: String        // short axis summary
    let description: String
}

private let allArchetypes: [ArchetypeInfo] = [
    ArchetypeInfo(
        archetype: .tycoon,
        emoji: "👑",
        axes: "High aggression · High early · Low risk · High consistency",
        description: "Methodical and consistent. You play efficiently, shed cards early, and rarely take unnecessary risks."
    ),
    ArchetypeInfo(
        archetype: .gambler,
        emoji: "🎭",
        axes: "High aggression · High early · High risk · Low consistency",
        description: "High energy and unpredictable. You play aggressively and love a revolution, but results can vary wildly."
    ),
    ArchetypeInfo(
        archetype: .hoarder,
        emoji: "🐢",
        axes: "Low aggression · Low early · Low risk · High consistency",
        description: "Patient and calculated. You wait for the perfect moment, hold strong cards, and rarely show your hand."
    ),
    ArchetypeInfo(
        archetype: .wildcard,
        emoji: "⚡",
        axes: "Low aggression · Low early · High risk · Low consistency",
        description: "Chaotic and hard to read. You hold back but strike with high-risk plays that keep opponents guessing."
    ),
]

struct ArchetypeGuideSheet: View {
    let currentArchetype: PlayingStyleArchetype
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tycoonSheet.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(allArchetypes, id: \.archetype.rawValue) { info in
                            archetypeCard(info)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Playing Styles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.tycoonSheet, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.ruleTitle)
                        .foregroundStyle(Color.tycoonMint)
                }
            }
        }
        .presentationDetents([.fraction(0.72)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func archetypeCard(_ info: ArchetypeInfo) -> some View {
        let isCurrent = info.archetype == currentArchetype

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(info.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(info.archetype.rawValue)
                            .font(.custom("Fraunces-9ptBlackItalic", size: 21))
                            .foregroundStyle(Color.textPrimary)

                        if isCurrent {
                            Text("YOU")
                                .font(.ruleCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.tycoonBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.tycoonMint)
                                .clipShape(Capsule())
                        }
                    }

                    Text(info.axes)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(2)
                }
            }

            Text(info.description)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tycoonCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isCurrent ? Color.tycoonMint.opacity(0.5) : Color.tycoonBorder,
                    lineWidth: isCurrent ? 1.5 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    ArchetypeGuideSheet(currentArchetype: .gambler)
}
