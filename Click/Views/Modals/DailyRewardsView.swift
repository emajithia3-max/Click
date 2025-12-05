import SwiftUI

struct DailyRewardsView: View {
    @ObservedObject var manager = DailyRewardsManager.shared
    @State private var claimedReward: DailyReward?
    @State private var showClaimAnimation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            headerSection

            if let reward = claimedReward {
                claimedSection(reward: reward)
            } else {
                streakSection
                rewardsGrid
                claimButton
            }

            Spacer()
        }
        .padding()
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20)

                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .scaleEffect(showClaimAnimation ? 1.2 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showClaimAnimation)

            Text("Daily Rewards")
                .font(Typography.h1)
                .foregroundColor(.primary)

            if manager.state.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(manager.state.currentStreak) day streak!")
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var streakSection: some View {
        VStack(spacing: 8) {
            if manager.state.streakWillReset && manager.state.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Streak will reset! Claim now to continue.")
                        .font(Typography.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
    }

    private var rewardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(DailyReward.weeklyRewards) { reward in
                DayRewardCell(
                    reward: reward,
                    isCurrent: reward.day == manager.state.currentDayIndex + 1,
                    isClaimed: reward.day <= manager.state.currentDayIndex || (reward.day == manager.state.currentDayIndex + 1 && !manager.state.canClaimToday)
                )
            }
        }
        .padding()
        .glassyBackground()
    }

    private var claimButton: some View {
        Button {
            claimDailyReward()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                Text("Claim Day \(manager.state.currentDayIndex + 1) Reward")
                    .font(Typography.button)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color(hex: "FFD700").opacity(0.4), radius: 10, y: 5)
        }
        .disabled(!manager.state.canClaimToday)
        .opacity(manager.state.canClaimToday ? 1 : 0.6)
    }

    private func claimedSection(reward: DailyReward) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("You received:")
                    .font(Typography.body)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    rewardIcon(for: reward)
                        .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(rewardTitle(for: reward))
                            .font(Typography.h2)
                            .foregroundColor(.primary)

                        Text(rewardSubtitle(for: reward))
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .glassyBackground()
            }

            Button {
                manager.dismissDailyRewards()
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

    private func rewardIcon(for reward: DailyReward) -> some View {
        ZStack {
            Circle()
                .fill(rewardGradient(for: reward))

            Image(systemName: reward.rewardType.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
    }

    private func rewardGradient(for reward: DailyReward) -> LinearGradient {
        switch reward.rewardType {
        case .coins:
            return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .boost(let type):
            return LinearGradient(colors: [type.iconColors.primary, type.iconColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .multiplierBonus:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func rewardTitle(for reward: DailyReward) -> String {
        switch reward.rewardType {
        case .coins:
            return "+\(Int(reward.amount)) Coins"
        case .boost(let type):
            return "\(Int(reward.amount))x \(type.displayName)"
        case .multiplierBonus:
            return "Multiplier Bonus"
        }
    }

    private func rewardSubtitle(for reward: DailyReward) -> String {
        switch reward.rewardType {
        case .coins:
            return "Added to your balance"
        case .boost:
            return "Added to your inventory"
        case .multiplierBonus(let duration):
            return "Active for \(Int(duration / 60)) minutes"
        }
    }

    private func claimDailyReward() {
        withAnimation(.spring()) {
            showClaimAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let reward = manager.claimReward()
            withAnimation {
                claimedReward = reward
                showClaimAnimation = false
            }
        }
    }
}

// MARK: - Day Reward Cell

struct DayRewardCell: View {
    let reward: DailyReward
    let isCurrent: Bool
    let isClaimed: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text("Day \(reward.day)")
                .font(.custom("Roboto-Medium", size: 11))
                .foregroundColor(isCurrent ? .white : .secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isCurrent ? Color(hex: "FFD700") : Color.clear, lineWidth: 2)
                    )

                if isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: reward.rewardType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(isCurrent ? .white : .secondary)

                        Text(rewardAmountText)
                            .font(.custom("Roboto-Bold", size: 10))
                            .foregroundColor(isCurrent ? .white : .secondary)
                    }
                }
            }

            if reward.isMilestone && !isClaimed {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "FFD700"))
            }
        }
    }

    private var cellBackground: some View {
        Group {
            if isCurrent {
                LinearGradient(
                    colors: [Color(hex: "FFD700").opacity(0.3), Color(hex: "FFA500").opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if isClaimed {
                Color(.systemGray5)
            } else {
                Theme.cardBackground
            }
        }
    }

    private var rewardAmountText: String {
        switch reward.rewardType {
        case .coins:
            return "+\(Int(reward.amount))"
        case .boost:
            return "x\(Int(reward.amount))"
        case .multiplierBonus:
            return "Bonus"
        }
    }
}
