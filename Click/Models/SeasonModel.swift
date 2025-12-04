import Foundation
import FirebaseFirestore

struct Season: Codable, Identifiable {
    var id: String
    var name: String
    var startUtc: Date
    var endUtc: Date
    var isActive: Bool
    var coefficients: SeasonCoefficients

    init(
        id: String = "season_1",
        name: String = "Season 1",
        startUtc: Date = Date(),
        endUtc: Date = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date(),
        isActive: Bool = true,
        coefficients: SeasonCoefficients = SeasonCoefficients()
    ) {
        self.id = id
        self.name = name
        self.startUtc = startUtc
        self.endUtc = endUtc
        self.isActive = isActive
        self.coefficients = coefficients
    }

    var timeRemaining: TimeInterval {
        max(0, endUtc.timeIntervalSince(Date()))
    }

    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var hasEnded: Bool {
        Date() >= endUtc
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> Season {
        Season(
            id: id,
            name: data["name"] as? String ?? "Season 1",
            startUtc: (data["startUtc"] as? Timestamp)?.dateValue() ?? Date(),
            endUtc: (data["endUtc"] as? Timestamp)?.dateValue() ?? Date(),
            isActive: data["isActive"] as? Bool ?? false,
            coefficients: SeasonCoefficients.fromFirestore(data["coefficients"] as? [String: Any] ?? [:])
        )
    }
}

struct SeasonCoefficients: Codable {
    var rankGrowthA: Double
    var rankGrowthB: Double
    var prestigeGrowthA: Double
    var baseThreshold: Double
    var offlineHoursCap: Double
    var baseOfflineRate: Double

    init(
        rankGrowthA: Double = 500,
        rankGrowthB: Double = 1.22,
        prestigeGrowthA: Double = 1.35,
        baseThreshold: Double = 500,
        offlineHoursCap: Double = 8,
        baseOfflineRate: Double = 10
    ) {
        self.rankGrowthA = rankGrowthA
        self.rankGrowthB = rankGrowthB
        self.prestigeGrowthA = prestigeGrowthA
        self.baseThreshold = baseThreshold
        self.offlineHoursCap = offlineHoursCap
        self.baseOfflineRate = baseOfflineRate
    }

    static func fromFirestore(_ data: [String: Any]) -> SeasonCoefficients {
        SeasonCoefficients(
            rankGrowthA: data["rankGrowthA"] as? Double ?? 500,
            rankGrowthB: data["rankGrowthB"] as? Double ?? 1.22,
            prestigeGrowthA: data["prestigeGrowthA"] as? Double ?? 1.35,
            baseThreshold: data["baseThreshold"] as? Double ?? 500,
            offlineHoursCap: data["offlineHoursCap"] as? Double ?? 8,
            baseOfflineRate: data["baseOfflineRate"] as? Double ?? 10
        )
    }
}

struct SeasonHistory: Codable, Identifiable {
    var id: String
    var seasonName: String
    var finalTaps: Double
    var finalRankIndex: Int
    var finalPrestigeCount: Int
    var endDate: Date

    init(
        id: String,
        seasonName: String,
        finalTaps: Double,
        finalRankIndex: Int,
        finalPrestigeCount: Int,
        endDate: Date
    ) {
        self.id = id
        self.seasonName = seasonName
        self.finalTaps = finalTaps
        self.finalRankIndex = finalRankIndex
        self.finalPrestigeCount = finalPrestigeCount
        self.endDate = endDate
    }
}
