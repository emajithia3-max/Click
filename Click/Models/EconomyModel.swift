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
        id: "overclock_pack",
        name: "Overclock Pack",
        description: "x5 taps for 15 seconds",
        type: .boostConsumable,
        basePrice: 500,
        priceGrowth: 1.0,
        maxLevel: 1,
        effectPerLevel: 5.0
    )

    static let allItems: [ShopItem] = [
        .clickMultiplier,
        .offlineMultiplier,
        .overclockPack
    ]
}

enum ShopItemType {
    case clickMultiplier
    case offlineMultiplier
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
