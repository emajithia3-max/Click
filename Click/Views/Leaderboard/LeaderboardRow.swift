import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            positionView

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayNameOrAnon)
                    .font(Typography.body)
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                    .lineLimit(1)

                Text(NumberFormatService.shared.formatTaps(entry.taps) + " taps")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            RankBadge(
                rank: RankSystem().rank(at: entry.rankIndex),
                size: .small
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isCurrentUser ? Color.blue.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }

    private var positionView: some View {
        Group {
            if entry.position <= 3 {
                medalView
            } else {
                Text("#\(entry.position)")
                    .font(.custom("Roboto-Bold", size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
    }

    private var medalView: some View {
        Image(systemName: "medal.fill")
            .font(.system(size: 24))
            .foregroundColor(medalColor)
            .frame(width: 40)
    }

    private var medalColor: Color {
        switch entry.position {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return Color(hex: "CD7F32")
        default: return .secondary
        }
    }
}
