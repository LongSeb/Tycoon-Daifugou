import SwiftUI

struct RevolutionSlide: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    TutorialCardChip(label: "8", highlighted: true)
                }
            }
            VStack(spacing: 10) {
                Text("REVOLUTION")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 32))
                    .foregroundStyle(Color.tycoonMint)
                Text("↕")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.tycoonMint)
                Text("Card order reverses completely")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}
