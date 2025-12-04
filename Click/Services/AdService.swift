import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit

final class AdService: NSObject, ObservableObject {
    static let shared = AdService()

    static let testRewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    static let testBannerAdUnitId = "ca-app-pub-3940256099942544/2934735716"
    static let testAppId = "ca-app-pub-3940256099942544~1458002511"

    @Published private(set) var isRewardedAdReady = false
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private var rewardedAd: GADRewardedAd?
    private var rewardCompletion: ((Bool) -> Void)?

    override private init() {
        super.init()
    }

    func configure() {
        GADMobileAds.sharedInstance().start { [weak self] _ in
            DispatchQueue.main.async {
                self?.loadRewardedAd()
            }
        }
    }

    func loadRewardedAd() {
        guard RemoteConfigService.shared.admobRewardedEnabled else {
            isRewardedAdReady = false
            return
        }

        guard !isLoading else { return }

        isLoading = true
        lastError = nil

        GADRewardedAd.load(
            withAdUnitID: Self.testRewardedAdUnitId,
            request: GADRequest()
        ) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.lastError = error.localizedDescription
                    self?.isRewardedAdReady = false
                    return
                }

                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isRewardedAdReady = true
            }
        }
    }

    func showRewardedAd(from viewController: UIViewController? = nil, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd else {
            completion(false)
            loadRewardedAd()
            return
        }

        guard let rootViewController = viewController ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            completion(false)
            return
        }

        rewardCompletion = completion

        ad.present(fromRootViewController: rootViewController) { [weak self] in
            let reward = ad.adReward
            _ = reward.amount
            _ = reward.type
            self?.rewardCompletion?(true)
            self?.rewardCompletion = nil
        }
    }

    func canShowRewardedAd() -> Bool {
        RemoteConfigService.shared.admobRewardedEnabled && isRewardedAdReady
    }
}

extension AdService: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isRewardedAdReady = false
        loadRewardedAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        lastError = error.localizedDescription
        rewardCompletion?(false)
        rewardCompletion = nil
        isRewardedAdReady = false
        loadRewardedAd()
    }

    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        HapticsService.shared.selection()
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AdService.testBannerAdUnitId) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: 320, height: 50)))
        banner.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }

        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

struct AdaptiveBannerAdView: UIViewRepresentable {
    let adUnitID: String
    let width: CGFloat

    init(adUnitID: String = AdService.testBannerAdUnitId, width: CGFloat = UIScreen.main.bounds.width) {
        self.adUnitID = adUnitID
        self.width = width
    }

    func makeUIView(context: Context) -> GADBannerView {
        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }

        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
