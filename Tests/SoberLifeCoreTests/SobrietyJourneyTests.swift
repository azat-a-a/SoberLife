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

    func testPeriodSummariesOrdersCurrentFirstThenNewestPast() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let currentStart = Date(timeIntervalSince1970: 1_701_000_000)
        let now = Date(timeIntervalSince1970: 1_701_086_400)
        let older = RelapseEvent(
            occurredAt: Date(timeIntervalSince1970: 1_700_500_000),
            previousPeriodStart: Date(timeIntervalSince1970: 1_700_000_000),
            streakAtRelapseDays: 5
        )
        let newer = RelapseEvent(
            occurredAt: Date(timeIntervalSince1970: 1_700_900_000),
            previousPeriodStart: Date(timeIntervalSince1970: 1_700_600_000),
            streakAtRelapseDays: 10
        )
        let rows = SobrietyJourney.periodSummaries(
            currentPeriodStart: currentStart,
            now: now,
            history: [older, newer],
            calendar: calendar
        )
        XCTAssertEqual(rows.count, 3)
        XCTAssertTrue(rows[0].isCurrent)
        XCTAssertEqual(rows[0].periodStart, currentStart)
        XCTAssertNil(rows[0].periodEnd)
        XCTAssertEqual(rows[1].soberDaysCounted, 10)
        XCTAssertEqual(rows[1].periodEnd, newer.occurredAt)
        XCTAssertEqual(rows[2].soberDaysCounted, 5)
    }
}
