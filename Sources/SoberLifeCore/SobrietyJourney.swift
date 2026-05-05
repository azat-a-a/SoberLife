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

/// One sober period for timelines (current open period plus each closed period from honesty check-ins).
public struct SobrietyPeriodSummary: Sendable, Equatable {
    public let periodStart: Date
    /// Set when the period ended with an honesty check-in; `nil` for the active period.
    public let periodEnd: Date?
    public let soberDaysCounted: Int
    public let isCurrent: Bool

    public init(periodStart: Date, periodEnd: Date?, soberDaysCounted: Int, isCurrent: Bool) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.soberDaysCounted = soberDaysCounted
        self.isCurrent = isCurrent
    }
}

public enum SobrietyJourney {
    /// Current period first, then past periods newest-first (by check-in time).
    public static func periodSummaries(
        currentPeriodStart: Date,
        now: Date,
        history: [RelapseEvent],
        calendar: Calendar
    ) -> [SobrietyPeriodSummary] {
        let currentDays = SobrietyCounter.soberDays(
            since: currentPeriodStart,
            now: now,
            calendar: calendar
        )
        var rows: [SobrietyPeriodSummary] = [
            SobrietyPeriodSummary(
                periodStart: currentPeriodStart,
                periodEnd: nil,
                soberDaysCounted: currentDays,
                isCurrent: true
            )
        ]
        let pastDescending = history.sorted { $0.occurredAt > $1.occurredAt }
        for event in pastDescending {
            rows.append(
                SobrietyPeriodSummary(
                    periodStart: event.previousPeriodStart,
                    periodEnd: event.occurredAt,
                    soberDaysCounted: event.streakAtRelapseDays,
                    isCurrent: false
                )
            )
        }
        return rows
    }

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
