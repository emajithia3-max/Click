import Foundation
import FirebaseRemoteConfig

final class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()

    private let remoteConfig = RemoteConfig.remoteConfig()

    @Published private(set) var isLoaded = false

    private init() {
        setupDefaults()
    }

    private func setupDefaults() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        remoteConfig.configSettings = settings

        if let defaultsURL = Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist") {
            remoteConfig.setDefaults(fromPlist: defaultsURL.lastPathComponent.replacingOccurrences(of: ".plist", with: ""))
        }

        remoteConfig.setDefaults([
            "season_active_id": "season_1" as NSObject,
            "season_end_utc": Date().addingTimeInterval(28 * 24 * 3600).timeIntervalSince1970 as NSObject,
            "rank_growth_a": 500.0 as NSObject,
            "rank_growth_b": 1.22 as NSObject,
            "prestige_growth_a": 1.35 as NSObject,
            "offline_hours_cap": 8.0 as NSObject,
            "base_offline_rate": 10.0 as NSObject,
            "admob_rewarded_enabled": true as NSObject,
            "rewarded_cooldown_seconds": 120.0 as NSObject,
            "world_rank_feature_enabled": true as NSObject,
            "world_rank_update_interval_ms": 5000 as NSObject,
            "base_tap": 1.0 as NSObject,
            "click_multiplier_per_level": 0.10 as NSObject,
            "offline_multiplier_per_level": 0.20 as NSObject,
            "milestone_coins_base": 10.0 as NSObject,
            "rank_up_coins_base": 50.0 as NSObject,
            "ad_rush_duration": 30.0 as NSObject,
            "ad_rush_multiplier": 2.0 as NSObject,
            "ad_rush_cooldown": 120.0 as NSObject,
            "overclock_duration": 15.0 as NSObject,
            "overclock_multiplier": 5.0 as NSObject,
            "overclock_cooldown": 300.0 as NSObject,
            "season_name": "Season 1" as NSObject,
            "whats_new_text": "Season 1 begins — ranks reset, fresh boosts, smoother progression." as NSObject
        ])
    }

    func fetchAndActivate() async {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            await MainActor.run {
                self.isLoaded = status == .successFetchedFromRemote || status == .successUsingPreFetchedData
            }
        } catch {
            await MainActor.run {
                self.isLoaded = true
            }
        }
    }

    var seasonActiveId: String {
        remoteConfig.configValue(forKey: "season_active_id").stringValue ?? "season_1"
    }

    var seasonEndUtc: Date {
        let timestamp = remoteConfig.configValue(forKey: "season_end_utc").numberValue.doubleValue
        return Date(timeIntervalSince1970: timestamp)
    }

    var rankGrowthA: Double {
        remoteConfig.configValue(forKey: "rank_growth_a").numberValue.doubleValue
    }

    var rankGrowthB: Double {
        remoteConfig.configValue(forKey: "rank_growth_b").numberValue.doubleValue
    }

    var prestigeGrowthA: Double {
        remoteConfig.configValue(forKey: "prestige_growth_a").numberValue.doubleValue
    }

    var offlineHoursCap: Double {
        remoteConfig.configValue(forKey: "offline_hours_cap").numberValue.doubleValue
    }

    var baseOfflineRate: Double {
        remoteConfig.configValue(forKey: "base_offline_rate").numberValue.doubleValue
    }

    var admobRewardedEnabled: Bool {
        remoteConfig.configValue(forKey: "admob_rewarded_enabled").boolValue
    }

    var rewardedCooldownSeconds: Double {
        remoteConfig.configValue(forKey: "rewarded_cooldown_seconds").numberValue.doubleValue
    }

    var worldRankFeatureEnabled: Bool {
        remoteConfig.configValue(forKey: "world_rank_feature_enabled").boolValue
    }

    var worldRankUpdateIntervalMs: Int {
        remoteConfig.configValue(forKey: "world_rank_update_interval_ms").numberValue.intValue
    }

    var baseTap: Double {
        remoteConfig.configValue(forKey: "base_tap").numberValue.doubleValue
    }

    var clickMultiplierPerLevel: Double {
        remoteConfig.configValue(forKey: "click_multiplier_per_level").numberValue.doubleValue
    }

    var offlineMultiplierPerLevel: Double {
        remoteConfig.configValue(forKey: "offline_multiplier_per_level").numberValue.doubleValue
    }

    var milestoneCoinsBase: Double {
        remoteConfig.configValue(forKey: "milestone_coins_base").numberValue.doubleValue
    }

    var rankUpCoinsBase: Double {
        remoteConfig.configValue(forKey: "rank_up_coins_base").numberValue.doubleValue
    }

    var adRushDuration: Double {
        remoteConfig.configValue(forKey: "ad_rush_duration").numberValue.doubleValue
    }

    var adRushMultiplier: Double {
        remoteConfig.configValue(forKey: "ad_rush_multiplier").numberValue.doubleValue
    }

    var adRushCooldown: Double {
        remoteConfig.configValue(forKey: "ad_rush_cooldown").numberValue.doubleValue
    }

    var overclockDuration: Double {
        remoteConfig.configValue(forKey: "overclock_duration").numberValue.doubleValue
    }

    var overclockMultiplier: Double {
        remoteConfig.configValue(forKey: "overclock_multiplier").numberValue.doubleValue
    }

    var overclockCooldown: Double {
        remoteConfig.configValue(forKey: "overclock_cooldown").numberValue.doubleValue
    }

    var seasonName: String {
        remoteConfig.configValue(forKey: "season_name").stringValue ?? "Season 1"
    }

    var whatsNewText: String {
        remoteConfig.configValue(forKey: "whats_new_text").stringValue ?? ""
    }

    func buildSeasonCoefficients() -> SeasonCoefficients {
        SeasonCoefficients(
            rankGrowthA: rankGrowthA,
            rankGrowthB: rankGrowthB,
            prestigeGrowthA: prestigeGrowthA,
            baseThreshold: rankGrowthA,
            offlineHoursCap: offlineHoursCap,
            baseOfflineRate: baseOfflineRate
        )
    }

    func buildEconomyConfig() -> EconomyConfig {
        EconomyConfig(
            baseTap: baseTap,
            clickMultiplierPerLevel: clickMultiplierPerLevel,
            offlineMultiplierPerLevel: offlineMultiplierPerLevel,
            baseOfflineRate: baseOfflineRate,
            offlineCapHours: offlineHoursCap,
            milestoneCoinsBase: milestoneCoinsBase,
            rankUpCoinsBase: rankUpCoinsBase
        )
    }
}
