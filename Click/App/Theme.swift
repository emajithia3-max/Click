import SwiftUI

enum Theme {
    static let deepPurple = Color(hex: "201634")
    static let night = Color(hex: "0F0A1A")
    static let lilac = Color(hex: "D4CCFF")
    static let accent = Color(hex: "9C8CFF")
    static let mutedAccent = Color(hex: "6E5DC6")
    static let cardBackground = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.12)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [deepPurple, night],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [lilac, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func glassyBackground(cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
                .shadow(color: Theme.accent.opacity(0.15), radius: 12, x: 0, y: 6)
        )
    }
}
