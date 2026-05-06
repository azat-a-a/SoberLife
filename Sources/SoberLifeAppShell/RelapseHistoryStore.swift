import Foundation
import SoberLifeCore

public protocol RelapseHistoryStore: Sendable {
    func events(userID: UUID) -> [RelapseEvent]
    func append(_ event: RelapseEvent, userID: UUID)
    func replaceEvents(_ events: [RelapseEvent], userID: UUID)
}

public final class UserDefaultsRelapseHistoryStore: RelapseHistoryStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "soberlife.relapse.history."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func events(userID: UUID) -> [RelapseEvent] {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([RelapseEvent].self, from: data)) ?? []
    }

    public func append(_ event: RelapseEvent, userID: UUID) {
        var list = events(userID: userID)
        list.append(event)
        replaceEvents(list, userID: userID)
    }

    public func replaceEvents(_ events: [RelapseEvent], userID: UUID) {
        let key = keyPrefix + userID.uuidString
        guard let data = try? encoder.encode(events) else { return }
        userDefaults.set(data, forKey: key)
    }
}
