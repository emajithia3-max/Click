import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameStateService
    @EnvironmentObject var authService: AuthService
    @State private var isInitialized = false

    var body: some View {
        Group {
            if gameState.isLoading || authService.isLoading {
                LoadingView()
            } else {
                MainTabView()
                    .sheet(isPresented: $gameState.showOfflineEarnings) {
                        OfflineEarningsModal()
                    }
                    .sheet(isPresented: $gameState.showRankUp) {
                        if let rank = gameState.newRank {
                            RankUpModal(rank: rank)
                        }
                    }
                    .sheet(isPresented: $gameState.showSeasonEnd) {
                        SeasonEndModal()
                    }
            }
        }
        .task {
            if !isInitialized {
                isInitialized = true
                await gameState.initialize()
            }
        }
    }
}

struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    )
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: rotation
                    )

                Text("Click")
                    .font(.custom("Roboto-Bold", size: 34))
                    .foregroundColor(.primary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear {
            rotation = 360
        }
    }
}

struct Typography {
    static let h1 = Font.custom("Roboto-Bold", size: 34)
    static let h2 = Font.custom("Roboto-Medium", size: 24)
    static let body = Font.custom("Roboto-Regular", size: 17)
    static let caption = Font.custom("Roboto-Regular", size: 13)
    static let counter = Font.custom("Roboto-Bold", size: 48)
    static let button = Font.custom("Roboto-Medium", size: 17)
}
