import Foundation
import FirebaseFirestore

struct LeaderboardEntry: Identifiable, Codable {
    var id: String { odid }
    let odid: String
    let displayName: String
    let taps: Double
    let rankIndex: Int
    let position: Int

    var isAnonymous: Bool {
        displayName.isEmpty || displayName == "Anonymous"
    }

    var displayNameOrAnon: String {
        isAnonymous ? "Anonymous" : displayName
    }

    static func fromFirestore(_ data: [String: Any], position: Int) -> LeaderboardEntry {
        LeaderboardEntry(
            odid: data["uid"] as? String ?? UUID().uuidString,
            displayName: data["displayName"] as? String ?? "Anonymous",
            taps: data["taps"] as? Double ?? 0,
            rankIndex: data["rankIndex"] as? Int ?? 1,
            position: position
        )
    }
}

struct LeaderboardData: Codable {
    var top: [LeaderboardEntry]
    var buckets: [Int: Int]
    var totalPlayers: Int
    var lastUpdated: Date

    init(
        top: [LeaderboardEntry] = [],
        buckets: [Int: Int] = [:],
        totalPlayers: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.top = top
        self.buckets = buckets
        self.totalPlayers = totalPlayers
        self.lastUpdated = lastUpdated
    }

    func percentile(for taps: Double) -> Double {
        guard totalPlayers > 0 else { return 0 }

        var playersBelow = 0
        for (bucketThreshold, count) in buckets.sorted(by: { $0.key < $1.key }) {
            if Double(bucketThreshold) <= taps {
                playersBelow += count
            }
        }

        return Double(playersBelow) / Double(totalPlayers)
    }

    func approximateRank(for taps: Double) -> Int {
        if let topEntry = top.first(where: { entry in
            abs(entry.taps - taps) < 1
        }) {
            return topEntry.position
        }

        let percentile = self.percentile(for: taps)
        return max(1, Int(Double(totalPlayers) * (1.0 - percentile)))
    }

    static func fromFirestore(_ data: [String: Any]) -> LeaderboardData {
        let topArray = data["top"] as? [[String: Any]] ?? []
        let top = topArray.enumerated().map { index, entry in
            LeaderboardEntry.fromFirestore(entry, position: index + 1)
        }

        let bucketsRaw = data["buckets"] as? [String: Int] ?? [:]
        var buckets: [Int: Int] = [:]
        for (key, value) in bucketsRaw {
            if let intKey = Int(key) {
                buckets[intKey] = value
            }
        }

        return LeaderboardData(
            top: top,
            buckets: buckets,
            totalPlayers: data["totalPlayers"] as? Int ?? 0,
            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

struct WorldRankState {
    var isEnabled: Bool
    var userRank: Int?
    var userPercentile: Double
    var totalPlayers: Int
    var sliderPosition: Double

    init(
        isEnabled: Bool = false,
        userRank: Int? = nil,
        userPercentile: Double = 0,
        totalPlayers: Int = 0
    ) {
        self.isEnabled = isEnabled
        self.userRank = userRank
        self.userPercentile = userPercentile
        self.totalPlayers = totalPlayers
        self.sliderPosition = 1.0 - userPercentile
    }

    var rankDisplayText: String {
        if let rank = userRank {
            return "#\(NumberFormatService.shared.format(Double(rank)))"
        }
        let percentileText = Int(userPercentile * 100)
        return "Top \(100 - percentileText)%"
    }
}

enum LeaderboardTab: String, CaseIterable, Identifiable {
    case global = "Global"
    case friends = "Friends"
    case lifetime = "Lifetime"

    var id: String { rawValue }
}
