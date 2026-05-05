import Foundation
import SoberLifeCore

public enum NotificationScheduleSync {
    /// Clears prior pending notifications for this user, then schedules enabled categories when onboarding allows notifications.
    public static func syncAll(
        userID: UUID,
        profile: OnboardingProfile?,
        preferences: NotificationPreferences,
        currentStreakDays: Int,
        nextMilestoneTarget: Int,
        notificationService: NotificationService,
        calendar: Calendar,
        now: Date
    ) async throws {
        let dailyKey = NotificationIdentifiers.dailyReminder(userID: userID)
        let milestoneKey = NotificationIdentifiers.milestonePrefix(userID: userID)
        let reengagementKey = NotificationIdentifiers.reengagement(userID: userID)

        try await notificationService.removePending(withIdentifierPrefix: dailyKey)
        try await notificationService.removePending(withIdentifierPrefix: milestoneKey)
        try await notificationService.removePending(withIdentifierPrefix: reengagementKey)

        guard let profile else { return }
        guard profile.notificationsEnabled else { return }

        _ = await notificationService.requestPermission()

        let (dh, dm) = NotificationQuietHours.clampedDailyHourMinute(
            preferences: preferences,
            calendar: calendar,
            referenceDay: now
        )

        guard let dailyAnchor = calendar.date(bySettingHour: dh, minute: dm, second: 0, of: now) else { return }

        if preferences.dailyEnabled {
            try await notificationService.schedule(
                category: .daily,
                payload: NotificationPayload(
                    title: "One gentle check-in",
                    body: "You are allowed to take today one moment at a time. Open SoberLife when you feel ready."
                ),
                for: userID,
                at: dailyAnchor
            )
        }

        if preferences.milestoneEnabled,
           currentStreakDays < nextMilestoneTarget,
           let milestoneDay = SobrietyJourney.dateWhenStreakReaches(
               targetDays: nextMilestoneTarget,
               periodStart: profile.sobrietyStartDate,
               calendar: calendar
           ),
           let atMilestone = calendar.date(bySettingHour: dh, minute: dm, second: 0, of: milestoneDay)
        {
            let at = NotificationQuietHours.shiftDateOutOfQuietHours(atMilestone, preferences: preferences, calendar: calendar)
            if at > now {
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

        if preferences.reengagementEnabled,
           let inDays = calendar.date(byAdding: .day, value: 5, to: now),
           let atRe = calendar.date(bySettingHour: dh, minute: dm, second: 0, of: inDays)
        {
            let at = NotificationQuietHours.shiftDateOutOfQuietHours(atRe, preferences: preferences, calendar: calendar)
            if at > now {
                try await notificationService.schedule(
                    category: .reengagement,
                    payload: NotificationPayload(
                        title: "Still here with you",
                        body: "No pressure — open the app whenever you want a small moment of support."
                    ),
                    for: userID,
                    at: at
                )
            }
        }
    }
}
