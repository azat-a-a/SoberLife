import XCTest
import Foundation
@testable import SoberLifeCore
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
            relapseStore: InMemoryRelapseStore(),
            achievementStore: achievementStore,
            calendar: calendar,
            nowProvider: { now }
        )
        state.load()

        XCTAssertEqual(state.currentStreakDays, 3)
        XCTAssertEqual(state.longestStreakDays, 3)
        XCTAssertEqual(state.honestyCheckIns, 0)
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
            relapseStore: InMemoryRelapseStore(),
            achievementStore: InMemoryAchievementStore()
        )
        state.load()

        XCTAssertEqual(state.currentStreakDays, 0)
        XCTAssertEqual(state.longestStreakDays, 0)
        XCTAssertEqual(state.honestyCheckIns, 0)
        XCTAssertEqual(state.savedMoney, 0)
        XCTAssertEqual(state.nextMilestoneDays, 7)
        XCTAssertEqual(state.progressPercent, 0)
        XCTAssertTrue(state.periodSummaries.isEmpty)
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
            relapseStore: InMemoryRelapseStore(),
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

    func testLongestStreakUsesRelapseHistory() {
        let userID = UUID()
        let store = InMemoryStatsStore()
        let relapseStore = InMemoryRelapseStore()
        relapseStore.append(
            RelapseEvent(
                occurredAt: Date(timeIntervalSince1970: 1_700_600_000),
                previousPeriodStart: Date(timeIntervalSince1970: 1_700_000_000),
                streakAtRelapseDays: 14
            ),
            userID: userID
        )
        let start = Date(timeIntervalSince1970: 1_700_700_000)
        store.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: start,
                dailyAlcoholCost: 10,
                notificationsEnabled: true
            )
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_786_400)

        let state = StatsState(
            userID: userID,
            store: store,
            relapseStore: relapseStore,
            achievementStore: InMemoryAchievementStore(),
            calendar: calendar,
            nowProvider: { now }
        )
        state.load()

        XCTAssertEqual(state.currentStreakDays, 2)
        XCTAssertEqual(state.longestStreakDays, 14)
        XCTAssertEqual(state.honestyCheckIns, 1)
        XCTAssertEqual(state.periodSummaries.count, 2)
        XCTAssertTrue(state.periodSummaries[0].isCurrent)
        XCTAssertFalse(state.periodSummaries[1].isCurrent)
        XCTAssertEqual(state.periodSummaries[1].soberDaysCounted, 14)
    }

    func testMilestonesPersistAcrossRelapseWithoutDuplicates() {
        let userID = UUID()
        let store = InMemoryStatsStore()
        let achievementStore = InMemoryAchievementStore()
        let relapseStore = InMemoryRelapseStore()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
        let day7 = Date(timeIntervalSince1970: 1_700_518_400)

        let stateAt7 = StatsState(
            userID: userID,
            store: store,
            relapseStore: relapseStore,
            achievementStore: achievementStore,
            calendar: calendar,
            nowProvider: { day7 }
        )
        stateAt7.load()
        XCTAssertEqual(stateAt7.unlockedMilestones, [7])
        XCTAssertEqual(stateAt7.newlyUnlockedMilestones, [7])

        let relapseAt = Date(timeIntervalSince1970: 1_700_600_000)
        relapseStore.append(
            RelapseEvent(
                occurredAt: relapseAt,
                previousPeriodStart: start,
                streakAtRelapseDays: 7
            ),
            userID: userID
        )
        store.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: relapseAt,
                dailyAlcoholCost: 0,
                notificationsEnabled: true
            )
        )
        let shortlyAfter = Date(timeIntervalSince1970: 1_700_691_200)

        let stateAfter = StatsState(
            userID: userID,
            store: store,
            relapseStore: relapseStore,
            achievementStore: achievementStore,
            calendar: calendar,
            nowProvider: { shortlyAfter }
        )
        stateAfter.load()
        XCTAssertEqual(stateAfter.unlockedMilestones, [7])
        XCTAssertTrue(stateAfter.newlyUnlockedMilestones.isEmpty)

        stateAfter.load()
        XCTAssertEqual(stateAfter.unlockedMilestones, [7])
        XCTAssertTrue(stateAfter.newlyUnlockedMilestones.isEmpty)
    }
}

private final class InMemoryRelapseStore: RelapseHistoryStore, @unchecked Sendable {
    private var storage: [UUID: [RelapseEvent]] = [:]

    func events(userID: UUID) -> [RelapseEvent] {
        storage[userID] ?? []
    }

    func append(_ event: RelapseEvent, userID: UUID) {
        storage[userID, default: []].append(event)
    }

    func replaceEvents(_ events: [RelapseEvent], userID: UUID) {
        storage[userID] = events
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
