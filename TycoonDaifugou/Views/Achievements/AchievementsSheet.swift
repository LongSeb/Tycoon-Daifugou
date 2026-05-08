import SwiftUI

struct AchievementsSheet: View {
    @Environment(AchievementManager.self) private var manager

    enum Filter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
    }

    @State private var filter: Filter = .all

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle
                header
                filterPicker
                achievementsList
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 26))
                        .foregroundStyle(.white)
                    let p = manager.progress
                    Text("\(p.unlocked) / \(p.total) Unlocked")
                        .font(.custom("InstrumentSans-Regular", size: 13).weight(.medium))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            let p = manager.progress
            let fraction = p.total > 0 ? CGFloat(p.unlocked) / CGFloat(p.total) : 0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tycoonCard).frame(height: 4)
                    Capsule()
                        .fill(Color.cardBlush)
                        .frame(width: geo.size.width * fraction, height: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 16)
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(Filter.allCases, id: \.self) { f in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .tracking(0.3)
                        .foregroundStyle(filter == f ? Color.tycoonBlack : Color.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(filter == f ? Color.cardBlush : Color.tycoonCard)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var achievementsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if filteredAchievements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: filter == .unlocked ? "trophy" : "lock")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textTertiary.opacity(0.4))
                    Text(filter == .unlocked ? "No achievements yet" : "All unlocked!")
                        .font(.custom("InstrumentSans-Regular", size: 14).weight(.medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var filteredAchievements: [Achievement] {
        switch filter {
        case .all:      return manager.achievements
        case .unlocked: return manager.achievements.filter(\.isUnlocked)
        case .locked:   return manager.achievements.filter { !$0.isUnlocked }
        }
    }
}
