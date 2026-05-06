import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class UserSettingsCloudSync: ObservableObject {
    @Published public private(set) var lastError: String?
    /// Incremented after cloud prefs/contact are merged into local stores so Profile can refresh.
    @Published public private(set) var settingsRevision: UInt = 0

    private let userID: UUID
    private let authWiring: AuthWiring?
    private let sessionState: SessionState
    private let notificationPreferencesStore: NotificationPreferencesStore
    private let supportContactStore: SupportContactStore

    public init(
        userID: UUID,
        authWiring: AuthWiring?,
        sessionState: SessionState,
        notificationPreferencesStore: NotificationPreferencesStore,
        supportContactStore: SupportContactStore
    ) {
        self.userID = userID
        self.authWiring = authWiring
        self.sessionState = sessionState
        self.notificationPreferencesStore = notificationPreferencesStore
        self.supportContactStore = supportContactStore
    }

    public func clearError() {
        lastError = nil
    }

    public func bootstrapFromCloudIfPossible(skipEnsureProfile: Bool = false) async {
        guard let (token, http) = await makeClient() else { return }
        let sync = UserSettingsSupabaseSync(http: http)
        do {
            if !skipEnsureProfile {
                try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            }
            let localPrefs = notificationPreferencesStore.load(userID: userID)
            let resolvedPrefs = try await sync.resolveNotificationPreferences(
                userId: userID,
                local: localPrefs,
                bearerToken: token
            )
            var changed = false
            if resolvedPrefs != localPrefs {
                notificationPreferencesStore.save(resolvedPrefs, userID: userID)
                changed = true
            }

            let localContact = supportContactStore.loadContact(userID: userID)
            let resolvedContact = try await sync.resolveSupportContact(
                userId: userID,
                local: localContact,
                bearerToken: token
            )
            if resolvedContact != localContact {
                supportContactStore.saveContact(resolvedContact, userID: userID)
                changed = true
            }

            lastError = nil
            if changed {
                settingsRevision &+= 1
            }
        } catch {
            await handleSyncError(error)
        }
    }

    public func pushNotificationPreferences(_ preferences: NotificationPreferences) async {
        guard let (token, http) = await makeClient() else { return }
        let sync = UserSettingsSupabaseSync(http: http)
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            try await sync.upsertNotificationPreferences(
                userId: userID,
                preferences: preferences,
                bearerToken: token
            )
            lastError = nil
        } catch {
            await handleSyncError(error)
        }
    }

    public func pushSupportContact(_ contact: SupportContact) async {
        guard let (token, http) = await makeClient() else { return }
        let sync = UserSettingsSupabaseSync(http: http)
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            try await sync.upsertSupportContact(
                userId: userID,
                contact: contact,
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
