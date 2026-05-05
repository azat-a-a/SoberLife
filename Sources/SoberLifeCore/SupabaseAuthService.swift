import Foundation

public enum AuthServiceError: Error, Equatable {
    case invalidCredentials
    case invalidResponse
}

public actor SupabaseAuthService: AuthService {
    private let supabaseService: SupabaseService
    private var cachedSession: UserSession?

    public init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    public func signInWithApple(idToken: String, nonce: String?) async throws -> UserSession {
        guard !idToken.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }

        var payload: [String: String] = ["id_token": idToken]
        if let nonce {
            payload["nonce"] = nonce
        }

        let response = try await supabaseService.invoke(function: "auth-exchange-apple", payload: payload)

        guard
            let userIDRaw = response["user_id"],
            let userID = UUID(uuidString: userIDRaw),
            let accessToken = response["access_token"],
            !accessToken.isEmpty
        else {
            throw AuthServiceError.invalidResponse
        }

        let session = UserSession(userID: userID, accessToken: accessToken)
        cachedSession = session
        return session
    }

    public func signOut() async throws {
        cachedSession = nil
    }

    public func currentSession() async throws -> UserSession? {
        cachedSession
    }
}
