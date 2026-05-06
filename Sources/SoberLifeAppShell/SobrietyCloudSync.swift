import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class SobrietyCloudSync: ObservableObject {
    @Published public private(set) var lastError: String?
    @Published public private(set) var historyRevision: UInt = 0

    private let userID: UUID
    private let authWiring: AuthWiring?
    private let sessionState: SessionState
    private let onboardingStore: OnboardingStore
    private let relapseStore: RelapseHistoryStore

    public init(
        userID: UUID,
        authWiring: AuthWiring?,
        sessionState: SessionState,
        onboardingStore: OnboardingStore,
        relapseStore: RelapseHistoryStore
    ) {
        self.userID = userID
        self.authWiring = authWiring
        self.sessionState = sessionState
        self.onboardingStore = onboardingStore
        self.relapseStore = relapseStore
    }

    public func clearError() {
        lastError = nil
    }

    public func syncOnboardingFromLocalStore() async {
        guard let (token, http) = await makeClient() else { return }
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            let sync = SobrietySupabaseSync(http: http)
            try await hydrateLocalHistoryFromCloud(sync: sync, bearerToken: token)
            guard let profile = onboardingStore.loadProfile(userID: userID) else { return }
            try await sync.syncOnboardingProfile(
                userId: userID,
                profile: profile.sobrietySnapshot,
                bearerToken: token
            )
            lastError = nil
        } catch {
            await handleSyncError(error)
        }
    }

    public func syncAfterRelapse(newPeriodStart: Date, occurredAt: Date) async {
        guard let (token, http) = await makeClient() else { return }
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            guard let profile = onboardingStore.loadProfile(userID: userID) else { return }
            let sync = SobrietySupabaseSync(http: http)
            try await sync.syncRelapse(
                userId: userID,
                profileAfterRelapse: profile.sobrietySnapshot,
                newPeriodStart: newPeriodStart,
                occurredAt: occurredAt,
                bearerToken: token
            )
            lastError = nil
        } catch {
            await handleSyncError(error)
        }
    }

    private func hydrateLocalHistoryFromCloud(sync: SobrietySupabaseSync, bearerToken: String) async throws {
        guard let snapshot = try await sync.fetchHistorySnapshot(userId: userID, bearerToken: bearerToken) else {
            return
        }
        let existingHistory = relapseStore.events(userID: userID)
        if existingHistory != snapshot.relapseEvents {
            relapseStore.replaceEvents(snapshot.relapseEvents, userID: userID)
            historyRevision &+= 1
        }

        if let currentProfile = onboardingStore.loadProfile(userID: userID) {
            if currentProfile.sobrietyStartDate != snapshot.currentStartDate {
                onboardingStore.saveProfile(
                    OnboardingProfile(
                        userID: currentProfile.userID,
                        goal: currentProfile.goal,
                        sobrietyStartDate: snapshot.currentStartDate,
                        dailyAlcoholCost: currentProfile.dailyAlcoholCost,
                        notificationsEnabled: currentProfile.notificationsEnabled,
                        createdAt: currentProfile.createdAt
                    )
                )
                historyRevision &+= 1
            }
        }
    }

    private func makeClient() async -> (String, HTTPSupabaseService)? {
        guard let wiring = authWiring else { return nil }
        guard let token = await sessionState.accessTokenIfAvailable(),
              SupabaseJWT.isLikelyUserAccessToken(token)
        else { return nil }
        let http = HTTPSupabaseService(baseURL: wiring.supabaseURL, anonKey: wiring.supabaseAnonKey)
        return (token, http)
    }

    private func handleSyncError(_ error: Error) async {
        if case SupabaseHTTPServiceError.httpStatus(401) = error {
            lastError = EmpathyCopy.sessionExpiredNeedsSignIn
            await sessionState.handleUnauthorizedSession()
            return
        }
        if let urlError = error as? URLError,
           Self.isOfflineError(urlError)
        {
            lastError = EmpathyCopy.networkOfflineShort
            return
        }
        lastError = EmpathyCopy.dataSyncFailedShort
    }

    private static func isOfflineError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
