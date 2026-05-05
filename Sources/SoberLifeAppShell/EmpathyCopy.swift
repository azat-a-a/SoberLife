import Foundation

/// Centralized supportive, non-shaming language (SAFE-01).
public enum EmpathyCopy {
    public static let sosTitle = "You are not alone"
    public static let sosSubtitle =
        "Cravings are hard, and reaching for help is brave. Nothing here erases your progress."

    public static let sosBreathingTitle = "Slow breathing"
    public static let sosBreathingDetail = "Inhale 4 counts, hold 2, exhale 6. Repeat a few times. There is no rush."

    public static let sosWaterTitle = "Hydrate"
    public static let sosWaterDetail = "A glass of water can be a small reset. You deserve care in small steps."

    public static let sosGroundingTitle = "Ground yourself"
    public static let sosGroundingDetail = "Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste."

    public static let sosAiButton = "Get a supportive message"
    public static let sosAiLoading = "Finding gentle words…"
    public static let sosAiFallback =
        "This moment is uncomfortable, not permanent. You have already practiced showing up for yourself. One next right step is enough."

    public static let sosCrisisSection = "If you might hurt yourself or someone else"
    public static let sosCrisisBody =
        "Please contact local emergency services or a crisis line right now. This app is not a substitute for professional or emergency care."

    public static let relapseButton = "I had a drink (new period)"
    public static let relapseTitle = "Thank you for telling the truth"
    public static let relapseMessage =
        "A slip does not delete who you are or the work you have already done. We will start a fresh sober period while keeping your milestones and history."

    public static let relapseConfirm = "Start fresh from today"
    public static let relapseCancel = "Not now"

    public static let profileSupportHeading = "SOS contact (optional)"
    public static let profileSupportHint =
        "Someone you trust for a quick call when things feel intense. Stored only on this device."

    public static let chatNeedsBackend =
        "To talk with the assistant, the app needs your Supabase project wired in (same setup as Apple sign-in)."

    public static let chatCloudLoadFailed =
        "We could not load your cloud history. Showing what is saved on this device."

    public static let chatCloudSyncFailed =
        "Your words are saved on this device; syncing to the cloud failed for a moment."

    public static let chatSendFailed =
        "The assistant could not answer just now. Your message is still here — try again when you feel ready."

    public static let chatRetryAction = "Try again"

    public static let chatEmptyHint =
        "This is a private space. There is no wrong thing to say. Short messages are fine."

    public static let dataSyncFailedShort =
        "Could not sync your progress to the cloud. It is still saved on this device — you can try again later."

    public static let sessionExpiredNeedsSignIn =
        "Your session expired. Please sign in again to continue syncing."

    public static let networkOfflineShort =
        "No internet connection right now. Your data stays on this device and will sync when you're back online."

    public static let statsPeriodsHeading = "Your sober periods"
    public static let statsPeriodsFootnote =
        "Each row is a chapter, not a verdict. Milestones you already earned stay with you."
    public static let statsPeriodCurrentBadge = "Current period"
    public static let statsPeriodPastBadge = "Earlier period"

    public static let profileNotificationsHeading = "Notifications"
    public static let profileNotificationsHint =
        "Saved on this device. We avoid pings during quiet hours when we can."
    public static let profileNotificationsDaily = "Daily gentle reminder"
    public static let profileNotificationsMilestone = "Milestone reminders"
    public static let profileNotificationsReengagement = "Nudge after you have been away"
    public static let profileNotificationsTime = "Reminder time"
    public static let profileNotificationsQuiet = "Quiet hours"
    public static let profileNotificationsQuietStart = "Quiet from (hour)"
    public static let profileNotificationsQuietEnd = "Quiet until (hour)"
}
