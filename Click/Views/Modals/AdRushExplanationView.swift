import SwiftUI

struct AdRushExplanationView: View {
    let onConfirm: () -> Void
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
                                colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Ad Rush")
                    .font(.custom("Roboto-Bold", size: 28))
                    .foregroundColor(.white)

                Text("Watch a short ad to get a 2x tap multiplier for 30 seconds!")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Watch Ad")
                            .font(.custom("Roboto-Bold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }

                Button {
                    onDecline()
                    dismiss()
                } label: {
                    Text("Not Now")
                        .font(Typography.button)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
