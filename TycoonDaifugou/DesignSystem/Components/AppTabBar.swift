import SwiftUI

enum AppTab {
    case home, profile
}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            Spacer()
            tabItem(tab: .home, icon: "house", label: "Home")
            Spacer()
            Spacer()
            tabItem(tab: .profile, icon: "person", label: "Profile")
            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [.tycoonBlack, .tycoonBlack, .tycoonBlack.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        )
    }

    private func tabItem(tab: AppTab, icon: String, label: String) -> some View {
        let isActive = selectedTab == tab
        let iconName = isActive ? "\(icon).fill" : icon

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.textPrimary : Color.textTertiary)

                Text(label)
                    .font(isActive ? .tycoonCaption.weight(.semibold) : .tycoonCaption)
                    .foregroundStyle(isActive ? Color.textPrimary : Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewHost: View {
        @State private var tab: AppTab = .home
        var body: some View {
            VStack {
                Spacer()
                AppTabBar(selectedTab: $tab)
            }
            .background(Color.tycoonBlack)
        }
    }
    return PreviewHost()
}
