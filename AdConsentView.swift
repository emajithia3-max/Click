import SwiftUI

struct AdConsentView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Personalized Ads")
                    .font(.custom("Roboto-Bold", size: 28))
                    .foregroundColor(.white)

                Text("Can we show you ads based on your interests? This helps support the app while showing you more relevant content.")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    SettingsManager.shared.personalizedAdsEnabled = true
                    SettingsManager.shared.hasSeenAdConsent = true
                    onAccept()
                    dismiss()
                } label: {
                    Text("Yes, Personalize Ads")
                        .font(.custom("Roboto-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }

                Button {
                    SettingsManager.shared.personalizedAdsEnabled = false
                    SettingsManager.shared.hasSeenAdConsent = true
                    onDecline()
                    dismiss()
                } label: {
                    Text("No Thanks")
                        .font(Typography.button)
                        .foregroundColor(.secondary)
                }

                Text("You can change this anytime in Settings.")
                    .font(Typography.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
