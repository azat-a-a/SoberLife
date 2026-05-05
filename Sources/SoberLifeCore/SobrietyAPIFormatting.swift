import Foundation

public enum SobrietyAPIFormatting {
    public static func isoTimestamp(_ date: Date) -> String {
        let primary = ISO8601DateFormatter()
        primary.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let a = primary.string(from: date)
        if !a.isEmpty { return a }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.string(from: date)
    }
}
