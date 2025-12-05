import Foundation

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let type: ShopItemType
    let basePrice: Double
    let priceGrowth: Double
    let maxLevel: Int
    let effectPerLevel: Double

    func price(at level: Int) -> Double {
        basePrice * pow(priceGrowth, Double(level - 1))
    }

    func effect(at level: Int) -> Double {
        1.0 + (effectPerLevel * Double(level - 1))
    }

    static let clickMultiplier = ShopItem(
        id: "click_multiplier",
        name: "Click Power",
        description: "+10% tap value per level",
        type: .clickMultiplier,
        basePrice: 50,
        priceGrowth: 2.0,
        maxLevel: 100,
        effectPerLevel: 0.10
    )

    static let offlineMultiplier = ShopItem(
        id: "offline_multiplier",
        name: "Offline Earnings",
        description: "+20% offline rate per level",
        type: .offlineMultiplier,
        basePrice: 100,
        priceGrowth: 2.2,
        maxLevel: 50,
        effectPerLevel: 0.20
    )

    static let overclockPack = ShopItem(
        id: "overclock",
        name: "Overclock Pack",
        description: "x5 taps for 15 seconds",
        type: .boostConsumable,
        basePrice: 500,
        priceGrowth: 1.0,
        maxLevel: 99,
        effectPerLevel: 5.0
    )

    static let tapsPerSecond = ShopItem(
        id: "taps_per_second",
        name: "Auto Tapper",
        description: "+1 tap/second per level",
        type: .tapsPerSecond,
        basePrice: 200,
        priceGrowth: 1.8,
        maxLevel: 50,
        effectPerLevel: 1.0
    )

    // New boost packs
    static let luckyTapPack = ShopItem(
        id: "lucky_tap",
        name: "Lucky Tap Pack",
        description: "10% chance for x10 taps",
        type: .boostConsumable,
        basePrice: 750,
        priceGrowth: 1.0,
        maxLevel: 99,
        effectPerLevel: 10.0
    )

    static let criticalHitPack = ShopItem(
        id: "critical_hit",
        name: "Critical Hit Pack",
        description: "Every 5th tap is x3",
        type: .boostConsumable,
        basePrice: 600,
        priceGrowth: 1.0,
        maxLevel: 99,
        effectPerLevel: 3.0
    )

    static let autoTapBoostPack = ShopItem(
        id: "auto_tap_boost",
        name: "Auto Boost Pack",
        description: "x2 auto-tap speed for 90s",
        type: .boostConsumable,
        basePrice: 400,
        priceGrowth: 1.0,
        maxLevel: 99,
        effectPerLevel: 2.0
    )

    // Upgrade items
    static let upgradeItems: [ShopItem] = [
        .clickMultiplier,
        .offlineMultiplier,
        .tapsPerSecond
    ]

    // Boost items
    static let boostItems: [ShopItem] = [
        .overclockPack,
        .luckyTapPack,
        .criticalHitPack,
        .autoTapBoostPack
    ]

    static let allItems: [ShopItem] = upgradeItems + boostItems
}

// MARK: - Shop Category
enum ShopCategory: String, CaseIterable, Identifiable {
    case upgrades = "Upgrades"
    case boosts = "Boosts"
    case adRewards = "Ad Rewards"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .upgrades: return "arrow.up.circle.fill"
        case .boosts: return "flame.fill"
        case .adRewards: return "play.rectangle.fill"
        }
    }
}

// MARK: - Ad Reward Items
struct AdRewardItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let rewardType: AdRewardType
    let cooldownMinutes: Int

    enum AdRewardType {
        case coins(amount: Double)
        case boost(type: BoostType)
        case multiplier(value: Double, duration: TimeInterval)
    }

    static let freeCoins = AdRewardItem(
        id: "free_coins",
        name: "Free Coins",
        description: "Watch an ad to earn 100 coins",
        icon: "dollarsign.circle.fill",
        rewardType: .coins(amount: 100),
        cooldownMinutes: 5
    )

    static let tapFrenzy = AdRewardItem(
        id: "tap_frenzy",
        name: "Tap Frenzy",
        description: "x3 taps for 60 seconds",
        icon: "sparkles",
        rewardType: .boost(type: .tapFrenzy),
        cooldownMinutes: 10
    )

    static let coinMagnet = AdRewardItem(
        id: "coin_magnet",
        name: "Coin Magnet",
        description: "x2 coins for 2 minutes",
        icon: "magnet",
        rewardType: .boost(type: .coinMagnet),
        cooldownMinutes: 15
    )

    static let adRush = AdRewardItem(
        id: "ad_rush",
        name: "Ad Rush",
        description: "x2 taps for 30 seconds",
        icon: "bolt.fill",
        rewardType: .boost(type: .adRush),
        cooldownMinutes: 2
    )

    static let megaCoins = AdRewardItem(
        id: "mega_coins",
        name: "Mega Coins",
        description: "Watch an ad to earn 500 coins",
        icon: "star.circle.fill",
        rewardType: .coins(amount: 500),
        cooldownMinutes: 30
    )

    static let allItems: [AdRewardItem] = [
        .freeCoins,
        .adRush,
        .tapFrenzy,
        .coinMagnet,
        .megaCoins
    ]
}

enum ShopItemType {
    case clickMultiplier
    case offlineMultiplier
    case tapsPerSecond
    case boostConsumable
    case cosmetic
}

struct EconomyConfig {
    var baseTap: Double
    var clickMultiplierPerLevel: Double
    var offlineMultiplierPerLevel: Double
    var baseOfflineRate: Double
    var offlineCapHours: Double
    var milestoneCoinsBase: Double
    var rankUpCoinsBase: Double

    init(
        baseTap: Double = 1,
        clickMultiplierPerLevel: Double = 0.10,
        offlineMultiplierPerLevel: Double = 0.20,
        baseOfflineRate: Double = 10,
        offlineCapHours: Double = 8,
        milestoneCoinsBase: Double = 10,
        rankUpCoinsBase: Double = 50
    ) {
        self.baseTap = baseTap
        self.clickMultiplierPerLevel = clickMultiplierPerLevel
        self.offlineMultiplierPerLevel = offlineMultiplierPerLevel
        self.baseOfflineRate = baseOfflineRate
        self.offlineCapHours = offlineCapHours
        self.milestoneCoinsBase = milestoneCoinsBase
        self.rankUpCoinsBase = rankUpCoinsBase
    }

    static var `default`: EconomyConfig { EconomyConfig() }
}

struct OfflineEarningsResult {
    let baseCoins: Double
    let elapsedSeconds: TimeInterval
    let wasAtCap: Bool

    var canDouble: Bool { baseCoins > 0 }
    var doubledCoins: Double { baseCoins * 2 }
}

struct TapResult {
    let tapsAdded: Double
    let coinsEarned: Double
    let didRankUp: Bool
    let newRankIndex: Int?
    let milestoneReached: Milestone?
}

struct Milestone: Identifiable {
    let id: String
    let name: String
    let threshold: Double
    let coinsReward: Double

    static func milestones(for rankIndex: Int) -> [Milestone] {
        let base = Double(rankIndex) * 100
        return [
            Milestone(id: "m_\(rankIndex)_25", name: "25%", threshold: base * 0.25, coinsReward: 5),
            Milestone(id: "m_\(rankIndex)_50", name: "50%", threshold: base * 0.50, coinsReward: 10),
            Milestone(id: "m_\(rankIndex)_75", name: "75%", threshold: base * 0.75, coinsReward: 15)
        ]
    }
}

struct PurchaseResult {
    let success: Bool
    let newLevel: Int
    let remainingCoins: Double
    let message: String
}
