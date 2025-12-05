import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @EnvironmentObject var gameState: GameStateService

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                VStack(spacing: 0) {
                    worldRankHero
                        .padding(.horizontal)
                        .padding(.top, 8)

                    headerSection
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer()

                    tapSection

                    Spacer()

                    statsSection
                        .padding(.horizontal)
                        .padding(.bottom, 16)

                    boostSection
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                floatingLabelsOverlay
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showPrestigePanel) {
                PrestigePanel(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .fullScreenCover(isPresented: $leaderboardViewModel.showConsentSheet) {
                WorldRankSetupView(viewModel: leaderboardViewModel)
            }
            .task {
                await leaderboardViewModel.loadLeaderboard()
            }
            .onAppear {
                leaderboardViewModel.startRealtimeUpdates()
            }
            .onDisappear {
                leaderboardViewModel.stopRealtimeUpdates()
            }
        }
    }

    private var worldRankHero: some View {
        VStack(spacing: 8) {
            if leaderboardViewModel.isOptedIn {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORLD RANK")
                            .font(.custom("Roboto-Bold", size: 12))
                            .foregroundColor(Theme.lilac.opacity(0.7))
                            .tracking(2)

                        Text(leaderboardViewModel.worldRankState.rankDisplayText)
                            .font(.custom("Roboto-Bold", size: 36))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("of \(NumberFormatService.shared.format(Double(leaderboardViewModel.worldRankState.totalPlayers)))")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text("players")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if leaderboardViewModel.worldRankEnabled {
                Button {
                    leaderboardViewModel.showConsentSheet = true
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WORLD RANK")
                                .font(.custom("Roboto-Bold", size: 14))
                            Text("Tap to join the global leaderboard")
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .padding()
        .glassyBackground()
    }

    private var backgroundGradient: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    viewModel.currentRank.tierColor.opacity(0.25),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 60)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.seasonName)
                        .font(Typography.h2)
                        .foregroundColor(.white.opacity(0.9))

                    Text("\(viewModel.timeRemaining) remaining")
                        .font(Typography.caption)
                        .foregroundColor(Theme.lilac.opacity(0.7))
                }

                Spacer()

                RankBadge(rank: viewModel.currentRank)
                    .onTapGesture {
                        if viewModel.canPrestige {
                            viewModel.showPrestigePanel = true
                        }
                    }
            }

            RankProgressView(
                progress: viewModel.progressToNextRank,
                currentRank: viewModel.currentRank,
                prestigeCount: viewModel.prestigeCount
            )
        }
    }

    private var tapSection: some View {
        GeometryReader { geometry in
            ZStack {
                TapButton(
                    scale: viewModel.tapScale,
                    tierColor: viewModel.currentRank.tierColor,
                    hasGlow: viewModel.currentRank.hasGlow,
                    glowIntensity: viewModel.currentRank.glowIntensity
                ) { location in
                    let position = CGPoint(
                        x: geometry.frame(in: .global).midX + location.x - geometry.size.width / 2,
                        y: geometry.frame(in: .global).midY + location.y - geometry.size.height / 2 - 100
                    )
                    viewModel.handleTap(at: position)
                }
                .frame(width: min(geometry.size.width - 80, 280), height: min(geometry.size.width - 80, 280))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatRow(
                    title: "Your Taps",
                    value: NumberFormatService.shared.formatTaps(viewModel.currentTaps),
                    icon: "hand.tap"
                )

                StatRow(
                    title: "Multiplier",
                    value: NumberFormatService.shared.formatMultiplier(viewModel.seasonMultiplier * viewModel.boostMultiplier),
                    icon: "multiply.circle",
                    highlight: viewModel.hasActiveBoost
                )

                if viewModel.tapsPerSecond > 0 {
                    StatRow(
                        title: "Taps/Sec",
                        value: NumberFormatService.shared.format(viewModel.tapsPerSecond),
                        icon: "bolt.fill",
                        highlight: true
                    )
                } else {
                    StatRow(
                        title: "Lifetime",
                        value: NumberFormatService.shared.formatTaps(viewModel.lifetimeTaps),
                        icon: "infinity"
                    )
                }
            }

            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(.yellow)
                Text(NumberFormatService.shared.formatCoins(viewModel.coins))
                    .font(Typography.h2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .glassyBackground()
    }

    private var boostSection: some View {
        HStack(spacing: 12) {
            BoostButton(
                type: .adRush,
                isAvailable: viewModel.canActivateAdRush(),
                cooldownText: viewModel.adRushCooldownRemaining(),
                activeBoost: viewModel.activeBoosts.first { $0.type == .adRush }
            ) {
                viewModel.activateAdRush()
            }

            if viewModel.canPrestige {
                Button {
                    viewModel.showPrestigePanel = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Prestige")
                            .font(Typography.button)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Theme.accentGradient)
                    )
                }
            }
        }
    }

    private var floatingLabelsOverlay: some View {
        ZStack {
            ForEach(viewModel.floatingLabels) { label in
                FloatingTapLabel(value: label.value)
                    .position(label.position)
            }
        }
        .allowsHitTesting(false)
    }
}
