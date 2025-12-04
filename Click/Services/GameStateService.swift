import Foundation
import Combine
import FirebaseAnalytics

final class GameStateService: ObservableObject {
    static let shared = GameStateService()

    @Published var userData: UserData?
    @Published var seasonData: SeasonUserData?
    @Published var boostState: BoostState = BoostState()
    @Published var rankSystem: RankSystem = RankSystem()
    @Published var isLoading = true
    @Published var showOfflineEarnings = false
    @Published var pendingOfflineEarnings: OfflineEarningsResult?
    @Published var showRankUp = false
    @Published var newRank: Rank?
    @Published var showSeasonEnd = false

    private var saveTimer: Timer?
    private var syncTimer: Timer?
    private var boostTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let minimumPrestigeRankIndex = 5

    private init() {
        startBoostTimer()
    }

    func initialize() async {
        do {
            try await AuthService.shared.ensureAuthenticated()
            guard let uid = AuthService.shared.uid else { return }

            await loadUserData(uid: uid)
            await loadSeasonData(uid: uid)
            await SeasonService.shared.loadCurrentSeason()

            await MainActor.run {
                self.rankSystem = RankSystem(coefficients: SeasonService.shared.coefficients)
                self.isLoading = false
                self.startSaveTimer()
                self.startSyncTimer()
                self.checkOfflineEarnings()
                self.logSessionStart()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func loadUserData(uid: String) async {
        do {
            if let data = try await FirestoreService.shared.fetchUserData(uid: uid) {
                await MainActor.run {
                    self.userData = data
                }
            } else {
                let newUser = UserData()
                try await FirestoreService.shared.createUserData(uid: uid, data: newUser)
                await MainActor.run {
                    self.userData = newUser
                }
            }
        } catch {
            await MainActor.run {
                self.userData = UserData()
            }
        }
    }

    private func loadSeasonData(uid: String) async {
        let seasonId = SeasonService.shared.seasonId
        do {
            if let data = try await FirestoreService.shared.fetchSeasonData(uid: uid, seasonId: seasonId) {
                await MainActor.run {
                    self.seasonData = data
                    self.loadBoostState(from: data)
                }
            } else {
                let newSeason = SeasonUserData()
                try await FirestoreService.shared.createSeasonData(uid: uid, seasonId: seasonId, data: newSeason)
                await MainActor.run {
                    self.seasonData = newSeason
                }
            }
        } catch {
            await MainActor.run {
                self.seasonData = SeasonUserData()
            }
        }
    }

    private func loadBoostState(from data: SeasonUserData) {
        var cooldowns: [BoostType: Date] = [:]
        if let adRushLast = data.adRushLastUsed {
            let cooldownEnd = adRushLast.addingTimeInterval(BoostType.adRush.cooldownSeconds)
            if cooldownEnd > Date() {
                cooldowns[.adRush] = cooldownEnd
            }
        }
        if let overclockLast = data.overclockLastUsed {
            let cooldownEnd = overclockLast.addingTimeInterval(BoostType.overclock.cooldownSeconds)
            if cooldownEnd > Date() {
                cooldowns[.overclock] = cooldownEnd
            }
        }

        var inventory: [BoostType: Int] = [:]
        for (key, count) in data.boostInventory {
            if let type = BoostType(rawValue: key) {
                inventory[type] = count
            }
        }

        boostState = BoostState(activeBoosts: [], cooldowns: cooldowns, inventory: inventory)
    }

    private func checkOfflineEarnings() {
        guard let data = seasonData else { return }
        let result = EconomyService.shared.calculateOfflineEarnings(
            lastActiveAt: data.lastActiveAt,
            offlineMultiplierLevel: data.offlineMultiplierLevel,
            seasonBaseMultiplier: data.seasonBaseMultiplier
        )

        if result.baseCoins >= 1 {
            pendingOfflineEarnings = result
            showOfflineEarnings = true
        }
    }

    func tap() {
        guard var data = seasonData else { return }

        let tapValue = EconomyService.shared.calculateTapValue(
            clickMultiplierLevel: data.clickMultiplierLevel,
            seasonBaseMultiplier: data.seasonBaseMultiplier,
            temporaryBoostMultiplier: boostState.totalMultiplier
        )

        let previousRankIndex = data.rankIndex
        data.currentSeasonTaps += tapValue

        let currentRank = rankSystem.currentRank(taps: data.currentSeasonTaps, prestigeCount: data.prestigeCount)
        if currentRank.index > previousRankIndex {
            data.rankIndex = currentRank.index

            let coinsEarned = EconomyService.shared.coinsForRankUp(newRankIndex: currentRank.index)
            data.coins += coinsEarned

            data.seasonBaseMultiplier = rankSystem.seasonBaseMultiplier(
                rankIndex: currentRank.index,
                prestigeCount: data.prestigeCount
            )

            newRank = currentRank
            showRankUp = true
            HapticsService.shared.rankUp()
            logRankUp(currentRank.index)
        } else {
            HapticsService.shared.tap()
        }

        seasonData = data
    }

    func claimOfflineEarnings(doubled: Bool) {
        guard var data = seasonData, let earnings = pendingOfflineEarnings else { return }

        let coins = doubled ? earnings.doubledCoins : earnings.baseCoins
        data.coins += coins
        data.lastActiveAt = Date()

        seasonData = data
        pendingOfflineEarnings = nil
        showOfflineEarnings = false

        HapticsService.shared.rewardClaim()
    }

    func purchaseUpgrade(_ item: ShopItem) -> Bool {
        guard var data = seasonData else { return false }

        let currentLevel: Int
        switch item.type {
        case .clickMultiplier:
            currentLevel = data.clickMultiplierLevel
        case .offlineMultiplier:
            currentLevel = data.offlineMultiplierLevel
        case .boostConsumable:
            currentLevel = 0
        case .cosmetic:
            return false
        }

        let result = EconomyService.shared.purchaseUpgrade(item, currentLevel: currentLevel, coins: data.coins)

        guard result.success else {
            HapticsService.shared.error()
            return false
        }

        data.coins = result.remainingCoins

        switch item.type {
        case .clickMultiplier:
            data.clickMultiplierLevel = result.newLevel
        case .offlineMultiplier:
            data.offlineMultiplierLevel = result.newLevel
        case .boostConsumable:
            let key = item.id
            data.boostInventory[key] = (data.boostInventory[key] ?? 0) + 1
            if let type = BoostType(rawValue: key) {
                boostState.inventory[type] = data.boostInventory[key]
            }
        case .cosmetic:
            break
        }

        seasonData = data
        HapticsService.shared.rewardClaim()
        logShopPurchase(item.id)
        return true
    }

    func activateBoost(_ type: BoostType) -> Bool {
        guard boostState.canActivate(type) else { return false }

        if let boost = boostState.activateBoost(type) {
            var data = seasonData
            switch type {
            case .adRush:
                data?.adRushLastUsed = Date()
            case .overclock:
                data?.overclockLastUsed = Date()
                let key = type.rawValue
                let currentCount = data?.boostInventory[key] ?? 1
                data?.boostInventory[key] = max(0, currentCount - 1)
            case .offlineDoubler:
                break
            }
            seasonData = data

            HapticsService.shared.boostActivate()
            return true
        }
        return false
    }

    func prestige() {
        guard var data = seasonData else { return }

        let newPrestigeCount = data.prestigeCount + 1
        let newMultiplier = rankSystem.seasonBaseMultiplier(rankIndex: 1, prestigeCount: newPrestigeCount)

        data.currentSeasonTaps = 0
        data.coins = 0
        data.clickMultiplierLevel = 1
        data.offlineMultiplierLevel = 1
        data.rankIndex = 1
        data.prestigeCount = newPrestigeCount
        data.seasonBaseMultiplier = newMultiplier
        data.boostInventory = [:]
        data.adRushLastUsed = nil
        data.overclockLastUsed = nil

        seasonData = data
        boostState = BoostState()

        HapticsService.shared.prestigeConfirm()
        logPrestige(newPrestigeCount - 1)

        saveNow()
    }

    var canPrestige: Bool {
        guard let data = seasonData else { return false }
        return data.rankIndex >= minimumPrestigeRankIndex
    }

    var currentRank: Rank {
        guard let data = seasonData else { return rankSystem.rank(at: 1) }
        return rankSystem.rank(at: data.rankIndex)
    }

    var progressToNextRank: Double {
        guard let data = seasonData else { return 0 }
        return rankSystem.progress(
            taps: data.currentSeasonTaps,
            currentRankIndex: data.rankIndex,
            prestigeCount: data.prestigeCount
        )
    }

    var tapValue: Double {
        guard let data = seasonData else { return 1 }
        return EconomyService.shared.calculateTapValue(
            clickMultiplierLevel: data.clickMultiplierLevel,
            seasonBaseMultiplier: data.seasonBaseMultiplier,
            temporaryBoostMultiplier: boostState.totalMultiplier
        )
    }

    private func startSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.saveNow()
        }
    }

    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.syncToCloud()
        }
    }

    private func startBoostTimer() {
        boostTimer?.invalidate()
        boostTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.boostState.cleanupExpiredBoosts()
        }
    }

    func saveNow() {
        guard let uid = AuthService.shared.uid,
              var data = seasonData else { return }

        data.lastActiveAt = Date()
        seasonData = data

        Task {
            try? await FirestoreService.shared.saveSeasonData(
                uid: uid,
                seasonId: SeasonService.shared.seasonId,
                data: data
            )
        }
    }

    private func syncToCloud() {
        guard let uid = AuthService.shared.uid,
              let data = seasonData,
              let user = userData,
              user.leaderboardOptIn else { return }

        Task {
            try? await FirestoreService.shared.updateLeaderboardEntry(
                uid: uid,
                seasonId: SeasonService.shared.seasonId,
                displayName: user.displayName,
                taps: data.currentSeasonTaps,
                rankIndex: data.rankIndex
            )
        }
    }

    private func logSessionStart() {
        Analytics.logEvent("session_start", parameters: nil)
    }

    private func logRankUp(_ rankIndex: Int) {
        Analytics.logEvent("rank_up", parameters: ["rankIndex": rankIndex])
    }

    private func logPrestige(_ previousCount: Int) {
        Analytics.logEvent("prestige", parameters: ["prestigeCountBefore": previousCount])
    }

    private func logShopPurchase(_ itemId: String) {
        Analytics.logEvent("shop_purchase", parameters: ["itemId": itemId])
    }

    func cleanup() {
        saveTimer?.invalidate()
        syncTimer?.invalidate()
        boostTimer?.invalidate()
        saveNow()
        Analytics.logEvent("session_end", parameters: nil)
    }
}
