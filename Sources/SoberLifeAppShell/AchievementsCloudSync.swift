import Foundation
import Combine
import SoberLifeCore

@MainActor
public final class AchievementsCloudSync: ObservableObject {
    @Published public private(set) var lastError: String?
    @Published public private(set) var achievementsRevision: UInt = 0

    private let userID: UUID
    private let authWiring: AuthWiring?
    private let sessionState: SessionState
    private let achievementStore: AchievementStore

    public init(
        userID: UUID,
        authWiring: AuthWiring?,
        sessionState: SessionState,
        achievementStore: AchievementStore
    ) {
        self.userID = userID
        self.authWiring = authWiring
        self.sessionState = sessionState
        self.achievementStore = achievementStore
    }

    public func clearError() {
        lastError = nil
    }

    public func bootstrapFromCloudIfPossible() async {
        guard let (token, http) = await makeClient() else { return }
        let sync = AchievementSupabaseSync(http: http)
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            let cloud = try await sync.fetchUnlockedMilestoneDays(userId: userID, bearerToken: token)
            let local = achievementStore.unlockedMilestones(userID: userID)
            let merged = cloud.union(local)
            var changed = false
            if merged != local {
                achievementStore.saveUnlockedMilestones(merged, userID: userID)
                changed = true
            }
            let toPush = merged.subtracting(cloud)
            for m in toPush.sorted() {
                try await sync.upsertMilestone(userId: userID, milestoneDays: m, bearerToken: token)
            }
            lastError = nil
            if changed || toPush.isEmpty == false {
                achievementsRevision &+= 1
            }
        } catch {
            await handleSyncError(error)
        }
    }

    public func pushMilestones(days: Set<Int>) async {
        guard days.isEmpty == false else { return }
        guard let (token, http) = await makeClient() else { return }
        let sync = AchievementSupabaseSync(http: http)
        do {
            try await UserProfileSync.ensureProfileExists(http: http, bearerToken: token)
            for m in days.sorted() {
                try await sync.upsertMilestone(userId: userID, milestoneDays: m, bearerToken: token)
            }
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
