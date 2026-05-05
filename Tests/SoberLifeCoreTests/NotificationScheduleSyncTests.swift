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
        let prefs = NotificationPreferences(reengagementEnabled: false)

        try await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            preferences: prefs,
            currentStreakDays: 2,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: calendar,
            now: now
        )

        let removed = await mock.removedPrefixes
        let scheduled = await mock.scheduled
        XCTAssertTrue(removed.contains(NotificationIdentifiers.dailyReminder(userID: userID)))
        XCTAssertTrue(removed.contains(NotificationIdentifiers.milestonePrefix(userID: userID)))
        XCTAssertTrue(removed.contains(NotificationIdentifiers.reengagement(userID: userID)))
        XCTAssertTrue(scheduled.contains { $0.0 == .daily })
        XCTAssertTrue(scheduled.contains { $0.0 == .milestone(days: 7) })
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
            preferences: NotificationPreferences(),
            currentStreakDays: 1,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: .current,
            now: Date()
        )
        let removed = await mock.removedPrefixes
        let scheduled = await mock.scheduled
        XCTAssertTrue(removed.count >= 3)
        XCTAssertTrue(scheduled.isEmpty)
    }

    func testDailyDisabledSkipsDailySchedule() async throws {
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
        let prefs = NotificationPreferences(dailyEnabled: false, reengagementEnabled: false)

        try await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            preferences: prefs,
            currentStreakDays: 2,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: calendar,
            now: now
        )

        let scheduled = await mock.scheduled
        XCTAssertFalse(scheduled.contains { $0.0 == .daily })
        XCTAssertTrue(scheduled.contains { $0.0 == .milestone(days: 7) })
    }

    func testMilestoneTimeShiftsOutOfQuietHours() async throws {
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
        let prefs = NotificationPreferences(
            dailyEnabled: false,
            milestoneEnabled: true,
            reengagementEnabled: false,
            dailyReminderHour: 11,
            dailyReminderMinute: 0,
            quietHoursStart: 10,
            quietHoursEnd: 13
        )

        try await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            preferences: prefs,
            currentStreakDays: 2,
            nextMilestoneTarget: 7,
            notificationService: mock,
            calendar: calendar,
            now: now
        )

        let milestoneAt = await mock.scheduled.first { pair in
            if case .milestone(let d) = pair.0, d == 7 { return true }
            return false
        }?.1
        XCTAssertNotNil(milestoneAt)
        XCTAssertEqual(calendar.component(.hour, from: milestoneAt!), 13)
    }
}

private actor MockNotificationServiceActor: NotificationService {
    private(set) var removedPrefixes: [String] = []
    private(set) var scheduled: [(NotificationCategory, Date?)] = []

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
        scheduled.append((category, at))
    }

    func removePending(withIdentifierPrefix prefix: String) async throws {
        removedPrefixes.append(prefix)
    }
}
