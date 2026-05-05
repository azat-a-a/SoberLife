import Foundation

public enum SupabaseJWT {
    /// Heuristic: real Supabase access tokens are JWT-shaped (three segments).
    public static func isLikelyUserAccessToken(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return false }
        return token != "placeholder-token"
    }
}
