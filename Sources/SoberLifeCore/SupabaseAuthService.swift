import Foundation

public enum AuthServiceError: Error, Equatable {
    case invalidCredentials
    case invalidResponse
    /// Sign-up returned a user without a session (e.g. email confirmation required in Supabase).
    case emailNotConfirmed
}

public protocol AuthSessionPersisting: Sendable {
    func load() -> UserSession?
    func save(_ session: UserSession)
    func clear()
}

public struct NoopAuthSessionPersistence: AuthSessionPersisting {
    public init() {}
    public func load() -> UserSession? { nil }
    public func save(_ session: UserSession) {}
    public func clear() {}
}

public final class UserDefaultsAuthSessionPersistence: AuthSessionPersisting, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard, key: String = "soberlife.auth.session.v1") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> UserSession? {
        guard let data = userDefaults.data(forKey: key),
              let payload = try? JSONDecoder().decode(PersistedSession.self, from: data)
        else { return nil }
        return UserSession(userID: payload.userID, accessToken: payload.accessToken)
    }

    public func save(_ session: UserSession) {
        let payload = PersistedSession(userID: session.userID, accessToken: session.accessToken)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        userDefaults.set(data, forKey: key)
    }

    public func clear() {
        userDefaults.removeObject(forKey: key)
    }

    private struct PersistedSession: Codable {
        let userID: UUID
        let accessToken: String
    }
}

public actor SupabaseAuthService: AuthService {
    private let supabaseService: SupabaseService
    private let sessionPersistence: AuthSessionPersisting
    private var cachedSession: UserSession?

    public init(
        supabaseService: SupabaseService,
        sessionPersistence: AuthSessionPersisting = NoopAuthSessionPersistence()
    ) {
        self.supabaseService = supabaseService
        self.sessionPersistence = sessionPersistence
        self.cachedSession = sessionPersistence.load()
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
            sessionPersistence.save(session)
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
            sessionPersistence.save(session)
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
        sessionPersistence.clear()
    }

    public func currentSession() async throws -> UserSession? {
        cachedSession
    }
}
