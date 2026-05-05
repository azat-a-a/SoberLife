import Foundation

/// Hour-granularity quiet window: non-wrapping `[start, end)`, or wrapping past midnight when `start > end`.
public enum NotificationQuietHours {
    public static func isQuietHour(_ hour: Int, quietStart: Int?, quietEnd: Int?) -> Bool {
        guard let start = quietStart, let end = quietEnd, start != end else { return false }
        if start < end {
            return hour >= start && hour < end
        }
        return hour >= start || hour < end
    }

    /// Moves `date` forward hour-by-hour until its hour is outside quiet hours (max 48 steps).
    public static func shiftDateOutOfQuietHours(
        _ date: Date,
        preferences: NotificationPreferences,
        calendar: Calendar
    ) -> Date {
        guard preferences.quietHoursStart != nil,
              preferences.quietHoursEnd != nil
        else { return date }
        var d = date
        for _ in 0..<48 {
            let h = calendar.component(.hour, from: d)
            if !isQuietHour(h, quietStart: preferences.quietHoursStart, quietEnd: preferences.quietHoursEnd) {
                return d
            }
            guard let next = calendar.date(byAdding: .hour, value: 1, to: d) else { return d }
            d = next
        }
        return date
    }

    /// Time-of-day for repeating daily notifications, nudged out of quiet hours on a reference calendar day.
    public static func clampedDailyHourMinute(
        preferences: NotificationPreferences,
        calendar: Calendar,
        referenceDay: Date
    ) -> (hour: Int, minute: Int) {
        let h = preferences.dailyReminderHour
        let m = preferences.dailyReminderMinute
        guard let anchor = calendar.date(bySettingHour: h, minute: m, second: 0, of: referenceDay) else {
            return (h, m)
        }
        let shifted = shiftDateOutOfQuietHours(anchor, preferences: preferences, calendar: calendar)
        return (
            calendar.component(.hour, from: shifted),
            calendar.component(.minute, from: shifted)
        )
    }
}
