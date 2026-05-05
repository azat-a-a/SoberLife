import SwiftUI
import Foundation

public struct AppShellView: View {
    @ObservedObject private var sessionState: SessionState

    public init(sessionState: SessionState) {
        self.sessionState = sessionState
    }

    public var body: some View {
        Group {
            switch sessionState.authState {
            case .signedOut:
                SignedOutPlaceholderView(
                    errorMessage: sessionState.authErrorMessage,
                    onSignInTap: {
                        Task {
                            await sessionState.signInWithApple()
                        }
                    }
                )
            case let .signedIn(userID):
                SignedInRootView(
                    userID: userID,
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
    let userID: UUID
    let onSignOutTap: () -> Void
    private let onboardingStore: OnboardingStore

    @StateObject private var onboardingState: OnboardingState

    init(userID: UUID, onSignOutTap: @escaping () -> Void) {
        self.userID = userID
        self.onSignOutTap = onSignOutTap
        let store = UserDefaultsOnboardingStore()
        self.onboardingStore = store
        _onboardingState = StateObject(
            wrappedValue: OnboardingState(
                userID: userID,
                store: store
            )
        )
    }

    var body: some View {
        Group {
            if onboardingState.isCompleted {
                MainTabView(
                    userID: userID,
                    onboardingStore: onboardingStore,
                    onSignOutTap: onSignOutTap
                )
            } else {
                OnboardingFlowView(state: onboardingState)
            }
        }
    }
}

private struct MainTabView: View {
    let userID: UUID
    let onboardingStore: OnboardingStore
    let onSignOutTap: () -> Void

    var body: some View {
        TabView {
            HomeView(
                state: HomeState(
                    userID: userID,
                    store: onboardingStore
                )
            )
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            AIChatPlaceholderView()
                .tabItem {
                    Label("AI Chat", systemImage: "message")
                }

            StatsView(
                state: StatsState(
                    userID: userID,
                    store: onboardingStore
                )
            )
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            ProfilePlaceholderView(onSignOutTap: onSignOutTap)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
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
            Text("What is your goal?")
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

            Text("You can skip this and decide later.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("When did your sobriety period start?")
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
            Toggle("Enable motivational notifications", isOn: $state.notificationsEnabled)
            Text("You can change this anytime in settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SignedOutPlaceholderView: View {
    let errorMessage: String?
    let onSignInTap: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("SoberLife")
                    .font(.largeTitle)
                    .bold()

                Text("Apple Sign-In flow is scaffolded. Real token exchange is wired through AuthService.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }

                Button("Sign In Placeholder", action: onSignInTap)
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .navigationTitle("Welcome")
        }
    }
}

private struct HomeView: View {
    @StateObject private var state: HomeState

    init(state: HomeState) {
        _state = StateObject(wrappedValue: state)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sobriety")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(state.soberDays) days")
                    .font(.system(size: 42, weight: .bold))

                if let dailyAlcoholCost = state.dailyAlcoholCost {
                    Text("Saved money: \(Int(Double(state.soberDays) * dailyAlcoholCost))")
                        .font(.subheadline)
                }

                if let startDate = state.sobrietyStartDate {
                    Text("Started: \(startDate.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Next milestone: \(state.nextMilestoneDays) days")
                        .font(.subheadline)
                    ProgressView(value: state.milestoneProgress)
                }

                Divider()

                Text("Sobriety counter is now connected to your onboarding start date.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .task {
                state.load()
            }
        }
    }
}

private struct AIChatPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Chat")
                    .font(.title2)
                    .bold()
                Text("DeepSeek chat and SOS flow will be connected in Sprint 03.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("AI Chat")
        }
    }
}

private struct StatsView: View {
    @StateObject private var state: StatsState

    init(state: StatsState) {
        _state = StateObject(wrappedValue: state)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Stats")
                    .font(.title2)
                    .bold()

                statRow(label: "Current streak", value: "\(state.currentStreakDays) days")
                statRow(label: "Saved money", value: "\(Int(state.savedMoney))")
                statRow(label: "Next milestone", value: "\(state.nextMilestoneDays) days")
                statRow(label: "Progress", value: "\(state.progressPercent)%")

                ProgressView(value: Double(state.progressPercent), total: 100)

                if !state.unlockedMilestones.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Milestones")
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
                    Text("New unlock: \(state.newlyUnlockedMilestones.map { "\($0)d" }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }

                Text("Stats are calculated from your onboarding start date and daily cost.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Stats")
            .task {
                state.load()
            }
        }
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

private struct ProfilePlaceholderView: View {
    let onSignOutTap: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile")
                    .font(.title2)
                    .bold()
                Text("Settings, privacy, and legal screens are wired in later milestones.")
                    .foregroundStyle(.secondary)

                Button("Sign Out Placeholder", action: onSignOutTap)
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("Profile")
        }
    }
}
