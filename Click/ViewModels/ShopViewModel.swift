import Foundation
import Combine

final class ShopViewModel: ObservableObject {
    @Published var showPurchaseResult = false
    @Published var purchaseResultMessage = ""
    @Published var purchaseSuccess = false

    private var cancellables = Set<AnyCancellable>()
    private let gameState = GameStateService.shared

    init() {
        setupBindings()
    }

    private func setupBindings() {
        gameState.$seasonData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var coins: Double {
        gameState.seasonData?.coins ?? 0
    }

    var clickMultiplierLevel: Int {
        gameState.seasonData?.clickMultiplierLevel ?? 1
    }

    var offlineMultiplierLevel: Int {
        gameState.seasonData?.offlineMultiplierLevel ?? 1
    }

    var overclockCount: Int {
        gameState.boostState.inventory[.overclock] ?? 0
    }

    var tapsPerSecondLevel: Int {
        gameState.seasonData?.tapsPerSecondLevel ?? 0
    }

    var shopItems: [ShopItem] {
        ShopItem.allItems
    }

    func levelFor(_ item: ShopItem) -> Int {
        switch item.type {
        case .clickMultiplier:
            return clickMultiplierLevel
        case .offlineMultiplier:
            return offlineMultiplierLevel
        case .tapsPerSecond:
            return tapsPerSecondLevel
        case .boostConsumable:
            return overclockCount
        case .cosmetic:
            return 0
        }
    }

    func priceFor(_ item: ShopItem) -> Double {
        switch item.type {
        case .boostConsumable:
            return item.basePrice
        default:
            return EconomyService.shared.priceForUpgrade(item, currentLevel: levelFor(item))
        }
    }

    func canAfford(_ item: ShopItem) -> Bool {
        switch item.type {
        case .boostConsumable:
            return coins >= item.basePrice
        default:
            return EconomyService.shared.canAfford(item, currentLevel: levelFor(item), coins: coins)
        }
    }

    func isMaxLevel(_ item: ShopItem) -> Bool {
        switch item.type {
        case .boostConsumable:
            return false
        default:
            return levelFor(item) >= item.maxLevel
        }
    }

    func currentEffect(_ item: ShopItem) -> String {
        EconomyService.shared.effectDescription(item, level: levelFor(item))
    }

    func nextEffect(_ item: ShopItem) -> String {
        EconomyService.shared.nextEffectDescription(item, currentLevel: levelFor(item))
    }

    func purchase(_ item: ShopItem) {
        let success = gameState.purchaseUpgrade(item)

        purchaseSuccess = success
        purchaseResultMessage = success ? "Upgrade purchased!" : "Not enough coins"
        showPurchaseResult = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showPurchaseResult = false
        }
    }
}
