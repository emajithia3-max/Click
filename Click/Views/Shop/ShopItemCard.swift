import SwiftUI

struct ShopItemCard: View {
    let item: ShopItem
    let currentLevel: Int
    let price: Double
    let canAfford: Bool
    let isMaxLevel: Bool
    let currentEffect: String
    let nextEffect: String
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(Typography.h2)
                        .foregroundColor(.primary)

                    Text(item.description)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                levelBadge
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)

                    Text(currentEffect)
                        .font(Typography.body)
                        .foregroundColor(.primary)
                }

                Spacer()

                if !isMaxLevel {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text(nextEffect)
                            .font(Typography.body)
                            .foregroundColor(.green)
                    }
                }
            }

            purchaseButton
        }
        .padding()
        .glassyBackground()
    }

    private var levelBadge: some View {
        Group {
            if item.type == .boostConsumable {
                HStack(spacing: 4) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 12))
                    Text("\(currentLevel)")
                        .font(.custom("Roboto-Bold", size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.accentGradient)
                )
            } else {
                Text("Lv. \(currentLevel)")
                    .font(.custom("Roboto-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Theme.accentGradient)
                    )
            }
        }
    }

    private var purchaseButton: some View {
        Button(action: onPurchase) {
            HStack {
                if isMaxLevel {
                    Text("Max Level")
                        .font(Typography.button)
                } else {
                    CoinIcon(size: 16)
                    Text(NumberFormatService.shared.formatCoins(price))
                        .font(Typography.button)
                }
            }
            .foregroundColor(buttonForegroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.cardStroke, lineWidth: canAfford ? 0 : 1)
                    )
            )
        }
        .disabled(isMaxLevel || !canAfford)
    }

    private var buttonForegroundColor: Color {
        if isMaxLevel {
            return .secondary
        }
        return canAfford ? .white : .secondary
    }

    private var buttonBackgroundColor: LinearGradient {
        if isMaxLevel {
            return LinearGradient(colors: [Color(.systemGray5)], startPoint: .leading, endPoint: .trailing)
        }
        return canAfford ? Theme.accentGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
    }
}
