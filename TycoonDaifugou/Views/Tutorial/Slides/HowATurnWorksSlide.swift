import SwiftUI

struct HowATurnWorksSlide: View {
    var body: some View {
        VStack(spacing: 8) {
            playExample(label: "Single", played: ["7♠"],              beats: ["8♦"])
            playExample(label: "Pair",   played: ["5♥", "5♣"],        beats: ["6♠", "6♦"])
            playExample(label: "Triple", played: ["J♦", "J♠", "J♣"], beats: ["Q", "Q", "Q"])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func playExample(label: String, played: [String], beats: [String]) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textTertiary)

            HStack(spacing: 4) {
                ForEach(Array(played.enumerated()), id: \.offset) { _, chip in
                    TutorialCardChip(label: chip)
                }
            }

            Text("→")
                .font(.tycoonBody)
                .foregroundStyle(Color.tycoonMint)

            HStack(spacing: 4) {
                ForEach(Array(beats.enumerated()), id: \.offset) { _, chip in
                    TutorialCardChip(label: chip, highlighted: true)
                }
            }
        }
    }
}
