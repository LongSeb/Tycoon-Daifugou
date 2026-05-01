import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import TycoonDaifugouKit

@main
struct TycoonDaifugouApp: App {
    @State private var authService: AuthService
    @State private var syncManager: SyncManager
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
        // Offline persistence keeps writes queued when there's no network and
        // hot-loads cached reads on launch — both tabs the app expects.
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        Firestore.firestore().settings = settings
        _authService = State(wrappedValue: AuthService())
        _syncManager = State(wrappedValue: SyncManager())
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
            .environment(syncManager)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthed in
                if isAuthed {
                    Task { await syncManager.syncOnSignIn() }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
