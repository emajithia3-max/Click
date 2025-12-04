import SwiftUI

struct OfflineEarningsModal: View {
    @EnvironmentObject var gameState: GameStateService
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAd = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                iconSection

                titleSection

                earningsCard

                Spacer()

                actionButtons
            }
            .padding()
            .navigationTitle("Welcome Back!")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: "moon.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Offline Earnings")
                .font(Typography.h1)
                .foregroundColor(.primary)

            if let earnings = gameState.pendingOfflineEarnings {
                Text("You were away for \(NumberFormatService.shared.formatDuration(earnings.elapsedSeconds))")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var earningsCard: some View {
        VStack(spacing: 16) {
            if let earnings = gameState.pendingOfflineEarnings {
                HStack {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)

                    Text(NumberFormatService.shared.formatCoins(earnings.baseCoins))
                        .font(Typography.counter)
                        .foregroundColor(.primary)

                    Text("coins")
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                }

                if earnings.wasAtCap {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Capped at 8 hours - come back sooner!")
                            .font(Typography.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if AdService.shared.canShowRewardedAd(), let earnings = gameState.pendingOfflineEarnings {
                Button {
                    showRewardedAd()
                } label: {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("Watch Ad for x2 (\(NumberFormatService.shared.formatCoins(earnings.doubledCoins)))")
                    }
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.gradient)
                    )
                }
            }

            Button {
                gameState.claimOfflineEarnings(doubled: false)
                dismiss()
            } label: {
                Text("Claim")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.gradient)
                    )
            }
        }
    }

    private func showRewardedAd() {
        isShowingAd = true
        AdService.shared.showRewardedAd { success in
            isShowingAd = false
            if success {
                gameState.claimOfflineEarnings(doubled: true)
                dismiss()
            }
        }
    }
}
