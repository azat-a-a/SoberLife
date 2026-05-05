import Foundation

@MainActor
public extension SessionStateFactory {
    static func makePlaceholderSessionState(
        wiring: AuthWiring,
        shouldFailTokenRequest: Bool = false
    ) -> SessionState {
        let tokenProvider = PlaceholderAppleSignInTokenProvider(shouldFail: shouldFailTokenRequest)
        return makeSessionState(
            wiring: wiring,
            tokenProvider: tokenProvider
        )
    }
}
