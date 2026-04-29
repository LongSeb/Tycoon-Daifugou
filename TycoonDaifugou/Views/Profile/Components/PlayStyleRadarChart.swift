import SwiftUI

// Animatable hex polygon used for the outline stroke.
// All 6 axis values are scaled uniformly by `progress` (0→1) for the draw-in animation.
private struct HexRadarPolygon: Shape {
    var values: [Double]  // 6 elements
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(cx, cy) * hexRadiusRatio

        var path = Path()
        let pts = (0..<6).map { i -> CGPoint in
            let angle = -Double.pi / 2 + Double(i) * (Double.pi / 3)
            let v = CGFloat(values[i]) * progress
            return CGPoint(x: cx + r * v * CGFloat(cos(angle)),
                           y: cy + r * v * CGFloat(sin(angle)))
        }
        path.move(to: pts[0])
        for pt in pts.dropFirst() { path.addLine(to: pt) }
        path.closeSubpath()
        return path
    }
}

// 0.58 * 1.15 — 15% bigger than the original hex.
// Must match the radius used inside the Canvas closure below.
private let hexRadiusRatio: CGFloat = 0.667

struct PlayStyleRadarChart: View {
    let stats: ExtendedStatsData

    @State private var progress: CGFloat = 0

    private var axisValues: [Double] {
        [
            stats.aggressionAxis,   // top          (0° = -90°)
            stats.calculatedAxis,   // upper-right  (60° = -30°)
            stats.earlyAxis,        // lower-right  (120° = 30°)
            stats.riskAxis,         // bottom       (180° = 90°)
            stats.dominantAxis,     // lower-left   (240° = 150°)
            stats.consistencyAxis,  // upper-left   (300° = 210°)
        ]
    }

    private let axisColors: [Color] = [
        .tycoonMint, .cardSky, .cardLavender, .cardRed, .cardPeach, .cardGold,
    ]

    private let axisNames = [
        "Aggressive", "Calculated", "Early", "Risky", "Dominant", "Consistent",
    ]

    private let axisSubtitles = [
        "Play vs. pass", "Deliberate pace", "Top-2 finishes",
        "Bold play rate", "Drives action",  "Finish variance",
    ]

    private var leadingAxisIndex: Int {
        axisValues.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }

    // Each label extends outward from its hex ring vertex so it never overlaps the polygon.
    private func axisLabel(index i: Int, vx: CGFloat, vy: CGFloat) -> some View {
        let gap: CGFloat = 8
        let labelW: CGFloat = 72
        let labelH: CGFloat = 26

        let lx: CGFloat
        let ly: CGFloat
        let textAlign: TextAlignment
        let frameAlign: Alignment

        switch i {
        case 0:  // top — extend upward
            lx = vx;  ly = vy - gap - labelH / 2
            textAlign = .center;  frameAlign = .center
        case 1, 2:  // right side — extend rightward
            lx = vx + gap + labelW / 2;  ly = vy
            textAlign = .leading;  frameAlign = .leading
        case 3:  // bottom — extend downward
            lx = vx;  ly = vy + gap + labelH / 2
            textAlign = .center;  frameAlign = .center
        default:  // left side (4, 5) — extend leftward
            lx = vx - gap - labelW / 2;  ly = vy
            textAlign = .trailing;  frameAlign = .trailing
        }

        let isLeading = i == leadingAxisIndex
        return VStack(spacing: 2) {
            Text(axisNames[i])
                .font(.system(size: 11, weight: isLeading ? .semibold : .regular))
                .foregroundStyle(isLeading ? axisColors[i] : axisColors[i].opacity(0.55))
            Text(axisSubtitles[i])
                .font(.system(size: 9))
                .foregroundStyle(Color.textTertiary)
        }
        .multilineTextAlignment(textAlign)
        .frame(width: labelW, alignment: frameAlign)
        .position(x: lx, y: ly)
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let r = min(cx, cy) * hexRadiusRatio
                let n = 6
                let p = progress

                func vertex(axis: Int, frac: CGFloat) -> CGPoint {
                    let angle = -Double.pi / 2 + Double(axis) * (Double.pi / 3)
                    return CGPoint(
                        x: cx + r * frac * CGFloat(cos(angle)),
                        y: cy + r * frac * CGFloat(sin(angle))
                    )
                }

                // Concentric hex grid rings — inner 3 dashed, outer solid
                for frac in [0.25, 0.5, 0.75, 1.0] as [CGFloat] {
                    var hex = Path()
                    hex.move(to: vertex(axis: 0, frac: frac))
                    for i in 1..<n { hex.addLine(to: vertex(axis: i, frac: frac)) }
                    hex.closeSubpath()

                    if frac == 1.0 {
                        context.stroke(hex, with: .color(Color.white.opacity(0.12)), lineWidth: 1)
                    } else {
                        context.stroke(hex, with: .color(Color.white.opacity(0.08)),
                                       style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 4]))
                    }
                }

                // Spoke lines from center to each axis vertex
                for i in 0..<n {
                    var spoke = Path()
                    spoke.move(to: CGPoint(x: cx, y: cy))
                    spoke.addLine(to: vertex(axis: i, frac: 1.0))
                    context.stroke(spoke, with: .color(Color.white.opacity(0.06)), lineWidth: 1)
                }

                // Data polygon — conic gradient fill
                let pts = (0..<n).map { vertex(axis: $0, frac: CGFloat(axisValues[$0]) * p) }
                var poly = Path()
                poly.move(to: pts[0])
                for pt in pts.dropFirst() { poly.addLine(to: pt) }
                poly.closeSubpath()

                var stops: [Gradient.Stop] = []
                for i in 0..<n {
                    stops.append(.init(color: axisColors[i].opacity(0.8), location: CGFloat(i) / CGFloat(n)))
                }
                stops.append(.init(color: axisColors[0].opacity(0.8), location: 1.0))

                context.fill(poly, with: .conicGradient(
                    Gradient(stops: stops),
                    center: CGPoint(x: cx, y: cy),
                    angle: Angle(degrees: -90)
                ))
            }

            // Outline stroke animates via the shape's animatableData
            HexRadarPolygon(values: axisValues, progress: progress)
                .stroke(Color.white.opacity(0.6), lineWidth: 1.0)

            // Labels anchored at the hex ring vertex and extending OUTWARD —
            // right-side labels grow right, left-side grow left, top/bottom grow vertically.
            GeometryReader { geo in
                let cx = geo.size.width / 2
                let cy = geo.size.height / 2
                let hexR = min(cx, cy) * hexRadiusRatio

                ForEach(0..<6, id: \.self) { i in
                    let angle = -Double.pi / 2 + Double(i) * (Double.pi / 3)
                    let vx = cx + hexR * CGFloat(cos(angle))
                    let vy = cy + hexR * CGFloat(sin(angle))
                    axisLabel(index: i, vx: vx, vy: vy)
                }
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                progress = 1.0
            }
        }
    }
}

#Preview {
    let sample = ExtendedStatsData(
        totalGamesPlayed: 24,
        passRate: 0.22, earlyFinisherRate: 0.71, comebackRate: 0.30,
        sweepRate: 0.15, cardHoardingIndex: 0.25, trickWinRate: 0.68,
        jokerEfficiency: 0.58, avgRevolutionsPerGame: 1.2,
        aggressionAxis: 0.78, earlyAxis: 0.71, riskAxis: 0.30,
        consistencyAxis: 0.82, calculatedAxis: 0.65, dominantAxis: 0.55,
        archetype: .mogul, archetypeEmoji: "👩🏼‍💼",
        archetypeDescription: "Cold and methodical. You control the table's tempo, make intentional moves, and force players to your rhythm."
    )
    return PlayStyleRadarChart(stats: sample)
        .padding(24)
        .background(Color.tycoonSurface)
}
