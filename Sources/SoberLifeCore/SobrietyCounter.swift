import Foundation

public enum SobrietyCounter {
    public static func soberDays(since startDate: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let current = calendar.startOfDay(for: now)

        guard current >= start else { return 0 }
        let components = calendar.dateComponents([.day], from: start, to: current)
        return max(0, (components.day ?? 0) + 1)
    }
}
