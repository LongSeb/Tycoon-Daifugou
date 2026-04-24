import SwiftUI
import SwiftData
import TycoonDaifugouKit

@main
struct TycoonDaifugouApp: App {
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

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
