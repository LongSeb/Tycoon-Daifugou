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

    /// Notified after any local profile mutation (equip changes, post-game stats,
    /// editor saves). SyncManager attaches here so it can push to Firestore.
    var profileDidChange: (() -> Void)?

    // MARK: - Prestige prompt

    /// True when the prestige modal should be shown on the main menu.
    /// Resets to false when the player dismisses the prompt or confirms prestige.
    var showPrestigePrompt = false

    // Session flag — set to true when the player dismisses "Not Yet". Stays true
    // until the app is relaunched, preventing the modal from re-appearing mid-session.
    // On next launch the flag resets (it is not persisted), so the prompt returns if
    // the player is still eligible. This avoids nagging during a single play session
    // while keeping the feature discoverable across sessions.
    private var hasSeenPrestigePromptThisSession = false

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
        profileDidChange?()
    }

    func updateEquippedTitle(_ titleID: String) {
        profile.equippedTitleID = titleID
        try? context.save()
        profileDidChange?()
    }

    func updateEquippedSkin(_ skinID: String) {
        profile.equippedSkinID = skinID
        try? context.save()
        profileDidChange?()
    }

    func updateEquippedBorder(_ borderID: String?) {
        profile.equippedBorderID = borderID
        try? context.save()
        profileDidChange?()
    }

    func resetForSignOut() {
        profile.username = "TycoonPlayer"
        try? context.save()
    }

    func wipeAllLocalData() {
        for record in records {
            context.delete(record)
        }
        context.delete(profile)
        try? context.save()
        profile = Self.fetchOrCreateProfile(context: context)
        records = Self.fetchAllRecords(context: context)
    }

    // MARK: - Sync ingestion

    var localRecordIDs: Set<UUID> { Set(records.map(\.id)) }

    /// Replace the in-memory profile's persisted state with cloud values. Computed
    /// derivations (axes, archetype, win rate) re-derive automatically.
    func applyCloudProfile(_ snapshot: CloudPlayerSnapshot) {
        profile.username = snapshot.username
        profile.emoji = snapshot.emoji
        profile.totalXP = snapshot.totalXP
        profile.currentLevel = snapshot.currentLevel
        profile.memberSince = snapshot.memberSince
        profile.equippedTitleID = snapshot.equippedTitleID
        profile.equippedSkinID = snapshot.equippedSkinID
        profile.equippedBorderID = snapshot.equippedBorderID
        profile.hasPrestigeBadge = snapshot.hasPrestigeBadge
        profile.hardModeWins = snapshot.hardModeWins
        profile.prestigeLevel = snapshot.prestigeLevel
        profile.prestigeXP = snapshot.prestigeXP
        profile.jokersPlayed = snapshot.jokersPlayed
        profile.jokersWonTrick = snapshot.jokersWonTrick
        profile.roundFinishPositions = snapshot.roundFinishPositions
        profile.comebackCount = snapshot.comebackCount
        profile.comebackOpportunities = snapshot.comebackOpportunities
        profile.sweepsAchieved = snapshot.sweepsAchieved
        profile.multiRoundGamesPlayed = snapshot.multiRoundGamesPlayed
        profile.tricksLed = snapshot.tricksLed
        profile.tricksWon = snapshot.tricksWon
        profile.totalPasses = snapshot.totalPasses
        profile.totalTurns = snapshot.totalTurns
        profile.revolutionsTriggered = snapshot.revolutionsTriggered
        profile.eightStopsTotal = snapshot.eightStopsTotal
        profile.threeSpadesTotal = snapshot.threeSpadesTotal
        profile.gamesPlayedCount = snapshot.gamesPlayedCount
        profile.gamesWonCount = snapshot.gamesWonCount
        profile.totalDuration = snapshot.totalDuration
        profile.totalRoundsPlayed = snapshot.totalRoundsPlayed
        // Fall back to the cloud's currentLevel when the field is absent (old documents).
        profile.highestLevelEver = snapshot.highestLevelEver ?? snapshot.currentLevel
        try? context.save()
    }

    /// Insert a cloud-only game into SwiftData. Caller is responsible for skipping
    /// records whose UUID already exists locally (use `localRecordIDs` to filter).
    func importCloudGame(_ snapshot: CloudGameSnapshot) {
        let opponents = snapshot.opponents.map {
            OpponentRecord(name: $0.name, emoji: $0.emoji, finishRank: $0.finishRank, xpEarned: $0.xpEarned)
        }
        let record = GameRecord(
            id: snapshot.id,
            date: snapshot.date,
            finishRank: snapshot.finishRank,
            xpEarned: snapshot.xpEarned,
            roundsPlayed: snapshot.roundsPlayed,
            roundsWon: snapshot.roundsWon,
            cardsPlayed: snapshot.cardsPlayed,
            duration: snapshot.duration,
            highlight: snapshot.highlight,
            ruleSetUsed: snapshot.ruleSetUsed,
            revolutionCount: snapshot.revolutionCount,
            eightStopCount: snapshot.eightStopCount,
            jokerPlayCount: snapshot.jokerPlayCount,
            threeSpadeCount: snapshot.threeSpadeCount,
            opponents: opponents,
            roundPointsTotal: snapshot.roundPointsTotal,
            opponentBestPoints: snapshot.opponentBestPoints,
            difficulty: snapshot.difficulty
        )
        context.insert(record)
        try? context.save()
        records = Self.fetchAllRecords(context: context)
    }

    // MARK: - Save

    private(set) var pendingLevelUpUnlocks: [UnlockDefinition]? = nil

    func clearLevelUpUnlocks() {
        pendingLevelUpUnlocks = nil
    }

    // MARK: - Prestige

    /// Resets the player to Level 1 / 0 XP and increments their prestige level.
    /// All unlocks and stats are preserved — only level/XP/prestigeXP are touched.
    func confirmPrestige() {
        guard profile.prestigeLevel < LevelCalculator.maxPrestigeLevel else { return }
        profile.totalXP = 0
        profile.currentLevel = 1
        profile.prestigeLevel += 1
        profile.prestigeXP = 0
        hasSeenPrestigePromptThisSession = false
        showPrestigePrompt = false
        onPrestigeLevelReached(profile.prestigeLevel)
        try? context.save()
        profileDidChange?()
    }

    /// True when the player is eligible to prestige (XP capped, below max prestige).
    /// Drives the tab badge and level card affordance after the prompt is dismissed.
    var isPrestigeAvailable: Bool {
        profile.totalXP >= LevelCalculator.prestigeThresholdXP
            && profile.prestigeLevel < LevelCalculator.maxPrestigeLevel
    }

    /// Suppresses the prestige prompt for the rest of this session.
    func dismissPrestigePrompt() {
        hasSeenPrestigePromptThisSession = true
        showPrestigePrompt = false
    }

    /// Re-shows the prestige modal (called from the Profile level card affordance).
    func reactivatePrestigePrompt() {
        guard isPrestigeAvailable else { return }
        hasSeenPrestigePromptThisSession = false
        showPrestigePrompt = true
    }

    @discardableResult
    func save(controller: GameController, result: GameResultData, ruleSet: RuleSet) -> GameRecord {
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
            opponentBestPoints: controller.opponentBestPoints,
            difficulty: controller.difficulty.rawValue
        )

        context.insert(record)

        let levelBefore = profile.currentLevel
        profile.totalXP += result.xpGained
        // Freeze XP at the prestige threshold until the player prestiges.
        // XP earned in the game still appears on the results screen (it's
        // recorded in the GameRecord before this cap applies).
        if profile.prestigeLevel < LevelCalculator.maxPrestigeLevel {
            profile.totalXP = min(profile.totalXP, LevelCalculator.prestigeThresholdXP)
        }
        profile.currentLevel = LevelCalculator.level(forTotalXP: profile.totalXP)
        profile.highestLevelEver = max(profile.highestLevelEver, profile.currentLevel)

        // Hard mode wins
        if controller.difficulty == .hard && result.playerFinishRank == "Tycoon" {
            profile.hardModeWins += 1
        }

        // Prestige badge
        if profile.currentLevel >= 50 {
            profile.hasPrestigeBadge = true
        }

        // Prestige XP: XP earned while playing Levels 1–10 post-prestige feeds
        // directly into Prestige XP at 1:1. We use levelBefore (the level at game
        // start) as the determinant — if they were in the 1–10 window when the
        // game began, those gains count toward prestige progression.
        if profile.prestigeLevel > 0 && (1...10).contains(levelBefore) {
            profile.prestigeXP += result.xpGained
            while profile.prestigeXP >= LevelCalculator.prestigeXPPerLevel {
                if profile.prestigeLevel < LevelCalculator.maxPrestigeLevel {
                    profile.prestigeXP -= LevelCalculator.prestigeXPPerLevel
                    profile.prestigeLevel += 1
                    onPrestigeLevelReached(profile.prestigeLevel)
                } else {
                    profile.prestigeXP = LevelCalculator.prestigeXPPerLevel
                    break
                }
            }
        }

        // Prestige prompt: fires the first time the player hits the XP cap this
        // session. Suppressed for the remainder of the session once dismissed;
        // the profile tab badge + level card affordance let them re-trigger it.
        if profile.totalXP >= LevelCalculator.prestigeThresholdXP
            && profile.prestigeLevel < LevelCalculator.maxPrestigeLevel
            && !hasSeenPrestigePromptThisSession {
            showPrestigePrompt = true
        }

        // Level-up unlock notification
        if profile.currentLevel > levelBefore {
            let unlocks = UnlockRegistry.unlocks(forLevel: profile.currentLevel)
            pendingLevelUpUnlocks = unlocks.isEmpty ? nil : unlocks
        } else {
            pendingLevelUpUnlocks = nil
        }

        // Stamp daily bonus date so the 25h window resets from this game.
        if result.earnedDailyBonus {
            profile.lastDailyBonusDate = Date()
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
        return record
    }

    // MARK: - HomeViewState

    var homeViewState: HomeViewState {
        let wins = profile.gamesWonCount
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
        let wins = profile.gamesWonCount
        let totalGames = profile.gamesPlayedCount
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
            let fraction: CGFloat = records.count > 0 ? CGFloat(count) / CGFloat(records.count) : 0
            return RankStat(rank: rank, count: count, fraction: fraction, color: rankColors[rank] ?? .white.opacity(0.2))
        }

        let specialPlays: [SpecialPlayStat] = [
            SpecialPlayStat(name: "Revolutions", subtitle: "Four-of-a-kind plays", count: totalRevolutions, badge: .star),
            SpecialPlayStat(name: "8-stops", subtitle: "Round-ending eights", count: records.reduce(0) { $0 + $1.eightStopCount }, badge: .eight),
            SpecialPlayStat(name: "Jokers played", subtitle: "Wild card uses", count: records.reduce(0) { $0 + $1.jokerPlayCount }, badge: .joker),
            SpecialPlayStat(name: "3-Spade reversals", subtitle: "Joker beats", count: records.reduce(0) { $0 + $1.threeSpadeCount }, badge: .threeSpade),
        ]

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
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
            prestigeLevel: profile.prestigeLevel,
            prestigeXP: profile.prestigeXP,
            canPrestige: isPrestigeAvailable,
            isAtMaxLevel: currentLevel >= LevelCalculator.maxLevel,
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
            points: record.roundPointsTotal,
            duration: formatDuration(record.duration),
            ago: timeAgo(record.date),
            highlight: highlightFromRecord(record)
        )
    }

    private func highlightFromRecord(_ record: GameRecord) -> String {
        if record.threeSpadeCount > 0 {
            return record.threeSpadeCount == 1 ? "3♠ Reversal" : "\(record.threeSpadeCount)× 3♠ Reversal"
        }
        if record.revolutionCount > 0 {
            return record.revolutionCount == 1 ? "Revolution!" : "\(record.revolutionCount)× Revolution"
        }
        if record.eightStopCount > 0 {
            return record.eightStopCount == 1 ? "8-Stop" : "\(record.eightStopCount)× 8-Stop"
        }
        if record.jokerPlayCount > 0 {
            return record.jokerPlayCount == 1 ? "Joker played" : "\(record.jokerPlayCount)× Joker"
        }
        return record.highlight
    }

    private func makeRecentGameData(_ record: GameRecord) -> RecentGameRowData {
        RecentGameRowData(
            rank: record.finishRank,
            xp: "+\(record.xpEarned)",
            points: record.roundPointsTotal,
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
