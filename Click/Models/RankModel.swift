import Foundation
import SwiftUI

struct Rank: Identifiable, Equatable {
    var id: Int { index }
    let index: Int
    let tier: Int
    let level: Int
    let threshold: Double

    var tierName: String {
        "Tier \(tier)"
    }

    var levelNumeral: String {
        let numerals = ["V", "IV", "III", "II", "I"]
        guard level >= 1 && level <= 5 else { return "" }
        return numerals[level - 1]
    }

    var displayName: String {
        "\(tierName) \(levelNumeral)"
    }

    var shortName: String {
        "T\(tier)-\(levelNumeral)"
    }

    var tierColor: Color {
        Rank.tierColors[tier - 1]
    }

    var hasGlow: Bool {
        tier >= 6
    }

    var glowIntensity: Double {
        guard hasGlow else { return 0 }
        return Double(tier - 5) * 0.15
    }

    static let tierColors: [Color] = [
        Color(hex: "A3A3A3"),
        Color(hex: "8BC6EC"),
        Color(hex: "B08968"),
        Color(hex: "C0C0C0"),
        Color(hex: "E6B422"),
        Color(hex: "9AD1D4"),
        Color(hex: "6EE7F0"),
        Color(hex: "7C3AED"),
        Color(hex: "EF4444"),
        Color(hex: "22C55E")
    ]

    static func fromIndex(_ index: Int) -> (tier: Int, level: Int) {
        let clampedIndex = max(1, min(50, index))
        let tier = ((clampedIndex - 1) / 5) + 1
        let level = ((clampedIndex - 1) % 5) + 1
        return (tier, level)
    }

    static func toIndex(tier: Int, level: Int) -> Int {
        ((tier - 1) * 5) + level
    }
}

struct RankSystem {
    let coefficients: SeasonCoefficients
    private var rankCache: [Int: Rank] = [:]

    init(coefficients: SeasonCoefficients = SeasonCoefficients()) {
        self.coefficients = coefficients
    }

    func threshold(for rankIndex: Int) -> Double {
        let index = max(1, min(50, rankIndex))
        return coefficients.baseThreshold * pow(coefficients.rankGrowthB, Double(index - 1))
    }

    func rank(at index: Int) -> Rank {
        let clampedIndex = max(1, min(50, index))
        let (tier, level) = Rank.fromIndex(clampedIndex)
        return Rank(
            index: clampedIndex,
            tier: tier,
            level: level,
            threshold: threshold(for: clampedIndex)
        )
    }

    func currentRank(taps: Double, prestigeCount: Int) -> Rank {
        let adjustedTaps = taps
        for index in (1...50).reversed() {
            let thresh = threshold(for: index, prestigeCount: prestigeCount)
            if adjustedTaps >= thresh {
                return rank(at: index)
            }
        }
        return rank(at: 1)
    }

    func threshold(for rankIndex: Int, prestigeCount: Int) -> Double {
        let baseThresh = threshold(for: rankIndex)
        let prestigeEase = prestigeCount > 0 ? pow(0.92, Double(prestigeCount)) : 1.0
        return baseThresh * prestigeEase
    }

    func progress(taps: Double, currentRankIndex: Int, prestigeCount: Int) -> Double {
        let currentThresh = currentRankIndex > 1 ? threshold(for: currentRankIndex, prestigeCount: prestigeCount) : 0
        let nextThresh = currentRankIndex < 50 ? threshold(for: currentRankIndex + 1, prestigeCount: prestigeCount) : threshold(for: 50, prestigeCount: prestigeCount)
        let range = nextThresh - currentThresh
        guard range > 0 else { return 1.0 }
        return min(1.0, max(0, (taps - currentThresh) / range))
    }

    func seasonBaseMultiplier(rankIndex: Int, prestigeCount: Int) -> Double {
        let rankBonus = 1.0 + (Double(rankIndex - 1) * 0.02)
        let prestigeBonus = prestigeCount > 0 ? pow(coefficients.prestigeGrowthA, Double(prestigeCount)) : 1.0
        return rankBonus * prestigeBonus
    }

    func projectedMultiplier(afterPrestige currentPrestigeCount: Int, currentRankIndex: Int) -> Double {
        seasonBaseMultiplier(rankIndex: 1, prestigeCount: currentPrestigeCount + 1)
    }

    func allRanks() -> [Rank] {
        (1...50).map { rank(at: $0) }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
