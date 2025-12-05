import Foundation
import SwiftUI

struct Rank: Identifiable, Equatable {
    var id: Int { index }
    let index: Int
    let tier: Int
    let threshold: Double

    static let tierNames: [String] = [
        // Tier 1-10: Basic Metals
        "Copper", "Bronze", "Iron", "Steel", "Silver",
        "Gold", "Platinum", "Titanium", "Chrome", "Cobalt",
        // Tier 11-20: Gems
        "Amber", "Jade", "Topaz", "Amethyst", "Emerald",
        "Sapphire", "Ruby", "Diamond", "Opal", "Onyx",
        // Tier 21-30: Elements
        "Crystal", "Prism", "Aurora", "Nebula", "Eclipse",
        "Meteor", "Comet", "Quasar", "Pulsar", "Nova",
        // Tier 31-40: Celestial
        "Lunar", "Solar", "Stellar", "Astral", "Cosmic",
        "Ethereal", "Phantom", "Spectral", "Void", "Abyss",
        // Tier 41-50: Legendary
        "Mythic", "Divine", "Immortal", "Eternal", "Infinite",
        "Omega", "Supreme", "Transcendent", "Apex", "Ultimate"
    ]

    static let tierColors: [Color] = [
        // Tier 1-10: Basic Metals
        Color(hex: "B87333"),  // Copper
        Color(hex: "CD7F32"),  // Bronze
        Color(hex: "71797E"),  // Iron
        Color(hex: "8B939C"),  // Steel
        Color(hex: "C0C0C0"),  // Silver
        Color(hex: "FFD700"),  // Gold
        Color(hex: "E5E4E2"),  // Platinum
        Color(hex: "878681"),  // Titanium
        Color(hex: "DBE0E6"),  // Chrome
        Color(hex: "0047AB"),  // Cobalt
        // Tier 11-20: Gems
        Color(hex: "FFBF00"),  // Amber
        Color(hex: "00A86B"),  // Jade
        Color(hex: "FFC87C"),  // Topaz
        Color(hex: "9966CC"),  // Amethyst
        Color(hex: "50C878"),  // Emerald
        Color(hex: "0F52BA"),  // Sapphire
        Color(hex: "E0115F"),  // Ruby
        Color(hex: "B9F2FF"),  // Diamond
        Color(hex: "A8C3BC"),  // Opal
        Color(hex: "353839"),  // Onyx
        // Tier 21-30: Elements
        Color(hex: "A7D8DE"),  // Crystal
        Color(hex: "FF6FFF"),  // Prism
        Color(hex: "78D8A8"),  // Aurora
        Color(hex: "6B5B95"),  // Nebula
        Color(hex: "3D2B56"),  // Eclipse
        Color(hex: "FF5733"),  // Meteor
        Color(hex: "2EC4B6"),  // Comet
        Color(hex: "7B68EE"),  // Quasar
        Color(hex: "00FFFF"),  // Pulsar
        Color(hex: "FF4500"),  // Nova
        // Tier 31-40: Celestial
        Color(hex: "C4C3D0"),  // Lunar
        Color(hex: "FDB813"),  // Solar
        Color(hex: "E6E6FA"),  // Stellar
        Color(hex: "7851A9"),  // Astral
        Color(hex: "9D4EDD"),  // Cosmic
        Color(hex: "B388FF"),  // Ethereal
        Color(hex: "8E8CD8"),  // Phantom
        Color(hex: "4FC3F7"),  // Spectral
        Color(hex: "1A1A2E"),  // Void
        Color(hex: "0D0221"),  // Abyss
        // Tier 41-50: Legendary
        Color(hex: "FF69B4"),  // Mythic
        Color(hex: "FFD700"),  // Divine
        Color(hex: "E6B422"),  // Immortal
        Color(hex: "00FFCC"),  // Eternal
        Color(hex: "FF00FF"),  // Infinite
        Color(hex: "FF2400"),  // Omega
        Color(hex: "FFD700"),  // Supreme
        Color(hex: "E0B0FF"),  // Transcendent
        Color(hex: "FFFFFF"),  // Apex
        Color(hex: "FFE4B5")   // Ultimate
    ]

    static let maxTier = 50

    var tierName: String {
        Rank.tierNames[tier - 1]
    }

    var displayName: String {
        tierName
    }

    var shortName: String {
        String(tierName.prefix(3)).uppercased()
    }

    var tierColor: Color {
        Rank.tierColors[tier - 1]
    }

    var hasGlow: Bool {
        tier >= 21
    }

    var glowIntensity: Double {
        guard hasGlow else { return 0 }
        return min(1.0, Double(tier - 20) * 0.035)
    }

    static func fromIndex(_ index: Int) -> Int {
        max(1, min(Rank.maxTier, index))
    }
}

struct RankSystem {
    let coefficients: SeasonCoefficients
    private var rankCache: [Int: Rank] = [:]

    init(coefficients: SeasonCoefficients = SeasonCoefficients()) {
        self.coefficients = coefficients
    }

    func threshold(for rankIndex: Int) -> Double {
        let index = max(1, min(Rank.maxTier, rankIndex))
        return coefficients.baseThreshold * pow(coefficients.rankGrowthB, Double(index - 1))
    }

    func rank(at index: Int) -> Rank {
        let clampedIndex = max(1, min(Rank.maxTier, index))
        let tier = Rank.fromIndex(clampedIndex)
        return Rank(
            index: clampedIndex,
            tier: tier,
            threshold: threshold(for: clampedIndex)
        )
    }

    func currentRank(taps: Double, prestigeCount: Int) -> Rank {
        for index in (1...Rank.maxTier).reversed() {
            let thresh = threshold(for: index, prestigeCount: prestigeCount)
            if taps >= thresh {
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
        let nextThresh = currentRankIndex < Rank.maxTier ? threshold(for: currentRankIndex + 1, prestigeCount: prestigeCount) : threshold(for: Rank.maxTier, prestigeCount: prestigeCount)
        let range = nextThresh - currentThresh
        guard range > 0 else { return 1.0 }
        return min(1.0, max(0, (taps - currentThresh) / range))
    }

    func seasonBaseMultiplier(rankIndex: Int, prestigeCount: Int) -> Double {
        let rankBonus = 1.0 + (Double(rankIndex - 1) * 0.05)
        let prestigeBonus = prestigeCount > 0 ? pow(coefficients.prestigeGrowthA, Double(prestigeCount)) : 1.0
        return rankBonus * prestigeBonus
    }

    func projectedMultiplier(afterPrestige currentPrestigeCount: Int, currentRankIndex: Int) -> Double {
        seasonBaseMultiplier(rankIndex: 1, prestigeCount: currentPrestigeCount + 1)
    }

    func allRanks() -> [Rank] {
        (1...Rank.maxTier).map { rank(at: $0) }
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
