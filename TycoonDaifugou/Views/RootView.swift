import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(state: .preview, onPlayTapped: { print("Play tapped") })
                case .profile:
                    ProfileView(profile: .preview)
                }
            }

            AppTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
