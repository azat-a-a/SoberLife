import Foundation

// MARK: - DTOs

public struct SobrietyRecordRowDTO: Decodable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let startDate: String
    public let endDate: String?
    public let isCurrent: Bool
}

public struct SobrietyHistorySnapshot: Sendable, Equatable {
    public let currentStartDate: Date
    public let relapseEvents: [RelapseEvent]

    public init(currentStartDate: Date, relapseEvents: [RelapseEvent]) {
        self.currentStartDate = currentStartDate
        self.relapseEvents = relapseEvents
    }
}

// MARK: - Encodable payloads (explicit keys for PostgREST)

private struct UserSobrietyPatchBody: Encodable {
    let sobriety_start_date: String
    let daily_alcohol_cost: Double?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case sobriety_start_date
        case daily_alcohol_cost
        case name
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sobriety_start_date, forKey: .sobriety_start_date)
        try c.encodeIfPresent(name, forKey: .name)
        if let daily_alcohol_cost {
            try c.encode(daily_alcohol_cost, forKey: .daily_alcohol_cost)
        } else {
            try c.encodeNil(forKey: .daily_alcohol_cost)
        }
    }
}

private struct SobrietyRecordInsertBody: Encodable {
    let user_id: UUID
    let start_date: String
    let end_date: String?
    let is_current: Bool
}

private struct SobrietyRecordPatchBody: Encodable {
    var start_date: String?
    var end_date: String?
    var is_current: Bool?

    enum CodingKeys: String, CodingKey {
        case start_date, end_date, is_current
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(start_date, forKey: .start_date)
        try c.encodeIfPresent(end_date, forKey: .end_date)
        try c.encodeIfPresent(is_current, forKey: .is_current)
    }
}

// MARK: - Sync service

public final class SobrietySupabaseSync: Sendable {
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

    /// Updates `public.users` sobriety fields and ensures one current `sobriety_records` row aligned with local profile.
    public func syncOnboardingProfile(
        userId: UUID,
        profile: SobrietyProfileSnapshot,
        bearerToken: String
    ) async throws {
        let startIso = SobrietyAPIFormatting.isoTimestamp(profile.sobrietyStartDate)
        let userBody = UserSobrietyPatchBody(
            sobriety_start_date: startIso,
            daily_alcohol_cost: profile.dailyAlcoholCost,
            name: profile.displayName
        )
        let encodedUser = try encoder.encode(userBody)
        try await http.restPatch(
            table: "users",
            filter: ["id": userId.uuidString],
            jsonBody: encodedUser,
            bearerToken: bearerToken
        )

        if let current = try await fetchCurrentRecord(userId: userId, bearerToken: bearerToken) {
            let patch = SobrietyRecordPatchBody(
                start_date: startIso,
                end_date: nil,
                is_current: true
            )
            try await patchRecord(id: current.id, body: patch, bearerToken: bearerToken)
        } else {
            let insert = SobrietyRecordInsertBody(
                user_id: userId,
                start_date: startIso,
                end_date: nil,
                is_current: true
            )
            let body = try encoder.encode(insert)
            _ = try await http.restInsert(
                table: "sobriety_records",
                jsonBody: body,
                bearerToken: bearerToken,
                returnRepresentation: false
            )
        }
    }

    /// Closes the current server period and opens a new one; updates `users.sobriety_start_date` from `profile`.
    public func syncRelapse(
        userId: UUID,
        profileAfterRelapse: SobrietyProfileSnapshot,
        newPeriodStart: Date,
        occurredAt: Date,
        bearerToken: String
    ) async throws {
        let startIso = SobrietyAPIFormatting.isoTimestamp(newPeriodStart)
        let endIso = SobrietyAPIFormatting.isoTimestamp(occurredAt)

        if let current = try await fetchCurrentRecord(userId: userId, bearerToken: bearerToken) {
            let closePatch = SobrietyRecordPatchBody(
                start_date: nil,
                end_date: endIso,
                is_current: false
            )
            try await patchRecord(id: current.id, body: closePatch, bearerToken: bearerToken)
        }

        let insert = SobrietyRecordInsertBody(
            user_id: userId,
            start_date: startIso,
            end_date: nil,
            is_current: true
        )
        let insertData = try encoder.encode(insert)
        _ = try await http.restInsert(
            table: "sobriety_records",
            jsonBody: insertData,
            bearerToken: bearerToken,
            returnRepresentation: false
        )

        let userBody = UserSobrietyPatchBody(
            sobriety_start_date: SobrietyAPIFormatting.isoTimestamp(profileAfterRelapse.sobrietyStartDate),
            daily_alcohol_cost: profileAfterRelapse.dailyAlcoholCost,
            name: profileAfterRelapse.displayName
        )
        let encodedUser = try encoder.encode(userBody)
        try await http.restPatch(
            table: "users",
            filter: ["id": userId.uuidString],
            jsonBody: encodedUser,
            bearerToken: bearerToken
        )
    }

    /// Reads all periods from `sobriety_records` and converts them into current period start + relapse events.
    public func fetchHistorySnapshot(userId: UUID, bearerToken: String) async throws -> SobrietyHistorySnapshot? {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "order", value: "start_date.asc")
        ]
        let data = try await http.restSelectRaw(
            table: "sobriety_records",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([SobrietyRecordRowDTO].self, from: data)
        guard rows.isEmpty == false else { return nil }

        guard let current = rows.first(where: \.isCurrent),
              let currentStart = SobrietyAPIFormatting.date(fromISO8601: current.startDate)
        else {
            return nil
        }

        let relapseEvents = rows
            .filter { $0.isCurrent == false }
            .compactMap { row -> RelapseEvent? in
                guard
                    let start = SobrietyAPIFormatting.date(fromISO8601: row.startDate),
                    let endISO = row.endDate,
                    let end = SobrietyAPIFormatting.date(fromISO8601: endISO)
                else {
                    return nil
                }
                let streakDays = SobrietyCounter.soberDays(
                    since: start,
                    now: end,
                    calendar: .current
                )
                return RelapseEvent(
                    occurredAt: end,
                    previousPeriodStart: start,
                    streakAtRelapseDays: streakDays
                )
            }
            .sorted { $0.occurredAt < $1.occurredAt }

        return SobrietyHistorySnapshot(currentStartDate: currentStart, relapseEvents: relapseEvents)
    }

    private func fetchCurrentRecord(userId: UUID, bearerToken: String) async throws -> SobrietyRecordRowDTO? {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "is_current", value: "eq.true"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let data = try await http.restSelectRaw(
            table: "sobriety_records",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([SobrietyRecordRowDTO].self, from: data)
        return rows.first
    }

    private func patchRecord(id: UUID, body: SobrietyRecordPatchBody, bearerToken: String) async throws {
        let data = try encoder.encode(body)
        try await http.restPatch(
            table: "sobriety_records",
            filter: ["id": id.uuidString],
            jsonBody: data,
            bearerToken: bearerToken
        )
    }
}
