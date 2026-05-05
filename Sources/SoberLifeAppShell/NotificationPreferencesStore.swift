import Foundation
import SoberLifeCore

public protocol NotificationPreferencesStore: Sendable {
    func load(userID: UUID) -> NotificationPreferences
    func save(_ preferences: NotificationPreferences, userID: UUID)
}

public final class UserDefaultsNotificationPreferencesStore: NotificationPreferencesStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "soberlife.notification.prefs."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load(userID: UUID) -> NotificationPreferences {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key),
              let prefs = try? decoder.decode(NotificationPreferences.self, from: data)
        else { return NotificationPreferences() }
        return prefs
    }

    public func save(_ preferences: NotificationPreferences, userID: UUID) {
        let key = keyPrefix + userID.uuidString
        guard let data = try? encoder.encode(preferences) else { return }
        userDefaults.set(data, forKey: key)
    }
}
