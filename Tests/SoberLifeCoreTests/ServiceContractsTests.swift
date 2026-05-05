import XCTest
@testable import SoberLifeCore

final class ServiceContractsTests: XCTestCase {
    func testConversationTypeRawValues() {
        XCTAssertEqual(ConversationType.chat.rawValue, "chat")
        XCTAssertEqual(ConversationType.sos.rawValue, "sos")
        XCTAssertEqual(ConversationType.daily.rawValue, "daily")
        XCTAssertEqual(ConversationType.analysis.rawValue, "analysis")
    }

    func testNotificationCategoryRawValues() {
        XCTAssertEqual(NotificationCategory.daily.rawValue, "daily")
        XCTAssertEqual(NotificationCategory.milestone.rawValue, "milestone")
        XCTAssertEqual(NotificationCategory.reengagement.rawValue, "reengagement")
    }

    func testNotificationPreferencesDefaults() {
        let preferences = NotificationPreferences()
        XCTAssertTrue(preferences.dailyEnabled)
        XCTAssertTrue(preferences.milestoneEnabled)
        XCTAssertTrue(preferences.reengagementEnabled)
        XCTAssertNil(preferences.quietHoursStart)
        XCTAssertNil(preferences.quietHoursEnd)
    }
}
