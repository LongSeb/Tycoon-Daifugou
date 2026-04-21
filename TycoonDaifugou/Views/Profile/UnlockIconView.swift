import SwiftUI

struct UnlockIconView: View {
    let icon: UnlockIcon
    var size: CGFloat = 13

    var body: some View {
        switch icon {
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.cardBlush.opacity(0.7))
        case .lock:
            Image(systemName: "rectangle.fill.on.rectangle.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.cardLavender.opacity(0.5))
        case .chart:
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: size))
                .foregroundStyle(Color.textTertiary)
        case .badge:
            Image(systemName: "seal.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.cardCream.opacity(0.4))
        }
    }
}
