import SwiftUI

struct XPProgressBar: View {
    let xpBefore: Int?
    let currentXP: Int
    let levelStartXP: Int
    let xpForNextLevel: Int

    init(currentXP: Int, levelStartXP: Int, xpForNextLevel: Int) {
        self.xpBefore = nil
        self.currentXP = currentXP
        self.levelStartXP = levelStartXP
        self.xpForNextLevel = xpForNextLevel
    }

    init(xpBefore: Int, xpAfter: Int, levelStartXP: Int, xpForNextLevel: Int) {
        self.xpBefore = xpBefore
        self.currentXP = xpAfter
        self.levelStartXP = levelStartXP
        self.xpForNextLevel = xpForNextLevel
    }

    @State private var animatedFill: CGFloat = 0

    private var fillFraction: CGFloat {
        fraction(for: currentXP)
    }

    private var beforeFraction: CGFloat {
        guard let xpBefore else { return 0 }
        return fraction(for: xpBefore)
    }

    private func fraction(for xp: Int) -> CGFloat {
        let range = CGFloat(xpForNextLevel - levelStartXP)
        guard range > 0 else { return 0 }
        return min(max(CGFloat(xp - levelStartXP) / range, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                if xpBefore != nil {
                    Capsule()
                        .fill(Color.cardBlush.opacity(0.35))
                        .frame(width: geo.size.width * beforeFraction)
                }

                Capsule()
                    .fill(Color.cardBlush)
                    .frame(width: geo.size.width * animatedFill)

                Circle()
                    .fill(Color.cardBlush)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().strokeBorder(Color.tycoonBlack, lineWidth: 2))
                    .offset(x: max(0, geo.size.width * animatedFill - 5.5))
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            if xpBefore != nil {
                animatedFill = beforeFraction
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedFill = fillFraction
                }
            }
        }
    }
}

#Preview("Static (Profile)") {
    XPProgressBar(currentXP: 1750, levelStartXP: 1500, xpForNextLevel: 2000)
        .frame(height: 5)
        .padding(32)
        .background(Color.tycoonBlack)
}

#Preview("Animated (Results)") {
    XPProgressBar(xpBefore: 1450, xpAfter: 1750, levelStartXP: 1500, xpForNextLevel: 2000)
        .frame(height: 6)
        .padding(32)
        .background(Color.tycoonBlack)
}
