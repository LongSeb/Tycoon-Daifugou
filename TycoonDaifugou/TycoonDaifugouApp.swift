import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import TycoonDaifugouKit

@main
struct TycoonDaifugouApp: App {
    @State private var authService: AuthService
    @AppStorage("auth.guestModeEnabled") private var guestModeEnabled: Bool = false
    @AppStorage(TutorialState.storageKey) private var hasCompletedTutorial: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameRecord.self,
            OpponentRecord.self,
            PlayerProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
        _authService = State(wrappedValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedTutorial {
                    TutorialView()
                } else if authService.isAuthenticated || guestModeEnabled {
                    RootView()
                } else {
                    SignInView(onContinueAsGuest: { guestModeEnabled = true })
                }
            }
            .environment(authService)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
