import SwiftUI

struct FloatingTapLabel: View {
    let value: Double

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text("+\(NumberFormatService.shared.formatTaps(value))")
            .font(.custom("Roboto-Bold", size: 24))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = -60
                    opacity = 0
                }
            }
    }
}
