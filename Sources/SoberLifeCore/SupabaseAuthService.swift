import Foundation

public enum AuthServiceError: Error, Equatable {
    case invalidCredentials
    case invalidResponse
    /// Sign-up returned a user without a session (e.g. email confirmation required in Supabase).
    case emailNotConfirmed
}

public actor SupabaseAuthService: AuthService {
    private let supabaseService: SupabaseService
    private var cachedSession: UserSession?

    public init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    public func signIn(email: String, password: String) async throws -> UserSession {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        do {
            let result = try await supabaseService.authSignIn(email: trimmedEmail, password: password)
            let session = UserSession(userID: result.userID, accessToken: result.accessToken)
            cachedSession = session
            return session
        } catch let error as SupabaseHTTPServiceError {
            throw mapSupabaseHTTPAuthError(error)
        } catch {
            throw AuthServiceError.invalidResponse
        }
    }

    public func signUp(email: String, password: String) async throws -> UserSession {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        do {
            let result = try await supabaseService.authSignUp(email: trimmedEmail, password: password)
            let session = UserSession(userID: result.userID, accessToken: result.accessToken)
            cachedSession = session
            return session
        } catch let error as SupabaseHTTPServiceError {
            throw mapSupabaseHTTPAuthError(error)
        } catch {
            throw AuthServiceError.invalidResponse
        }
    }

    private func mapSupabaseHTTPAuthError(_ error: SupabaseHTTPServiceError) -> AuthServiceError {
        switch error {
        case .httpStatus(let code) where [400, 401, 422].contains(code):
            return .invalidCredentials
        case .authPendingEmailConfirmation:
            return .emailNotConfirmed
        default:
            return .invalidResponse
        }
    }

    public func signOut() async throws {
        cachedSession = nil
    }

    public func currentSession() async throws -> UserSession? {
        cachedSession
    }
}
