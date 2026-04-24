import SwiftUI
import TycoonDaifugouKit

struct RootView: View {
    @State private var coordinator = NavigationCoordinator()
    @State private var selectedTab: AppTab = .home
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            tabRoot
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .preferredColorScheme(.dark)
        .alert(
            "Quit game?",
            isPresented: $coordinator.showingQuitConfirm
        ) {
            Button("Quit", role: .destructive) { coordinator.returnToHome() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Progress will be lost.")
        }
        .onAppear {
            if coordinator.store == nil {
                coordinator.store = GameRecordStore(context: modelContext)
            }
        }
    }

    private var tabRoot: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        state: coordinator.store?.homeViewState ?? .empty,
                        onPlayTapped: { coordinator.startNewGame() },
                        onSettingsTapped: { coordinator.showSettings() }
                    )
                case .profile:
                    if let profileData = coordinator.store?.profileData {
                        ProfileView(profile: profileData)
                    } else {
                        ProfileView(profile: .preview)
                    }
                }
            }

            AppTabBar(selectedTab: $selectedTab)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .game:
            if let controller = coordinator.gameController {
                GameView(
                    controller: controller,
                    onExitRequest: { coordinator.showingQuitConfirm = true },
                    onGameEnded: { coordinator.showResults(for: $0) }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
            }
        case .results:
            if let result = coordinator.lastResult {
                ResultsView(
                    result: result,
                    onPlayAgain: { coordinator.startNewGame(ruleSet: coordinator.currentRuleSet) },
                    onMainMenu: { coordinator.returnToHome() }
                )
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
            }
        case .settings:
            SettingsView(onBack: { coordinator.popSettings() })
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    RootView()
}
