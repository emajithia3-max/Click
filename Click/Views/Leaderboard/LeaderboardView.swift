import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker

                tabContent
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await viewModel.loadLeaderboard()
            }
            .onAppear {
                viewModel.startRealtimeUpdates()
            }
            .onDisappear {
                viewModel.stopRealtimeUpdates()
            }
            .fullScreenCover(isPresented: $viewModel.showConsentSheet) {
                WorldRankSetupView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(leaderboardViewModel: viewModel)
            }
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $viewModel.selectedTab) {
            ForEach(LeaderboardTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .global:
            globalLeaderboard
        case .lifetime:
            lifetimeView
        }
    }

    private var globalLeaderboard: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.leaderboardData.top.isEmpty {
                emptyLeaderboard
            } else {
                leaderboardList
            }
        }
    }

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.leaderboardData.top) { entry in
                    LeaderboardRow(
                        entry: entry,
                        isCurrentUser: entry.odid == AuthService.shared.uid
                    )
                }

                if let position = viewModel.userPosition,
                   viewModel.userEntry == nil {
                    Divider()
                        .padding(.vertical, 8)

                    yourPositionCard(position: position)
                }
            }
            .padding()
        }
    }

    private func yourPositionCard(position: Int) -> some View {
        HStack {
            Text("#\(NumberFormatService.shared.format(Double(position)))")
                .font(.custom("Roboto-Bold", size: 20))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Position")
                    .font(Typography.body)
                    .foregroundColor(.primary)

                Text(NumberFormatService.shared.formatTaps(viewModel.currentTaps) + " taps")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            RankBadge(
                rank: RankSystem().rank(at: viewModel.currentRankIndex),
                size: .small
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var emptyLeaderboard: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No rankings yet")
                .font(Typography.h2)
                .foregroundColor(.primary)

            Text("Be the first to climb the ranks!")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lifetimeView: some View {
        Group {
            if viewModel.seasonHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No History Yet")
                        .font(Typography.h2)
                        .foregroundColor(.primary)

                    Text("Your past season records will appear here")
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.seasonHistory) { history in
                            seasonHistoryCard(history)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadSeasonHistory()
        }
    }

    private func seasonHistoryCard(_ history: SeasonHistory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.seasonName)
                    .font(Typography.h2)
                    .foregroundColor(.primary)

                Text(history.endDate, style: .date)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                RankBadge(
                    rank: RankSystem().rank(at: history.finalRankIndex),
                    size: .small
                )

                Text("\(NumberFormatService.shared.formatTaps(history.finalTaps)) taps")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
