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
            authErrorMessage = "Failed to restore session."
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
                authErrorMessage = "Incorrect email or password."
            case .emailNotConfirmed:
                authErrorMessage = EmpathyCopy.emailConfirmationRequired
            case .invalidResponse:
                authErrorMessage = "Sign in failed. Please try again."
            }
        } catch {
            authState = .signedOut
            authErrorMessage = "Sign in failed. Please try again."
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
                authErrorMessage = "Check your email and password and try again."
            case .invalidResponse:
                authErrorMessage = "Could not create account. Please try again."
            }
        } catch {
            authState = .signedOut
            authErrorMessage = "Could not create account. Please try again."
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

    public func handleUnauthorizedSession() async {
        try? await authService.signOut()
        authState = .signedOut
        authErrorMessage = EmpathyCopy.sessionExpiredNeedsSignIn
    }
}
