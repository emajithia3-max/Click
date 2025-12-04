import SwiftUI

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(highlight ? .orange : .secondary)

            Text(value)
                .font(.custom("Roboto-Bold", size: 17))
                .foregroundColor(highlight ? .orange : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
