import SwiftUI

struct RankBadge: View {
    let rank: Rank
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 18
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 18
            }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if rank.tier >= 5 {
                Image(systemName: tierIcon)
                    .font(.system(size: size.iconSize, weight: .bold))
            }

            Text(rank.tierName)
                .font(.custom("Roboto-Bold", size: size.fontSize))
        }
        .foregroundColor(.white)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(
            Capsule()
                .fill(rank.tierColor.gradient)
                .shadow(color: rank.tierColor.opacity(rank.hasGlow ? 0.5 : 0.2), radius: rank.hasGlow ? 8 : 4)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var tierIcon: String {
        switch rank.tier {
        case 5: return "star.fill"
        case 6: return "star.circle.fill"
        case 7: return "sparkles"
        case 8: return "crown.fill"
        case 9: return "flame.fill"
        case 10: return "diamond.fill"
        default: return "circle.fill"
        }
    }
}
