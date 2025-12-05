import Foundation
import FirebaseFirestore

struct UserData: Codable {
    var displayName: String
    var createdAt: Date
    var lifetimeTaps: Double
    var lifetimeBestRankIndex: Int
    var cosmetics: [String]
    var leaderboardOptIn: Bool

    init(
        displayName: String = "",
        createdAt: Date = Date(),
        lifetimeTaps: Double = 0,
        lifetimeBestRankIndex: Int = 1,
        cosmetics: [String] = [],
        leaderboardOptIn: Bool = false
    ) {
        self.displayName = displayName
        self.createdAt = createdAt
        self.lifetimeTaps = lifetimeTaps
        self.lifetimeBestRankIndex = lifetimeBestRankIndex
        self.cosmetics = cosmetics
        self.leaderboardOptIn = leaderboardOptIn
    }
}

struct SeasonUserData: Codable {
    var currentSeasonTaps: Double
    var coins: Double
    var clickMultiplierLevel: Int
    var offlineMultiplierLevel: Int
    var tapsPerSecondLevel: Int
    var rankIndex: Int
    var prestigeCount: Int
    var seasonBaseMultiplier: Double
    var lastActiveAt: Date
    var boostInventory: [String: Int]
    var adRushLastUsed: Date?
    var overclockLastUsed: Date?

    init(
        currentSeasonTaps: Double = 0,
        coins: Double = 0,
        clickMultiplierLevel: Int = 1,
        offlineMultiplierLevel: Int = 1,
        tapsPerSecondLevel: Int = 0,
        rankIndex: Int = 1,
        prestigeCount: Int = 0,
        seasonBaseMultiplier: Double = 1.0,
        lastActiveAt: Date = Date(),
        boostInventory: [String: Int] = [:],
        adRushLastUsed: Date? = nil,
        overclockLastUsed: Date? = nil
    ) {
        self.currentSeasonTaps = currentSeasonTaps
        self.coins = coins
        self.clickMultiplierLevel = clickMultiplierLevel
        self.offlineMultiplierLevel = offlineMultiplierLevel
        self.tapsPerSecondLevel = tapsPerSecondLevel
        self.rankIndex = rankIndex
        self.prestigeCount = prestigeCount
        self.seasonBaseMultiplier = seasonBaseMultiplier
        self.lastActiveAt = lastActiveAt
        self.boostInventory = boostInventory
        self.adRushLastUsed = adRushLastUsed
        self.overclockLastUsed = overclockLastUsed
    }

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "currentSeasonTaps": currentSeasonTaps,
            "coins": coins,
            "clickMultiplierLevel": clickMultiplierLevel,
            "offlineMultiplierLevel": offlineMultiplierLevel,
            "tapsPerSecondLevel": tapsPerSecondLevel,
            "rankIndex": rankIndex,
            "prestigeCount": prestigeCount,
            "seasonBaseMultiplier": seasonBaseMultiplier,
            "lastActiveAt": Timestamp(date: lastActiveAt),
            "boostInventory": boostInventory
        ]
        if let adRush = adRushLastUsed {
            data["adRushLastUsed"] = Timestamp(date: adRush)
        }
        if let overclock = overclockLastUsed {
            data["overclockLastUsed"] = Timestamp(date: overclock)
        }
        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> SeasonUserData {
        SeasonUserData(
            currentSeasonTaps: data["currentSeasonTaps"] as? Double ?? 0,
            coins: data["coins"] as? Double ?? 0,
            clickMultiplierLevel: data["clickMultiplierLevel"] as? Int ?? 1,
            offlineMultiplierLevel: data["offlineMultiplierLevel"] as? Int ?? 1,
            tapsPerSecondLevel: data["tapsPerSecondLevel"] as? Int ?? 0,
            rankIndex: data["rankIndex"] as? Int ?? 1,
            prestigeCount: data["prestigeCount"] as? Int ?? 0,
            seasonBaseMultiplier: data["seasonBaseMultiplier"] as? Double ?? 1.0,
            lastActiveAt: (data["lastActiveAt"] as? Timestamp)?.dateValue() ?? Date(),
            boostInventory: data["boostInventory"] as? [String: Int] ?? [:],
            adRushLastUsed: (data["adRushLastUsed"] as? Timestamp)?.dateValue(),
            overclockLastUsed: (data["overclockLastUsed"] as? Timestamp)?.dateValue()
        )
    }
}

struct PrivacyLog: Codable {
    var optInTimestamp: Date?
    var optOutTimestamp: Date?
    var currentOptInState: Bool

    init(optInTimestamp: Date? = nil, optOutTimestamp: Date? = nil, currentOptInState: Bool = false) {
        self.optInTimestamp = optInTimestamp
        self.optOutTimestamp = optOutTimestamp
        self.currentOptInState = currentOptInState
    }
}
