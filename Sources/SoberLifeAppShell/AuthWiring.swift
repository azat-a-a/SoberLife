import Foundation
import SoberLifeCore

public struct AuthWiring {
    public let supabaseURL: URL
    public let supabaseAnonKey: String

    public init(supabaseURL: URL, supabaseAnonKey: String) {
        self.supabaseURL = supabaseURL
        self.supabaseAnonKey = supabaseAnonKey
    }
}

@MainActor
public enum SessionStateFactory {
    public static func makeSessionState(
        wiring: AuthWiring,
        tokenProvider: AppleSignInTokenProvider
    ) -> SessionState {
        let supabaseService = HTTPSupabaseService(
            baseURL: wiring.supabaseURL,
            anonKey: wiring.supabaseAnonKey
        )
        let authService = SupabaseAuthService(supabaseService: supabaseService)
        return SessionState(
            authService: authService,
            appleSignInTokenProvider: tokenProvider
        )
    }
}
