import SwiftUI

struct YoureReadySlide: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.tycoonMint.opacity(0.07))
                .frame(width: 200, height: 200)
                .blur(radius: 32)

            VStack(spacing: 20) {
                HStack(spacing: 28) {
                    Text("👑").font(.system(size: 52))
                    Text("🤑").font(.system(size: 52))
                }
                HStack(spacing: 28) {
                    Text("😟").font(.system(size: 52))
                    Text("🥺").font(.system(size: 52))
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}
