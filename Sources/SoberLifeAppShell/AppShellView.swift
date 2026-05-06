import SwiftUI
import Foundation
import SoberLifeCore

public struct AppShellView: View {
    @ObservedObject private var sessionState: SessionState
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
        self.onboardingStore = store
        self.relapseStore = UserDefaultsRelapseHistoryStore()
        self.supportContactStore = UserDefaultsSupportContactStore()
        self.achievementStore = UserDefaultsAchievementStore()
        self.notificationService = UNNotificationCenterService()
        self.notificationPreferencesStore = UserDefaultsNotificationPreferencesStore()
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
                onboardingStore: store
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
    let onSignOutTap: () -> Void

    @State private var notificationSyncTick: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if let message = cloudSync.lastError {
                HStack(alignment: .top, spacing: 8) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Button("Dismiss") {
                        cloudSync.clearError()
                    }
                    .font(.footnote)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.18))
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
                Label("Home", systemImage: "house")
            }

            AIChatTabView(
                sessionState: sessionState,
                userID: userID,
                onboardingStore: onboardingStore,
                aiService: aiService,
                authWiring: authWiring
            )
            .tabItem {
                Label("AI Chat", systemImage: "message")
            }

            StatsView(
                state: StatsState(
                    userID: userID,
                    store: onboardingStore,
                    relapseStore: relapseStore,
                    achievementStore: achievementStore
                ),
                syncTick: notificationSyncTick
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }

            ProfileView(
                userID: userID,
                supportContactStore: supportContactStore,
                notificationPreferencesStore: notificationPreferencesStore,
                onNotificationPreferencesChanged: { notificationSyncTick += 1 },
                onSignOutTap: onSignOutTap
            )
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            }
        }
        .environmentObject(cloudSync)
        .task(id: notificationSyncTick) {
            await runNotificationSync()
        }
        .task {
            await syncUserProfileIfPossible()
        }
    }

    private func syncUserProfileIfPossible() async {
        guard let wiring = authWiring,
              let token = await sessionState.accessTokenIfAvailable(),
              SupabaseJWT.isLikelyUserAccessToken(token)
        else { return }
        let http = HTTPSupabaseService(baseURL: wiring.supabaseURL, anonKey: wiring.supabaseAnonKey)
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
        } catch let error as SupabaseHTTPServiceError {
            if case .httpStatus(401) = error {
                await sessionState.handleUnauthorizedSession()
            }
        } catch {
            // Ignore transient errors here; onboarding/relapse sync paths surface user-facing messages.
        }
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
}

private struct OnboardingFlowView: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Onboarding \(state.currentStep + 1)/\(state.totalSteps)")
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
                        Button("Back") {
                            state.back()
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if state.currentStep == 0 || state.currentStep == 2 {
                        Button("Skip") {
                            state.skipCurrentStep()
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(state.currentStep == state.totalSteps - 1 ? "Finish" : "Continue") {
                        if state.currentStep == state.totalSteps - 1 {
                            state.complete()
                        } else {
                            state.next()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!state.canContinue)
                }
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What feels right as a direction?")
                .font(.title2)
                .bold()

            ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                Button {
                    state.selectedGoal = goal
                } label: {
                    HStack {
                        Text(goal.rawValue)
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

            Text("There is no wrong answer, and you can change your mind later.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When does this sober period start?")
                .font(.title2)
                .bold()
            DatePicker(
                "Start date",
                selection: $state.sobrietyStartDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
        }
    }

    private var costStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Average daily alcohol spend")
                .font(.title2)
                .bold()

            TextField("Optional (e.g. 850)", text: $state.dailyAlcoholCostText)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

            Text("Used to calculate your savings. You can skip this step.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily reminders")
                .font(.title2)
                .bold()
            Toggle("Gentle daily reminders", isOn: $state.notificationsEnabled)
            Text("You can change this anytime. We keep reminders short and skip shaming language.")
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
                Text("SoberLife")
                    .font(.largeTitle)
                    .bold()

                Text("Sign in with email to save your progress. If signing in feels like a lot right now, you can still come back when you are ready.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Group {
                    #if os(iOS)
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    #else
                    TextField("Email", text: $email)
                    #endif
                }
                .textFieldStyle(.roundedBorder)

                Group {
                    #if os(iOS)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    #else
                    SecureField("Password", text: $password)
                    #endif
                }
                .textFieldStyle(.roundedBorder)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button("Sign in") {
                    Task {
                        isBusy = true
                        await onSignIn(
                            email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password
                        )
                        isBusy = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBusy)

                Button("Create account") {
                    Task {
                        isBusy = true
                        await onSignUp(
                            email.trimmingCharacters(in: .whitespacesAndNewlines),
                            password
                        )
                        isBusy = false
                    }
                }
                .disabled(isBusy)
            }
            .padding(24)
            .navigationTitle("Welcome")
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

    @State private var showSOS = false
    @State private var showRelapseConfirm = false

    init(
        userID: UUID,
        onboardingStore: OnboardingStore,
        relapseStore: RelapseHistoryStore,
        supportContactStore: SupportContactStore,
        state: HomeState,
        aiService: (any AIService)?,
        notificationSyncTick: Binding<Int>
    ) {
        self.userID = userID
        self.onboardingStore = onboardingStore
        self.relapseStore = relapseStore
        self.supportContactStore = supportContactStore
        self.aiService = aiService
        _notificationSyncTick = notificationSyncTick
        _state = StateObject(wrappedValue: state)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showSOS = true
                } label: {
                    Label("SOS — quick help", systemImage: "lifepreserver")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Text("Sobriety")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(state.soberDays) days")
                    .font(.system(size: 42, weight: .bold))

                if let dailyAlcoholCost = state.dailyAlcoholCost {
                    Text("Estimated savings: \(Int(Double(state.soberDays) * dailyAlcoholCost))")
                        .font(.subheadline)
                }

                if let startDate = state.sobrietyStartDate {
                    Text("This period started: \(startDate.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Next milestone: \(state.nextMilestoneDays) days")
                        .font(.subheadline)
                    ProgressView(value: state.milestoneProgress)
                }

                Divider()

                Button(EmpathyCopy.relapseButton) {
                    showRelapseConfirm = true
                }
                .buttonStyle(.bordered)

                Text("Your milestones stay with you. Starting a new period does not erase what you have already learned.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
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
                    .navigationTitle("SOS")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showSOS = false
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
    let syncTick: Int

    init(state: StatsState, syncTick: Int) {
        _state = StateObject(wrappedValue: state)
        self.syncTick = syncTick
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stats")
                        .font(.title2)
                        .bold()

                    statRow(label: "Current period", value: "\(state.currentStreakDays) days")
                    statRow(label: "Best streak so far", value: "\(state.longestStreakDays) days")
                    statRow(label: "Times you chose honesty", value: "\(state.honestyCheckIns)")
                    statRow(label: "Estimated savings (period)", value: "\(Int(state.savedMoney))")
                    statRow(label: "Next milestone", value: "\(state.nextMilestoneDays) days")
                    statRow(label: "Progress", value: "\(state.progressPercent)%")

                    ProgressView(value: Double(state.progressPercent), total: 100)

                    if !state.unlockedMilestones.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Milestones you have earned")
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
                        Text("Celebrating: \(state.newlyUnlockedMilestones.map { "\($0)d" }.joined(separator: ", "))")
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

                    Text("Honesty check-ins start a new sober period without removing badges you already unlocked.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Stats")
            .task(id: syncTick) {
                state.load()
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
                Text("\(row.soberDaysCounted) days")
                    .font(.subheadline)
                    .bold()
            }
            if row.isCurrent {
                Text("Since \(row.periodStart.formatted(date: .abbreviated, time: .omitted))")
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
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
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
    let onNotificationPreferencesChanged: () -> Void
    let onSignOutTap: () -> Void

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
                    Text("More settings will arrive later. What you add here stays on this device unless you sign in and sync in a future release.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    TextField("Name or nickname", text: $trustedName)
                    TextField("Phone number", text: $trustedPhone)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text(EmpathyCopy.profileSupportHeading)
                } footer: {
                    Text(EmpathyCopy.profileSupportHint)
                }

                Section {
                    Button("Save SOS contact") {
                        supportContactStore.saveContact(
                            SupportContact(trustedName: trustedName, trustedPhone: trustedPhone),
                            userID: userID
                        )
                    }
                }

                Section {
                    Button("Sign out", action: onSignOutTap)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                let c = supportContactStore.loadContact(userID: userID)
                trustedName = c.trustedName
                trustedPhone = c.trustedPhone
                loadNotificationForm()
            }
        }
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
