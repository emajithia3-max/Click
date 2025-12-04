import Foundation
import Combine
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var floatingLabels: [FloatingLabel] = []
    @Published var tapScale: CGFloat = 1.0
    @Published var showPrestigePanel = false

    private var cancellables = Set<AnyCancellable>()
    private let gameState = GameStateService.shared

    struct FloatingLabel: Identifiable {
        let id = UUID()
        let value: Double
        let position: CGPoint
        var opacity: Double = 1.0
        var offset: CGFloat = 0
    }

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

        gameState.$boostState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var currentTaps: Double {
        gameState.seasonData?.currentSeasonTaps ?? 0
    }

    var lifetimeTaps: Double {
        (gameState.userData?.lifetimeTaps ?? 0) + currentTaps
    }

    var coins: Double {
        gameState.seasonData?.coins ?? 0
    }

    var tapValue: Double {
        gameState.tapValue
    }

    var seasonMultiplier: Double {
        gameState.seasonData?.seasonBaseMultiplier ?? 1.0
    }

    var currentRank: Rank {
        gameState.currentRank
    }

    var progressToNextRank: Double {
        gameState.progressToNextRank
    }

    var seasonName: String {
        SeasonService.shared.seasonName
    }

    var timeRemaining: String {
        SeasonService.shared.timeRemaining
    }

    var prestigeCount: Int {
        gameState.seasonData?.prestigeCount ?? 0
    }

    var canPrestige: Bool {
        gameState.canPrestige
    }

    var activeBoosts: [ActiveBoost] {
        gameState.boostState.activeBoosts.filter { $0.isActive }
    }

    var boostMultiplier: Double {
        gameState.boostState.totalMultiplier
    }

    var hasActiveBoost: Bool {
        !activeBoosts.isEmpty
    }

    func handleTap(at position: CGPoint) {
        let value = tapValue
        gameState.tap()

        withAnimation(.easeOut(duration: 0.1)) {
            tapScale = 0.95
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                self.tapScale = 1.0
            }
        }

        addFloatingLabel(value: value, at: position)
    }

    private func addFloatingLabel(value: Double, at position: CGPoint) {
        let label = FloatingLabel(
            value: value,
            position: CGPoint(
                x: position.x + CGFloat.random(in: -20...20),
                y: position.y - 30
            )
        )

        floatingLabels.append(label)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.floatingLabels.removeAll { $0.id == label.id }
        }
    }

    func activateAdRush() {
        guard AdService.shared.canShowRewardedAd() else { return }

        AdService.shared.showRewardedAd { [weak self] success in
            if success {
                _ = self?.gameState.activateBoost(.adRush)
            }
        }
    }

    func canActivateAdRush() -> Bool {
        !gameState.boostState.isOnCooldown(.adRush) &&
        !gameState.boostState.hasActiveBoost(.adRush) &&
        AdService.shared.canShowRewardedAd()
    }

    func adRushCooldownRemaining() -> String {
        gameState.boostState.cooldownRemainingFormatted(.adRush)
    }

    func prestige() {
        gameState.prestige()
        showPrestigePanel = false
    }

    func projectedMultiplierAfterPrestige() -> Double {
        let rankSystem = gameState.rankSystem
        return rankSystem.projectedMultiplier(
            afterPrestige: prestigeCount,
            currentRankIndex: currentRank.index
        )
    }
}
