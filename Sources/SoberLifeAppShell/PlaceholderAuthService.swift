import Foundation
import SoberLifeCore

public actor PlaceholderAuthService: AuthService {
    private var storedSession: UserSession?
    private let shouldFailSignIn: Bool
    private let userDefaults: UserDefaults
    private let sessionKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        shouldFailSignIn: Bool = false,
        userDefaults: UserDefaults = .standard,
        sessionKey: String = "soberlife.placeholder.session.v1"
    ) {
        self.shouldFailSignIn = shouldFailSignIn
        self.userDefaults = userDefaults
        self.sessionKey = sessionKey
        if let data = userDefaults.data(forKey: sessionKey),
           let persisted = try? decoder.decode(PersistedSession.self, from: data)
        {
            self.storedSession = UserSession(
                userID: persisted.userID,
                accessToken: persisted.accessToken
            )
        }
    }

    public func signIn(email: String, password: String) async throws -> UserSession {
        if shouldFailSignIn || email.isEmpty || password.isEmpty {
            throw AuthServiceError.invalidCredentials
        }

        let userID = storedSession?.userID ?? UUID()
        let session = UserSession(userID: userID, accessToken: "placeholder-token")
        storedSession = session
        persist(session)
        return session
    }

    public func signUp(email: String, password: String) async throws -> UserSession {
        try await signIn(email: email, password: password)
    }

    public func signOut() async throws {
        storedSession = nil
        userDefaults.removeObject(forKey: sessionKey)
    }

    public func currentSession() async throws -> UserSession? {
        storedSession
    }

    private func persist(_ session: UserSession) {
        let payload = PersistedSession(userID: session.userID, accessToken: session.accessToken)
        guard let data = try? encoder.encode(payload) else { return }
        userDefaults.set(data, forKey: sessionKey)
    }
}

private struct PersistedSession: Codable {
    let userID: UUID
    let accessToken: String
}
