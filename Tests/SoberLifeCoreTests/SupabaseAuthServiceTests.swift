import XCTest
import Foundation
@testable import SoberLifeCore

final class SupabaseAuthServiceTests: XCTestCase {
    func testSignInReturnsSessionFromPasswordGrant() async throws {
        let userID = UUID()
        let supabase = MockSupabaseService(
            signIn: .success(SupabasePasswordAuthResult(accessToken: "token-123", userID: userID))
        )
        let service = SupabaseAuthService(supabaseService: supabase)

        let session = try await service.signIn(email: "a@b.co", password: "secret")

        XCTAssertEqual(session.userID, userID)
        XCTAssertEqual(session.accessToken, "token-123")
        let currentSession = try await service.currentSession()
        XCTAssertEqual(currentSession, session)
    }

    func testSignInEmptyPasswordThrows() async {
        let service = SupabaseAuthService(supabaseService: MockSupabaseService())

        do {
            _ = try await service.signIn(email: "a@b.co", password: "")
            XCTFail("Expected error")
        } catch let error as AuthServiceError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSignInMapsHttp400ToInvalidCredentials() async {
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(
                signIn: .failure(SupabaseHTTPServiceError.httpStatus(400))
            )
        )

        do {
            _ = try await service.signIn(email: "a@b.co", password: "bad")
            XCTFail("Expected error")
        } catch let error as AuthServiceError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSignUpMapsPendingConfirmationToEmailNotConfirmed() async {
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(
                signUp: .failure(SupabaseHTTPServiceError.authPendingEmailConfirmation)
            )
        )

        do {
            _ = try await service.signUp(email: "a@b.co", password: "secret")
            XCTFail("Expected error")
        } catch let error as AuthServiceError {
            XCTAssertEqual(error, .emailNotConfirmed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSignOutClearsCachedSession() async throws {
        let userID = UUID()
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(
                signIn: .success(SupabasePasswordAuthResult(accessToken: "token-123", userID: userID))
            )
        )

        _ = try await service.signIn(email: "a@b.co", password: "secret")
        try await service.signOut()

        let current = try await service.currentSession()
        XCTAssertNil(current)
    }

    func testSessionPersistsAcrossServiceRecreation() async throws {
        let suiteName = "SupabaseAuthServiceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let userID = UUID()
        let persistence = UserDefaultsAuthSessionPersistence(
            userDefaults: defaults,
            key: "session"
        )
        let service = SupabaseAuthService(
            supabaseService: MockSupabaseService(
                signIn: .success(SupabasePasswordAuthResult(accessToken: "token-123", userID: userID))
            ),
            sessionPersistence: persistence
        )
        _ = try await service.signIn(email: "a@b.co", password: "secret")

        let recreated = SupabaseAuthService(
            supabaseService: MockSupabaseService(),
            sessionPersistence: persistence
        )
        let restored = try await recreated.currentSession()
        XCTAssertEqual(restored?.userID, userID)
        XCTAssertEqual(restored?.accessToken, "token-123")
    }
}

private actor MockSupabaseService: SupabaseService {
    private let signIn: Result<SupabasePasswordAuthResult, Error>
    private let signUp: Result<SupabasePasswordAuthResult, Error>

    init(
        signIn: Result<SupabasePasswordAuthResult, Error> = .success(
            SupabasePasswordAuthResult(
                accessToken: "token-123",
                userID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            )
        ),
        signUp: Result<SupabasePasswordAuthResult, Error>? = nil
    ) {
        self.signIn = signIn
        self.signUp = signUp ?? signIn
    }

    func select(table: String, filter: [String: String]) async throws -> [[String: String]] {
        []
    }

    func insert(table: String, values: [String: String]) async throws {}

    func invoke(function: String, payload: [String: String]) async throws -> [String: String] {
        [:]
    }

    func authSignIn(email: String, password: String) async throws -> SupabasePasswordAuthResult {
        switch signIn {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }

    func authSignUp(email: String, password: String) async throws -> SupabasePasswordAuthResult {
        switch signUp {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
