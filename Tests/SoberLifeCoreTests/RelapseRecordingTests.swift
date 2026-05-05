import XCTest
import Foundation
@testable import SoberLifeAppShell
@testable import SoberLifeCore

@MainActor
final class RelapseRecordingTests: XCTestCase {
    func testRecordRelapsePreservesMilestonesPathAndAppendsHistory() {
        let userID = UUID()
        let profileStore = InMemoryRelapseProfileStore()
        let history = InMemoryRelapseEventStore()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        profileStore.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: start,
                dailyAlcoholCost: nil,
                notificationsEnabled: true
            )
        )
        let now = Date(timeIntervalSince1970: 1_700_172_800)

        RelapseRecording.recordRelapse(
            userID: userID,
            newPeriodStart: now,
            now: now,
            calendar: calendar,
            profileStore: profileStore,
            historyStore: history
        )

        let events = history.events(userID: userID)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].streakAtRelapseDays, 3)
        XCTAssertEqual(events[0].previousPeriodStart, start)

        let updated = profileStore.loadProfile(userID: userID)!
        XCTAssertEqual(updated.sobrietyStartDate, calendar.startOfDay(for: now))
    }
}

private final class InMemoryRelapseProfileStore: OnboardingStore, @unchecked Sendable {
    private var profiles: [UUID: OnboardingProfile] = [:]

    func loadProfile(userID: UUID) -> OnboardingProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: OnboardingProfile) {
        profiles[profile.userID] = profile
    }
}

private final class InMemoryRelapseEventStore: RelapseHistoryStore, @unchecked Sendable {
    private var storage: [UUID: [RelapseEvent]] = [:]

    func events(userID: UUID) -> [RelapseEvent] {
        storage[userID] ?? []
    }

    func append(_ event: RelapseEvent, userID: UUID) {
        storage[userID, default: []].append(event)
    }
}
