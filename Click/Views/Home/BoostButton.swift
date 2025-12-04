import SwiftUI

struct BoostButton: View {
    let type: BoostType
    let isAvailable: Bool
    let cooldownText: String
    let activeBoost: ActiveBoost?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16, weight: .semibold))

                if let boost = activeBoost, boost.isActive {
                    Text(boost.remainingTimeFormatted)
                        .font(Typography.button)
                } else if !isAvailable && !cooldownText.isEmpty {
                    Text(cooldownText)
                        .font(Typography.button)
                } else {
                    Text(type.displayName)
                        .font(Typography.button)
                }
            }
            .foregroundColor(buttonForegroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(buttonBackground)
        }
        .disabled(!isAvailable && activeBoost == nil)
    }

    private var buttonForegroundColor: Color {
        if let boost = activeBoost, boost.isActive {
            return .white
        }
        return isAvailable ? .white : .secondary
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if let boost = activeBoost, boost.isActive {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    GeometryReader { geometry in
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: geometry.size.width * boost.progress)
                    }
                )
        } else if isAvailable {
            Capsule()
                .fill(Color.blue.gradient)
        } else {
            Capsule()
                .fill(Color(.systemGray4))
        }
    }
}
