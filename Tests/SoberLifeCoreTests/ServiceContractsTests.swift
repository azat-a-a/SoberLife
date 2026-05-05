import XCTest
@testable import SoberLifeCore

final class ServiceContractsTests: XCTestCase {
    func testConversationTypeRawValues() {
        XCTAssertEqual(ConversationType.chat.rawValue, "chat")
        XCTAssertEqual(ConversationType.sos.rawValue, "sos")
        XCTAssertEqual(ConversationType.daily.rawValue, "daily")
        XCTAssertEqual(ConversationType.analysis.rawValue, "analysis")
    }

    func testNotificationCategoryEquality() {
        XCTAssertEqual(NotificationCategory.daily, .daily)
        XCTAssertEqual(NotificationCategory.milestone(days: 7), .milestone(days: 7))
        XCTAssertNotEqual(NotificationCategory.milestone(days: 7), .milestone(days: 30))
        XCTAssertEqual(NotificationCategory.reengagement, .reengagement)
    }

    func testNotificationPreferencesDefaults() {
        let preferences = NotificationPreferences()
        XCTAssertTrue(preferences.dailyEnabled)
        XCTAssertTrue(preferences.milestoneEnabled)
        XCTAssertTrue(preferences.reengagementEnabled)
        XCTAssertEqual(preferences.dailyReminderHour, 10)
        XCTAssertEqual(preferences.dailyReminderMinute, 0)
        XCTAssertNil(preferences.quietHoursStart)
        XCTAssertNil(preferences.quietHoursEnd)
    }
}
