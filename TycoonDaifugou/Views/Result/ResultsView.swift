import SwiftUI

struct ResultsView: View {
    let result: GameResultData
    var onPlayAgain: () -> Void = {}
    var onMainMenu: () -> Void = {}

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    winnerHero
                    standingsCard
                    xpCard
                    actionButtons
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            Text("Tycoon Daifugō")
                .font(.resultBrandSmall)
                .foregroundStyle(Color.white.opacity(0.45))
                .tracking(-0.2)
            Spacer()
            Text("ROUND \(result.roundsPlayed) COMPLETE")
                .font(.resultEyebrow)
                .foregroundStyle(Color.white.opacity(0.25))
                .tracking(2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: Winner Hero

    private var winnerHero: some View {
        VStack(spacing: 0) {
            Text("You finished as")
                .font(.resultEyebrow)
                .foregroundStyle(Color.white.opacity(0.3))
                .tracking(3)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            Text(result.playerFinishRank)
                .font(.resultHeroRank)
                .foregroundStyle(Color.textPrimary)
                .tracking(-1.5)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 4) {
                Text("Game Score:")
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text("\(result.roundPointsTotal) pts")
                    .font(.tycoonCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.cardBlush.opacity(0.7))
            }
            .padding(.top, 6)

            Rectangle()
                .fill(Color.cardBlush.opacity(0.25))
                .frame(width: 40, height: 1)
                .padding(.vertical, 14)

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.cardBlush.opacity(0.6))

                Text(result.highlight)
                    .font(.tycoonCaption)
                    .italic()
                    .foregroundStyle(Color.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: Final Standings

    private var standingsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("FINAL STANDINGS")
                    .font(.sectionLabel)
                    .foregroundStyle(Color.white.opacity(0.25))
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )

            ForEach(Array(result.players.enumerated()), id: \.element.id) { index, player in
                ResultPlayerRow(position: index + 1, player: player)
                if index < result.players.count - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                        .padding(.leading, 14)
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
        .padding(.bottom, 16)
    }

    // MARK: XP Card

    private var xpCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("XP EARNED")
                        .font(.sectionLabel)
                        .foregroundStyle(Color.white.opacity(0.25))
                        .tracking(2)

                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text("+\(result.xpGained)")
                            .font(.profileLevel)
                            .foregroundStyle(Color.cardBlush)
                            .tracking(-1)
                        Text("XP")
                            .font(.ruleTitle)
                            .foregroundStyle(Color.cardBlush.opacity(0.45))
                            .tracking(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("LEVEL")
                        .font(.sectionLabel)
                        .foregroundStyle(Color.white.opacity(0.25))
                        .tracking(2)
                    Text("\(result.currentLevel)")
                        .font(.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .padding(.bottom, 14)

            HStack {
                Text("Level \(result.currentLevel)")
                    .font(.resultMeta)
                    .foregroundStyle(Color.white.opacity(0.3))
                Spacer()
                Text("Level \(result.currentLevel + 1)")
                    .font(.resultMeta)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.bottom, 6)

            XPProgressBar(
                xpBefore: result.xpBefore,
                xpAfter: result.xpAfter,
                levelStartXP: result.levelStartXP,
                xpForNextLevel: result.xpForNextLevel
            )
            .frame(height: 6)
            .padding(.bottom, 8)

            HStack {
                Text("\(result.xpBefore.formatted()) XP before")
                    .font(.resultMeta)
                    .foregroundStyle(Color.white.opacity(0.3))
                Spacer()
                Text("\(result.xpAfter.formatted()) XP now")
                    .font(.resultMetaStrong)
                    .foregroundStyle(Color.cardBlush.opacity(0.7))
            }
            .padding(.bottom, 12)

            FlowLayout(spacing: 6) {
                ForEach(result.xpBreakdown) { item in
                    XPChip(label: item.label, amount: item.amount)
                }
            }
        }
        .padding(14)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onPlayAgain) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.12))
                            .frame(width: 20, height: 20)
                        Image(systemName: "play.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.tycoonBlack)
                    }
                    Text("Play again")
                        .font(.resultButton)
                        .foregroundStyle(Color.tycoonBlack)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.cardBlush)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onMainMenu) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("Main menu")
                        .font(.ruleTitle)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.tycoonCard)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}
