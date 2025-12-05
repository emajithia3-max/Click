import Foundation
import Combine

final class EconomyService: ObservableObject {
    static let shared = EconomyService()

    @Published var config: EconomyConfig

    private init() {
        self.config = RemoteConfigService.shared.buildEconomyConfig()
    }

    func refreshConfig() {
        config = RemoteConfigService.shared.buildEconomyConfig()
    }

    func calculateTapValue(
        clickMultiplierLevel: Int,
        seasonBaseMultiplier: Double,
        temporaryBoostMultiplier: Double
    ) -> Double {
        let clickMultiplier = 1.0 + (config.clickMultiplierPerLevel * Double(clickMultiplierLevel - 1))
        return config.baseTap * clickMultiplier * seasonBaseMultiplier * temporaryBoostMultiplier
    }

    func calculateOfflineEarnings(
        lastActiveAt: Date,
        offlineMultiplierLevel: Int,
        seasonBaseMultiplier: Double
    ) -> OfflineEarningsResult {
        let elapsed = Date().timeIntervalSince(lastActiveAt)
        let cappedElapsed = min(elapsed, config.offlineCapHours * 3600)

        let offlineMultiplier = 1.0 + (config.offlineMultiplierPerLevel * Double(offlineMultiplierLevel - 1))
        let rate = config.baseOfflineRate * offlineMultiplier * seasonBaseMultiplier

        let baseCoins = rate * (cappedElapsed / 3600)
        let wasAtCap = elapsed >= (config.offlineCapHours * 3600)

        return OfflineEarningsResult(
            baseCoins: baseCoins,
            elapsedSeconds: cappedElapsed,
            wasAtCap: wasAtCap
        )
    }

    func priceForUpgrade(_ item: ShopItem, currentLevel: Int) -> Double {
        item.price(at: currentLevel + 1)
    }

    func canAfford(_ item: ShopItem, currentLevel: Int, coins: Double) -> Bool {
        coins >= priceForUpgrade(item, currentLevel: currentLevel)
    }

    func purchaseUpgrade(
        _ item: ShopItem,
        currentLevel: Int,
        coins: Double
    ) -> PurchaseResult {
        let price = priceForUpgrade(item, currentLevel: currentLevel)

        guard coins >= price else {
            return PurchaseResult(
                success: false,
                newLevel: currentLevel,
                remainingCoins: coins,
                message: "Not enough coins"
            )
        }

        guard currentLevel < item.maxLevel else {
            return PurchaseResult(
                success: false,
                newLevel: currentLevel,
                remainingCoins: coins,
                message: "Already at max level"
            )
        }

        return PurchaseResult(
            success: true,
            newLevel: currentLevel + 1,
            remainingCoins: coins - price,
            message: "Upgrade successful"
        )
    }

    func coinsForRankUp(newRankIndex: Int) -> Double {
        config.rankUpCoinsBase * Double(newRankIndex)
    }

    func coinsForMilestone(milestone: Milestone) -> Double {
        milestone.coinsReward
    }

    func effectDescription(_ item: ShopItem, level: Int) -> String {
        switch item.type {
        case .clickMultiplier:
            let effect = item.effect(at: level)
            return "x\(String(format: "%.1f", effect)) tap power"
        case .offlineMultiplier:
            let effect = item.effect(at: level)
            return "x\(String(format: "%.1f", effect)) offline rate"
        case .tapsPerSecond:
            return "\(level) tap\(level == 1 ? "" : "s")/sec"
        case .boostConsumable:
            return "x\(Int(item.effectPerLevel)) taps"
        case .cosmetic:
            return "Unlocked"
        }
    }

    func nextEffectDescription(_ item: ShopItem, currentLevel: Int) -> String {
        guard currentLevel < item.maxLevel else { return "Max Level" }
        switch item.type {
        case .clickMultiplier:
            let nextEffect = item.effect(at: currentLevel + 1)
            return "x\(String(format: "%.1f", nextEffect)) tap power"
        case .offlineMultiplier:
            let nextEffect = item.effect(at: currentLevel + 1)
            return "x\(String(format: "%.1f", nextEffect)) offline rate"
        case .tapsPerSecond:
            let nextLevel = currentLevel + 1
            return "\(nextLevel) tap\(nextLevel == 1 ? "" : "s")/sec"
        case .boostConsumable:
            return "+1 charge"
        case .cosmetic:
            return "Unlock"
        }
    }
}
