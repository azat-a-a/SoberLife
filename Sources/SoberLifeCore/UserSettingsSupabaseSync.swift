import Foundation

// MARK: - Row DTOs

private struct NotificationPreferencesRowDTO: Decodable, Sendable {
    let userId: UUID
    let dailyEnabled: Bool
    let milestoneEnabled: Bool
    let reengagementEnabled: Bool
    let dailyReminderHour: Int
    let dailyReminderMinute: Int
    let quietHoursStart: Int?
    let quietHoursEnd: Int?
}

private struct SupportContactRowDTO: Decodable, Sendable {
    let userId: UUID
    let trustedName: String?
    let trustedPhone: String?
}

// MARK: - Upsert bodies

private struct NotificationPreferencesUpsertBody: Encodable {
    let user_id: UUID
    let daily_enabled: Bool
    let milestone_enabled: Bool
    let reengagement_enabled: Bool
    let daily_reminder_hour: Int
    let daily_reminder_minute: Int
    let quiet_hours_start: Int?
    let quiet_hours_end: Int?
}

private struct SupportContactUpsertBody: Encodable {
    let user_id: UUID
    let trusted_name: String?
    let trusted_phone: String?
}

// MARK: - Sync

public final class UserSettingsSupabaseSync: Sendable {
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

    /// Cloud wins when a row exists; otherwise uploads `local` and returns it.
    public func resolveNotificationPreferences(
        userId: UUID,
        local: NotificationPreferences,
        bearerToken: String
    ) async throws -> NotificationPreferences {
        if let cloud = try await fetchNotificationPreferences(userId: userId, bearerToken: bearerToken) {
            return cloud
        }
        try await upsertNotificationPreferences(userId: userId, preferences: local, bearerToken: bearerToken)
        return local
    }

    /// Cloud wins when a row exists; otherwise uploads `local` and returns it.
    public func resolveSupportContact(
        userId: UUID,
        local: SupportContact,
        bearerToken: String
    ) async throws -> SupportContact {
        if let cloud = try await fetchSupportContact(userId: userId, bearerToken: bearerToken) {
            return cloud
        }
        try await upsertSupportContact(userId: userId, contact: local, bearerToken: bearerToken)
        return local
    }

    public func fetchNotificationPreferences(
        userId: UUID,
        bearerToken: String
    ) async throws -> NotificationPreferences? {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let data = try await http.restSelectRaw(
            table: "notification_preferences",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([NotificationPreferencesRowDTO].self, from: data)
        guard let row = rows.first else { return nil }
        return NotificationPreferences(
            dailyEnabled: row.dailyEnabled,
            milestoneEnabled: row.milestoneEnabled,
            reengagementEnabled: row.reengagementEnabled,
            dailyReminderHour: row.dailyReminderHour,
            dailyReminderMinute: row.dailyReminderMinute,
            quietHoursStart: row.quietHoursStart,
            quietHoursEnd: row.quietHoursEnd
        )
    }

    public func upsertNotificationPreferences(
        userId: UUID,
        preferences: NotificationPreferences,
        bearerToken: String
    ) async throws {
        let body = NotificationPreferencesUpsertBody(
            user_id: userId,
            daily_enabled: preferences.dailyEnabled,
            milestone_enabled: preferences.milestoneEnabled,
            reengagement_enabled: preferences.reengagementEnabled,
            daily_reminder_hour: preferences.dailyReminderHour,
            daily_reminder_minute: preferences.dailyReminderMinute,
            quiet_hours_start: preferences.quietHoursStart,
            quiet_hours_end: preferences.quietHoursEnd
        )
        let data = try encoder.encode(body)
        try await http.restUpsertMerge(
            table: "notification_preferences",
            jsonBody: data,
            bearerToken: bearerToken
        )
    }

    public func fetchSupportContact(userId: UUID, bearerToken: String) async throws -> SupportContact? {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let data = try await http.restSelectRaw(
            table: "support_contacts",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([SupportContactRowDTO].self, from: data)
        guard let row = rows.first else { return nil }
        return SupportContact(
            trustedName: row.trustedName ?? "",
            trustedPhone: row.trustedPhone ?? ""
        )
    }

    public func upsertSupportContact(
        userId: UUID,
        contact: SupportContact,
        bearerToken: String
    ) async throws {
        let trimmedName = contact.trustedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = contact.trustedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = SupportContactUpsertBody(
            user_id: userId,
            trusted_name: trimmedName.isEmpty ? nil : trimmedName,
            trusted_phone: trimmedPhone.isEmpty ? nil : trimmedPhone
        )
        let data = try encoder.encode(body)
        try await http.restUpsertMerge(
            table: "support_contacts",
            jsonBody: data,
            bearerToken: bearerToken
        )
    }
}
