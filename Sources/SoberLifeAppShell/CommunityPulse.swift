import Foundation
import SwiftUI
import SoberLifeCore

@MainActor
final class CommunityPulseState: ObservableObject {
    struct DayCount: Identifiable, Decodable {
        let day: String
        let checkins: Int
        var id: String { day }
    }

    @Published var last7: [DayCount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let sessionState: SessionState
    private let authWiring: AuthWiring?
    private let userDefaults: UserDefaults
    private let localPrefix = "soberlife.community.local."

    var isAvailable: Bool { true }

    init(
        sessionState: SessionState,
        authWiring: AuthWiring?,
        userDefaults: UserDefaults = .standard
    ) {
        self.sessionState = sessionState
        self.authWiring = authWiring
        self.userDefaults = userDefaults
    }

    func checkInAnonymously() async {
        guard authWiring != nil else {
            checkInLocallyOncePerDay()
            await refresh()
            return
        }
        await perform {
            guard let authWiring else { return }
            let token = try await requireToken()
            let http = HTTPSupabaseService(baseURL: authWiring.supabaseURL, anonKey: authWiring.supabaseAnonKey)
            try await http.restRPCVoid(function: "community_checkin", jsonBody: Data("{}".utf8), bearerToken: token)
        }
        await refresh()
    }

    func refresh() async {
        guard authWiring != nil else {
            refreshLocal()
            return
        }
        await perform {
            guard let authWiring else { return }
            let token = try await requireToken()
            let http = HTTPSupabaseService(baseURL: authWiring.supabaseURL, anonKey: authWiring.supabaseAnonKey)
            let data = try await http.restRPC(function: "community_pulse_last7", jsonBody: Data("{}".utf8), bearerToken: token)
            let decoded = try JSONDecoder().decode([DayCount].self, from: data)
            last7 = decoded
        }
    }

    private func requireToken() async throws -> String {
        guard let token = await sessionState.accessTokenIfAvailable(),
              SupabaseJWT.isLikelyUserAccessToken(token)
        else {
            throw SupabaseHTTPServiceError.httpStatus(401)
        }
        return token
    }

    private func perform(_ work: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await work()
        } catch let error as SupabaseHTTPServiceError {
            if case .httpStatus(401) = error {
                await sessionState.handleUnauthorizedSession()
                return
            }
            errorMessage = String(describing: error)
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func checkInLocallyOncePerDay() {
        let day = Self.utcDayKey(Date())
        let onceKey = localPrefix + "checked.\(day)"
        guard userDefaults.bool(forKey: onceKey) == false else { return }
        let countKey = localPrefix + "count.\(day)"
        let next = userDefaults.integer(forKey: countKey) + 1
        userDefaults.set(next, forKey: countKey)
        userDefaults.set(true, forKey: onceKey)
    }

    private func refreshLocal() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        var rows: [DayCount] = []
        for i in stride(from: 6, through: 0, by: -1) {
            guard let d = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let day = Self.utcDayKey(d)
            let count = userDefaults.integer(forKey: localPrefix + "count.\(day)")
            rows.append(DayCount(day: day, checkins: count))
        }
        last7 = rows
    }

    private static func utcDayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

struct CommunityPulseCard: View {
    @ObservedObject var state: CommunityPulseState

    private var todayCount: Int? {
        let today = Self.utcDayKey(Date())
        return state.last7.first(where: { $0.day == today })?.checkins
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("community.title", bundle: .module)
                .font(.title3)
                .bold()
                .fontDesign(.rounded)

            Text("community.subtitle", bundle: .module)
                .font(.footnote)
                .calmSecondaryText()

            if let n = todayCount {
                Text(
                    L10n.format("community.today_checkins", "\(n)")
                )
                .font(.subheadline.weight(.semibold))
            }

            if let msg = state.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(CalmTheme.sos)
            }

            Button {
                Task { await state.checkInAnonymously() }
            } label: {
                if state.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("community.checkin", bundle: .module).frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(CalmPrimaryButtonStyle())
            .tint(CalmTheme.accent)
        }
        .calmCard()
        .task {
            await state.refresh()
        }
    }

    private static func utcDayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

