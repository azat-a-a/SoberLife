import XCTest
import Foundation
@testable import SoberLifeCore

final class NotificationQuietHoursTests: XCTestCase {
    func testNonWrappingQuietWindow() {
        XCTAssertFalse(NotificationQuietHours.isQuietHour(9, quietStart: 10, quietEnd: 13))
        XCTAssertTrue(NotificationQuietHours.isQuietHour(10, quietStart: 10, quietEnd: 13))
        XCTAssertTrue(NotificationQuietHours.isQuietHour(12, quietStart: 10, quietEnd: 13))
        XCTAssertFalse(NotificationQuietHours.isQuietHour(13, quietStart: 10, quietEnd: 13))
    }

    func testWrappingQuietWindow() {
        XCTAssertTrue(NotificationQuietHours.isQuietHour(23, quietStart: 22, quietEnd: 8))
        XCTAssertTrue(NotificationQuietHours.isQuietHour(3, quietStart: 22, quietEnd: 8))
        XCTAssertFalse(NotificationQuietHours.isQuietHour(10, quietStart: 22, quietEnd: 8))
    }

    func testShiftMovesHourForwardWithinSameDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let prefs = NotificationPreferences(
            dailyEnabled: true,
            milestoneEnabled: true,
            reengagementEnabled: true,
            dailyReminderHour: 11,
            dailyReminderMinute: 0,
            quietHoursStart: 10,
            quietHoursEnd: 13
        )
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        guard let atEleven = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: base) else {
            XCTFail("date")
            return
        }
        let shifted = NotificationQuietHours.shiftDateOutOfQuietHours(atEleven, preferences: prefs, calendar: calendar)
        XCTAssertEqual(calendar.component(.hour, from: shifted), 13)
        XCTAssertEqual(calendar.component(.minute, from: shifted), 0)
    }

    func testClampedDailyHourMinute() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let ref = Date(timeIntervalSince1970: 1_800_000_000)
        let prefs = NotificationPreferences(
            dailyEnabled: true,
            milestoneEnabled: true,
            reengagementEnabled: true,
            dailyReminderHour: 11,
            dailyReminderMinute: 30,
            quietHoursStart: 10,
            quietHoursEnd: 14
        )
        let (h, m) = NotificationQuietHours.clampedDailyHourMinute(
            preferences: prefs,
            calendar: calendar,
            referenceDay: ref
        )
        XCTAssertEqual(h, 14)
        XCTAssertEqual(m, 30)
    }
}
