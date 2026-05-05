import Foundation

public enum UserProfileSync {
    /// Ensures `public.users` has a row for `auth.uid()` (RLS-safe RPC).
    public static func ensureProfileExists(http: HTTPSupabaseService, bearerToken: String) async throws {
        try await http.restRPCVoid(
            function: "ensure_user_profile",
            jsonBody: Data("{}".utf8),
            bearerToken: bearerToken
        )
    }
}
