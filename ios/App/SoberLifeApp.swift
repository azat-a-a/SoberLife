import SwiftUI
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
            sessionState = SessionStateFactory.makeSessionState(wiring: wiring)
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
}
