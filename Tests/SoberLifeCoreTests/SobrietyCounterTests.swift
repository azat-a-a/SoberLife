import XCTest
@testable import SoberLifeCore

final class SobrietyCounterTests: XCTestCase {
    func testIncludesStartDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let sameDay = Date(timeIntervalSince1970: 1_700_000_100)

        XCTAssertEqual(SobrietyCounter.soberDays(since: start, now: sameDay, calendar: calendar), 1)
    }

    func testCountsMultipleDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let threeDaysLater = Date(timeIntervalSince1970: 1_700_172_800)

        XCTAssertEqual(SobrietyCounter.soberDays(since: start, now: threeDaysLater, calendar: calendar), 3)
    }

    func testFutureDateReturnsZero() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let future = Date(timeIntervalSince1970: 1_700_172_800)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertEqual(SobrietyCounter.soberDays(since: future, now: now, calendar: calendar), 0)
    }
}
