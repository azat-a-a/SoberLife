import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class SobrietyCloudSync: ObservableObject {
    @Published public private(set) var lastError: String?

    private let userID: UUID
    private let authWiring: AuthWiring?
    private let sessionState: SessionState
    private let onboardingStore: OnboardingStore

    public init(
        userID: UUID,
        authWiring: AuthWiring?,
        sessionState: SessionState,
        onboardingStore: OnboardingStore
    ) {
        self.userID = userID
        self.authWiring = authWiring
        self.sessionState = sessionState
        self.onboardingStore = onboardingStore
    }

    public func clearError() {
        lastError = nil
    }

    public func syncOnboardingFromLocalStore() async {
        guard let (token, http) = await makeClient() else { return }
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            guard let profile = onboardingStore.loadProfile(userID: userID) else { return }
            let sync = SobrietySupabaseSync(http: http)
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
