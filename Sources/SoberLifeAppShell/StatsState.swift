import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class StatsState: ObservableObject {
    @Published public private(set) var currentStreakDays: Int = 0
    @Published public private(set) var savedMoney: Double = 0
    @Published public private(set) var nextMilestoneDays: Int = 7
    @Published public private(set) var progressPercent: Int = 0

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
            currentStreakDays = 0
            savedMoney = 0
            nextMilestoneDays = 7
            progressPercent = 0
            return
        }

        currentStreakDays = SobrietyCounter.soberDays(
            since: profile.sobrietyStartDate,
            now: nowProvider(),
            calendar: calendar
        )
        savedMoney = (profile.dailyAlcoholCost ?? 0) * Double(currentStreakDays)
        nextMilestoneDays = Self.nextMilestone(after: currentStreakDays)
        progressPercent = min(100, Int((Double(currentStreakDays) / Double(nextMilestoneDays)) * 100))
    }

    private static func nextMilestone(after days: Int) -> Int {
        let milestones = [7, 30, 90, 365]
        return milestones.first(where: { days < $0 }) ?? (days + 30)
    }
}
