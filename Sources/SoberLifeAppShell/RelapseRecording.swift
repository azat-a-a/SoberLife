import Foundation
import SoberLifeCore

public enum RelapseRecording {
    /// Starts a new sobriety period from `newPeriodStart` (typically start of today) while preserving milestone history and recording the prior streak.
    public static func recordRelapse(
        userID: UUID,
        newPeriodStart: Date,
        now: Date,
        calendar: Calendar,
        profileStore: OnboardingStore,
        historyStore: RelapseHistoryStore
    ) {
        guard let profile = profileStore.loadProfile(userID: userID) else { return }
        let streak = SobrietyCounter.soberDays(since: profile.sobrietyStartDate, now: now, calendar: calendar)
        let event = RelapseEvent(
            occurredAt: now,
            previousPeriodStart: profile.sobrietyStartDate,
            streakAtRelapseDays: streak
        )
        historyStore.append(event, userID: userID)

        let normalizedStart = calendar.startOfDay(for: newPeriodStart)
        let updated = OnboardingProfile(
            userID: userID,
            goal: profile.goal,
            sobrietyStartDate: normalizedStart,
            dailyAlcoholCost: profile.dailyAlcoholCost,
            notificationsEnabled: profile.notificationsEnabled,
            createdAt: profile.createdAt
        )
        profileStore.saveProfile(updated)
    }
}
