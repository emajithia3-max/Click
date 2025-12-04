import SwiftUI

struct PrestigePanel: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                multiplierPreview

                resetWarning

                Spacer()

                actionButtons
            }
            .padding()
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
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var resetWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text("Taps, coins, and upgrades will reset")
                .font(Typography.caption)
                .foregroundColor(.secondary)
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
                        .fill(Color.purple.gradient)
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
