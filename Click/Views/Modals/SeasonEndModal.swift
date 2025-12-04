import SwiftUI

struct SeasonEndModal: View {
    @EnvironmentObject var gameState: GameStateService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                iconSection

                titleSection

                statsSection

                nextSeasonPreview

                Spacer()

                continueButton
            }
            .padding()
            .navigationTitle("Season Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Season Complete!")
                .font(Typography.h1)
                .foregroundColor(.primary)

            Text(SeasonService.shared.seasonName)
                .font(Typography.h2)
                .foregroundColor(.secondary)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(Typography.h2)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                statItem(
                    title: "Final Rank",
                    value: gameState.currentRank.displayName,
                    icon: "medal.fill"
                )

                statItem(
                    title: "Total Taps",
                    value: NumberFormatService.shared.formatTaps(gameState.seasonData?.currentSeasonTaps ?? 0),
                    icon: "hand.tap.fill"
                )

                statItem(
                    title: "Prestiges",
                    value: "\(gameState.seasonData?.prestigeCount ?? 0)",
                    icon: "star.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.orange)

            Text(value)
                .font(.custom("Roboto-Bold", size: 17))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var nextSeasonPreview: some View {
        VStack(spacing: 8) {
            Text("Coming Next")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            Text("Season 2")
                .font(Typography.h2)
                .foregroundColor(.primary)

            Text(RemoteConfigService.shared.whatsNewText)
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var continueButton: some View {
        Button {
            Task {
                if let uid = AuthService.shared.uid,
                   let seasonData = gameState.seasonData {
                    try? await SeasonService.shared.handleSeasonRollover(uid: uid, currentSeasonData: seasonData)
                }
            }
            dismiss()
        } label: {
            Text("Start New Season")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.gradient)
                )
        }
    }
}
