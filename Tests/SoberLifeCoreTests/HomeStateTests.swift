import XCTest
import Foundation
@testable import SoberLifeAppShell

@MainActor
final class HomeStateTests: XCTestCase {
    func testLoadCalculatesSoberDaysAndMilestone() {
        let userID = UUID()
        let store = InMemoryHomeOnboardingStore()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        store.saveProfile(
            OnboardingProfile(
                userID: userID,
                goal: .quit,
                sobrietyStartDate: start,
                dailyAlcoholCost: 100,
                notificationsEnabled: true
            )
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_172_800) // day 3

        let state = HomeState(
            userID: userID,
            store: store,
            calendar: calendar,
            nowProvider: { now }
        )
        state.load()

        XCTAssertEqual(state.soberDays, 3)
        XCTAssertEqual(state.nextMilestoneDays, 7)
        XCTAssertEqual(state.milestoneProgress, 3.0 / 7.0, accuracy: 0.0001)
    }

    func testLoadWithoutProfileResetsValues() {
        let state = HomeState(userID: UUID(), store: InMemoryHomeOnboardingStore())
        state.load()

        XCTAssertEqual(state.soberDays, 0)
        XCTAssertEqual(state.nextMilestoneDays, 7)
        XCTAssertEqual(state.milestoneProgress, 0)
        XCTAssertNil(state.sobrietyStartDate)
    }
}

private final class InMemoryHomeOnboardingStore: OnboardingStore, @unchecked Sendable {
    private var profiles: [UUID: OnboardingProfile] = [:]

    func loadProfile(userID: UUID) -> OnboardingProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: OnboardingProfile) {
        profiles[profile.userID] = profile
    }
}
