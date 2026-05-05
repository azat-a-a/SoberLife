import Foundation

public protocol OnboardingStore: Sendable {
    func loadProfile(userID: UUID) -> OnboardingProfile?
    func saveProfile(_ profile: OnboardingProfile)
}

public final class UserDefaultsOnboardingStore: OnboardingStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "soberlife.onboarding."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func loadProfile(userID: UUID) -> OnboardingProfile? {
        let key = keyPrefix + userID.uuidString
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(OnboardingProfile.self, from: data)
    }

    public func saveProfile(_ profile: OnboardingProfile) {
        let key = keyPrefix + profile.userID.uuidString
        guard let data = try? encoder.encode(profile) else { return }
        userDefaults.set(data, forKey: key)
    }
}
