import SwiftUI

struct SettingsView: View {
    @ObservedObject var leaderboardViewModel: LeaderboardViewModel
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $settingsManager.personalizedAdsEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.rectangle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Personalized Ads")
                                    .font(Typography.body)
                                Text("Show ads based on your interests")
                                    .font(Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Advertising")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { leaderboardViewModel.isOptedIn },
                        set: { newValue in
                            if newValue {
                                leaderboardViewModel.showConsentSheet = true
                            } else {
                                showDeleteConfirmation = true
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("World Rank")
                                    .font(Typography.body)
                                Text("Compete on the global leaderboard")
                                    .font(Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Leaderboard")
                } footer: {
                    Text("Turning this off will remove your data from the public leaderboard.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Turn Off World Rank?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Turn Off", role: .destructive) {
                    leaderboardViewModel.optOut()
                }
            } message: {
                Text("This will remove your data from the public leaderboard. You can turn it back on at any time.")
            }
        }
    }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private static let personalizedAdsKey = "personalizedAdsEnabled"
    private static let hasSeenAdConsentKey = "hasSeenAdConsent"

    @Published var personalizedAdsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(personalizedAdsEnabled, forKey: Self.personalizedAdsKey)
        }
    }

    var hasSeenAdConsent: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasSeenAdConsentKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasSeenAdConsentKey) }
    }

    private init() {
        self.personalizedAdsEnabled = UserDefaults.standard.bool(forKey: Self.personalizedAdsKey)
    }
}
