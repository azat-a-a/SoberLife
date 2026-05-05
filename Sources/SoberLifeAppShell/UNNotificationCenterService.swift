import Foundation
import SoberLifeCore
import UserNotifications

public final class UNNotificationCenterService: NotificationService, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    public func updatePreferences(_ preferences: NotificationPreferences, for userID: UUID) async throws {
        _ = preferences
        _ = userID
    }

    public func schedule(
        category: NotificationCategory,
        payload: NotificationPayload,
        for userID: UUID,
        at: Date?
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default

        let identifier: String
        let trigger: UNNotificationTrigger?

        switch category {
        case .daily:
            identifier = NotificationIdentifiers.dailyReminder(userID: userID)
            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .milestone(let days):
            identifier = NotificationIdentifiers.milestone(userID: userID, milestoneDays: days)
            guard let at else { return }
            let cal = Calendar.current
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: at)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        case .reengagement:
            identifier = "soberlife.reengagement.\(userID.uuidString)"
            if let at {
                let cal = Calendar.current
                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: at)
                trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            } else {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            }
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    public func removePending(withIdentifierPrefix prefix: String) async throws {
        let requests = await withCheckedContinuation { (cont: CheckedContinuation<[UNNotificationRequest], Never>) in
            center.getPendingNotificationRequests { cont.resume(returning: $0) }
        }
        let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
