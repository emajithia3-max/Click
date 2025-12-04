import Foundation
import Combine

final class LeaderboardViewModel: ObservableObject {
    @Published var selectedTab: LeaderboardTab = .global
    @Published var leaderboardData: LeaderboardData = LeaderboardData()
    @Published var worldRankState: WorldRankState = WorldRankState()
    @Published var isLoading = true
    @Published var showConsentSheet = false
    @Published var displayName = ""
    @Published var seasonHistory: [SeasonHistory] = []

    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    private let gameState = GameStateService.shared

    init() {
        setupBindings()
    }

    private func setupBindings() {
        gameState.$userData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userData in
                self?.worldRankState.isEnabled = userData?.leaderboardOptIn ?? false
                self?.displayName = userData?.displayName ?? ""
            }
            .store(in: &cancellables)

        gameState.$seasonData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateWorldRank()
            }
            .store(in: &cancellables)
    }

    var isOptedIn: Bool {
        gameState.userData?.leaderboardOptIn ?? false
    }

    var worldRankEnabled: Bool {
        RemoteConfigService.shared.worldRankFeatureEnabled
    }

    var currentTaps: Double {
        gameState.seasonData?.currentSeasonTaps ?? 0
    }

    var currentRankIndex: Int {
        gameState.seasonData?.rankIndex ?? 1
    }

    var userEntry: LeaderboardEntry? {
        guard let uid = AuthService.shared.uid else { return nil }
        return leaderboardData.top.first { $0.odid == uid }
    }

    var userPosition: Int? {
        if let entry = userEntry {
            return entry.position
        }
        return leaderboardData.approximateRank(for: currentTaps)
    }

    func loadLeaderboard() async {
        isLoading = true
        let seasonId = SeasonService.shared.seasonId

        do {
            let data = try await FirestoreService.shared.fetchLeaderboard(seasonId: seasonId)
            await MainActor.run {
                self.leaderboardData = data
                self.updateWorldRank()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func loadSeasonHistory() async {
        guard let uid = AuthService.shared.uid else { return }

        do {
            let history = try await FirestoreService.shared.fetchSeasonHistory(uid: uid)
            await MainActor.run {
                self.seasonHistory = history
            }
        } catch {
        }
    }

    func startRealtimeUpdates() {
        guard worldRankEnabled && isOptedIn else { return }

        let interval = Double(RemoteConfigService.shared.worldRankUpdateIntervalMs) / 1000.0

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateWorldRank()
        }

        FirestoreService.shared.listenToLeaderboard(seasonId: SeasonService.shared.seasonId) { [weak self] data in
            self?.leaderboardData = data
            self?.updateWorldRank()
        }
    }

    func stopRealtimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateWorldRank() {
        guard worldRankEnabled && isOptedIn else { return }

        let previousPercentile = worldRankState.userPercentile
        let newPercentile = leaderboardData.percentile(for: currentTaps)

        let crossedThreshold = hasPercentileCrossed(from: previousPercentile, to: newPercentile)

        worldRankState = WorldRankState(
            isEnabled: true,
            userRank: userEntry?.position,
            userPercentile: newPercentile,
            totalPlayers: leaderboardData.totalPlayers
        )

        if crossedThreshold {
            HapticsService.shared.worldRankPercentileCross()
        } else if abs(newPercentile - previousPercentile) > 0.01 {
            HapticsService.shared.worldRankTick()
        }
    }

    private func hasPercentileCrossed(from: Double, to: Double) -> Bool {
        let thresholds = [0.01, 0.05, 0.10, 0.25, 0.50]
        for threshold in thresholds {
            let fromAbove = from >= threshold
            let toAbove = to >= threshold
            if fromAbove != toAbove {
                return true
            }
        }
        return false
    }

    func toggleOptIn() {
        if isOptedIn {
            Task {
                await setOptIn(false, displayName: nil)
            }
        } else {
            showConsentSheet = true
        }
    }

    func confirmOptIn() {
        Task {
            await setOptIn(true, displayName: displayName.isEmpty ? nil : displayName)
            await MainActor.run {
                self.showConsentSheet = false
                self.startRealtimeUpdates()
            }
        }
    }

    private func setOptIn(_ optIn: Bool, displayName: String?) async {
        guard let uid = AuthService.shared.uid else { return }

        do {
            try await FirestoreService.shared.updateLeaderboardOptIn(
                uid: uid,
                optIn: optIn,
                displayName: displayName
            )

            await MainActor.run {
                self.gameState.userData?.leaderboardOptIn = optIn
                if let name = displayName {
                    self.gameState.userData?.displayName = name
                }
                self.worldRankState.isEnabled = optIn
            }
        } catch {
        }
    }
}
