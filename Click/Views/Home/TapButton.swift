import SwiftUI

struct TapButton: View {
    let scale: CGFloat
    let tierColor: Color
    let hasGlow: Bool
    let glowIntensity: Double
    let onTap: (CGPoint) -> Void

    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if hasGlow {
                    Circle()
                        .fill(tierColor.opacity(glowIntensity * 0.3))
                        .blur(radius: 30)
                        .scaleEffect(1.3)
                }

                Circle()
                    .fill(tierColor.opacity(rippleOpacity * 0.3))
                    .scaleEffect(rippleScale)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                tierColor.opacity(0.9),
                                tierColor
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: geometry.size.width
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(tierColor.opacity(0.5), lineWidth: 4)
                    )
                    .shadow(color: tierColor.opacity(0.4), radius: 20, x: 0, y: 10)

                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: geometry.size.width * 0.25))
                        .foregroundColor(.white)

                    Text("TAP")
                        .font(.custom("Roboto-Bold", size: geometry.size.width * 0.12))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .scaleEffect(scale)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        onTap(location)
                        triggerRipple()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func triggerRipple() {
        rippleScale = 0.8
        rippleOpacity = 0.6

        withAnimation(.easeOut(duration: 0.4)) {
            rippleScale = 1.5
            rippleOpacity = 0
        }
    }
}
