import Foundation
import SoberLifeCore

public actor PlaceholderAuthService: AuthService {
    private var storedSession: UserSession?
    private let shouldFailSignIn: Bool

    public init(shouldFailSignIn: Bool = false) {
        self.shouldFailSignIn = shouldFailSignIn
    }

    public func signIn(email: String, password: String) async throws -> UserSession {
        if shouldFailSignIn || email.isEmpty || password.isEmpty {
            throw AuthServiceError.invalidCredentials
        }

        let session = UserSession(userID: UUID(), accessToken: "placeholder-token")
        storedSession = session
        return session
    }

    public func signUp(email: String, password: String) async throws -> UserSession {
        try await signIn(email: email, password: password)
    }

    public func signOut() async throws {
        storedSession = nil
    }

    public func currentSession() async throws -> UserSession? {
        storedSession
    }
}
