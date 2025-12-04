import SwiftUI

struct RankUpModal: View {
    let rank: Rank
    @Environment(\.dismiss) private var dismiss
    @State private var confettiCounter = 0

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 24) {
                confettiView

                badgeSection

                titleSection

                rewardSection

                continueButton
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: rank.tierColor.opacity(0.4), radius: 30, x: 0, y: 12)
            )
            .padding(32)
        }
        .onAppear {
            confettiCounter += 1
        }
    }

    private var confettiView: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                ConfettiPiece(
                    color: [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.orange].randomElement() ?? .blue,
                    delay: Double(index) * 0.05
                )
            }
        }
        .frame(height: 100)
    }

    private var badgeSection: some View {
        ZStack {
            Circle()
                .fill(rank.tierColor.opacity(0.2))
                .frame(width: 120, height: 120)

            Circle()
                .fill(rank.tierColor.opacity(0.3))
                .frame(width: 100, height: 100)

            RankBadge(rank: rank, size: .large)
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Rank Up!")
                .font(Typography.h1)
                .foregroundColor(.primary)

            Text(rank.displayName)
                .font(Typography.h2)
                .foregroundColor(rank.tierColor)
        }
    }

    private var rewardSection: some View {
        HStack {
            Image(systemName: "bitcoinsign.circle.fill")
                .foregroundColor(.yellow)

            Text("+\(NumberFormatService.shared.formatCoins(EconomyService.shared.coinsForRankUp(newRankIndex: rank.index)))")
                .font(Typography.h2)
                .foregroundColor(.primary)

            Text("coins")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
        )
    }

    private var continueButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Continue")
                .font(Typography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accentGradient)
                )
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    let delay: Double

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
            .offset(
                x: animate ? CGFloat.random(in: -100...100) : 0,
                y: animate ? CGFloat.random(in: -150 ... -50) : 0
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(delay)) {
                    animate = true
                }
            }
    }
}
