#if os(iOS)
import Foundation
import AuthenticationServices

@MainActor
public extension SessionStateFactory {
    static func makeLiveSessionState(
        wiring: AuthWiring,
        presentationAnchorProvider: @escaping @MainActor () -> ASPresentationAnchor
    ) -> SessionState {
        let tokenProvider = LiveAppleSignInTokenProvider(
            presentationAnchorProvider: presentationAnchorProvider
        )
        return makeSessionState(
            wiring: wiring,
            tokenProvider: tokenProvider
        )
    }
}
#endif
