import XCTest
import Foundation
@testable import SoberLifeAppShell

@MainActor
final class OnboardingStateTests: XCTestCase {
    func testStartsIncompleteWithoutStoredProfile() {
        let state = OnboardingState(userID: UUID(), store: InMemoryOnboardingStore())
        XCTAssertFalse(state.isCompleted)
        XCTAssertEqual(state.currentStep, 0)
    }

    func testCompletingOnboardingPersistsProfile() {
        let store = InMemoryOnboardingStore()
        let userID = UUID()
        let state = OnboardingState(userID: userID, store: store)
        state.selectedGoal = .quit
        state.dailyAlcoholCostText = "123.50"
        state.notificationsEnabled = true

        state.complete()

        XCTAssertTrue(state.isCompleted)
        let stored = store.loadProfile(userID: userID)
        XCTAssertEqual(stored?.goal, .quit)
        XCTAssertEqual(stored?.dailyAlcoholCost, 123.50)
        XCTAssertEqual(stored?.notificationsEnabled, true)
    }

    func testRestoresCompletedProfileFromStore() {
        let store = InMemoryOnboardingStore()
        let userID = UUID()
        let profile = OnboardingProfile(
            userID: userID,
            goal: .reduce,
            sobrietyStartDate: Date(timeIntervalSince1970: 1_700_000_000),
            dailyAlcoholCost: 321,
            notificationsEnabled: false
        )
        store.saveProfile(profile)

        let state = OnboardingState(userID: userID, store: store)

        XCTAssertTrue(state.isCompleted)
        XCTAssertEqual(state.selectedGoal, .reduce)
        XCTAssertEqual(state.notificationsEnabled, false)
    }
}

private final class InMemoryOnboardingStore: OnboardingStore, @unchecked Sendable {
    private var profiles: [UUID: OnboardingProfile] = [:]

    func loadProfile(userID: UUID) -> OnboardingProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: OnboardingProfile) {
        profiles[profile.userID] = profile
    }
}
