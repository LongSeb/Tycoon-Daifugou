import SwiftUI
import TycoonDaifugouKit

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @State private var activeGame: GameController?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(state: .preview, onPlayTapped: startNewGame)
                case .profile:
                    ProfileView(profile: .preview)
                }
            }

            AppTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: Binding(
            get: { activeGame != nil },
            set: { if !$0 { activeGame = nil } }
        )) {
            if let controller = activeGame {
                GameView(controller: controller, onExit: { activeGame = nil })
            }
        }
    }

    private func startNewGame() {
        activeGame = .newMatch(seed: UInt64.random(in: .min ... .max))
    }
}

#Preview {
    RootView()
}
