import SwiftUI
import AuthenticationServices
import UIKit
import SoberLifeAppShell
import SoberLifeCore

@main
struct SoberLifeApp: App {
    @StateObject private var root = AppRootState()

    var body: some Scene {
        WindowGroup {
            AppShellView(sessionState: root.sessionState, authWiring: root.authWiring)
        }
    }
}

@MainActor
private final class AppRootState: ObservableObject {
    let sessionState: SessionState
    let authWiring: AuthWiring?

    init() {
        if let wiring = Self.loadAuthWiring() {
            authWiring = wiring
            sessionState = SessionStateFactory.makeLiveSessionState(wiring: wiring) {
                Self.presentationAnchor()
            }
        } else {
            authWiring = nil
            let fallback = AuthWiring(
                supabaseURL: URL(string: "https://placeholder.invalid")!,
                supabaseAnonKey: "dev-without-secrets"
            )
            sessionState = SessionStateFactory.makePlaceholderSessionState(wiring: fallback)
        }
    }

    private static func loadAuthWiring() -> AuthWiring? {
        guard
            let dict = Bundle.main.infoDictionary,
            let urlStr = dict["SUPABASE_URL"] as? String,
            let key = dict["SUPABASE_ANON_KEY"] as? String,
            let url = URL(string: urlStr),
            !urlStr.isEmpty,
            !key.isEmpty
        else { return nil }
        return AuthWiring(supabaseURL: url, supabaseAnonKey: key)
    }

    private static func presentationAnchor() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let window = scene.windows.first(where: \.isKeyWindow) {
                return window
            }
        }
        if let window = scenes.first?.windows.first {
            return window
        }
        // Before the first window exists (rare); Sign in with Apple may need a second tap.
        return UIWindow(frame: UIScreen.main.bounds)
    }
}
