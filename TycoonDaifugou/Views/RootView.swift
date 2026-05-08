import SwiftUI
import TycoonDaifugouKit

struct RootView: View {
    @State private var coordinator = NavigationCoordinator()
    @State private var selectedTab: AppTab = .home
    @State private var achievementManager = AchievementManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncManager.self) private var syncManager
    @Environment(AuthService.self) private var authService

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
        .environment(achievementManager)
        .onAppear {
            if coordinator.store == nil {
                let store = GameRecordStore(context: modelContext)
                let manager = syncManager
                store.profileDidChange = { manager.pushProfile() }
                manager.attach(store: store)
                coordinator.store = store
                coordinator.syncManager = manager
                coordinator.achievementManager = achievementManager
                if authService.isAuthenticated {
                    Task { await manager.syncOnSignIn() }
                }
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
                        onPlayTapped: {
                            coordinator.startNewGame(
                                ruleSet: .allRules,
                                opponentCount: 3,
                                roundsPerGame: 3
                            )
                        },
                        onCustomPlayTapped: { coordinator.startNewGame() },
                        onSettingsTapped: { coordinator.showSettings() }
                    )
                case .profile:
                    if let store = coordinator.store {
                        ProfileView(
                            profile: store.profileData,
                            store: store,
                            onSettingsTapped: { coordinator.showSettings() },
                            onPrestigeActivate: { store.reactivatePrestigePrompt() }
                        )
                    } else {
                        ProfileView(
                            profile: .preview,
                            onSettingsTapped: { coordinator.showSettings() }
                        )
                    }
                }
            }

            AppTabBar(
                selectedTab: $selectedTab,
                showPrestigeBadge: coordinator.store?.isPrestigeAvailable ?? false
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(
            isPresented: Binding(
                get: { syncManager.needsUsernameSetup },
                set: { if !$0 { syncManager.needsUsernameSetup = false } }
            )
        ) {
            NavigationStack {
                ProfileEditorView(
                    initialEmoji: coordinator.store?.profile.emoji ?? "😎",
                    initialUsername: coordinator.store?.profile.username ?? "TycoonPlayer",
                    currentLevel: coordinator.store?.profile.currentLevel ?? 1,
                    unlockedBorders: coordinator.store?.profile.unlockedBorders ?? [],
                    currentBorderID: coordinator.store?.profile.equippedBorder?.id,
                    onBorderSelect: { coordinator.store?.updateEquippedBorder($0) },
                    checkAvailability: { username in
                        await syncManager.isUsernameAvailable(username)
                    },
                    onSave: { emoji, username in
                        guard let store = coordinator.store else { return true }
                        return await syncManager.claimAndUpdateProfile(emoji: emoji, newUsername: username, store: store)
                    }
                )
                .navigationTitle("Set Your Username")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { (coordinator.store?.showPrestigePrompt ?? false) && coordinator.path.isEmpty },
                set: { if !$0 { coordinator.store?.dismissPrestigePrompt() } }
            )
        ) {
            if let store = coordinator.store {
                PrestigeModal(
                    currentPrestigeLevel: store.profile.prestigeLevel,
                    onPrestige: {
                        store.confirmPrestige()
                        selectedTab = .home
                    },
                    onDismiss: {
                        store.dismissPrestigePrompt()
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .game:
            if let controller = coordinator.gameController {
                GameView(
                    controller: controller,
                    onExitRequest: { coordinator.showingQuitConfirm = true },
                    onGameEnded: { coordinator.showResults(for: $0) },
                    humanEquippedTitle: coordinator.store?.profile.equippedTitleID,
                    humanEquippedBorder: coordinator.store?.profile.equippedBorder,
                    humanEquippedSkin: coordinator.store?.profile.equippedSkin
                )
                .id(ObjectIdentifier(controller))
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
            SettingsView(
                onBack: { coordinator.popSettings() },
                store: coordinator.store
            )
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    RootView()
        .environment(AuthService())
        .environment(SyncManager())
}
