import Foundation
import SoberLifeCore

extension AuthWiring {
    public func makeAIService() -> DeepSeekAIService {
        let supabase = HTTPSupabaseService(baseURL: supabaseURL, anonKey: supabaseAnonKey)
        return DeepSeekAIService(supabaseService: supabase)
    }
}
