import Foundation

public struct ChatMessage: Sendable, Equatable, Codable {
    public let role: String
    public let content: String
    public let timestamp: Date

    public init(role: String, content: String, timestamp: Date) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public struct AIContext: Sendable, Equatable, Codable {
    public let soberDays: Int?
    public let recentTriggers: [String]
    public let recentJournalNotes: [String]

    public init(soberDays: Int? = nil, recentTriggers: [String] = [], recentJournalNotes: [String] = []) {
        self.soberDays = soberDays
        self.recentTriggers = recentTriggers
        self.recentJournalNotes = recentJournalNotes
    }
}

public struct AIReply: Sendable, Equatable, Codable {
    public let reply: String
    public let suggestedActions: [String]
    public let riskFlags: [String]

    public init(reply: String, suggestedActions: [String] = [], riskFlags: [String] = []) {
        self.reply = reply
        self.suggestedActions = suggestedActions
        self.riskFlags = riskFlags
    }
}

public struct UserSession: Sendable, Equatable {
    public let userID: UUID
    public let accessToken: String

    public init(userID: UUID, accessToken: String) {
        self.userID = userID
        self.accessToken = accessToken
    }
}

/// Result of Supabase Auth password grant or sign-up when a session is issued.
public struct SupabasePasswordAuthResult: Sendable, Equatable {
    public let accessToken: String
    public let userID: UUID

    public init(accessToken: String, userID: UUID) {
        self.accessToken = accessToken
        self.userID = userID
    }
}

public struct NotificationPayload: Sendable, Equatable {
    public let title: String
    public let body: String
    public let deepLink: String?

    public init(title: String, body: String, deepLink: String? = nil) {
        self.title = title
        self.body = body
        self.deepLink = deepLink
    }
}

public struct NotificationPreferences: Sendable, Equatable, Codable {
    public let dailyEnabled: Bool
    public let milestoneEnabled: Bool
    public let reengagementEnabled: Bool
    /// Local hour 0–23 for repeating daily (and milestone / re-engagement time-of-day).
    public let dailyReminderHour: Int
    public let dailyReminderMinute: Int
    /// Inclusive start hour 0–23 when paired with `quietHoursEnd`. If either is `nil`, quiet hours are off.
    public let quietHoursStart: Int?
    /// Exclusive end hour 0–23 for non-wrapping intervals, or morning “open” hour when the window wraps past midnight.
    public let quietHoursEnd: Int?

    enum CodingKeys: String, CodingKey {
        case dailyEnabled, milestoneEnabled, reengagementEnabled
        case dailyReminderHour, dailyReminderMinute
        case quietHoursStart, quietHoursEnd
    }

    public init(
        dailyEnabled: Bool = true,
        milestoneEnabled: Bool = true,
        reengagementEnabled: Bool = true,
        dailyReminderHour: Int = 10,
        dailyReminderMinute: Int = 0,
        quietHoursStart: Int? = nil,
        quietHoursEnd: Int? = nil
    ) {
        self.dailyEnabled = dailyEnabled
        self.milestoneEnabled = milestoneEnabled
        self.reengagementEnabled = reengagementEnabled
        self.dailyReminderHour = min(23, max(0, dailyReminderHour))
        self.dailyReminderMinute = min(59, max(0, dailyReminderMinute))
        self.quietHoursStart = quietHoursStart.map { min(23, max(0, $0)) }
        self.quietHoursEnd = quietHoursEnd.map { min(23, max(0, $0)) }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyEnabled = try c.decodeIfPresent(Bool.self, forKey: .dailyEnabled) ?? true
        milestoneEnabled = try c.decodeIfPresent(Bool.self, forKey: .milestoneEnabled) ?? true
        reengagementEnabled = try c.decodeIfPresent(Bool.self, forKey: .reengagementEnabled) ?? true
        let h = try c.decodeIfPresent(Int.self, forKey: .dailyReminderHour) ?? 10
        let m = try c.decodeIfPresent(Int.self, forKey: .dailyReminderMinute) ?? 0
        dailyReminderHour = min(23, max(0, h))
        dailyReminderMinute = min(59, max(0, m))
        quietHoursStart = try c.decodeIfPresent(Int.self, forKey: .quietHoursStart).map { min(23, max(0, $0)) }
        quietHoursEnd = try c.decodeIfPresent(Int.self, forKey: .quietHoursEnd).map { min(23, max(0, $0)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(dailyEnabled, forKey: .dailyEnabled)
        try c.encode(milestoneEnabled, forKey: .milestoneEnabled)
        try c.encode(reengagementEnabled, forKey: .reengagementEnabled)
        try c.encode(dailyReminderHour, forKey: .dailyReminderHour)
        try c.encode(dailyReminderMinute, forKey: .dailyReminderMinute)
        try c.encodeIfPresent(quietHoursStart, forKey: .quietHoursStart)
        try c.encodeIfPresent(quietHoursEnd, forKey: .quietHoursEnd)
    }
}

public struct SupportContact: Codable, Sendable, Equatable {
    public var trustedName: String
    public var trustedPhone: String

    public init(trustedName: String = "", trustedPhone: String = "") {
        self.trustedName = trustedName
        self.trustedPhone = trustedPhone
    }

    public var hasCallableNumber: Bool {
        trustedPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

public enum ConversationType: String, Sendable {
    case chat
    case sos
    case daily
    case analysis
}

public enum NotificationCategory: Sendable, Equatable {
    case daily
    case milestone(days: Int)
    case reengagement
}

public protocol AuthService: Sendable {
    func signIn(email: String, password: String) async throws -> UserSession
    func signUp(email: String, password: String) async throws -> UserSession
    func signOut() async throws
    func currentSession() async throws -> UserSession?
}

public protocol SupabaseService: Sendable {
    func select(table: String, filter: [String: String]) async throws -> [[String: String]]
    func insert(table: String, values: [String: String]) async throws
    func invoke(function: String, payload: [String: String]) async throws -> [String: String]
    func authSignIn(email: String, password: String) async throws -> SupabasePasswordAuthResult
    func authSignUp(email: String, password: String) async throws -> SupabasePasswordAuthResult
}

public protocol AIService: Sendable {
    func send(
        userID: UUID,
        conversationType: ConversationType,
        messages: [ChatMessage],
        context: AIContext
    ) async throws -> AIReply
}

public protocol NotificationService: Sendable {
    func requestPermission() async -> Bool
    func updatePreferences(_ preferences: NotificationPreferences, for userID: UUID) async throws
    func schedule(category: NotificationCategory, payload: NotificationPayload, for userID: UUID, at: Date?) async throws
    /// Removes pending notifications whose identifiers match the given prefix (used to dedupe milestone schedules).
    func removePending(withIdentifierPrefix prefix: String) async throws
}

public enum NotificationIdentifiers {
    public static func dailyReminder(userID: UUID) -> String {
        "soberlife.daily.\(userID.uuidString)"
    }

    public static func milestone(userID: UUID, milestoneDays: Int) -> String {
        "soberlife.milestone.\(userID.uuidString).\(milestoneDays)"
    }

    public static func milestonePrefix(userID: UUID) -> String {
        "soberlife.milestone.\(userID.uuidString)."
    }

    public static func reengagement(userID: UUID) -> String {
        "soberlife.reengagement.\(userID.uuidString)"
    }
}
