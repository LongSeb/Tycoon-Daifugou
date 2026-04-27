import SwiftUI

// Animatable diamond polygon used for the outline stroke only.
private struct RadarPolygon: Shape {
    var aggression: Double
    var early: Double
    var risky: Double
    var consistent: Double
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(cx, cy)
        let p = progress

        var path = Path()
        path.move(to: CGPoint(x: cx, y: cy - r * CGFloat(aggression) * p))
        path.addLine(to: CGPoint(x: cx + r * CGFloat(early) * p, y: cy))
        path.addLine(to: CGPoint(x: cx, y: cy + r * CGFloat(risky) * p))
        path.addLine(to: CGPoint(x: cx - r * CGFloat(consistent) * p, y: cy))
        path.closeSubpath()
        return path
    }
}

struct PlayStyleRadarChart: View {
    let stats: ExtendedStatsData

    @State private var progress: CGFloat = 0

    // Characteristic colors — one per axis
    private let aggressColor = Color.tycoonMint      // top
    private let earlyColor   = Color.cardLavender    // right
    private let riskyColor   = Color.cardRed         // bottom
    private let consistColor = Color.cardGold        // left

    private var dominantAxis: Int {
        let axes = [stats.aggressionAxis, stats.earlyAxis, stats.riskAxis, stats.consistencyAxis]
        return axes.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }

    // Left frame = 70 + 6 spacing = 76pt, right frame = 44 + 6 spacing = 50pt.
    // Shift top/bottom labels right by half the difference so they sit over the chart center.
    private let chartHorizontalOffset: CGFloat = (76 - 50) / 2  // = 13

    var body: some View {
        VStack(spacing: 6) {
            topLabel
            HStack(spacing: 6) {
                leftLabel.frame(width: 70, alignment: .trailing)
                chartArea
                rightLabel.frame(width: 44, alignment: .leading)
            }
            bottomLabel
        }
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                progress = 1.0
            }
        }
    }

    // MARK: - Axis Labels

    private func labelColor(_ axisIndex: Int) -> Color {
        let base: Color
        switch axisIndex {
        case 0: base = aggressColor
        case 1: base = earlyColor
        case 2: base = riskyColor
        default: base = consistColor
        }
        return dominantAxis == axisIndex ? base : base.opacity(0.55)
    }

    private var topLabel: some View {
        VStack(spacing: 2) {
            Text("Aggressive")
                .font(.system(size: 11, weight: dominantAxis == 0 ? .semibold : .regular))
                .foregroundStyle(labelColor(0))
            Text("Play vs. pass")
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
        }
        .offset(x: chartHorizontalOffset)
    }

    private var bottomLabel: some View {
        VStack(spacing: 2) {
            Text("Risky")
                .font(.system(size: 11, weight: dominantAxis == 2 ? .semibold : .regular))
                .foregroundStyle(labelColor(2))
            Text("Bold play rate")
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
        }
        .offset(x: chartHorizontalOffset)
    }

    private var leftLabel: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Consistent")
                .font(.system(size: 11, weight: dominantAxis == 3 ? .semibold : .regular))
                .foregroundStyle(labelColor(3))
            Text("Finish variance")
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
        }
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var rightLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Early")
                .font(.system(size: 11, weight: dominantAxis == 1 ? .semibold : .regular))
                .foregroundStyle(labelColor(1))
            Text("Top-2 finishes")
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: - Chart Canvas

    private var chartArea: some View {
        ZStack {
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let r = min(cx, cy)
                let p = CGFloat(progress)

                // 4 concentric diamond grid lines — inner 3 dotted, outer solid
                for frac in [0.25, 0.5, 0.75, 1.0] as [CGFloat] {
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: cx, y: cy - r * frac))
                    diamond.addLine(to: CGPoint(x: cx + r * frac, y: cy))
                    diamond.addLine(to: CGPoint(x: cx, y: cy + r * frac))
                    diamond.addLine(to: CGPoint(x: cx - r * frac, y: cy))
                    diamond.closeSubpath()
                    if frac == 1.0 {
                        context.stroke(diamond,
                                       with: .color(Color.white.opacity(0.12)),
                                       lineWidth: 1)
                    } else {
                        context.stroke(diamond,
                                       with: .color(Color.white.opacity(0.08)),
                                       style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 4]))
                    }
                }

                // Axis points (animated)
                let topPt    = CGPoint(x: cx,           y: cy - r * CGFloat(stats.aggressionAxis)  * p)
                let rightPt  = CGPoint(x: cx + r * CGFloat(stats.earlyAxis)       * p, y: cy)
                let bottomPt = CGPoint(x: cx,           y: cy + r * CGFloat(stats.riskAxis)        * p)
                let leftPt   = CGPoint(x: cx - r * CGFloat(stats.consistencyAxis) * p, y: cy)
                let centerPt = CGPoint(x: cx, y: cy)

                // Single polygon filled with an angular gradient — smooth color wheel with no seams
                var poly = Path()
                poly.move(to: topPt)
                poly.addLine(to: rightPt)
                poly.addLine(to: bottomPt)
                poly.addLine(to: leftPt)
                poly.closeSubpath()

                context.fill(poly, with: .conicGradient(
                    Gradient(stops: [
                        .init(color: Color.tycoonMint.opacity(0.8),   location: 0.00), // top
                        .init(color: Color.cardLavender.opacity(0.8), location: 0.25), // right
                        .init(color: Color.cardRed.opacity(0.8),      location: 0.50), // bottom
                        .init(color: Color.cardGold.opacity(0.8),     location: 0.75), // left
                        .init(color: Color.tycoonMint.opacity(0.8),   location: 1.00), // back to top
                    ]),
                    center: centerPt,
                    angle: Angle(degrees: -90)
                ))
            }

            // Outline stroke (animated via animatableData)
            RadarPolygon(
                aggression: stats.aggressionAxis,
                early: stats.earlyAxis,
                risky: stats.riskAxis,
                consistent: stats.consistencyAxis,
                progress: progress
            )
            .stroke(Color.white.opacity(0.6), lineWidth: 1.0)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    let tycoon = ExtendedStatsData(
        totalGamesPlayed: 24,
        passRate: 0.22, earlyFinisherRate: 0.71, comebackRate: 0.30,
        sweepRate: 0.15, cardHoardingIndex: 0.25, trickWinRate: 0.68,
        jokerEfficiency: 0.58, avgRevolutionsPerGame: 1.2,
        aggressionAxis: 0.78, earlyAxis: 0.71, riskAxis: 0.30, consistencyAxis: 0.82,
        archetype: .tycoon, archetypeEmoji: "👑",
        archetypeDescription: "Methodical and consistent."
    )
    return PlayStyleRadarChart(stats: tycoon)
        .padding(24)
        .background(Color.tycoonSurface)
}
