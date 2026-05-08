import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            iconBadge
            info
            Spacer()
            statusIcon
        }
        .padding(16)
        .background(achievement.isUnlocked ? iconColor.opacity(0.06) : Color.tycoonCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    achievement.isUnlocked ? iconColor.opacity(0.2) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(achievement.isUnlocked ? iconColor.opacity(0.15) : Color.tycoonSurface)
                .frame(width: 48, height: 48)
            Image(systemName: achievement.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(achievement.isUnlocked ? iconColor : Color.textTertiary.opacity(0.4))
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(achievement.title)
                .font(.custom("Fraunces-9ptBlackItalic", size: 16))
                .foregroundStyle(achievement.isUnlocked ? .white : Color.textTertiary)
            Text(achievement.description)
                .font(.custom("InstrumentSans-Regular", size: 12))
                .foregroundStyle(achievement.isUnlocked ? Color.textSecondary : Color.textTertiary.opacity(0.5))
                .lineLimit(2)
            if achievement.isUnlocked, let date = achievement.dateUnlocked {
                Text("Unlocked \(Self.dateFormatter.string(from: date))")
                    .font(.custom("InstrumentSans-Regular", size: 10).weight(.medium))
                    .foregroundStyle(iconColor.opacity(0.7))
                    .padding(.top, 1)
            }
        }
    }

    private var statusIcon: some View {
        Group {
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textTertiary.opacity(0.35))
            }
        }
    }

    private var iconColor: Color {
        achievement.category == .milestone ? Color.cardGold : Color.cardBlush
    }
}
