import Foundation

// MARK: - DTOs (PostgREST / jsonb)

public struct AIConversationRowDTO: Decodable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let messages: [PersistedChatLineDTO]
    public let conversationType: String
    public let createdAt: String?
}

public struct AIChatThread: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let createdAt: Date?
    public let messages: [ChatMessage]

    public init(id: UUID, createdAt: Date?, messages: [ChatMessage]) {
        self.id = id
        self.createdAt = createdAt
        self.messages = messages
    }

    public var preview: String {
        if let last = messages.last {
            let prefix = last.role == "user" ? "" : "Assistant: "
            let trimmed = last.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "Empty chat" }
            return prefix + String(trimmed.prefix(88))
        }
        return "Empty chat"
    }
}

public struct PersistedChatLineDTO: Codable, Sendable, Equatable {
    public let role: String
    public let content: String
    public let timestamp: String

    public init(role: String, content: String, timestamp: String) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public enum AIConversationRESTMapper {
    public static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    public static func fallbackISO8601() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }

    public static func encodeLines(_ messages: [ChatMessage]) -> [PersistedChatLineDTO] {
        let primary = iso8601
        let fallback = fallbackISO8601()
        return messages.map { msg in
            var ts = primary.string(from: msg.timestamp)
            if ts.isEmpty { ts = fallback.string(from: msg.timestamp) }
            return PersistedChatLineDTO(role: msg.role, content: msg.content, timestamp: ts)
        }
    }

    public static func decodeLines(_ lines: [PersistedChatLineDTO]) -> [ChatMessage] {
        let primary = iso8601
        let fallback = fallbackISO8601()
        return lines.map { line in
            if let d = primary.date(from: line.timestamp) ?? fallback.date(from: line.timestamp) {
                return ChatMessage(role: line.role, content: line.content, timestamp: d)
            }
            return ChatMessage(role: line.role, content: line.content, timestamp: Date())
        }
    }
}

// MARK: - Supabase persistence

private struct AIConversationInsertPayload: Encodable {
    let userId: UUID
    let conversationType: String
    let messages: [PersistedChatLineDTO]
}

private struct AIConversationPatchPayload: Encodable {
    let messages: [PersistedChatLineDTO]
}

public final class SupabaseAIChatHistoryStore: Sendable {
    private let http: HTTPSupabaseService
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(http: HTTPSupabaseService) {
        self.http = http
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    public func fetchChatThreads(
        userID: UUID,
        bearerToken: String,
        limit: Int = 40
    ) async throws -> [AIChatThread] {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
            URLQueryItem(name: "conversation_type", value: "eq.chat"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let data = try await http.restSelectRaw(
            table: "ai_conversations",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([AIConversationRowDTO].self, from: data)
        return rows.map { row in
            AIChatThread(
                id: row.id,
                createdAt: Self.parseCreatedAt(row.createdAt),
                messages: AIConversationRESTMapper.decodeLines(row.messages)
            )
        }
    }

    public func fetchConversation(id: UUID, bearerToken: String) async throws -> AIChatThread? {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        let data = try await http.restSelectRaw(
            table: "ai_conversations",
            queryItems: items,
            bearerToken: bearerToken
        )
        let rows = try decoder.decode([AIConversationRowDTO].self, from: data)
        guard let row = rows.first else { return nil }
        return AIChatThread(
            id: row.id,
            createdAt: Self.parseCreatedAt(row.createdAt),
            messages: AIConversationRESTMapper.decodeLines(row.messages)
        )
    }

    private static func parseCreatedAt(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        return AIConversationRESTMapper.iso8601.date(from: raw)
            ?? AIConversationRESTMapper.fallbackISO8601().date(from: raw)
    }

    public func insertChat(userID: UUID, messages: [ChatMessage], bearerToken: String) async throws -> UUID {
        let payload = AIConversationInsertPayload(
            userId: userID,
            conversationType: ConversationType.chat.rawValue,
            messages: AIConversationRESTMapper.encodeLines(messages)
        )
        let body = try encoder.encode(payload)
        let data = try await http.restInsert(
            table: "ai_conversations",
            jsonBody: body,
            bearerToken: bearerToken,
            returnRepresentation: true
        )
        let rows = try decoder.decode([AIConversationRowDTO].self, from: data)
        guard let id = rows.first?.id else {
            throw SupabaseHTTPServiceError.decodingFailed
        }
        return id
    }

    public func updateMessages(conversationId: UUID, messages: [ChatMessage], bearerToken: String) async throws {
        let payload = AIConversationPatchPayload(messages: AIConversationRESTMapper.encodeLines(messages))
        let body = try encoder.encode(payload)
        try await http.restPatch(
            table: "ai_conversations",
            filter: ["id": conversationId.uuidString],
            jsonBody: body,
            bearerToken: bearerToken
        )
    }
}
