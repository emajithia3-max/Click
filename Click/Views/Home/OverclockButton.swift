import SwiftUI

struct OverclockButton: View {
    let count: Int
    let isAvailable: Bool
    let cooldownText: String
    let activeBoost: ActiveBoost?
    let action: () -> Void

    private var isActive: Bool {
        activeBoost != nil
    }

    private var isOnCooldown: Bool {
        !cooldownText.isEmpty && cooldownText != "0s" && !isActive
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .scaleEffect(1.2)
                            .opacity(0.5)
                    }

                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isActive ? [.orange, .red] : [.orange.opacity(0.7), .red.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    if isActive, let boost = activeBoost {
                        Text("x\(Int(boost.multiplier))")
                            .font(.custom("Roboto-Bold", size: 14))
                            .foregroundColor(.white)
                        Text(boost.remainingTimeFormatted)
                            .font(.custom("Roboto-Regular", size: 10))
                            .foregroundColor(.orange)
                    } else if isOnCooldown {
                        Text("Overclock")
                            .font(.custom("Roboto-Bold", size: 12))
                            .foregroundColor(.secondary)
                        Text(cooldownText)
                            .font(.custom("Roboto-Regular", size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Overclock")
                            .font(.custom("Roboto-Bold", size: 12))
                            .foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text("x\(count)")
                                .font(.custom("Roboto-Regular", size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isActive
                            ? LinearGradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Theme.cardBackground, Theme.cardBackground], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isActive ? Color.orange : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
        }
        .disabled(!isAvailable && !isActive)
        .opacity(isAvailable || isActive ? 1 : 0.6)
    }
}
