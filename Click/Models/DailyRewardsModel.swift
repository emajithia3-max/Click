import Foundation
import SwiftUI

struct DailyReward: Identifiable {
    let id: Int // Day number (1-7)
    let day: Int
    let rewardType: DailyRewardType
    let amount: Double
    let isMilestone: Bool

    enum DailyRewardType {
        case coins
        case boost(BoostType)
        case multiplierBonus(duration: TimeInterval)

        var icon: String {
            switch self {
            case .coins: return "dollarsign.circle.fill"
            case .boost(let type): return type.iconName
            case .multiplierBonus: return "sparkles"
            }
        }

        var description: String {
            switch self {
            case .coins: return "Coins"
            case .boost(let type): return type.displayName
            case .multiplierBonus: return "Multiplier Bonus"
            }
        }
    }

    static let weeklyRewards: [DailyReward] = [
        DailyReward(id: 1, day: 1, rewardType: .coins, amount: 50, isMilestone: false),
        DailyReward(id: 2, day: 2, rewardType: .coins, amount: 75, isMilestone: false),
        DailyReward(id: 3, day: 3, rewardType: .boost(.overclock), amount: 1, isMilestone: true),
        DailyReward(id: 4, day: 4, rewardType: .coins, amount: 100, isMilestone: false),
        DailyReward(id: 5, day: 5, rewardType: .coins, amount: 150, isMilestone: false),
        DailyReward(id: 6, day: 6, rewardType: .boost(.luckyTap), amount: 1, isMilestone: true),
        DailyReward(id: 7, day: 7, rewardType: .coins, amount: 500, isMilestone: true)
    ]
}

struct DailyRewardsState: Codable {
    var lastClaimDate: Date?
    var currentStreak: Int
    var totalDaysClaimed: Int

    init() {
        self.lastClaimDate = nil
        self.currentStreak = 0
        self.totalDaysClaimed = 0
    }

    var canClaimToday: Bool {
        guard let lastClaim = lastClaimDate else { return true }
        return !Calendar.current.isDateInToday(lastClaim)
    }

    var currentDayIndex: Int {
        (currentStreak % 7)
    }

    var nextReward: DailyReward {
        DailyReward.weeklyRewards[currentDayIndex]
    }

    var streakWillReset: Bool {
        guard let lastClaim = lastClaimDate else { return false }
        let calendar = Calendar.current
        let daysSinceLastClaim = calendar.dateComponents([.day], from: lastClaim, to: Date()).day ?? 0
        return daysSinceLastClaim > 1
    }

    mutating func claim() -> DailyReward {
        let reward = nextReward

        if streakWillReset {
            currentStreak = 1
        } else {
            currentStreak += 1
        }

        totalDaysClaimed += 1
        lastClaimDate = Date()

        return reward
    }
}

class DailyRewardsManager: ObservableObject {
    static let shared = DailyRewardsManager()

    @Published var state: DailyRewardsState
    @Published var showDailyRewards = false

    private static let stateKey = "dailyRewardsState"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.stateKey),
           let savedState = try? JSONDecoder().decode(DailyRewardsState.self, from: data) {
            self.state = savedState
        } else {
            self.state = DailyRewardsState()
        }
    }

    func checkAndShowDailyRewards() {
        if state.canClaimToday {
            showDailyRewards = true
        }
    }

    func claimReward() -> DailyReward {
        let reward = state.claim()
        saveState()

        // Apply the reward
        switch reward.rewardType {
        case .coins:
            GameStateService.shared.addCoins(reward.amount)

        case .boost(let boostType):
            // Add to inventory
            var data = GameStateService.shared.seasonData
            let key = boostType.rawValue
            data?.boostInventory[key] = (data?.boostInventory[key] ?? 0) + Int(reward.amount)
            if let data = data {
                GameStateService.shared.seasonData = data
            }
            GameStateService.shared.boostState.inventory[boostType] = (GameStateService.shared.boostState.inventory[boostType] ?? 0) + Int(reward.amount)

        case .multiplierBonus:
            // Could implement as a special temporary bonus
            break
        }

        HapticsService.shared.rewardClaim()
        return reward
    }

    func dismissDailyRewards() {
        showDailyRewards = false
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.stateKey)
        }
    }
}
