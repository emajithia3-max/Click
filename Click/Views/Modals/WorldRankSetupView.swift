import SwiftUI

struct WorldRankSetupView: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        heroSection

                        nameInputSection

                        privacySection

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("Join the")
                    .font(Typography.h2)
                    .foregroundColor(.secondary)

                Text("WORLD RANK")
                    .font(.custom("Roboto-Bold", size: 36))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("Compete against players worldwide and see where you stand on the global leaderboard")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 40)
    }

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Display Name")
                .font(Typography.h2)
                .foregroundColor(.white)

            TextField("Enter your name", text: $viewModel.displayName)
                .textFieldStyle(.plain)
                .font(.custom("Roboto-Regular", size: 18))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

            Text("This is how other players will see you on the leaderboard. Leave blank to appear as 'Anonymous'.")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .glassyBackground()
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What we share", systemImage: "shield.checkered")
                .font(Typography.h2)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                privacyItem("Your display name (or Anonymous)", icon: "person.fill")
                privacyItem("Your current tap count", icon: "hand.tap.fill")
                privacyItem("Your rank tier", icon: "trophy.fill")
            }

            Divider()
                .background(Color.white.opacity(0.2))

            Text("You can opt out anytime from the settings. Your data will be removed from the leaderboard immediately.")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .glassyBackground()
    }

    private func privacyItem(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24)

            Text(text)
                .font(Typography.body)
                .foregroundColor(.primary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.confirmOptIn()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Join World Rank")
                        .font(.custom("Roboto-Bold", size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }

            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(Typography.button)
                    .foregroundColor(.secondary)
            }
        }
    }
}
