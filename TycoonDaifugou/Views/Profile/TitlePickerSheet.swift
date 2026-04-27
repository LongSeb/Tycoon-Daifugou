import SwiftUI

struct TitlePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let titles: [String]
    let lockedTitles: [String]
    let currentTitle: String
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                handle
                header
                ScrollView(.vertical, showsIndicators: false) {
                    titleList
                        .padding(.bottom, 24)
                }
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
            Text("Choose Title")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.2)
            Text("\(titles.count) unlocked")
                .font(.ruleCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var titleList: some View {
        VStack(spacing: 0) {
            ForEach(Array(titles.enumerated()), id: \.element) { index, title in
                titleRow(title)
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
            }
            ForEach(Array(lockedTitles.enumerated()), id: \.element) { index, _ in
                lockedTitleRow()
                if index < lockedTitles.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1)
                }
            }
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func titleRow(_ title: String) -> some View {
        let isSelected = title == currentTitle
        return Button {
            onSelect(title)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.custom("InstrumentSans-Regular", size: 15).weight(.medium).italic())
                    .foregroundStyle(isSelected ? Color.tycoonMint : Color.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tycoonMint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.tycoonMint.opacity(0.06) : Color.clear)
    }

    private func lockedTitleRow() -> some View {
        HStack(spacing: 12) {
            Text("???")
                .font(.custom("InstrumentSans-Regular", size: 15).weight(.medium).italic())
                .foregroundStyle(Color.white.opacity(0.2))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .allowsHitTesting(false)
    }
}
