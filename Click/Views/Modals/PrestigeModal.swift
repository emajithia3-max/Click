import SwiftUI

struct PrestigeModal: View {
    @EnvironmentObject var gameState: GameStateService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                prestigeIcon

                titleSection

                multiplierSection

                warningSection

                Spacer()

                buttonSection
            }
            .padding()
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Prestige")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var prestigeIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 100, height: 100)

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Prestige Now?")
                .font(Typography.h1)
                .foregroundColor(.primary)

            Text("Reset your progress for a permanent multiplier boost")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var multiplierSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(spacing: 4) {
                    Text("Current")
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(NumberFormatService.shared.formatMultiplier(
                        gameState.seasonData?.seasonBaseMultiplier ?? 1.0
                    ))
                    .font(Typography.h2)
                    .foregroundColor(.white)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.lilac)
                    .padding(.horizontal)

                VStack(spacing: 4) {
                    Text("After Prestige")
                        .font(Typography.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(NumberFormatService.shared.formatMultiplier(
                        projectedMultiplier
                    ))
                    .font(Typography.h2)
                    .foregroundColor(Theme.lilac)
                }
            }
            .padding()
            .glassyBackground(cornerRadius: 14)

            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.lilac)
                Text("Prestige \((gameState.seasonData?.prestigeCount ?? 0) + 1)")
                    .font(Typography.body)
                    .foregroundColor(.white)
            }
        }
    }

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What will reset:", systemImage: "exclamationmark.triangle.fill")
                .font(Typography.body)
                .foregroundColor(Theme.lilac)

            VStack(alignment: .leading, spacing: 4) {
                resetItem("Current season taps")
                resetItem("All coins")
                resetItem("Shop upgrades")
                resetItem("Boost inventory")
            }
            .padding(.leading)
        }
        .padding()
        .glassyBackground(cornerRadius: 14)
    }

    private func resetItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.lilac)
            Text(text)
                .font(Typography.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button {
                gameState.prestige()
                dismiss()
            } label: {
                Text("Confirm Prestige")
                    .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accentGradient)
                )
            }

            Button {
                dismiss()
            } label: {
                Text("Not Yet")
                    .font(Typography.button)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var projectedMultiplier: Double {
        let rankSystem = gameState.rankSystem
        return rankSystem.projectedMultiplier(
            afterPrestige: gameState.seasonData?.prestigeCount ?? 0,
            currentRankIndex: gameState.seasonData?.rankIndex ?? 1
        )
    }
}
