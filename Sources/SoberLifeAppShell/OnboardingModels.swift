import Foundation
import SoberLifeCore

public enum OnboardingGoal: String, CaseIterable, Codable, Sendable {
    case reduce = "onboarding.goal.reduce"
    case quit = "onboarding.goal.quit"

    public var localizedTitle: String {
        L10n.string(rawValue)
    }
}

public struct OnboardingProfile: Codable, Sendable, Equatable {
    public let userID: UUID
    public let goal: OnboardingGoal?
    public let sobrietyStartDate: Date
    public let dailyAlcoholCost: Double?
    public let notificationsEnabled: Bool
    public let createdAt: Date

    public init(
        userID: UUID,
        goal: OnboardingGoal?,
        sobrietyStartDate: Date,
        dailyAlcoholCost: Double?,
        notificationsEnabled: Bool,
        createdAt: Date = Date()
    ) {
        self.userID = userID
        self.goal = goal
        self.sobrietyStartDate = sobrietyStartDate
        self.dailyAlcoholCost = dailyAlcoholCost
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
    }

    public var sobrietySnapshot: SobrietyProfileSnapshot {
        SobrietyProfileSnapshot(
            sobrietyStartDate: sobrietyStartDate,
            dailyAlcoholCost: dailyAlcoholCost,
            displayName: goal.map { L10n.string($0.rawValue) }
        )
    }
}
