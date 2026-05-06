import Foundation
import SoberLifeCore

public protocol SupportContactStore: Sendable {
    func loadContact(userID: UUID) -> SupportContact
    func saveContact(_ contact: SupportContact, userID: UUID)
}

public final class UserDefaultsSupportContactStore: SupportContactStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "soberlife.support.contact."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func loadContact(userID: UUID) -> SupportContact {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key) else { return SupportContact() }
        return (try? decoder.decode(SupportContact.self, from: data)) ?? SupportContact()
    }

    public func saveContact(_ contact: SupportContact, userID: UUID) {
        let key = keyPrefix + userID.uuidString
        guard let data = try? encoder.encode(contact) else { return }
        userDefaults.set(data, forKey: key)
    }
}
