import SwiftUI
import TycoonDaifugouKit

struct InterRoundResultsView: View {
    let result: RoundResult
    let isLastRound: Bool
    var humanEquippedTitle: String? = nil
    var humanEquippedBorder: ProfileBorder? = nil
    let onContinue: () -> Void

    @State private var headerVisible = false
    @State private var animateRows = false
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                header
                    .padding(.bottom, 28)

                standingsCard
                    .padding(.bottom, 24)

                ctaButton

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                headerVisible = true
            }
            animateRows = true
            ctaVisible = true
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ROUND \(result.roundNumber)")
                .font(.resultEyebrow)
                .foregroundStyle(Color.white.opacity(0.35))
                .tracking(3)
            Text("Results")
                .font(.custom("Fraunces-9ptBlackItalic", size: 42))
                .foregroundStyle(Color.cardBlush)
                .tracking(-1)
        }
        .opacity(headerVisible ? 1 : 0)
        .offset(y: headerVisible ? 0 : 12)
        .animation(.easeOut(duration: 0.4), value: headerVisible)
    }

    // MARK: Standings Card

    private var standingsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(result.playerResults.enumerated()), id: \.element.playerID.value) { index, player in
                playerRow(player, index: index)
                if index < result.playerResults.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                }
            }
        }
        .background(Color.tycoonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
    }

    private func playerRow(_ player: PlayerRoundResult, index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(player.isHuman ? Color.cardBlush.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        Circle().strokeBorder(
                            player.isHuman ? Color.cardBlush.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: 1.5
                        )
                    )
                Text(player.emoji)
                    .font(.system(size: 18))

                if player.isHuman, let border = humanEquippedBorder {
                    Circle()
                        .stroke(border.color, lineWidth: 1.5)
                }
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.ruleTitle)
                        .foregroundStyle(player.isHuman ? Color.cardBlush : Color.textPrimary)
                    if player.isHuman, let title = humanEquippedTitle {
                        Text(title)
                            .font(.custom("InstrumentSans-Regular", size: 10).weight(.medium).italic())
                            .foregroundStyle(Color.tycoonMint.opacity(0.8))
                    }
                }
                Text(player.title.displayName)
                    .font(.resultMeta)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(player.pointsEarned) pts")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.cardBlush)
                Text("Total: \(player.cumulativePoints)")
                    .font(.resultMeta)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(player.isHuman ? Color.cardBlush.opacity(0.05) : Color.clear)
        .overlay(alignment: .leading) {
            if player.isHuman {
                Rectangle()
                    .fill(Color.cardBlush.opacity(0.5))
                    .frame(width: 2)
            }
        }
        .opacity(animateRows ? 1 : 0)
        .offset(y: animateRows ? 0 : 10)
        .animation(
            .easeOut(duration: 0.35).delay(0.25 + Double(index) * 0.08),
            value: animateRows
        )
    }

    // MARK: CTA Button

    private var ctaButton: some View {
        let delay = 0.25 + Double(result.playerResults.count) * 0.08 + 0.1

        return Button(action: onContinue) {
            HStack(spacing: 8) {
                Image(systemName: isLastRound ? "flag.checkered" : "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tycoonBlack)
                Text(isLastRound ? "See Final Results" : "Start Round \(result.roundNumber + 1)")
                    .font(.resultButton)
                    .foregroundStyle(Color.tycoonBlack)
                    .tracking(0.3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.cardBlush)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(ctaVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.3).delay(delay), value: ctaVisible)
    }
}
