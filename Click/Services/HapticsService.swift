import Foundation
import UIKit

final class HapticsService {
    static let shared = HapticsService()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    func tap() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func rankUp() {
        mediumGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationGenerator.notificationOccurred(.success)
            self?.notificationGenerator.prepare()
        }
        mediumGenerator.prepare()
    }

    func prestigeConfirm() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    func seasonStart() {
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.mediumGenerator.impactOccurred()
            self?.mediumGenerator.prepare()
        }
        notificationGenerator.prepare()
    }

    func rewardClaim() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func boostActivate() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func worldRankTick() {
        lightGenerator.impactOccurred(intensity: 0.5)
        lightGenerator.prepare()
    }

    func worldRankPercentileCross() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func milestone() {
        selectionGenerator.selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.lightGenerator.impactOccurred()
            self?.lightGenerator.prepare()
        }
        selectionGenerator.prepare()
    }
}
