import Foundation
import SoberLifeCore

public actor PlaceholderAuthService: AuthService {
    private var storedSession: UserSession?
    private let shouldFailSignIn: Bool

    public init(shouldFailSignIn: Bool = false) {
        self.shouldFailSignIn = shouldFailSignIn
    }

    public func signInWithApple(idToken: String, nonce: String?) async throws -> UserSession {
        if shouldFailSignIn || idToken.isEmpty {
            throw NSError(domain: "PlaceholderAuthService", code: 401)
        }

        let session = UserSession(userID: UUID(), accessToken: "placeholder-token")
        storedSession = session
        return session
    }

    public func signOut() async throws {
        storedSession = nil
    }

    public func currentSession() async throws -> UserSession? {
        storedSession
    }
}
