import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class StatsState: ObservableObject {
    @Published public private(set) var currentStreakDays: Int = 0
    @Published public private(set) var longestStreakDays: Int = 0
    @Published public private(set) var honestyCheckIns: Int = 0
    @Published public private(set) var savedMoney: Double = 0
    @Published public private(set) var nextMilestoneDays: Int = 7
    @Published public private(set) var progressPercent: Int = 0
    @Published public private(set) var unlockedMilestones: [Int] = []
    @Published public private(set) var newlyUnlockedMilestones: [Int] = []
    @Published public private(set) var periodSummaries: [SobrietyPeriodSummary] = []

    private let userID: UUID
    private let store: OnboardingStore
    private let relapseStore: RelapseHistoryStore
    private let achievementStore: AchievementStore
    private let calendar: Calendar
    private let nowProvider: () -> Date

    public init(
        userID: UUID,
        store: OnboardingStore,
        relapseStore: RelapseHistoryStore = UserDefaultsRelapseHistoryStore(),
        achievementStore: AchievementStore = UserDefaultsAchievementStore(),
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.userID = userID
        self.store = store
        self.relapseStore = relapseStore
        self.achievementStore = achievementStore
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    public func load() {
        let history = relapseStore.events(userID: userID)
        honestyCheckIns = history.count

        guard let profile = store.loadProfile(userID: userID) else {
            currentStreakDays = 0
            longestStreakDays = 0
            savedMoney = 0
            nextMilestoneDays = 7
            progressPercent = 0
            unlockedMilestones = []
            newlyUnlockedMilestones = []
            periodSummaries = []
            return
        }

        let now = nowProvider()
        currentStreakDays = SobrietyCounter.soberDays(
            since: profile.sobrietyStartDate,
            now: now,
            calendar: calendar
        )
        longestStreakDays = SobrietyJourney.longestStreakDays(
            currentPeriodStart: profile.sobrietyStartDate,
            now: now,
            history: history,
            calendar: calendar
        )
        periodSummaries = SobrietyJourney.periodSummaries(
            currentPeriodStart: profile.sobrietyStartDate,
            now: now,
            history: history,
            calendar: calendar
        )
        savedMoney = (profile.dailyAlcoholCost ?? 0) * Double(currentStreakDays)
        nextMilestoneDays = Self.nextMilestone(after: currentStreakDays)
        progressPercent = min(100, Int((Double(currentStreakDays) / Double(nextMilestoneDays)) * 100))

        let allMilestones = [7, 30, 90, 365]
        let reached = Set(allMilestones.filter { currentStreakDays >= $0 })
        let existing = achievementStore.unlockedMilestones(userID: userID)
        let newly = reached.subtracting(existing)
        let merged = existing.union(reached)

        achievementStore.saveUnlockedMilestones(merged, userID: userID)
        unlockedMilestones = Array(merged).sorted()
        newlyUnlockedMilestones = Array(newly).sorted()
    }

    private static func nextMilestone(after days: Int) -> Int {
        let milestones = [7, 30, 90, 365]
        return milestones.first(where: { days < $0 }) ?? (days + 30)
    }
}
