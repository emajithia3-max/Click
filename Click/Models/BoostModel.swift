import Foundation

enum BoostType: String, Codable, CaseIterable, Identifiable {
    case adRush = "ad_rush"
    case overclock = "overclock"
    case offlineDoubler = "offline_doubler"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adRush: return "Ad Rush"
        case .overclock: return "Overclock"
        case .offlineDoubler: return "Offline Doubler"
        }
    }

    var description: String {
        switch self {
        case .adRush: return "x2 taps for 30 seconds"
        case .overclock: return "x5 taps for 15 seconds"
        case .offlineDoubler: return "Double offline earnings"
        }
    }

    var multiplier: Double {
        switch self {
        case .adRush: return 2.0
        case .overclock: return 5.0
        case .offlineDoubler: return 2.0
        }
    }

    var durationSeconds: TimeInterval {
        switch self {
        case .adRush: return 30
        case .overclock: return 15
        case .offlineDoubler: return 0
        }
    }

    var cooldownSeconds: TimeInterval {
        switch self {
        case .adRush: return 120
        case .overclock: return 300
        case .offlineDoubler: return 0
        }
    }

    var source: BoostSource {
        switch self {
        case .adRush: return .rewardedAd
        case .overclock: return .coins
        case .offlineDoubler: return .rewardedAd
        }
    }

    var iconName: String {
        switch self {
        case .adRush: return "bolt.fill"
        case .overclock: return "flame.fill"
        case .offlineDoubler: return "moon.fill"
        }
    }
}

enum BoostSource {
    case rewardedAd
    case coins
    case free
}

struct ActiveBoost: Identifiable {
    let id: UUID
    let type: BoostType
    let startTime: Date
    let endTime: Date
    let multiplier: Double

    var isActive: Bool {
        Date() < endTime
    }

    var remainingTime: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var remainingTimeFormatted: String {
        let remaining = Int(remainingTime)
        if remaining >= 60 {
            return "\(remaining / 60):\(String(format: "%02d", remaining % 60))"
        }
        return "\(remaining)s"
    }

    var progress: Double {
        let total = endTime.timeIntervalSince(startTime)
        guard total > 0 else { return 0 }
        return remainingTime / total
    }

    init(type: BoostType) {
        self.id = UUID()
        self.type = type
        self.startTime = Date()
        self.endTime = Date().addingTimeInterval(type.durationSeconds)
        self.multiplier = type.multiplier
    }

    init(type: BoostType, duration: TimeInterval, multiplier: Double) {
        self.id = UUID()
        self.type = type
        self.startTime = Date()
        self.endTime = Date().addingTimeInterval(duration)
        self.multiplier = multiplier
    }
}

struct BoostState {
    var activeBoosts: [ActiveBoost]
    var cooldowns: [BoostType: Date]
    var inventory: [BoostType: Int]

    init(
        activeBoosts: [ActiveBoost] = [],
        cooldowns: [BoostType: Date] = [:],
        inventory: [BoostType: Int] = [:]
    ) {
        self.activeBoosts = activeBoosts
        self.cooldowns = cooldowns
        self.inventory = inventory
    }

    var totalMultiplier: Double {
        activeBoosts
            .filter { $0.isActive }
            .map { $0.multiplier }
            .reduce(1.0, *)
    }

    func isOnCooldown(_ type: BoostType) -> Bool {
        guard let cooldownEnd = cooldowns[type] else { return false }
        return Date() < cooldownEnd
    }

    func cooldownRemaining(_ type: BoostType) -> TimeInterval {
        guard let cooldownEnd = cooldowns[type] else { return 0 }
        return max(0, cooldownEnd.timeIntervalSince(Date()))
    }

    func cooldownRemainingFormatted(_ type: BoostType) -> String {
        let remaining = Int(cooldownRemaining(type))
        if remaining >= 60 {
            return "\(remaining / 60):\(String(format: "%02d", remaining % 60))"
        }
        return "\(remaining)s"
    }

    func canActivate(_ type: BoostType) -> Bool {
        if isOnCooldown(type) { return false }
        if type.source == .coins {
            return (inventory[type] ?? 0) > 0
        }
        return true
    }

    func hasActiveBoost(_ type: BoostType) -> Bool {
        activeBoosts.contains { $0.type == type && $0.isActive }
    }

    mutating func cleanupExpiredBoosts() {
        activeBoosts.removeAll { !$0.isActive }
    }

    mutating func activateBoost(_ type: BoostType) -> ActiveBoost? {
        guard canActivate(type) else { return nil }

        if type.source == .coins {
            let current = inventory[type] ?? 0
            guard current > 0 else { return nil }
            inventory[type] = current - 1
        }

        let boost = ActiveBoost(type: type)
        activeBoosts.append(boost)

        if type.cooldownSeconds > 0 {
            cooldowns[type] = Date().addingTimeInterval(type.cooldownSeconds)
        }

        return boost
    }
}
