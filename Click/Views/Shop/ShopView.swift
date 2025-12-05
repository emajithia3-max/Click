import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                coinsHeader
                    .padding()

                categoryPicker
                    .padding(.horizontal)

                tabContent
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Shop")
            .overlay {
                if viewModel.showPurchaseResult {
                    purchaseResultOverlay
                }
            }
            .sheet(isPresented: $viewModel.showAdConsent) {
                AdConsentView(
                    onAccept: { viewModel.onAdConsentComplete() },
                    onDecline: { viewModel.onAdConsentComplete() }
                )
                .presentationDetents([.height(450)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var coinsHeader: some View {
        HStack {
            CoinIcon(size: 32)

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

    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(ShopCategory.allCases) { category in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))

                        Text(category.rawValue)
                            .font(.custom("Roboto-Medium", size: 13))
                    }
                    .foregroundColor(viewModel.selectedCategory == category ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedCategory == category ? Theme.accentGradient : LinearGradient(colors: [Theme.cardBackground], startPoint: .leading, endPoint: .trailing))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(viewModel.selectedCategory == category ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                switch viewModel.selectedCategory {
                case .upgrades:
                    upgradesContent

                case .boosts:
                    boostsContent

                case .adRewards:
                    adRewardsContent
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    private var upgradesContent: some View {
        ForEach(viewModel.upgradeItems, id: \.id) { item in
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
    }

    private var boostsContent: some View {
        ForEach(viewModel.boostItems, id: \.id) { item in
            BoostPackCard(
                item: item,
                inventoryCount: viewModel.inventoryForItem(item),
                canAfford: viewModel.canAfford(item)
            ) {
                viewModel.purchase(item)
            }
        }
    }

    private var adRewardsContent: some View {
        VStack(spacing: 12) {
            adRewardsHeader

            ForEach(viewModel.adRewardItems) { item in
                AdRewardCard(
                    item: item,
                    canClaim: viewModel.canClaimAdReward(item),
                    cooldownText: viewModel.cooldownRemaining(item)
                ) {
                    viewModel.claimAdReward(item)
                }
            }
        }
    }

    private var adRewardsHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Watch ads for free rewards!")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
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

// MARK: - Boost Pack Card

struct BoostPackCard: View {
    let item: ShopItem
    let inventoryCount: Int
    let canAfford: Bool
    let onPurchase: () -> Void

    private var boostType: BoostType? {
        BoostType(rawValue: item.id)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if let boost = boostType {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [boost.iconColors.primary, boost.iconColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: boost.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(Typography.h2)
                        .foregroundColor(.primary)

                    Text(item.description)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                inventoryBadge
            }

            Divider()

            if let boost = boostType {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(boost.durationSeconds))s")
                            .font(Typography.body)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Cooldown")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(boost.cooldownSeconds / 60))m")
                            .font(Typography.body)
                            .foregroundColor(.primary)
                    }
                }
            }

            purchaseButton
        }
        .padding()
        .glassyBackground()
    }

    private var inventoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bag.fill")
                .font(.system(size: 12))
            Text("\(inventoryCount)")
                .font(.custom("Roboto-Bold", size: 14))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.accentGradient)
        )
    }

    private var purchaseButton: some View {
        Button(action: onPurchase) {
            HStack {
                CoinIcon(size: 16)
                Text(NumberFormatService.shared.formatCoins(item.basePrice))
                    .font(Typography.button)
            }
            .foregroundColor(canAfford ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canAfford ? Theme.accentGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
            )
        }
        .disabled(!canAfford)
    }
}

// MARK: - Ad Reward Card

struct AdRewardCard: View {
    let item: AdRewardItem
    let canClaim: Bool
    let cooldownText: String
    let onClaim: () -> Void

    private var iconColor: LinearGradient {
        switch item.rewardType {
        case .coins:
            return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .boost(let type):
            return LinearGradient(colors: [type.iconColors.primary, type.iconColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .multiplier:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 48, height: 48)

                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(Typography.h2)
                    .foregroundColor(.primary)

                Text(item.description)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            claimButton
        }
        .padding()
        .glassyBackground()
    }

    private var claimButton: some View {
        Button(action: onClaim) {
            if canClaim {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Watch")
                        .font(.custom("Roboto-Bold", size: 13))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            } else {
                Text(cooldownText.isEmpty ? "Loading..." : cooldownText)
                    .font(.custom("Roboto-Medium", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
            }
        }
        .disabled(!canClaim)
    }
}
