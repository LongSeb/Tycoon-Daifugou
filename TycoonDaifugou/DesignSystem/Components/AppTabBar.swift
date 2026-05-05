import SwiftUI

enum AppTab {
    case home, profile
}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    var showPrestigeBadge: Bool = false

    var body: some View {
        HStack {
            Spacer()
            tabItem(tab: .home, icon: "house", label: "Home", badge: false)
            Spacer()
            Spacer()
            tabItem(tab: .profile, icon: "person", label: "Profile", badge: showPrestigeBadge)
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

    private func tabItem(tab: AppTab, icon: String, label: String, badge: Bool) -> some View {
        let isActive = selectedTab == tab
        let iconName = isActive ? "\(icon).fill" : icon

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? Color.textPrimary : Color.textTertiary)

                    if badge {
                        Circle()
                            .fill(Color.cardBlush)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -2)
                    }
                }

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
