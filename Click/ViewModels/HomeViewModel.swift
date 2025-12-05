import Foundation
import Combine
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var floatingLabels: [FloatingLabel] = []
    @Published var tapScale: CGFloat = 1.0
    @Published var showPrestigePanel = false
    @Published var prestigePopupDismissed = false
    @Published var showAdRushExplanation = false
    @Published var showAdConsent = false
    private var pendingAdRushAfterConsent = false

    private var cancellables = Set<AnyCancellable>()
    private let gameState = GameStateService.shared
    private var previousCanPrestige = false
    private static let hasSeenAdRushKey = "hasSeenAdRushExplanation"
    private var autoTapTimer: Timer?
    var autoTapCenterPosition: CGPoint = .zero

    var hasSeenAdRushExplanation: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasSeenAdRushKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasSeenAdRushKey) }
    }

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

    deinit {
        autoTapTimer?.invalidate()
    }

    private func setupBindings() {
        gameState.$seasonData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.checkPrestigeAvailability()
                self?.updateAutoTapTimer()
            }
            .store(in: &cancellables)

        gameState.$boostState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        SeasonService.shared.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func updateAutoTapTimer() {
        autoTapTimer?.invalidate()
        autoTapTimer = nil

        guard tapsPerSecond > 0 else { return }

        let interval = 1.0 / max(tapsPerSecond, 1.0)
        autoTapTimer = Timer.scheduledTimer(withTimeInterval: min(interval, 0.2), repeats: true) { [weak self] _ in
            self?.showAutoTapLabel()
        }
    }

    private func showAutoTapLabel() {
        guard autoTapCenterPosition != .zero else { return }

        let value = tapValue / max(tapsPerSecond, 1.0)
        let randomOffset = CGFloat.random(in: -60...60)
        let position = CGPoint(
            x: autoTapCenterPosition.x + randomOffset,
            y: autoTapCenterPosition.y - 80 + CGFloat.random(in: -40...40)
        )

        let label = FloatingLabel(value: value, position: position)
        floatingLabels.append(label)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.floatingLabels.removeAll { $0.id == label.id }
        }
    }

    private func checkPrestigeAvailability() {
        let currentCanPrestige = canPrestige
        if currentCanPrestige && !previousCanPrestige && !prestigePopupDismissed {
            showPrestigePanel = true
        }
        previousCanPrestige = currentCanPrestige
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

    var shouldShowPrestigeButton: Bool {
        canPrestige && prestigePopupDismissed
    }

    func dismissPrestigePopup() {
        prestigePopupDismissed = true
        showPrestigePanel = false
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

    var tapsPerSecond: Double {
        gameState.tapsPerSecond
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

    func onAdRushTapped() {
        if !SettingsManager.shared.hasSeenAdConsent {
            pendingAdRushAfterConsent = true
            showAdConsent = true
        } else if !hasSeenAdRushExplanation {
            showAdRushExplanation = true
        } else {
            activateAdRush()
        }
    }

    func onAdConsentComplete() {
        showAdConsent = false
        if pendingAdRushAfterConsent {
            pendingAdRushAfterConsent = false
            if !hasSeenAdRushExplanation {
                showAdRushExplanation = true
            } else {
                activateAdRush()
            }
        }
    }

    func confirmAdRush() {
        hasSeenAdRushExplanation = true
        showAdRushExplanation = false
        activateAdRush()
    }

    func declineAdRush() {
        hasSeenAdRushExplanation = true
        showAdRushExplanation = false
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
        prestigePopupDismissed = false
        previousCanPrestige = false
    }

    func projectedMultiplierAfterPrestige() -> Double {
        let rankSystem = gameState.rankSystem
        return rankSystem.projectedMultiplier(
            afterPrestige: prestigeCount,
            currentRankIndex: currentRank.index
        )
    }
}
