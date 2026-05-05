import Foundation
import SoberLifeCore

public enum NotificationScheduleSync {
    /// Clears prior pending notifications for this user, then schedules daily and next milestone when enabled.
    public static func syncAll(
        userID: UUID,
        profile: OnboardingProfile?,
        currentStreakDays: Int,
        nextMilestoneTarget: Int,
        notificationService: NotificationService,
        calendar: Calendar,
        now: Date
    ) async throws {
        guard let profile else { return }

        let dailyKey = NotificationIdentifiers.dailyReminder(userID: userID)
        let milestoneKey = NotificationIdentifiers.milestonePrefix(userID: userID)

        try await notificationService.removePending(withIdentifierPrefix: dailyKey)
        try await notificationService.removePending(withIdentifierPrefix: milestoneKey)

        guard profile.notificationsEnabled else { return }

        _ = await notificationService.requestPermission()

        try await notificationService.schedule(
            category: .daily,
            payload: NotificationPayload(
                title: "One gentle check-in",
                body: "You are allowed to take today one moment at a time. Open SoberLife when you feel ready."
            ),
            for: userID,
            at: nil
        )

        guard currentStreakDays < nextMilestoneTarget else { return }

        guard let milestoneDay = SobrietyJourney.dateWhenStreakReaches(
            targetDays: nextMilestoneTarget,
            periodStart: profile.sobrietyStartDate,
            calendar: calendar
        ) else { return }

        var comps = calendar.dateComponents([.year, .month, .day], from: milestoneDay)
        comps.hour = 10
        comps.minute = 0
        guard let at = calendar.date(from: comps), at > now else { return }

        try await notificationService.schedule(
            category: .milestone(days: nextMilestoneTarget),
            payload: NotificationPayload(
                title: "Milestone within reach",
                body: "You are close to \(nextMilestoneTarget) days. However today feels, your effort still matters."
            ),
            for: userID,
            at: at
        )
    }
}
