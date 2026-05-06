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

    public init(
        authService: AuthService,
        authState: AuthFlowState = .signedOut
    ) {
        self.authService = authService
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
            authErrorMessage = L10n.string("auth.error.restore_failed")
        }
    }

    public func signIn(email: String, password: String) async {
        do {
            let session = try await authService.signIn(email: email, password: password)
            authState = .signedIn(userID: session.userID)
            authErrorMessage = nil
        } catch let error as AuthServiceError {
            authState = .signedOut
            switch error {
            case .invalidCredentials:
                authErrorMessage = L10n.string("auth.error.invalid_credentials")
            case .emailNotConfirmed:
                authErrorMessage = EmpathyCopy.emailConfirmationRequired
            case .invalidResponse:
                authErrorMessage = L10n.string("auth.error.signin_failed")
            }
        } catch {
            authState = .signedOut
            authErrorMessage = L10n.string("auth.error.signin_failed")
        }
    }

    public func signUp(email: String, password: String) async {
        do {
            let session = try await authService.signUp(email: email, password: password)
            authState = .signedIn(userID: session.userID)
            authErrorMessage = nil
        } catch let error as AuthServiceError {
            authState = .signedOut
            switch error {
            case .emailNotConfirmed:
                authErrorMessage = EmpathyCopy.emailConfirmationRequired
            case .invalidCredentials:
                authErrorMessage = L10n.string("auth.error.signup_check_email")
            case .invalidResponse:
                authErrorMessage = L10n.string("auth.error.signup_failed")
            }
        } catch {
            authState = .signedOut
            authErrorMessage = L10n.string("auth.error.signup_failed")
        }
    }

    public func signOut() async {
        do {
            try await authService.signOut()
            authState = .signedOut
            authErrorMessage = nil
        } catch {
            authErrorMessage = L10n.string("auth.error.signout_failed")
        }
    }

    /// JWT for PostgREST when signed in (needed for `ai_conversations` RLS).
    public func accessTokenIfAvailable() async -> String? {
        guard let session = try? await authService.currentSession() else { return nil }
        return session.accessToken
    }

    public func handleUnauthorizedSession() async {
        try? await authService.signOut()
        authState = .signedOut
        authErrorMessage = EmpathyCopy.sessionExpiredNeedsSignIn
    }
}
