import Foundation

@MainActor
public extension SessionStateFactory {
    static func makePlaceholderSessionState(
        wiring: AuthWiring,
        shouldFailSignIn: Bool = false
    ) -> SessionState {
        let authService = PlaceholderAuthService(shouldFailSignIn: shouldFailSignIn)
        return SessionState(authService: authService)
    }
}
