import SwiftUI

struct ConsentSheet: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                iconSection

                titleSection

                nameInput

                privacyInfo

                Spacer()

                actionButtons
            }
            .padding()
            .navigationTitle("World Rank")
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

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)

            Image(systemName: "globe")
                .font(.system(size: 40))
                .foregroundColor(.blue)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Join the Leaderboard")
                .font(Typography.h2)
                .foregroundColor(.primary)

            Text("See your rank among all players worldwide")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var nameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name (optional)")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            TextField("Anonymous", text: $viewModel.displayName)
                .textFieldStyle(.roundedBorder)
                .font(Typography.body)

            Text("Leave blank to appear as 'Anonymous'")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
    }

    private var privacyInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What we share:", systemImage: "info.circle.fill")
                .font(Typography.body)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 8) {
                infoItem("Your display name (or Anonymous)")
                infoItem("Your tap count")
                infoItem("Your current rank")
            }
            .padding(.leading)

            Text("You can opt out anytime in settings")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            Button {
            } label: {
                Text("View Privacy Policy")
                    .font(Typography.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private func infoItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text(text)
                .font(Typography.caption)
                .foregroundColor(.primary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.confirmOptIn()
            } label: {
                Text("Enable World Rank")
                    .font(Typography.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.gradient)
                    )
            }

            Button {
                dismiss()
            } label: {
                Text("Not Now")
                    .font(Typography.button)
                    .foregroundColor(.secondary)
            }
        }
    }
}
