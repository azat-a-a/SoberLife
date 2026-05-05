import XCTest
import Foundation
@testable import SoberLifeAppShell
@testable import SoberLifeCore

final class NotificationScheduleSyncTests: XCTestCase {
    func testSyncRemovesPendingBeforeScheduling() async throws {
        let userID = UUID()
        let mock = MockNotificationServiceActor()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let profile = OnboardingProfile(
            userID: userID,
            goal: .quit,
            sobrietyStartDate: start,
            dailyAlcoholCost: nil,
            notificationsEnabled: true
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_086_400)

        try await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            currentStreakDays: 2,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: calendar,
            now: now
        )

        let removed = await mock.removedPrefixes
        let scheduled = await mock.scheduledCategories
        XCTAssertTrue(removed.contains(NotificationIdentifiers.dailyReminder(userID: userID)))
        XCTAssertTrue(removed.contains(NotificationIdentifiers.milestonePrefix(userID: userID)))
        XCTAssertTrue(scheduled.contains(.daily))
        XCTAssertTrue(scheduled.contains(.milestone(days: 7)))
    }

    func testSyncSkipsWhenNotificationsDisabled() async throws {
        let userID = UUID()
        let mock = MockNotificationServiceActor()
        let profile = OnboardingProfile(
            userID: userID,
            goal: .quit,
            sobrietyStartDate: Date(),
            dailyAlcoholCost: nil,
            notificationsEnabled: false
        )
        try await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            currentStreakDays: 1,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: .current,
            now: Date()
        )
        let removed = await mock.removedPrefixes
        let scheduled = await mock.scheduledCategories
        XCTAssertTrue(removed.count >= 2)
        XCTAssertTrue(scheduled.isEmpty)
    }
}

private actor MockNotificationServiceActor: NotificationService {
    private(set) var removedPrefixes: [String] = []
    private(set) var scheduledCategories: [NotificationCategory] = []

    func requestPermission() async -> Bool {
        true
    }

    func updatePreferences(_ preferences: NotificationPreferences, for userID: UUID) async throws {}

    func schedule(
        category: NotificationCategory,
        payload: NotificationPayload,
        for userID: UUID,
        at: Date?
    ) async throws {
        scheduledCategories.append(category)
    }

    func removePending(withIdentifierPrefix prefix: String) async throws {
        removedPrefixes.append(prefix)
    }
}
