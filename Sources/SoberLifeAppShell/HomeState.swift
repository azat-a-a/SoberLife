import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class HomeState: ObservableObject {
    @Published public private(set) var soberDays: Int = 0
    @Published public private(set) var sobrietyStartDate: Date?
    @Published public private(set) var dailyAlcoholCost: Double?
    @Published public private(set) var nextMilestoneDays: Int = 7
    @Published public private(set) var milestoneProgress: Double = 0

    private let userID: UUID
    private let store: OnboardingStore
    private let calendar: Calendar
    private let nowProvider: () -> Date

    public init(
        userID: UUID,
        store: OnboardingStore,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.userID = userID
        self.store = store
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    public func load() {
        guard let profile = store.loadProfile(userID: userID) else {
            soberDays = 0
            sobrietyStartDate = nil
            dailyAlcoholCost = nil
            nextMilestoneDays = 7
            milestoneProgress = 0
            return
        }

        sobrietyStartDate = profile.sobrietyStartDate
        dailyAlcoholCost = profile.dailyAlcoholCost
        soberDays = SobrietyCounter.soberDays(
            since: profile.sobrietyStartDate,
            now: nowProvider(),
            calendar: calendar
        )

        nextMilestoneDays = Self.nextMilestone(after: soberDays)
        milestoneProgress = min(1, Double(soberDays) / Double(nextMilestoneDays))
    }

    private static func nextMilestone(after days: Int) -> Int {
        let milestones = [7, 30, 90, 365]
        return milestones.first(where: { days < $0 }) ?? (days + 30)
    }
}
