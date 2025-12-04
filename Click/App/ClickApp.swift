import SwiftUI
import FirebaseCore

@main
struct ClickApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var gameState = GameStateService.shared
    @StateObject private var authService = AuthService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .environmentObject(authService)
                .preferredColorScheme(nil)
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            break
        case .inactive:
            gameState.saveNow()
        case .background:
            gameState.saveNow()
        @unknown default:
            break
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        AdService.shared.configure()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        GameStateService.shared.cleanup()
    }
}
