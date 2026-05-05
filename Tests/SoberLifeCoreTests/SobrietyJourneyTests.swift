import XCTest
import Foundation
@testable import SoberLifeCore

final class SobrietyJourneyTests: XCTestCase {
    func testDateWhenStreakReaches() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let seventh = SobrietyJourney.dateWhenStreakReaches(targetDays: 7, periodStart: start, calendar: calendar)!
        let days = SobrietyCounter.soberDays(since: start, now: seventh, calendar: calendar)
        XCTAssertEqual(days, 7)
    }

    func testLongestStreakIncludesHistory() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_086_400)
        let periodStart = Date(timeIntervalSince1970: 1_700_000_000)
        let history = [
            RelapseEvent(occurredAt: now, previousPeriodStart: periodStart, streakAtRelapseDays: 20)
        ]
        let current = SobrietyCounter.soberDays(since: periodStart, now: now, calendar: calendar)
        let longest = SobrietyJourney.longestStreakDays(
            currentPeriodStart: periodStart,
            now: now,
            history: history,
            calendar: calendar
        )
        XCTAssertEqual(current, 2)
        XCTAssertEqual(longest, 20)
    }
}
