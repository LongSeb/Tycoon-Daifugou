import SwiftUI

private struct ArchetypeInfo {
    let archetype: PlayingStyleArchetype
    let emoji: String
    let axes: String
    let description: String
    let accentColor: Color
}

private let allArchetypes: [ArchetypeInfo] = [
    ArchetypeInfo(
        archetype: .tycoon,
        emoji: "👑",
        axes: "Super aggressive • Low Risk • Consistent",
        description: "Methodical and consistent. You play efficiently, rip cards early, and don't take risks.",
        accentColor: .cardGold
    ),
    ArchetypeInfo(
        archetype: .gambler,
        emoji: "🎲",
        axes: "Super aggressive • High Risk • High Reward",
        description: "High energy and unpredictable. You play aggressively, love a revolution and hope it pays off.",
        accentColor: .cardRed
    ),
    ArchetypeInfo(
        archetype: .hoarder,
        emoji: "🐌",
        axes: "Calm • Patient • Calculated",
        description: "Patient and calculated. You wait for the perfect moment to pounce and rarely show your hand.",
        accentColor: .cardLavender
    ),
    ArchetypeInfo(
        archetype: .wildcard,
        emoji: "🎰",
        axes: "Calm • Unplanned • Spotty",
        description: "Chaotic and hard to read. You hold back but strike with risky plays that keep everyone on their toes.",
        accentColor: .tycoonMint
    ),
    ArchetypeInfo(
        archetype: .mogul,
        emoji: "👩🏼‍💼",
        axes: "Assertive • Sets Pace • Calculated",
        description: "Cold and methodical. You control the table's tempo, make intentional moves, and force players to your rhythm.",
        accentColor: .cardSky
    ),
    ArchetypeInfo(
        archetype: .hustler,
        emoji: "🏃🏼‍♀️",
        axes: "Assertive • Unplanned • High Reward",
        description: "Dominant on instinct. You force the table, win on pressure and reads, and thrive when others can't keep up.",
        accentColor: .cardPeach
    ),
]

struct ArchetypeGuideSheet: View {
    let currentArchetype: PlayingStyleArchetype
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "111111").ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Playing Styles")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 16)

                        VStack(spacing: 10) {
                            ForEach(allArchetypes, id: \.archetype.rawValue) { info in
                                archetypeCard(info)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "111111"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(hex: "2a2a2a"))
                        .clipShape(Capsule())
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
            HStack(alignment: .top, spacing: 12) {
                Text(info.emoji)
                    .font(.system(size: 32))
                    .frame(width: 40, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(info.archetype.rawValue)
                            .font(.custom("Fraunces-9ptBlackItalic", size: 21))
                            .foregroundStyle(info.accentColor)

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
                        .fixedSize(horizontal: false, vertical: true)
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
        .background(Color(hex: "1c1c1e"))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isCurrent ? info.accentColor.opacity(0.6) : Color.white.opacity(0.08),
                    lineWidth: isCurrent ? 1.5 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ArchetypeGuideSheet(currentArchetype: .mogul)
}
