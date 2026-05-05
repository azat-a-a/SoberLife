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

public struct NotificationPreferences: Sendable, Equatable {
    public let dailyEnabled: Bool
    public let milestoneEnabled: Bool
    public let reengagementEnabled: Bool
    public let quietHoursStart: Int?
    public let quietHoursEnd: Int?

    public init(
        dailyEnabled: Bool = true,
        milestoneEnabled: Bool = true,
        reengagementEnabled: Bool = true,
        quietHoursStart: Int? = nil,
        quietHoursEnd: Int? = nil
    ) {
        self.dailyEnabled = dailyEnabled
        self.milestoneEnabled = milestoneEnabled
        self.reengagementEnabled = reengagementEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}

public enum ConversationType: String, Sendable {
    case chat
    case sos
    case daily
    case analysis
}

public enum NotificationCategory: String, Sendable {
    case daily
    case milestone
    case reengagement
}

public protocol AuthService: Sendable {
    func signInWithApple(idToken: String, nonce: String?) async throws -> UserSession
    func signOut() async throws
    func currentSession() async throws -> UserSession?
}

public protocol SupabaseService: Sendable {
    func select(table: String, filter: [String: String]) async throws -> [[String: String]]
    func insert(table: String, values: [String: String]) async throws
    func invoke(function: String, payload: [String: String]) async throws -> [String: String]
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
}
