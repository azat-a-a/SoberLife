import Foundation
import SoberLifeCore

public final class UserDefaultsAIChatTranscriptStore: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "soberlife.chat.transcript."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load(userID: UUID) -> ChatLocalSnapshot {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key),
              let bundle = try? decoder.decode(LocalTranscript.self, from: data)
        else {
            return ChatLocalSnapshot()
        }
        return ChatLocalSnapshot(
            remoteId: bundle.remoteId,
            selectedConversationId: bundle.selectedConversationId,
            messages: bundle.messages
        )
    }

    public func save(_ snapshot: ChatLocalSnapshot, userID: UUID) {
        let key = keyPrefix + userID.uuidString
        let bundle = LocalTranscript(
            remoteId: snapshot.remoteId,
            selectedConversationId: snapshot.selectedConversationId,
            messages: snapshot.messages
        )
        guard let data = try? encoder.encode(bundle) else { return }
        userDefaults.set(data, forKey: key)
    }
}

public struct ChatLocalSnapshot: Sendable, Equatable {
    public var remoteId: UUID?
    public var selectedConversationId: UUID?
    public var messages: [ChatMessage]

    public init(
        remoteId: UUID? = nil,
        selectedConversationId: UUID? = nil,
        messages: [ChatMessage] = []
    ) {
        self.remoteId = remoteId
        self.selectedConversationId = selectedConversationId
        self.messages = messages
    }
}

private struct LocalTranscript: Codable {
    var remoteId: UUID?
    var selectedConversationId: UUID?
    var messages: [ChatMessage]
}
