import SwiftUI

struct CoinIcon: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .strokeBorder(Color(hex: "DAA520"), lineWidth: size * 0.08)
                .frame(width: size * 0.85, height: size * 0.85)

            Text("C")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "8B6914"))
        }
    }
}
