import Foundation

public struct RelapseEvent: Codable, Sendable, Equatable {
    public let occurredAt: Date
    public let previousPeriodStart: Date
    public let streakAtRelapseDays: Int

    public init(occurredAt: Date, previousPeriodStart: Date, streakAtRelapseDays: Int) {
        self.occurredAt = occurredAt
        self.previousPeriodStart = previousPeriodStart
        self.streakAtRelapseDays = streakAtRelapseDays
    }
}

public enum SobrietyJourney {
    public static func longestStreakDays(
        currentPeriodStart: Date,
        now: Date,
        history: [RelapseEvent],
        calendar: Calendar
    ) -> Int {
        let current = SobrietyCounter.soberDays(since: currentPeriodStart, now: now, calendar: calendar)
        let pastMax = history.map(\.streakAtRelapseDays).max() ?? 0
        return max(current, pastMax)
    }

    /// Calendar day (start of day) when an inclusive streak count reaches `targetDays` for a period starting at `periodStart`.
    public static func dateWhenStreakReaches(
        targetDays: Int,
        periodStart: Date,
        calendar: Calendar
    ) -> Date? {
        guard targetDays >= 1 else { return nil }
        let start = calendar.startOfDay(for: periodStart)
        return calendar.date(byAdding: .day, value: targetDays - 1, to: start)
    }
}
