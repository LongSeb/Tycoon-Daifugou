import SwiftUI

struct TricksSlide: View {
    private let labels   = ["Pass", "Pass", "▶ Leads next", "Pass"]
    private let isLeader = [false, false, true, false]

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 36) {
                playerNode(label: labels[0], isLeader: isLeader[0])
                playerNode(label: labels[1], isLeader: isLeader[1])
            }
            HStack(spacing: 36) {
                playerNode(label: labels[2], isLeader: isLeader[2])
                playerNode(label: labels[3], isLeader: isLeader[3])
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func playerNode(label: String, isLeader: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isLeader ? Color.tycoonMint : Color.tycoonCard)
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(
                        isLeader ? Color.tycoonMint : Color.tycoonBorder,
                        lineWidth: 1.5
                    ))
                Text(isLeader ? "★" : "·")
                    .font(.system(size: isLeader ? 22 : 30, weight: .bold))
                    .foregroundStyle(isLeader ? Color.tycoonBlack : Color.textTertiary)
            }
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isLeader ? Color.tycoonMint : Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 96)
        }
    }
}
