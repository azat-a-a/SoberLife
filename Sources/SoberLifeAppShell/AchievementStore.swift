import Foundation

public protocol AchievementStore: Sendable {
    func unlockedMilestones(userID: UUID) -> Set<Int>
    func saveUnlockedMilestones(_ milestones: Set<Int>, userID: UUID)
}

public final class UserDefaultsAchievementStore: AchievementStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let keyPrefix = "soberlife.achievements."

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func unlockedMilestones(userID: UUID) -> Set<Int> {
        let key = keyPrefix + userID.uuidString
        let values = userDefaults.array(forKey: key) as? [Int] ?? []
        return Set(values)
    }

    public func saveUnlockedMilestones(_ milestones: Set<Int>, userID: UUID) {
        let key = keyPrefix + userID.uuidString
        userDefaults.set(Array(milestones).sorted(), forKey: key)
    }
}
