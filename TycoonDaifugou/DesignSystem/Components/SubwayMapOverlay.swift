import SwiftUI

/// Animated subway map card-back overlay. Renders the static map SVG and drives a
/// rolling station-pulse animation across all six lines simultaneously using TimelineView.
struct SubwayMapOverlay: View {
    let cornerRadius: CGFloat
    let width: CGFloat
    let height: CGFloat
    var animateStations: Bool = true

    // SVG viewBox coordinate space
    private let svgW: CGFloat = 340
    private let svgH: CGFloat = 500

    var body: some View {
        // GeometryReader is outside TimelineView so layout only runs when size changes,
        // not on every animation frame.
        GeometryReader { geo in
            let sx = geo.size.width / svgW
            let sy = geo.size.height / svgH

            // Cap to 30fps — the 1.3s pulse interval is smooth at 30fps and
            // avoids driving layout at ProMotion 120Hz on first appear.
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                ZStack(alignment: .topLeading) {
                    Image("SubwayMap")
                        .resizable()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)

                    if animateStations {
                        ForEach(SubwayLineData.all.indices, id: \.self) { li in
                            let line = SubwayLineData.all[li]
                            ForEach(line.stations.indices, id: \.self) { si in
                                let station = line.stations[si]
                                let b = pulseBrightness(
                                    time: t + line.phaseOffset,
                                    stationIdx: si,
                                    count: line.stations.count
                                )
                                Circle()
                                    .fill(Color.black.opacity(b))
                                    .frame(
                                        width: station.pulseDiameter * sx,
                                        height: station.pulseDiameter * sy
                                    )
                                    .position(
                                        x: station.center.x * sx,
                                        y: station.center.y * sy
                                    )
                            }
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Animation math

    private func pulseBrightness(time: Double, stationIdx: Int, count: Int) -> Double {
        let beatInterval = 1.3   // 1300 ms between each station's activation
        let fadeIn      = 0.5
        let hold        = 0.2
        let fadeOut     = 0.5
        let pulseDur    = fadeIn + hold + fadeOut   // 1.2 s total pulse
        let period      = Double(count) * beatInterval

        let phase       = time.truncatingRemainder(dividingBy: period)
        var t           = phase - Double(stationIdx) * beatInterval
        if t < 0 { t += period }
        guard t < pulseDur else { return 0 }

        if t < fadeIn {
            return smoothstep(t / fadeIn)
        } else if t < fadeIn + hold {
            return 1.0
        } else {
            return smoothstep(1.0 - (t - fadeIn - hold) / fadeOut)
        }
    }

    private func smoothstep(_ x: Double) -> Double {
        let v = max(0, min(1, x))
        return v * v * (3 - 2 * v)
    }
}

// MARK: - Station / Line data

private struct StationPoint {
    let center: CGPoint
    /// Diameter of the pulsing overlay circle in SVG coordinate space.
    /// Sized to cover the white interior of each station marker PNG.
    let pulseDiameter: CGFloat
}

private struct SubwayLineData {
    let stations: [StationPoint]
    /// Small fixed time offset so no two lines are perfectly in phase at launch.
    let phaseOffset: Double

    static let all: [SubwayLineData] = [
        // Yellow — diagonal, top-left → bottom-right
        .init(stations: [
            .init(center: CGPoint(x: 22,  y: 21),  pulseDiameter: 14),
            .init(center: CGPoint(x: 87,  y: 65),  pulseDiameter: 14),
            .init(center: CGPoint(x: 148, y: 106), pulseDiameter: 14),
            .init(center: CGPoint(x: 205, y: 146), pulseDiameter: 14),
        ], phaseOffset: 0.00),

        // Pink — top-left, curves downward
        .init(stations: [
            .init(center: CGPoint(x: 103, y: 15),  pulseDiameter: 14),
            .init(center: CGPoint(x: 44,  y: 100), pulseDiameter: 14),
        ], phaseOffset: 0.31),

        // Dark Blue (dashed express) — top → bottom
        .init(stations: [
            .init(center: CGPoint(x: 44,  y: 100), pulseDiameter: 14),
            .init(center: CGPoint(x: 44,  y: 202), pulseDiameter: 14),
            .init(center: CGPoint(x: 44,  y: 314), pulseDiameter: 14),
        ], phaseOffset: 0.17),

        // Teal (solid) — left → right
        .init(stations: [
            .init(center: CGPoint(x: 44,  y: 314), pulseDiameter: 14),
            .init(center: CGPoint(x: 97,  y: 314), pulseDiameter: 14),
            .init(center: CGPoint(x: 209, y: 314), pulseDiameter: 14),
            .init(center: CGPoint(x: 270, y: 314), pulseDiameter: 14),
            .init(center: CGPoint(x: 293, y: 314), pulseDiameter: 14),
        ], phaseOffset: 0.53),

        // Green (hatched) — top → bottom (long line)
        .init(stations: [
            .init(center: CGPoint(x: 323,   y: 139),   pulseDiameter: 18),
            .init(center: CGPoint(x: 270,   y: 189),   pulseDiameter: 18),
            .init(center: CGPoint(x: 293,   y: 207),   pulseDiameter: 18),
            .init(center: CGPoint(x: 293,   y: 246),   pulseDiameter: 18),
            .init(center: CGPoint(x: 293,   y: 283),   pulseDiameter: 18),
            .init(center: CGPoint(x: 293,   y: 314),   pulseDiameter: 14),
            .init(center: CGPoint(x: 293.5, y: 353.5), pulseDiameter: 16),
            .init(center: CGPoint(x: 293.5, y: 391.5), pulseDiameter: 16),
            .init(center: CGPoint(x: 293.5, y: 417.5), pulseDiameter: 16),
        ], phaseOffset: 0.87),

        // Purple — bottom-left, down, curves right
        .init(stations: [
            .init(center: CGPoint(x: 44,    y: 337), pulseDiameter: 15),
            .init(center: CGPoint(x: 133,   y: 337), pulseDiameter: 15),
            .init(center: CGPoint(x: 168.5, y: 394), pulseDiameter: 19),
            .init(center: CGPoint(x: 168.5, y: 448), pulseDiameter: 19),
            .init(center: CGPoint(x: 225,   y: 448), pulseDiameter: 14),
            .init(center: CGPoint(x: 265,   y: 448), pulseDiameter: 14),
            .init(center: CGPoint(x: 224.5, y: 483), pulseDiameter: 19),
        ], phaseOffset: 0.41),
    ]
}

#Preview {
    SubwayMapOverlay(cornerRadius: 10, width: 136, height: 200)
        .padding(24)
        .background(Color.black)
}
