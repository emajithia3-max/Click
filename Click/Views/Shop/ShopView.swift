import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    coinsHeader

                    ForEach(viewModel.shopItems, id: \.id) { item in
                        ShopItemCard(
                            item: item,
                            currentLevel: viewModel.levelFor(item),
                            price: viewModel.priceFor(item),
                            canAfford: viewModel.canAfford(item),
                            isMaxLevel: viewModel.isMaxLevel(item),
                            currentEffect: viewModel.currentEffect(item),
                            nextEffect: viewModel.nextEffect(item)
                        ) {
                            viewModel.purchase(item)
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Shop")
            .overlay(alignment: .bottom) {
                if RemoteConfigService.shared.admobRewardedEnabled {
                    AdaptiveBannerAdView()
                        .frame(height: 50)
                        .padding(.bottom, 8)
                }
            }
            .overlay {
                if viewModel.showPurchaseResult {
                    purchaseResultOverlay
                }
            }
        }
    }

    private var coinsHeader: some View {
        HStack {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Coins")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                Text(NumberFormatService.shared.formatCoins(viewModel.coins))
                    .font(Typography.h1)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .glassyBackground()
    }

    private var purchaseResultOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: viewModel.purchaseSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.purchaseSuccess ? .green : .red)

                Text(viewModel.purchaseResultMessage)
                    .font(Typography.body)
            }
            .padding()
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
                    .shadow(radius: 10)
            )
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: viewModel.showPurchaseResult)
    }
}
