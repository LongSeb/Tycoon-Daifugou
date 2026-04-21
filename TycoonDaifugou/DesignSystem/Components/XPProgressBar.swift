import SwiftUI

struct XPProgressBar: View {
    let currentXP: Int
    let levelStartXP: Int
    let xpForNextLevel: Int

    @State private var animatedFill: CGFloat = 0

    private var fillFraction: CGFloat {
        let range = CGFloat(xpForNextLevel - levelStartXP)
        guard range > 0 else { return 0 }
        return min(max(CGFloat(currentXP - levelStartXP) / range, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.9)) {
                    animatedFill = fillFraction
                }
            }
        }
    }
}

#Preview {
    XPProgressBar(currentXP: 1750, levelStartXP: 1500, xpForNextLevel: 2000)
        .frame(height: 5)
        .padding(32)
        .background(Color.tycoonBlack)
}
