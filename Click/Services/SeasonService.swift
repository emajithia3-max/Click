import Foundation
import Combine

final class SeasonService: ObservableObject {
    static let shared = SeasonService()

    @Published private(set) var currentSeason: Season?
    @Published private(set) var hasSeasonEnded = false

    private var timer: Timer?

    private init() {}

    func loadCurrentSeason() async {
        do {
            if let season = try await FirestoreService.shared.fetchActiveSeason() {
                await MainActor.run {
                    self.currentSeason = season
                    self.checkSeasonStatus()
                    self.startSeasonTimer()
                }
            } else {
                await MainActor.run {
                    self.currentSeason = self.createDefaultSeason()
                    self.startSeasonTimer()
                }
            }
        } catch {
            await MainActor.run {
                self.currentSeason = self.createDefaultSeason()
                self.startSeasonTimer()
            }
        }
    }

    private func createDefaultSeason() -> Season {
        let config = RemoteConfigService.shared
        return Season(
            id: config.seasonActiveId,
            name: config.seasonName,
            startUtc: Date(),
            endUtc: config.seasonEndUtc,
            isActive: true,
            coefficients: config.buildSeasonCoefficients()
        )
    }

    private func startSeasonTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSeasonStatus()
        }
    }

    private func checkSeasonStatus() {
        guard let season = currentSeason else { return }
        if season.hasEnded && !hasSeasonEnded {
            hasSeasonEnded = true
        }
    }

    func handleSeasonRollover(uid: String, currentSeasonData: SeasonUserData) async throws {
        guard let season = currentSeason, season.hasEnded else { return }

        let history = SeasonHistory(
            id: season.id,
            seasonName: season.name,
            finalTaps: currentSeasonData.currentSeasonTaps,
            finalRankIndex: currentSeasonData.rankIndex,
            finalPrestigeCount: currentSeasonData.prestigeCount,
            endDate: Date()
        )
        try await FirestoreService.shared.archiveSeasonHistory(uid: uid, seasonId: season.id, history: history)

        let userData = try await FirestoreService.shared.fetchUserData(uid: uid)
        if let user = userData {
            var updatedUser = user
            updatedUser.lifetimeTaps += currentSeasonData.currentSeasonTaps
            if currentSeasonData.rankIndex > updatedUser.lifetimeBestRankIndex {
                updatedUser.lifetimeBestRankIndex = currentSeasonData.rankIndex
            }
            try await FirestoreService.shared.updateUserData(uid: uid, fields: [
                "lifetimeTaps": updatedUser.lifetimeTaps,
                "lifetimeBestRankIndex": updatedUser.lifetimeBestRankIndex
            ])
        }
    }

    func createNewSeasonData() -> SeasonUserData {
        SeasonUserData(
            currentSeasonTaps: 0,
            coins: 0,
            clickMultiplierLevel: 1,
            offlineMultiplierLevel: 1,
            rankIndex: 1,
            prestigeCount: 0,
            seasonBaseMultiplier: 1.0,
            lastActiveAt: Date(),
            boostInventory: [:]
        )
    }

    var seasonId: String {
        currentSeason?.id ?? RemoteConfigService.shared.seasonActiveId
    }

    var seasonName: String {
        currentSeason?.name ?? RemoteConfigService.shared.seasonName
    }

    var timeRemaining: String {
        currentSeason?.timeRemainingFormatted ?? ""
    }

    var coefficients: SeasonCoefficients {
        currentSeason?.coefficients ?? RemoteConfigService.shared.buildSeasonCoefficients()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
