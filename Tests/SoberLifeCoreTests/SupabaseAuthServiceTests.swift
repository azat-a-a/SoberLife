import XCTest
import Foundation
@testable import SoberLifeCore

final class SupabaseAuthServiceTests: XCTestCase {
    func testSignInWithAppleReturnsSessionFromEdgeResponse() async throws {
        let userID = UUID()
        let supabase = MockSupabaseService(
            invokeResult: [
                "user_id": userID.uuidString,
                "access_token": "token-123"
            ]
        )
        let service = SupabaseAuthService(supabaseService: supabase)

        let session = try await service.signInWithApple(idToken: "apple-token", nonce: "nonce")

        XCTAssertEqual(session.userID, userID)
        XCTAssertEqual(session.accessToken, "token-123")
        let currentSession = try await service.currentSession()
        XCTAssertEqual(currentSession, session)
    }

    func testSignInWithAppleEmptyTokenThrows() async {
        let service = SupabaseAuthService(supabaseService: MockSupabaseService(invokeResult: [:]))

        do {
            _ = try await service.signInWithApple(idToken: "", nonce: nil)
            XCTFail("Expected error")
        } catch let error as AuthServiceError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSignInWithAppleInvalidResponseThrows() async {
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(invokeResult: ["unexpected": "value"])
        )

        do {
            _ = try await service.signInWithApple(idToken: "apple-token", nonce: nil)
            XCTFail("Expected error")
        } catch let error as AuthServiceError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSignOutClearsCachedSession() async throws {
        let userID = UUID()
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(
                invokeResult: [
                    "user_id": userID.uuidString,
                    "access_token": "token-123"
                ]
            )
        )

        _ = try await service.signInWithApple(idToken: "apple-token", nonce: nil)
        try await service.signOut()

        let current = try await service.currentSession()
        XCTAssertNil(current)
    }
}

private actor MockSupabaseService: SupabaseService {
    private let invokeResult: [String: String]

    init(invokeResult: [String: String]) {
        self.invokeResult = invokeResult
    }

    func select(table: String, filter: [String : String]) async throws -> [[String : String]] {
        []
    }

    func insert(table: String, values: [String : String]) async throws {}

    func invoke(function: String, payload: [String : String]) async throws -> [String : String] {
        invokeResult
    }
}
