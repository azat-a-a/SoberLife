import Foundation

public enum AIServiceError: Error, Equatable {
    case invalidResponse
    case timeout
}

public actor DeepSeekAIService: AIService {
    private let supabaseService: SupabaseService
    private let timeoutSeconds: Double
    private let maxRetries: Int
    private let retryBaseDelayNanoseconds: UInt64
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        supabaseService: SupabaseService,
        timeoutSeconds: Double = 10,
        maxRetries: Int = 2,
        retryBaseDelayNanoseconds: UInt64 = 250_000_000
    ) {
        self.supabaseService = supabaseService
        self.timeoutSeconds = timeoutSeconds
        self.maxRetries = maxRetries
        self.retryBaseDelayNanoseconds = retryBaseDelayNanoseconds
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func send(
        userID: UUID,
        conversationType: ConversationType,
        messages: [ChatMessage],
        context: AIContext
    ) async throws -> AIReply {
        let messagesJSON = try serialize(messages)
        let contextJSON = try serialize(context)

        let payload: [String: String] = [
            "user_id": userID.uuidString,
            "conversation_type": conversationType.rawValue,
            "messages_json": messagesJSON,
            "context_json": contextJSON
        ]

        var attempt = 0
        while true {
            do {
                let response = try await withTimeout(seconds: timeoutSeconds) {
                    try await self.supabaseService.invoke(function: "deepseek-chat", payload: payload)
                }
                return try parseReply(response)
            } catch {
                if attempt >= maxRetries {
                    throw error
                }
                attempt += 1
                let backoffMultiplier = UInt64(1 << (attempt - 1))
                try await Task.sleep(nanoseconds: retryBaseDelayNanoseconds * backoffMultiplier)
            }
        }
    }

    private func serialize<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        return text
    }

    private func parseReply(_ response: [String: String]) throws -> AIReply {
        guard let reply = response["reply"], !reply.isEmpty else {
            throw AIServiceError.invalidResponse
        }

        let suggestedActions = parseStringArray(response["suggested_actions_json"])
        let riskFlags = parseStringArray(response["risk_flags_json"])
        return AIReply(reply: reply, suggestedActions: suggestedActions, riskFlags: riskFlags)
    }

    private func parseStringArray(_ jsonString: String?) -> [String] {
        guard let jsonString, let data = jsonString.data(using: .utf8) else {
            return []
        }
        return (try? decoder.decode([String].self, from: data)) ?? []
    }

    private func withTimeout<T>(
        seconds: Double,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AIServiceError.timeout
            }

            let first = try await group.next()!
            group.cancelAll()
            return first
        }
    }
}
