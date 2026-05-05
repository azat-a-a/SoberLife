import Foundation
import Combine
import SoberLifeCore

public enum AuthFlowState: Sendable, Equatable {
    case signedOut
    case signedIn(userID: UUID)
}

@MainActor
public final class SessionState: ObservableObject {
    @Published public private(set) var authState: AuthFlowState
    @Published public private(set) var authErrorMessage: String?

    private let authService: AuthService
    private let appleSignInTokenProvider: AppleSignInTokenProvider

    public init(
        authService: AuthService,
        appleSignInTokenProvider: AppleSignInTokenProvider,
        authState: AuthFlowState = .signedOut
    ) {
        self.authService = authService
        self.appleSignInTokenProvider = appleSignInTokenProvider
        self.authState = authState
    }

    public func restoreSession() async {
        do {
            if let session = try await authService.currentSession() {
                authState = .signedIn(userID: session.userID)
            } else {
                authState = .signedOut
            }
            authErrorMessage = nil
        } catch {
            authState = .signedOut
            authErrorMessage = "Failed to restore session."
        }
    }

    public func signInWithApple() async {
        do {
            let token = try await appleSignInTokenProvider.requestToken()
            let session = try await authService.signInWithApple(idToken: token.idToken, nonce: token.nonce)
            authState = .signedIn(userID: session.userID)
            authErrorMessage = nil
        } catch {
            authErrorMessage = "Sign in failed. Please try again."
        }
    }

    public func signOut() async {
        do {
            try await authService.signOut()
            authState = .signedOut
            authErrorMessage = nil
        } catch {
            authErrorMessage = "Sign out failed. Please try again."
        }
    }

    /// JWT for PostgREST when signed in (needed for `ai_conversations` RLS).
    public func accessTokenIfAvailable() async -> String? {
        guard let session = try? await authService.currentSession() else { return nil }
        return session.accessToken
    }
}
