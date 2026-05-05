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

    public func load(userID: UUID) -> (remoteId: UUID?, messages: [ChatMessage]) {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key),
              let bundle = try? decoder.decode(LocalTranscript.self, from: data)
        else {
            return (nil, [])
        }
        return (bundle.remoteId, bundle.messages)
    }

    public func save(userID: UUID, remoteId: UUID?, messages: [ChatMessage]) {
        let key = keyPrefix + userID.uuidString
        let bundle = LocalTranscript(remoteId: remoteId, messages: messages)
        guard let data = try? encoder.encode(bundle) else { return }
        userDefaults.set(data, forKey: key)
    }
}

private struct LocalTranscript: Codable {
    var remoteId: UUID?
    var messages: [ChatMessage]
}
