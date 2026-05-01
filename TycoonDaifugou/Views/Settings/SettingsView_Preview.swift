import SwiftUI

#Preview("Settings") {
    SettingsView(onBack: {})
        .environment(AuthService())
        .environment(SyncManager())
}
