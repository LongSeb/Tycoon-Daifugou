import SwiftUI

struct CardSkinPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let skins: [CardSkin]
    let lockedSkins: [CardSkin]
    let currentSkinID: String
    let onSelect: (CardSkin) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                handle
                header
                skinGrid
                Spacer(minLength: 24)
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Choose Card Skin")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.2)
            Text("\(skins.count) unlocked")
                .font(.ruleCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var skinGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(skins) { skin in
                skinCell(skin)
            }
            ForEach(lockedSkins) { skin in
                lockedSkinCell(skin)
            }
        }
        .padding(.horizontal, 16)
    }

    private func skinCell(_ skin: CardSkin) -> some View {
        let isSelected = skin.id == currentSkinID
        return Button {
            onSelect(skin)
        } label: {
            VStack(spacing: 8) {
                CardBackView(skin: skin, cornerRadius: 8, width: 58, height: 82)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.tycoonMint : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.tycoonMint.opacity(0.3) : Color.clear,
                        radius: 8
                    )

                HStack(spacing: 4) {
                    Text(skin.name)
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                        .foregroundStyle(isSelected ? Color.tycoonMint : Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.tycoonCard)
                                .frame(width: 15, height: 15)
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.tycoonMint)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func lockedSkinCell(_ skin: CardSkin) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 58, height: 82)
                .overlay(
                    Text("?")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )

            Text("Locked")
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                .foregroundStyle(Color.white.opacity(0.2))
                .lineLimit(1)
        }
        .allowsHitTesting(false)
    }
}
