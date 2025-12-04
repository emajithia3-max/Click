import SwiftUI

struct PrestigePanel: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    multiplierPreview

                    resetWarning
                }
                .padding()
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("Prestige")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.25))
                    .frame(width: 80, height: 80)

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.lilac)
            }

            Text("Ready to Prestige?")
                .font(Typography.h2)
                .foregroundColor(.primary)

            Text("Reset progress for a permanent boost")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
    }

    private var multiplierPreview: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Current")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                Text(NumberFormatService.shared.formatMultiplier(viewModel.seasonMultiplier))
                    .font(Typography.h2)
                    .foregroundColor(.primary)
            }

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.purple)

            VStack(spacing: 4) {
                Text("New")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                Text(NumberFormatService.shared.formatMultiplier(viewModel.projectedMultiplierAfterPrestige()))
                    .font(Typography.h2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .glassyBackground(cornerRadius: 14)
    }

    private var resetWarning: some View {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.lilac)

                Text("Taps, coins, and upgrades will reset")
                    .font(Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.prestige()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Prestige Now")
                }
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
                Text("Keep Playing")
                    .font(Typography.button)
                    .foregroundColor(.secondary)
            }
        }
    }
}
