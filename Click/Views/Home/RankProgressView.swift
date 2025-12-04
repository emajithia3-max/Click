import SwiftUI

struct RankProgressView: View {
    let progress: Double
    let currentRank: Rank
    let prestigeCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(currentRank.displayName)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if currentRank.index < 50 {
                    let nextRank = RankSystem().rank(at: currentRank.index + 1)
                    Text(nextRank.displayName)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("MAX")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.cardStroke, lineWidth: 1)
                        )

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.lilac,
                                    currentRank.tierColor
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                        .animation(.spring(response: 0.3), value: progress)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(Int(progress * 100))%")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if prestigeCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("Prestige \(prestigeCount)")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
