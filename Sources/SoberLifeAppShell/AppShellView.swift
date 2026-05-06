import SwiftUI
import Foundation
import SoberLifeCore

public struct AppShellView: View {
    @ObservedObject private var sessionState: SessionState
    @StateObject private var localizationSettings = LocalizationSettings()
    private let aiService: (any AIService)?
    private let authWiring: AuthWiring?

    public init(sessionState: SessionState, authWiring: AuthWiring? = nil) {
        self.sessionState = sessionState
        self.authWiring = authWiring
        self.aiService = authWiring.map { wiring in wiring.makeAIService() }
    }

    public var body: some View {
        Group {
            switch sessionState.authState {
            case .signedOut:
                SignedOutPlaceholderView(
                    errorMessage: sessionState.authErrorMessage,
                    onSignIn: { email, password in
                        await sessionState.signIn(email: email, password: password)
                    },
                    onSignUp: { email, password in
                        await sessionState.signUp(email: email, password: password)
                    }
                )
            case let .signedIn(userID):
                SignedInRootView(
                    sessionState: sessionState,
                    userID: userID,
                    aiService: aiService,
                    authWiring: authWiring,
                    onSignOutTap: {
                        Task {
                            await sessionState.signOut()
                        }
                    }
                )
            }
        }
        .environmentObject(localizationSettings)
        .environment(\.locale, localizationSettings.locale)
        .task {
            await sessionState.restoreSession()
        }
    }
}

private struct SignedInRootView: View {
    @ObservedObject var sessionState: SessionState
    let userID: UUID
    let aiService: (any AIService)?
    let authWiring: AuthWiring?
    let onSignOutTap: () -> Void
    private let onboardingStore: OnboardingStore
    private let relapseStore: RelapseHistoryStore
    private let supportContactStore: SupportContactStore
    private let achievementStore: AchievementStore
    private let notificationService: NotificationService
    private let notificationPreferencesStore: NotificationPreferencesStore

    @StateObject private var onboardingState: OnboardingState
    @StateObject private var sobrietyCloudSync: SobrietyCloudSync
    @StateObject private var userSettingsCloudSync: UserSettingsCloudSync
    @StateObject private var achievementsCloudSync: AchievementsCloudSync

    init(
        sessionState: SessionState,
        userID: UUID,
        aiService: (any AIService)?,
        authWiring: AuthWiring?,
        onSignOutTap: @escaping () -> Void
    ) {
        self.sessionState = sessionState
        self.userID = userID
        self.aiService = aiService
        self.authWiring = authWiring
        self.onSignOutTap = onSignOutTap
        let store = UserDefaultsOnboardingStore()
        let relapseStore = UserDefaultsRelapseHistoryStore()
        self.onboardingStore = store
        self.relapseStore = relapseStore
        let supportStore = UserDefaultsSupportContactStore()
        let notificationStore = UserDefaultsNotificationPreferencesStore()
        self.supportContactStore = supportStore
        let achievementStore = UserDefaultsAchievementStore()
        self.achievementStore = achievementStore
        self.notificationService = UNNotificationCenterService()
        self.notificationPreferencesStore = notificationStore
        _onboardingState = StateObject(
            wrappedValue: OnboardingState(
                userID: userID,
                store: store
            )
        )
        _sobrietyCloudSync = StateObject(
            wrappedValue: SobrietyCloudSync(
                userID: userID,
                authWiring: authWiring,
                sessionState: sessionState,
                onboardingStore: store,
                relapseStore: relapseStore
            )
        )
        _userSettingsCloudSync = StateObject(
            wrappedValue: UserSettingsCloudSync(
                userID: userID,
                authWiring: authWiring,
                sessionState: sessionState,
                notificationPreferencesStore: notificationStore,
                supportContactStore: supportStore
            )
        )
        _achievementsCloudSync = StateObject(
            wrappedValue: AchievementsCloudSync(
                userID: userID,
                authWiring: authWiring,
                sessionState: sessionState,
                achievementStore: achievementStore
            )
        )
    }

    var body: some View {
        Group {
            if onboardingState.isCompleted {
                MainTabView(
                    sessionState: sessionState,
                    userID: userID,
                    onboardingStore: onboardingStore,
                    relapseStore: relapseStore,
                    supportContactStore: supportContactStore,
                    achievementStore: achievementStore,
                    notificationService: notificationService,
                    notificationPreferencesStore: notificationPreferencesStore,
                    aiService: aiService,
                    authWiring: authWiring,
                    cloudSync: sobrietyCloudSync,
                    userSettingsCloudSync: userSettingsCloudSync,
                    achievementsCloudSync: achievementsCloudSync,
                    onSignOutTap: onSignOutTap
                )
            } else {
                OnboardingFlowView(state: onboardingState)
            }
        }
        .task {
            if onboardingState.isCompleted {
                await sobrietyCloudSync.syncOnboardingFromLocalStore()
            }
        }
        .onChange(of: onboardingState.isCompleted) { _, completed in
            if completed {
                Task { await sobrietyCloudSync.syncOnboardingFromLocalStore() }
            }
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var sessionState: SessionState
    let userID: UUID
    let onboardingStore: OnboardingStore
    let relapseStore: RelapseHistoryStore
    let supportContactStore: SupportContactStore
    let achievementStore: AchievementStore
    let notificationService: NotificationService
    let notificationPreferencesStore: NotificationPreferencesStore
    let aiService: (any AIService)?
    let authWiring: AuthWiring?
    let cloudSync: SobrietyCloudSync
    let userSettingsCloudSync: UserSettingsCloudSync
    let achievementsCloudSync: AchievementsCloudSync
    let onSignOutTap: () -> Void
    private let analytics: AnalyticsTracker = .shared

    @State private var notificationSyncTick: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if let message = cloudSync.lastError {
                HStack(alignment: .top, spacing: 8) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Button {
                        cloudSync.clearError()
                    } label: {
                        Text("common.dismiss", bundle: .module)
                    }
                    .font(.footnote)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.18))
            }

            if let message = userSettingsCloudSync.lastError {
                HStack(alignment: .top, spacing: 8) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Button {
                        userSettingsCloudSync.clearError()
                    } label: {
                        Text("common.dismiss", bundle: .module)
                    }
                    .font(.footnote)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.15))
            }

            if let message = achievementsCloudSync.lastError {
                HStack(alignment: .top, spacing: 8) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Button {
                        achievementsCloudSync.clearError()
                    } label: {
                        Text("common.dismiss", bundle: .module)
                    }
                    .font(.footnote)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.12))
            }

            TabView {
            HomeView(
                userID: userID,
                onboardingStore: onboardingStore,
                relapseStore: relapseStore,
                supportContactStore: supportContactStore,
                state: HomeState(
                    userID: userID,
                    store: onboardingStore
                ),
                aiService: aiService,
                notificationSyncTick: $notificationSyncTick
            )
            .tabItem {
                Label {
                    Text("tab.home", bundle: .module)
                } icon: {
                    Image(systemName: "house")
                }
            }

            AIChatTabView(
                sessionState: sessionState,
                userID: userID,
                onboardingStore: onboardingStore,
                aiService: aiService,
                authWiring: authWiring
            )
            .tabItem {
                Label {
                    Text("tab.chat", bundle: .module)
                } icon: {
                    Image(systemName: "message")
                }
            }

            StatsView(
                state: StatsState(
                    userID: userID,
                    store: onboardingStore,
                    relapseStore: relapseStore,
                    achievementStore: achievementStore
                ),
                achievementsCloudSync: achievementsCloudSync,
                syncTick: notificationSyncTick
            )
            .tabItem {
                Label {
                    Text("tab.stats", bundle: .module)
                } icon: {
                    Image(systemName: "chart.bar")
                }
            }

            ProfileView(
                userID: userID,
                supportContactStore: supportContactStore,
                notificationPreferencesStore: notificationPreferencesStore,
                userSettingsCloudSync: userSettingsCloudSync,
                onNotificationPreferencesChanged: { notificationSyncTick += 1 },
                onSignOutTap: onSignOutTap
            )
            .tabItem {
                Label {
                    Text("tab.profile", bundle: .module)
                } icon: {
                    Image(systemName: "person")
                }
            }
            }
        }
        .environmentObject(cloudSync)
        .environmentObject(userSettingsCloudSync)
        .environmentObject(achievementsCloudSync)
        .task(id: notificationSyncTick) {
            await runNotificationSync()
        }
        .onChange(of: userSettingsCloudSync.settingsRevision) { _, _ in
            notificationSyncTick += 1
        }
        .onChange(of: cloudSync.historyRevision) { _, _ in
            notificationSyncTick += 1
        }
        .onChange(of: achievementsCloudSync.achievementsRevision) { _, _ in
            notificationSyncTick += 1
        }
        .task {
            await runMainTabInitialCloudSync()
        }
        .task {
            let dayKey = Self.dayKey(Date())
            analytics.trackOnce(
                name: "active_use_24h",
                dedupeKey: "active_use_24h.\(userID.uuidString).\(dayKey)",
                properties: ["surface": "main_tabs"]
            )
        }
    }

    /// Single `ensure_user_profile` before settings + achievements bootstrap when JWT is valid; bootstraps retry ensure if this fails transiently.
    private func runMainTabInitialCloudSync() async {
        guard let wiring = authWiring,
              let token = await sessionState.accessTokenIfAvailable(),
              SupabaseJWT.isLikelyUserAccessToken(token)
        else { return }
        let http = HTTPSupabaseService(baseURL: wiring.supabaseURL, anonKey: wiring.supabaseAnonKey)
        var profileEnsured = false
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            profileEnsured = true
        } catch let error as SupabaseHTTPServiceError {
            if case .httpStatus(401) = error {
                await sessionState.handleUnauthorizedSession()
                return
            }
        } catch {
            // Transient errors: bootstraps may call ensureProfileExists themselves.
        }
        await userSettingsCloudSync.bootstrapFromCloudIfPossible(skipEnsureProfile: profileEnsured)
        await achievementsCloudSync.bootstrapFromCloudIfPossible(skipEnsureProfile: profileEnsured)
    }

    private func runNotificationSync() async {
        guard let profile = onboardingStore.loadProfile(userID: userID) else { return }
        let calendar = Calendar.current
        let now = Date()
        let streak = SobrietyCounter.soberDays(
            since: profile.sobrietyStartDate,
            now: now,
            calendar: calendar
        )
        let nextMilestone = Self.nextMilestone(after: streak)
        let prefs = notificationPreferencesStore.load(userID: userID)
        try? await NotificationScheduleSync.syncAll(
            userID: userID,
            profile: profile,
            preferences: prefs,
            currentStreakDays: streak,
            nextMilestoneTarget: nextMilestone,
            notificationService: notificationService,
            calendar: calendar,
            now: now
        )
    }

    private static func nextMilestone(after days: Int) -> Int {
        let milestones = [7, 30, 90, 365]
        return milestones.first(where: { days < $0 }) ?? (days + 30)
    }

    private static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = .current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

private struct OnboardingFlowView: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(
                    L10n.format(
                        "onboarding.progress",
                        "\(state.currentStep + 1)",
                        "\(state.totalSteps)"
                    )
                )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Group {
                    switch state.currentStep {
                    case 0: goalStep
                    case 1: dateStep
                    case 2: costStep
                    default: notificationsStep
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                HStack {
                    if state.currentStep > 0 {
                        Button {
                            state.back()
                        } label: {
                            L10n.text("common.back")
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if state.currentStep == 0 || state.currentStep == 2 {
                        Button {
                            state.skipCurrentStep()
                        } label: {
                            L10n.text("common.skip")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        if state.currentStep == state.totalSteps - 1 {
                            state.complete()
                        } else {
                            state.next()
                        }
                    } label: {
                        if state.currentStep == state.totalSteps - 1 {
                            L10n.text("common.finish")
                        } else {
                            L10n.text("common.continue")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!state.canContinue)
                }
            }
            .padding()
            .navigationTitle(L10n.text("onboarding.title"))
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.text("onboarding.goal.question")
                .font(.title2)
                .bold()

            ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                Button {
                    state.selectedGoal = goal
                } label: {
                    HStack {
                        Text(goal.localizedTitle)
                        Spacer()
                        if state.selectedGoal == goal {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            L10n.text("onboarding.goal.helper")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.text("onboarding.startdate.title")
                .font(.title2)
                .bold()
            DatePicker(selection: $state.sobrietyStartDate, in: ...Date(), displayedComponents: .date) {
                L10n.text("onboarding.startdate.field")
            }
            .datePickerStyle(.graphical)
        }
    }

    private var costStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.text("onboarding.cost.title")
                .font(.title2)
                .bold()

            TextField(L10n.string("onboarding.cost.placeholder"), text: $state.dailyAlcoholCostText)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

            L10n.text("onboarding.cost.helper")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            L10n.text("onboarding.notifications.title")
                .font(.title2)
                .bold()
            Toggle(L10n.string("onboarding.notifications.toggle"), isOn: $state.notificationsEnabled)
            L10n.text("onboarding.notifications.helper")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SignedOutPlaceholderView: View {
    let errorMessage: String?
    let onSignIn: (String, String) async -> Void
    let onSignUp: (String, String) async -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isBusy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                L10n.text("app.name")
                    .font(.largeTitle)
                    .bold()

                L10n.text("auth.welcome.body")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Group {
                    #if os(iOS)
                    TextField(L10n.string("auth.email"), text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    #else
                    TextField(L10n.string("auth.email"), text: $email)
                    #endif
                }
                .textFieldStyle(.roundedBorder)

                Group {
                    #if os(iOS)
                    SecureField(L10n.string("auth.password"), text: $password)
                        .textContentType(.password)
                    #else
                    SecureField(L10n.string("auth.password"), text: $password)
                    #endif
                }
                .textFieldStyle(.roundedBorder)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button {
                    AnalyticsTracker.shared.track(
                        name: "auth_started",
                        properties: ["method": "email_password_signin"]
                    )
                    Task {
                        isBusy = true
                        await onSignIn(
                            email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password
                        )
                        isBusy = false
                    }
                } label: {
                    L10n.text("auth.signin")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBusy)

                Button {
                    AnalyticsTracker.shared.track(
                        name: "auth_started",
                        properties: ["method": "email_password_signup"]
                    )
                    Task {
                        isBusy = true
                        await onSignUp(
                            email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password
                        )
                        isBusy = false
                    }
                } label: {
                    L10n.text("auth.create_account")
                }
                .disabled(isBusy)
            }
            .padding(24)
            .navigationTitle(L10n.text("onboarding.title"))
        }
    }
}

private struct HomeView: View {
    let userID: UUID
    let onboardingStore: OnboardingStore
    let relapseStore: RelapseHistoryStore
    let supportContactStore: SupportContactStore
    @StateObject private var state: HomeState
    let aiService: (any AIService)?
    @Binding var notificationSyncTick: Int
    @EnvironmentObject private var sobrietyCloudSync: SobrietyCloudSync
    private let analytics: AnalyticsTracker

    @State private var showSOS = false
    @State private var showRelapseConfirm = false

    init(
        userID: UUID,
        onboardingStore: OnboardingStore,
        relapseStore: RelapseHistoryStore,
        supportContactStore: SupportContactStore,
        state: HomeState,
        aiService: (any AIService)?,
        notificationSyncTick: Binding<Int>,
        analytics: AnalyticsTracker = .shared
    ) {
        self.userID = userID
        self.onboardingStore = onboardingStore
        self.relapseStore = relapseStore
        self.supportContactStore = supportContactStore
        self.aiService = aiService
        self.analytics = analytics
        _notificationSyncTick = notificationSyncTick
        _state = StateObject(wrappedValue: state)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    analytics.track(name: "sos_opened", properties: ["source": "home"])
                    showSOS = true
                } label: {
                    Label {
                        L10n.text("home.sos")
                    } icon: {
                        Image(systemName: "lifepreserver")
                    }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                L10n.text("home.sobriety.heading")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(L10n.format("home.days", "\(state.soberDays)"))
                    .font(.system(size: 42, weight: .bold))

                if let dailyAlcoholCost = state.dailyAlcoholCost {
                    Text(
                        L10n.format(
                            "home.estimated_savings",
                            "\(Int(Double(state.soberDays) * dailyAlcoholCost))"
                        )
                    )
                        .font(.subheadline)
                }

                if let startDate = state.sobrietyStartDate {
                    Text(
                        L10n.format(
                            "home.period_started",
                            startDate.formatted(date: .abbreviated, time: .omitted)
                        )
                    )
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.format("home.next_milestone", "\(state.nextMilestoneDays)"))
                        .font(.subheadline)
                    ProgressView(value: state.milestoneProgress)
                }

                Divider()

                Button(EmpathyCopy.relapseButton) {
                    showRelapseConfirm = true
                }
                .buttonStyle(.bordered)

                L10n.text("home.relapse_helper")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle(L10n.text("home.title"))
            .task {
                state.load()
            }
            .sheet(isPresented: $showSOS) {
                NavigationStack {
                    SOSFlowView(
                        userID: userID,
                        contact: supportContactStore.loadContact(userID: userID),
                        soberDays: state.soberDays,
                        aiService: aiService
                    )
                    .navigationTitle(L10n.text("sos.title"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                showSOS = false
                            } label: {
                                L10n.text("common.close")
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                EmpathyCopy.relapseTitle,
                isPresented: $showRelapseConfirm,
                titleVisibility: .visible
            ) {
                Button(EmpathyCopy.relapseConfirm, role: .destructive) {
                    let calendar = Calendar.current
                    let now = Date()
                    let newStart = calendar.startOfDay(for: now)
                    let previousStreak = state.soberDays
                    RelapseRecording.recordRelapse(
                        userID: userID,
                        newPeriodStart: now,
                        now: now,
                        calendar: calendar,
                        profileStore: onboardingStore,
                        historyStore: relapseStore
                    )
                    state.load()
                    notificationSyncTick += 1
                    analytics.track(
                        name: "relapse_logged",
                        properties: [
                            "source": "home_truth_button",
                            "previous_streak_days": "\(previousStreak)"
                        ]
                    )
                    Task {
                        await sobrietyCloudSync.syncAfterRelapse(
                            newPeriodStart: newStart,
                            occurredAt: now
                        )
                    }
                }
                Button(EmpathyCopy.relapseCancel, role: .cancel) {}
            } message: {
                Text(EmpathyCopy.relapseMessage)
            }
        }
    }
}

private struct StatsView: View {
    @StateObject private var state: StatsState
    let achievementsCloudSync: AchievementsCloudSync
    let syncTick: Int

    init(state: StatsState, achievementsCloudSync: AchievementsCloudSync, syncTick: Int) {
        _state = StateObject(wrappedValue: state)
        self.achievementsCloudSync = achievementsCloudSync
        self.syncTick = syncTick
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    L10n.text("stats.title")
                        .font(.title2)
                        .bold()

                    statRow(labelKey: "stats.current_period", value: L10n.format("stats.period_row.days", "\(state.currentStreakDays)"))
                    statRow(labelKey: "stats.best_streak", value: L10n.format("stats.period_row.days", "\(state.longestStreakDays)"))
                    statRow(labelKey: "stats.honesty_times", value: "\(state.honestyCheckIns)")
                    statRow(labelKey: "stats.savings_period", value: "\(Int(state.savedMoney))")
                    statRow(labelKey: "stats.next_milestone", value: L10n.format("stats.period_row.days", "\(state.nextMilestoneDays)"))
                    statRow(labelKey: "stats.progress", value: "\(state.progressPercent)%")

                    ProgressView(value: Double(state.progressPercent), total: 100)

                    if !state.unlockedMilestones.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            L10n.text("stats.milestones_earned")
                                .font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(state.unlockedMilestones, id: \.self) { milestone in
                                        Text("\(milestone)d")
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.green.opacity(0.2), in: Capsule())
                                    }
                                }
                            }
                        }
                    }

                    if !state.newlyUnlockedMilestones.isEmpty {
                        Text(
                            L10n.format(
                                "stats.celebrating",
                                state.newlyUnlockedMilestones.map { "\($0)d" }.joined(separator: ", ")
                            )
                        )
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    if !state.periodSummaries.isEmpty {
                        Divider()
                        Text(EmpathyCopy.statsPeriodsHeading)
                            .font(.headline)
                        Text(EmpathyCopy.statsPeriodsFootnote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        ForEach(state.periodSummaries.indices, id: \.self) { idx in
                            statsPeriodCard(state.periodSummaries[idx])
                        }
                    }

                    L10n.text("stats.relapse_helper")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(L10n.text("stats.title"))
            .task(id: syncTick) {
                state.load()
                await achievementsCloudSync.pushMilestones(days: Set(state.newlyUnlockedMilestones))
            }
        }
    }

    @ViewBuilder
    private func statsPeriodCard(_ row: SobrietyPeriodSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.isCurrent ? EmpathyCopy.statsPeriodCurrentBadge : EmpathyCopy.statsPeriodPastBadge)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(L10n.format("stats.period_row.days", "\(row.soberDaysCounted)"))
                    .font(.subheadline)
                    .bold()
            }
            if row.isCurrent {
                Text(
                    L10n.format(
                        "stats.period_row.since",
                        row.periodStart.formatted(date: .abbreviated, time: .omitted)
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let end = row.periodEnd {
                Text(
                    "\(row.periodStart.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statRow(labelKey: String, value: String) -> some View {
        HStack {
            L10n.text(labelKey)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

private struct ProfileView: View {
    let userID: UUID
    let supportContactStore: SupportContactStore
    let notificationPreferencesStore: NotificationPreferencesStore
    let userSettingsCloudSync: UserSettingsCloudSync
    let onNotificationPreferencesChanged: () -> Void
    let onSignOutTap: () -> Void
    @EnvironmentObject private var localizationSettings: LocalizationSettings

    @State private var trustedName: String = ""
    @State private var trustedPhone: String = ""
    @State private var notificationPrefs = NotificationPreferences()
    @State private var reminderTime = Date()
    @State private var quietHoursOn = false
    @State private var quietStartHour = 22
    @State private var quietEndHour = 8

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    L10n.text("profile.more_settings")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Picker(selection: $localizationSettings.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            L10n.text(language.labelKey).tag(language)
                        }
                    } label: {
                        L10n.text("profile.language")
                    }
                }

                Section {
                    Toggle(EmpathyCopy.profileNotificationsDaily, isOn: dailyEnabledBinding)
                    Toggle(EmpathyCopy.profileNotificationsMilestone, isOn: milestoneEnabledBinding)
                    Toggle(EmpathyCopy.profileNotificationsReengagement, isOn: reengagementEnabledBinding)
                    DatePicker(EmpathyCopy.profileNotificationsTime, selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, newValue in
                            let cal = Calendar.current
                            saveNotificationPrefs(
                                NotificationPreferences(
                                    dailyEnabled: notificationPrefs.dailyEnabled,
                                    milestoneEnabled: notificationPrefs.milestoneEnabled,
                                    reengagementEnabled: notificationPrefs.reengagementEnabled,
                                    dailyReminderHour: cal.component(.hour, from: newValue),
                                    dailyReminderMinute: cal.component(.minute, from: newValue),
                                    quietHoursStart: notificationPrefs.quietHoursStart,
                                    quietHoursEnd: notificationPrefs.quietHoursEnd
                                )
                            )
                        }
                    Toggle(EmpathyCopy.profileNotificationsQuiet, isOn: $quietHoursOn)
                        .onChange(of: quietHoursOn) { _, on in
                            if on {
                                saveNotificationPrefs(
                                    NotificationPreferences(
                                        dailyEnabled: notificationPrefs.dailyEnabled,
                                        milestoneEnabled: notificationPrefs.milestoneEnabled,
                                        reengagementEnabled: notificationPrefs.reengagementEnabled,
                                        dailyReminderHour: notificationPrefs.dailyReminderHour,
                                        dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                                        quietHoursStart: quietStartHour,
                                        quietHoursEnd: quietEndHour
                                    )
                                )
                            } else {
                                saveNotificationPrefs(
                                    NotificationPreferences(
                                        dailyEnabled: notificationPrefs.dailyEnabled,
                                        milestoneEnabled: notificationPrefs.milestoneEnabled,
                                        reengagementEnabled: notificationPrefs.reengagementEnabled,
                                        dailyReminderHour: notificationPrefs.dailyReminderHour,
                                        dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                                        quietHoursStart: nil,
                                        quietHoursEnd: nil
                                    )
                                )
                            }
                        }
                    if quietHoursOn {
                        Picker(EmpathyCopy.profileNotificationsQuietStart, selection: $quietStartHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(String(format: "%02d:00", h)).tag(h)
                            }
                        }
                        .onChange(of: quietStartHour) { _, _ in
                            persistQuietHoursIfOn()
                        }
                        Picker(EmpathyCopy.profileNotificationsQuietEnd, selection: $quietEndHour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(String(format: "%02d:00", h)).tag(h)
                            }
                        }
                        .onChange(of: quietEndHour) { _, _ in
                            persistQuietHoursIfOn()
                        }
                    }
                } header: {
                    Text(EmpathyCopy.profileNotificationsHeading)
                } footer: {
                    Text(EmpathyCopy.profileNotificationsHint)
                }

                Section {
                    TextField(L10n.string("profile.contact.name"), text: $trustedName)
                    TextField(L10n.string("profile.contact.phone"), text: $trustedPhone)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text(EmpathyCopy.profileSupportHeading)
                } footer: {
                    Text(EmpathyCopy.profileSupportHint)
                }

                Section {
                    Button {
                        let contact = SupportContact(trustedName: trustedName, trustedPhone: trustedPhone)
                        supportContactStore.saveContact(contact, userID: userID)
                        Task {
                            await userSettingsCloudSync.pushSupportContact(contact)
                        }
                    } label: {
                        L10n.text("profile.sos_contact.save")
                    }
                }

                Section {
                    Button(action: onSignOutTap) {
                        L10n.text("profile.signout")
                    }
                }
            }
            .navigationTitle(L10n.text("profile.title"))
            .onAppear {
                applyStoresToForm()
            }
            .onChange(of: userSettingsCloudSync.settingsRevision) { _, _ in
                applyStoresToForm()
            }
        }
    }

    private func applyStoresToForm() {
        let c = supportContactStore.loadContact(userID: userID)
        trustedName = c.trustedName
        trustedPhone = c.trustedPhone
        loadNotificationForm()
    }

    private var dailyEnabledBinding: Binding<Bool> {
        Binding(
            get: { notificationPrefs.dailyEnabled },
            set: { newValue in
                saveNotificationPrefs(
                    NotificationPreferences(
                        dailyEnabled: newValue,
                        milestoneEnabled: notificationPrefs.milestoneEnabled,
                        reengagementEnabled: notificationPrefs.reengagementEnabled,
                        dailyReminderHour: notificationPrefs.dailyReminderHour,
                        dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                        quietHoursStart: notificationPrefs.quietHoursStart,
                        quietHoursEnd: notificationPrefs.quietHoursEnd
                    )
                )
            }
        )
    }

    private var milestoneEnabledBinding: Binding<Bool> {
        Binding(
            get: { notificationPrefs.milestoneEnabled },
            set: { newValue in
                saveNotificationPrefs(
                    NotificationPreferences(
                        dailyEnabled: notificationPrefs.dailyEnabled,
                        milestoneEnabled: newValue,
                        reengagementEnabled: notificationPrefs.reengagementEnabled,
                        dailyReminderHour: notificationPrefs.dailyReminderHour,
                        dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                        quietHoursStart: notificationPrefs.quietHoursStart,
                        quietHoursEnd: notificationPrefs.quietHoursEnd
                    )
                )
            }
        )
    }

    private var reengagementEnabledBinding: Binding<Bool> {
        Binding(
            get: { notificationPrefs.reengagementEnabled },
            set: { newValue in
                saveNotificationPrefs(
                    NotificationPreferences(
                        dailyEnabled: notificationPrefs.dailyEnabled,
                        milestoneEnabled: notificationPrefs.milestoneEnabled,
                        reengagementEnabled: newValue,
                        dailyReminderHour: notificationPrefs.dailyReminderHour,
                        dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                        quietHoursStart: notificationPrefs.quietHoursStart,
                        quietHoursEnd: notificationPrefs.quietHoursEnd
                    )
                )
            }
        )
    }

    private func loadNotificationForm() {
        let p = notificationPreferencesStore.load(userID: userID)
        notificationPrefs = p
        let cal = Calendar.current
        reminderTime = cal.date(
            bySettingHour: p.dailyReminderHour,
            minute: p.dailyReminderMinute,
            second: 0,
            of: Date()
        ) ?? Date()
        quietHoursOn = p.quietHoursStart != nil && p.quietHoursEnd != nil
        quietStartHour = p.quietHoursStart ?? 22
        quietEndHour = p.quietHoursEnd ?? 8
    }

    private func saveNotificationPrefs(_ prefs: NotificationPreferences) {
        notificationPrefs = prefs
        notificationPreferencesStore.save(prefs, userID: userID)
        onNotificationPreferencesChanged()
        Task {
            await userSettingsCloudSync.pushNotificationPreferences(prefs)
        }
    }

    private func persistQuietHoursIfOn() {
        guard quietHoursOn else { return }
        saveNotificationPrefs(
            NotificationPreferences(
                dailyEnabled: notificationPrefs.dailyEnabled,
                milestoneEnabled: notificationPrefs.milestoneEnabled,
                reengagementEnabled: notificationPrefs.reengagementEnabled,
                dailyReminderHour: notificationPrefs.dailyReminderHour,
                dailyReminderMinute: notificationPrefs.dailyReminderMinute,
                quietHoursStart: quietStartHour,
                quietHoursEnd: quietEndHour
            )
        )
    }
}
