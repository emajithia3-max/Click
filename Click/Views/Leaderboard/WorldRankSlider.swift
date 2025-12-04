import SwiftUI

struct WorldRankSlider: View {
    let state: WorldRankState

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)

                    markerView
                        .position(
                            x: markerPosition(in: geometry.size.width),
                            y: 4
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: state.sliderPosition)
                }
            }
            .frame(height: 24)

            HStack {
                Text("#1")
                    .font(Typography.caption)
                    .foregroundColor(.green)

                Spacer()

                Text(state.rankDisplayText)
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundColor(.blue)

                Spacer()

                Text("\(NumberFormatService.shared.format(Double(state.totalPlayers))) players")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var markerView: some View {
        VStack(spacing: 2) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(.blue)

            Circle()
                .fill(Color.blue)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                )
                .shadow(color: .blue.opacity(0.4), radius: 4)
        }
    }

    private func markerPosition(in width: CGFloat) -> CGFloat {
        let padding: CGFloat = 16
        let usableWidth = width - (padding * 2)
        let position = padding + (usableWidth * CGFloat(1.0 - state.sliderPosition))
        return min(max(position, padding), width - padding)
    }
}
