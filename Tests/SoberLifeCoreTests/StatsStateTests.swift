import XCTest
import Foundation
@testable import SoberLifeAppShell

@MainActor
final class StatsStateTests: XCTestCase {
    func testLoadComputesStatsFromProfile() {
        let userID = UUID()
        let store = InMemoryStatsStore()
        let achievementStore = InMemoryAchievementStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        store.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: start,
                dailyAlcoholCost: 200,
                notificationsEnabled: true
            )
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_172_800) // day 3

        let state = StatsState(
            userID: userID,
            store: store,
            achievementStore: achievementStore,
            calendar: calendar,
            nowProvider: { now }
        )
        state.load()

        XCTAssertEqual(state.currentStreakDays, 3)
        XCTAssertEqual(state.savedMoney, 600, accuracy: 0.0001)
        XCTAssertEqual(state.nextMilestoneDays, 7)
        XCTAssertEqual(state.progressPercent, 42)
        XCTAssertEqual(state.unlockedMilestones, [])
        XCTAssertEqual(state.newlyUnlockedMilestones, [])
    }

    func testLoadWithoutProfileResetsStats() {
        let state = StatsState(
            userID: UUID(),
            store: InMemoryStatsStore(),
            achievementStore: InMemoryAchievementStore()
        )
        state.load()

        XCTAssertEqual(state.currentStreakDays, 0)
        XCTAssertEqual(state.savedMoney, 0)
        XCTAssertEqual(state.nextMilestoneDays, 7)
        XCTAssertEqual(state.progressPercent, 0)
    }

    func testMilestonesUnlockOnceOnly() {
        let userID = UUID()
        let store = InMemoryStatsStore()
        let achievementStore = InMemoryAchievementStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        store.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: start,
                dailyAlcoholCost: 0,
                notificationsEnabled: true
            )
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_518_400) // day 7

        let state = StatsState(
            userID: userID,
            store: store,
            achievementStore: achievementStore,
            calendar: calendar,
            nowProvider: { now }
        )

        state.load()
        XCTAssertEqual(state.unlockedMilestones, [7])
        XCTAssertEqual(state.newlyUnlockedMilestones, [7])

        state.load()
        XCTAssertEqual(state.unlockedMilestones, [7])
        XCTAssertEqual(state.newlyUnlockedMilestones, [])
    }
}

private final class InMemoryStatsStore: OnboardingStore, @unchecked Sendable {
    private var profiles: [UUID: OnboardingProfile] = [:]

    func loadProfile(userID: UUID) -> OnboardingProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: OnboardingProfile) {
        profiles[profile.userID] = profile
    }
}

private final class InMemoryAchievementStore: AchievementStore, @unchecked Sendable {
    private var storage: [UUID: Set<Int>] = [:]

    func unlockedMilestones(userID: UUID) -> Set<Int> {
        storage[userID] ?? []
    }

    func saveUnlockedMilestones(_ milestones: Set<Int>, userID: UUID) {
        storage[userID] = milestones
    }
}
