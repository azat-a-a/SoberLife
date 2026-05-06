import Foundation
import Combine

@MainActor
public final class OnboardingState: ObservableObject {
    @Published public private(set) var currentStep: Int = 0
    @Published public private(set) var isCompleted: Bool = false

    @Published public var selectedGoal: OnboardingGoal?
    @Published public var sobrietyStartDate: Date
    @Published public var dailyAlcoholCostText: String = ""
    @Published public var notificationsEnabled: Bool = true

    private let userID: UUID
    private let store: OnboardingStore
    private let analytics: AnalyticsTracker

    public let totalSteps = 4

    public init(
        userID: UUID,
        store: OnboardingStore,
        analytics: AnalyticsTracker = .shared
    ) {
        self.userID = userID
        self.store = store
        self.analytics = analytics
        self.sobrietyStartDate = Date()

        if let profile = store.loadProfile(userID: userID) {
            selectedGoal = profile.goal
            sobrietyStartDate = profile.sobrietyStartDate
            if let dailyAlcoholCost = profile.dailyAlcoholCost {
                dailyAlcoholCostText = String(format: "%.2f", dailyAlcoholCost)
            }
            notificationsEnabled = profile.notificationsEnabled
            isCompleted = true
            currentStep = totalSteps - 1
        }
    }

    public var canContinue: Bool {
        switch currentStep {
        case 0:
            return true // Goal is optional
        case 1:
            return true // Date always has value
        case 2:
            return true // Cost is optional
        case 3:
            return true // Notification choice is always set
        default:
            return false
        }
    }

    public func next() {
        guard canContinue else { return }
        currentStep = min(totalSteps - 1, currentStep + 1)
    }

    public func back() {
        currentStep = max(0, currentStep - 1)
    }

    public func skipCurrentStep() {
        if currentStep == 0 {
            selectedGoal = nil
        } else if currentStep == 2 {
            dailyAlcoholCostText = ""
        }
        next()
    }

    public func complete() {
        let parsedCost = Double(dailyAlcoholCostText.replacingOccurrences(of: ",", with: "."))
        let cost = (parsedCost ?? 0) > 0 ? parsedCost : nil

        let profile = OnboardingProfile(
            userID: userID,
            goal: selectedGoal,
            sobrietyStartDate: sobrietyStartDate,
            dailyAlcoholCost: cost,
            notificationsEnabled: notificationsEnabled
        )
        store.saveProfile(profile)
        analytics.trackOnce(
            name: "onboarding_complete",
            dedupeKey: "onboarding_complete.\(userID.uuidString)",
            properties: [
                "goal_selected": selectedGoal == nil ? "false" : "true",
                "daily_cost_provided": cost == nil ? "false" : "true",
                "notifications_enabled": notificationsEnabled ? "true" : "false"
            ]
        )
        isCompleted = true
    }
}
