import Foundation

/// Minimal profile fields needed for Supabase `users` / period sync (decouples Core from app-layer onboarding models).
public struct SobrietyProfileSnapshot: Sendable, Equatable {
    public let sobrietyStartDate: Date
    public let dailyAlcoholCost: Double?
    public let displayName: String?

    public init(sobrietyStartDate: Date, dailyAlcoholCost: Double?, displayName: String?) {
        self.sobrietyStartDate = sobrietyStartDate
        self.dailyAlcoholCost = dailyAlcoholCost
        self.displayName = displayName
    }
}
