import SwiftUI

struct BorderPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentLevel: Int
    let unlockedBorders: [ProfileBorder]
    let currentBorderID: String?
    let onSelect: (String?) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var lockedBordersWithLevel: [(ProfileBorder, Int)] {
        let unlockedIDs = Set(unlockedBorders.map(\.id))
        return UnlockRegistry.all.compactMap { def in
            guard case .profileBorder(let b) = def.type,
                  !unlockedIDs.contains(b.id) else { return nil }
            return (b, def.level)
        }
    }

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                handle
                header

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 20) {
                        noBorderCell
                        ForEach(unlockedBorders) { border in
                            borderCell(border)
                        }
                        ForEach(lockedBordersWithLevel, id: \.0.id) { (border, level) in
                            lockedBorderCell(border, requiredLevel: level)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Header

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Choose Border")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.2)
            Text(unlockedBorders.isEmpty ? "Unlock borders by levelling up" : "\(unlockedBorders.count) unlocked")
                .font(.ruleCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    // MARK: - Cells

    private var noBorderCell: some View {
        let isSelected = currentBorderID == nil
        return Button {
            onSelect(nil)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.tycoonCard)
                        .frame(width: 64, height: 64)

                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [5, 4])
                        )
                        .foregroundStyle(isSelected ? Color.tycoonMint : Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)

                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(isSelected ? Color.tycoonMint : Color.textTertiary)
                }
                .shadow(
                    color: isSelected ? Color.tycoonMint.opacity(0.25) : Color.clear,
                    radius: 8
                )

                Text("None")
                    .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                    .foregroundStyle(isSelected ? Color.tycoonMint : Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func borderCell(_ border: ProfileBorder) -> some View {
        let isSelected = border.id == currentBorderID
        return Button {
            onSelect(border.id)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.tycoonCard)
                        .frame(width: 64, height: 64)

                    if border.isAnimated {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [border.color, border.color.opacity(0.3), border.color],
                                    center: .center
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 70, height: 70)
                    } else {
                        Circle()
                            .strokeBorder(border.color, lineWidth: 3)
                            .frame(width: 70, height: 70)
                    }

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.tycoonMint, lineWidth: 2)
                            .frame(width: 76, height: 76)
                    }
                }
                .shadow(
                    color: isSelected ? Color.tycoonMint.opacity(0.3) : Color.clear,
                    radius: 8
                )

                Text(border.name)
                    .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                    .foregroundStyle(isSelected ? Color.tycoonMint : Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private func lockedBorderCell(_ border: ProfileBorder, requiredLevel: Int) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 3)
                    .frame(width: 70, height: 70)
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.18))
            }

            Text("Lvl \(requiredLevel)")
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                .foregroundStyle(Color.white.opacity(0.18))
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    BorderPickerSheet(
        currentLevel: 13,
        unlockedBorders: [
            ProfileBorder(id: "bronze", name: "Bronze", color: Color(hex: "#CD7F32"), isAnimated: false),
            ProfileBorder(id: "royal_red_border", name: "Royal Red", color: Color(hex: "#AC2317"), isAnimated: false),
            ProfileBorder(id: "silver", name: "Silver", color: Color(hex: "#C0C0C0"), isAnimated: false),
        ],
        currentBorderID: "silver",
        onSelect: { _ in }
    )
}
