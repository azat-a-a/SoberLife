import Foundation

public enum AchievementMilestoneType: Sendable {
    public static let milestonePrefix = "milestone_"

    public static func typeString(milestoneDays: Int) -> String {
        "\(milestonePrefix)\(milestoneDays)"
    }

    public static func parseMilestoneDays(_ type: String) -> Int? {
        guard type.hasPrefix(milestonePrefix) else { return nil }
        let rest = String(type.dropFirst(milestonePrefix.count))
        return Int(rest)
    }
}

private struct AchievementRowDTO: Decodable, Sendable {
    let type: String
}

private struct AchievementUpsertBody: Encodable {
    let user_id: UUID
    let type: String
}

public final class AchievementSupabaseSync: Sendable {
    private let http: HTTPSupabaseService
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(http: HTTPSupabaseService) {
        self.http = http
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func fetchUnlockedMilestoneDays(userId: UUID, bearerToken: String) async throws -> Set<Int> {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "select", value: "type")
        ]
        let data = try await http.restSelectRaw(
            table: "achievements",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([AchievementRowDTO].self, from: data)
        return Set(rows.compactMap { AchievementMilestoneType.parseMilestoneDays($0.type) })
    }

    public func upsertMilestone(userId: UUID, milestoneDays: Int, bearerToken: String) async throws {
        let body = AchievementUpsertBody(
            user_id: userId,
            type: AchievementMilestoneType.typeString(milestoneDays: milestoneDays)
        )
        let data = try encoder.encode(body)
        try await http.restUpsertMerge(
            table: "achievements",
            jsonBody: data,
            bearerToken: bearerToken
        )
    }
}
