import Foundation
import SwiftData
import SwiftUI
import TycoonDaifugouKit

@Observable
@MainActor
final class GameRecordStore {
    private let context: ModelContext
    private(set) var records: [GameRecord] = []
    private(set) var profile: PlayerProfile

    init(context: ModelContext) {
        self.context = context
        self.profile = Self.fetchOrCreateProfile(context: context)
        self.records = Self.fetchAllRecords(context: context)
    }

    // MARK: - Profile

    func updateProfile(emoji: String, username: String) {
        profile.emoji = emoji
        profile.username = username
        try? context.save()
    }

    func updateEquippedTitle(_ titleID: String) {
        profile.equippedTitleID = titleID
        try? context.save()
    }

    func updateEquippedSkin(_ skinID: String) {
        profile.equippedSkinID = skinID
        try? context.save()
    }

    func updateEquippedBorder(_ borderID: String?) {
        profile.equippedBorderID = borderID
        try? context.save()
    }

    // MARK: - Save

    private(set) var pendingLevelUpUnlocks: [UnlockDefinition]? = nil

    func clearLevelUpUnlocks() {
        pendingLevelUpUnlocks = nil
    }

    func save(controller: GameController, result: GameResultData, ruleSet: RuleSet) {
        let opponentRecords = result.players
            .filter { !$0.isPlayer }
            .map { OpponentRecord(name: $0.name, emoji: $0.emoji, finishRank: $0.rank, xpEarned: $0.xpGained) }

        let ruleSetData = (try? JSONEncoder().encode(ruleSet)) ?? Data()

        let highlight = controller.gameHighlight.isEmpty ? result.highlight : controller.gameHighlight

        let record = GameRecord(
            finishRank: result.playerFinishRank,
            xpEarned: result.xpGained,
            roundsPlayed: result.roundsPlayed,
            roundsWon: controller.roundsWon,
            cardsPlayed: controller.cardsPlayed,
            duration: controller.gameDuration,
            highlight: highlight,
            ruleSetUsed: ruleSetData,
            revolutionCount: controller.revolutionCount,
            eightStopCount: controller.eightStopCount,
            jokerPlayCount: controller.jokerPlayCount,
            threeSpadeCount: controller.threeSpadeCount,
            opponents: opponentRecords,
            roundPointsTotal: controller.humanRoundPointsTotal,
            opponentBestPoints: controller.opponentBestPoints
        )

        context.insert(record)

        let levelBefore = profile.currentLevel
        profile.totalXP += result.xpGained
        profile.currentLevel = LevelCalculator.level(forTotalXP: profile.totalXP)

        // Hard mode wins
        if controller.difficulty == .hard && result.playerFinishRank == "Tycoon" {
            profile.hardModeWins += 1
        }

        // Prestige badge
        if profile.currentLevel >= 50 {
            profile.hasPrestigeBadge = true
        }

        // Level-up unlock notification
        if profile.currentLevel > levelBefore {
            let unlocks = UnlockRegistry.unlocks(forLevel: profile.currentLevel)
            pendingLevelUpUnlocks = unlocks.isEmpty ? nil : unlocks
        } else {
            pendingLevelUpUnlocks = nil
        }

        // Extended stats accumulation
        profile.jokersPlayed += controller.jokerPlayCount
        profile.jokersWonTrick += controller.jokersWonTrickCount
        profile.roundFinishPositions += controller.roundFinishPositions
        profile.comebackCount += controller.comebackCountThisGame
        profile.comebackOpportunities += controller.comebackOpportunitiesThisGame
        profile.tricksLed += controller.tricksLedCount
        profile.tricksWon += controller.tricksWonCount
        profile.totalPasses += controller.totalPassesCount
        profile.totalTurns += controller.totalTurnsCount
        profile.revolutionsTriggered += controller.revolutionCount
        profile.eightStopsTotal += controller.eightStopCount
        profile.threeSpadesTotal += controller.threeSpadeCount
        profile.gamesPlayedCount += 1
        profile.totalDuration += controller.gameDuration
        profile.totalRoundsPlayed += result.roundsPlayed
        if isWin(record) { profile.gamesWonCount += 1 }
        if controller.maxRounds > 1 {
            profile.multiRoundGamesPlayed += 1
            if controller.roundsWon == controller.maxRounds {
                profile.sweepsAchieved += 1
            }
        }

        try? context.save()
        records = Self.fetchAllRecords(context: context)
    }

    // MARK: - HomeViewState

    var homeViewState: HomeViewState {
        let wins = records.filter { isWin($0) }.count
        let last = records.first.map { makeLastGameData($0) }
        let recent = Array(records.prefix(5).dropFirst()).map { makeRecentGameData($0) }
        return HomeViewState(
            totalGamesWon: wins,
            lastGame: last,
            recentGames: recent,
            isExpertUnlocked: profile.isExpertDifficultyUnlocked
        )
    }

    // MARK: - ProfileData

    var profileData: ProfileData {
        let wins = records.filter { isWin($0) }.count
        let totalGames = records.count
        let winRate = totalGames > 0 ? Int(Double(wins) / Double(totalGames) * 100) : 0

        let totalRevolutions = records.reduce(0) { $0 + $1.revolutionCount }

        let avgFinishPlaceStr: String = {
            guard !profile.roundFinishPositions.isEmpty else { return "—" }
            let avg = Double(profile.roundFinishPositions.reduce(0, +)) / Double(profile.roundFinishPositions.count)
            return String(format: "%.1f", avg)
        }()
        let currentLevel = profile.currentLevel
        let levelStart = LevelCalculator.cumulativeXP(forLevel: currentLevel)
        let xpForNext = currentLevel < LevelCalculator.maxLevel
            ? LevelCalculator.cumulativeXP(forLevel: currentLevel + 1)
            : profile.totalXP

        let rankColors: [String: Color] = [
            "Tycoon": .cardBlush,
            "Rich": .cardLavender,
            "Poor": .white.opacity(0.25),
            "Beggar": .white.opacity(0.15),
        ]
        let rankStats = ["Tycoon", "Rich", "Poor", "Beggar"].map { rank in
            let count = records.filter { $0.finishRank == rank }.count
            let fraction: CGFloat = totalGames > 0 ? CGFloat(count) / CGFloat(totalGames) : 0
            return RankStat(rank: rank, count: count, fraction: fraction, color: rankColors[rank] ?? .white.opacity(0.2))
        }

        let specialPlays: [SpecialPlayStat] = [
            SpecialPlayStat(name: "Revolutions", subtitle: "Four-of-a-kind plays", count: totalRevolutions, badge: .star),
            SpecialPlayStat(name: "8-stops", subtitle: "Round-ending eights", count: records.reduce(0) { $0 + $1.eightStopCount }, badge: .eight),
            SpecialPlayStat(name: "Jokers played", subtitle: "Wild card uses", count: records.reduce(0) { $0 + $1.jokerPlayCount }, badge: .joker),
            SpecialPlayStat(name: "3-Spade reversals", subtitle: "Joker beats", count: records.reduce(0) { $0 + $1.threeSpadeCount }, badge: .threeSpade),
        ]

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let memberSince = formatter.string(from: profile.memberSince)

        let futureUnlocks = UnlockRegistry.all
            .filter { $0.level > currentLevel }
            .prefix(4)

        let nextUnlock: UnlockItem
        if let first = futureUnlocks.first {
            nextUnlock = UnlockItem(
                name: first.displayName,
                description: "Unlocks at Level \(first.level)",
                level: first.level,
                icon: iconForUnlock(first)
            )
        } else {
            nextUnlock = UnlockItem(
                name: "Max level reached",
                description: "All unlocks earned",
                level: currentLevel,
                icon: .badge
            )
        }

        let upcomingUnlocks = Array(futureUnlocks.dropFirst()).map { def in
            UnlockItem(
                name: def.displayName,
                description: "Unlocks at Level \(def.level)",
                level: def.level,
                icon: iconForUnlock(def)
            )
        }

        let extendedStats: ExtendedStatsData? = profile.isExtendedStatsUnlocked
            ? ExtendedStatsData(
                totalGamesPlayed: profile.gamesPlayedCount,
                passRate: profile.passRate,
                earlyFinisherRate: profile.earlyFinisherRate,
                comebackRate: profile.comebackRate,
                sweepRate: profile.sweepRate,
                cardHoardingIndex: profile.cardHoardingIndex,
                trickWinRate: profile.trickWinRate,
                jokerEfficiency: profile.jokerEfficiency,
                avgRevolutionsPerGame: profile.avgRevolutionsPerGame,
                aggressionAxis: profile.aggressionAxis,
                earlyAxis: profile.earlyAxis,
                riskAxis: profile.riskAxis,
                consistencyAxis: profile.consistencyAxis,
                calculatedAxis: profile.calculatedAxis,
                dominantAxis: profile.dominantAxis,
                archetype: profile.archetype,
                archetypeEmoji: profile.archetypeEmoji,
                archetypeDescription: profile.archetypeDescription
            )
            : nil

        return ProfileData(
            emoji: profile.emoji,
            username: profile.username,
            memberSince: memberSince,
            wins: wins,
            gamesPlayed: totalGames,
            winRate: winRate,
            currentLevel: currentLevel,
            currentXP: profile.totalXP,
            xpForNextLevel: xpForNext,
            levelStartXP: levelStart,
            winStreak: currentWinStreak,
            avgFinishPlace: avgFinishPlaceStr,
            totalTimePlayed: totalTimePlayedString,
            nextUnlock: nextUnlock,
            upcomingUnlocks: upcomingUnlocks,
            rankStats: rankStats,
            specialPlays: specialPlays,
            equippedTitle: profile.equippedTitleID,
            equippedSkinID: profile.equippedSkinID,
            equippedBorder: profile.equippedBorder,
            unlockedBorders: profile.unlockedBorders,
            hasPrestigeBadge: profile.hasPrestigeBadge,
            isExtendedStatsUnlocked: profile.isExtendedStatsUnlocked,
            extendedStats: extendedStats,
            unlockedTitles: profile.unlockedTitles,
            lockedTitles: {
                let unlockedSet = Set(profile.unlockedTitles)
                return UnlockRegistry.all.compactMap {
                    if case .title(let t) = $0.type, !unlockedSet.contains(t) { return t }
                    return nil
                }
            }(),
            unlockedSkins: profile.unlockedSkins,
            lockedSkins: {
                let unlockedIDs = Set(profile.unlockedSkins.map(\.id))
                return UnlockRegistry.all.compactMap {
                    if case .cardSkin(let skin) = $0.type, !unlockedIDs.contains(skin.id) { return skin }
                    return nil
                }
            }()
        )
    }

    // MARK: - Private Helpers

    private func isWin(_ record: GameRecord) -> Bool {
        // For records that have points data: human must have strictly more points than
        // the best opponent to count as a win.
        if record.roundPointsTotal > 0 {
            return record.roundPointsTotal > record.opponentBestPoints
        }
        // Legacy records (no points data): fall back to title — only Millionaire counts.
        return record.finishRank == "Tycoon"
    }

    private var currentWinStreak: Int {
        var streak = 0
        for record in records {
            if isWin(record) { streak += 1 } else { break }
        }
        return streak
    }

    private var totalTimePlayedString: String {
        let total = Int(profile.totalDuration)
        guard total > 0 else { return "—" }
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private var averageGameTime: String {
        guard !records.isEmpty else { return "—" }
        let avgPerRound = records.reduce(0.0) { acc, r in
            acc + r.duration / Double(max(1, r.roundsPlayed))
        } / Double(records.count)
        return formatDuration(avgPerRound)
    }

    private func makeLastGameData(_ record: GameRecord) -> LastGameData {
        LastGameData(
            rank: record.finishRank,
            emoji: rankEmoji(for: record.finishRank),
            xp: "+\(record.xpEarned)",
            rounds: record.roundsPlayed,
            roundsWon: record.roundsWon,
            cardsPlayed: record.cardsPlayed,
            duration: formatDuration(record.duration),
            ago: timeAgo(record.date),
            highlight: record.highlight
        )
    }

    private func makeRecentGameData(_ record: GameRecord) -> RecentGameRowData {
        RecentGameRowData(
            rank: record.finishRank,
            xp: "+\(record.xpEarned)",
            ago: timeAgo(record.date),
            medal: rankMedal(for: record.finishRank),
            avatarEmoji: profile.emoji
        )
    }

    private func rankEmoji(for rank: String) -> String {
        switch rank {
        case "Tycoon": return "👑"
        case "Rich":        return "💎"
        case "Commoner":    return "😐"
        case "Poor":        return "😔"
        case "Beggar":      return "😢"
        default:            return "😎"
        }
    }

    private func rankMedal(for rank: String) -> String? {
        switch rank {
        case "Tycoon": return "🥇"
        case "Rich":        return "🥈"
        default:            return nil
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        if diff < 172800 { return "Yesterday" }
        return "\(Int(diff / 86400))d ago"
    }

    private func iconForUnlock(_ def: UnlockDefinition) -> UnlockIcon {
        switch def.type {
        case .title:         return .star
        case .cardSkin:      return .lock
        case .profileBorder: return .star
        case .featureGate:   return .chart
        case .prestigeBadge: return .badge
        }
    }

    private static func fetchOrCreateProfile(context: ModelContext) -> PlayerProfile {
        let descriptor = FetchDescriptor<PlayerProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let profile: PlayerProfile
        if let first = existing.first {
            profile = first
        } else {
            profile = PlayerProfile()
            context.insert(profile)
            try? context.save()
        }
        return profile
    }

    private static func fetchAllRecords(context: ModelContext) -> [GameRecord] {
        let descriptor = FetchDescriptor<GameRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
