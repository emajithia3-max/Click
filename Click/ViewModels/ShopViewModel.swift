import Foundation
import Combine

final class ShopViewModel: ObservableObject {
    @Published var selectedCategory: ShopCategory = .upgrades
    @Published var showPurchaseResult = false
    @Published var purchaseResultMessage = ""
    @Published var purchaseSuccess = false
    @Published var adRewardCooldowns: [String: Date] = [:]
    @Published var showAdConsent = false
    private var pendingAdReward: AdRewardItem?

    private var cancellables = Set<AnyCancellable>()
    private let gameState = GameStateService.shared
    private static let adCooldownsKey = "shopAdRewardCooldowns"

    init() {
        loadAdCooldowns()
        setupBindings()
    }

    private func setupBindings() {
        gameState.$seasonData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        gameState.$boostState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func loadAdCooldowns() {
        if let data = UserDefaults.standard.dictionary(forKey: Self.adCooldownsKey) as? [String: Double] {
            adRewardCooldowns = data.mapValues { Date(timeIntervalSince1970: $0) }
        }
    }

    private func saveAdCooldowns() {
        let data = adRewardCooldowns.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(data, forKey: Self.adCooldownsKey)
    }

    var coins: Double {
        gameState.seasonData?.coins ?? 0
    }

    var clickMultiplierLevel: Int {
        gameState.seasonData?.clickMultiplierLevel ?? 1
    }

    var offlineMultiplierLevel: Int {
        gameState.seasonData?.offlineMultiplierLevel ?? 1
    }

    var tapsPerSecondLevel: Int {
        gameState.seasonData?.tapsPerSecondLevel ?? 0
    }

    // MARK: - Category Items

    var upgradeItems: [ShopItem] {
        ShopItem.upgradeItems
    }

    var boostItems: [ShopItem] {
        ShopItem.boostItems
    }

    var adRewardItems: [AdRewardItem] {
        AdRewardItem.allItems
    }

    // MARK: - Inventory

    func inventoryCount(for boostType: BoostType) -> Int {
        gameState.boostState.inventory[boostType] ?? 0
    }

    func levelFor(_ item: ShopItem) -> Int {
        switch item.type {
        case .clickMultiplier:
            return clickMultiplierLevel
        case .offlineMultiplier:
            return offlineMultiplierLevel
        case .tapsPerSecond:
            return tapsPerSecondLevel
        case .boostConsumable:
            return inventoryForItem(item)
        case .cosmetic:
            return 0
        }
    }

    func inventoryForItem(_ item: ShopItem) -> Int {
        switch item.id {
        case "overclock":
            return inventoryCount(for: .overclock)
        case "lucky_tap":
            return inventoryCount(for: .luckyTap)
        case "critical_hit":
            return inventoryCount(for: .criticalHit)
        case "auto_tap_boost":
            return inventoryCount(for: .autoTapBoost)
        default:
            return 0
        }
    }

    func priceFor(_ item: ShopItem) -> Double {
        switch item.type {
        case .boostConsumable:
            return item.basePrice
        default:
            return EconomyService.shared.priceForUpgrade(item, currentLevel: levelFor(item))
        }
    }

    func canAfford(_ item: ShopItem) -> Bool {
        switch item.type {
        case .boostConsumable:
            return coins >= item.basePrice
        default:
            return EconomyService.shared.canAfford(item, currentLevel: levelFor(item), coins: coins)
        }
    }

    func isMaxLevel(_ item: ShopItem) -> Bool {
        switch item.type {
        case .boostConsumable:
            return false
        default:
            return levelFor(item) >= item.maxLevel
        }
    }

    func currentEffect(_ item: ShopItem) -> String {
        EconomyService.shared.effectDescription(item, level: levelFor(item))
    }

    func nextEffect(_ item: ShopItem) -> String {
        EconomyService.shared.nextEffectDescription(item, currentLevel: levelFor(item))
    }

    func purchase(_ item: ShopItem) {
        let success = gameState.purchaseUpgrade(item)

        purchaseSuccess = success
        purchaseResultMessage = success ? "Purchased!" : "Not enough coins"
        showPurchaseResult = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showPurchaseResult = false
        }
    }

    // MARK: - Ad Rewards

    func canClaimAdReward(_ item: AdRewardItem) -> Bool {
        guard AdService.shared.canShowRewardedAd() else { return false }

        if let cooldownEnd = adRewardCooldowns[item.id] {
            return Date() >= cooldownEnd
        }
        return true
    }

    func cooldownRemaining(_ item: AdRewardItem) -> String {
        guard let cooldownEnd = adRewardCooldowns[item.id] else { return "" }
        let remaining = cooldownEnd.timeIntervalSince(Date())
        guard remaining > 0 else { return "" }

        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "\(seconds)s"
    }

    func claimAdReward(_ item: AdRewardItem) {
        guard canClaimAdReward(item) else { return }

        if !SettingsManager.shared.hasSeenAdConsent {
            pendingAdReward = item
            showAdConsent = true
            return
        }

        showRewardedAdFor(item)
    }

    func onAdConsentComplete() {
        showAdConsent = false
        if let item = pendingAdReward {
            pendingAdReward = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showRewardedAdFor(item)
            }
        }
    }

    private func showRewardedAdFor(_ item: AdRewardItem) {
        AdService.shared.showRewardedAd { [weak self] success in
            guard success else { return }
            self?.applyReward(item)
        }
    }

    private func applyReward(_ item: AdRewardItem) {
        switch item.rewardType {
        case .coins(let amount):
            gameState.addCoins(amount)
            purchaseResultMessage = "+\(Int(amount)) coins!"

        case .boost(let boostType):
            _ = gameState.activateBoost(boostType)
            purchaseResultMessage = "\(boostType.displayName) activated!"

        case .multiplier(let value, let duration):
            // Could implement custom temporary multiplier
            purchaseResultMessage = "x\(Int(value)) multiplier for \(Int(duration))s!"
        }

        // Set cooldown
        adRewardCooldowns[item.id] = Date().addingTimeInterval(Double(item.cooldownMinutes) * 60)
        saveAdCooldowns()

        purchaseSuccess = true
        showPurchaseResult = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showPurchaseResult = false
        }
    }
}
