import SwiftUI

struct SpecialCardsSlide: View {
    var body: some View {
        VStack(spacing: 20) {
            specialRow(chip: "8",  label: "8-Stop: ends the trick, you lead next",    highlighted: false)
            specialRow(chip: "🃏", label: "Joker: beats anything alone or in combos", highlighted: true)
            specialRow(chip: "3♠", label: "3 of Spades: trumps a lone Joker",         highlighted: false)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func specialRow(chip: String, label: String, highlighted: Bool) -> some View {
        HStack(spacing: 16) {
            TutorialCardChip(label: chip, highlighted: highlighted)
                .frame(minWidth: 56)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
