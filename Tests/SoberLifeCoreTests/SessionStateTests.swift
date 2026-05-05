import XCTest
import Foundation
import SoberLifeCore
@testable import SoberLifeAppShell

@MainActor
final class SessionStateTests: XCTestCase {
    func testSessionStartsSignedOutByDefault() {
        let session = SessionState(
            authService: MockAuthService(),
            appleSignInTokenProvider: MockAppleSignInTokenProvider()
        )
        XCTAssertEqual(session.authState, .signedOut)
    }

    func testSignInChangesState() async {
        let userID = UUID()
        let session = SessionState(
            authService: MockAuthService(signInUserID: userID),
            appleSignInTokenProvider: MockAppleSignInTokenProvider()
        )

        await session.signInWithApple()

        XCTAssertEqual(session.authState, .signedIn(userID: userID))
        XCTAssertNil(session.authErrorMessage)
    }

    func testSignOutReturnsToSignedOut() async {
        let session = SessionState(
            authService: MockAuthService(signInUserID: UUID()),
            appleSignInTokenProvider: MockAppleSignInTokenProvider(),
            authState: .signedIn(userID: UUID())
        )

        await session.signOut()

        XCTAssertEqual(session.authState, .signedOut)
    }

    func testSignInFailureSetsErrorMessage() async {
        let session = SessionState(
            authService: MockAuthService(shouldFailSignIn: true),
            appleSignInTokenProvider: MockAppleSignInTokenProvider()
        )

        await session.signInWithApple()

        XCTAssertEqual(session.authState, .signedOut)
        XCTAssertEqual(session.authErrorMessage, "Sign in failed. Please try again.")
    }

    func testRestoreSessionUsesCurrentSession() async {
        let userID = UUID()
        let session = SessionState(
            authService: MockAuthService(storedSession: UserSession(userID: userID, accessToken: "x")),
            appleSignInTokenProvider: MockAppleSignInTokenProvider()
        )

        await session.restoreSession()

        XCTAssertEqual(session.authState, .signedIn(userID: userID))
    }

    func testTokenProviderFailureSetsErrorMessage() async {
        let session = SessionState(
            authService: MockAuthService(),
            appleSignInTokenProvider: MockAppleSignInTokenProvider(shouldFail: true)
        )

        await session.signInWithApple()

        XCTAssertEqual(session.authState, .signedOut)
        XCTAssertEqual(session.authErrorMessage, "Sign in failed. Please try again.")
    }
}

private actor MockAuthService: AuthService {
    private let signInUserID: UUID
    private let shouldFailSignIn: Bool
    private var session: UserSession?

    init(
        signInUserID: UUID = UUID(),
        shouldFailSignIn: Bool = false,
        storedSession: UserSession? = nil
    ) {
        self.signInUserID = signInUserID
        self.shouldFailSignIn = shouldFailSignIn
        self.session = storedSession
    }

    func signInWithApple(idToken: String, nonce: String?) async throws -> UserSession {
        if shouldFailSignIn {
            throw NSError(domain: "MockAuthService", code: 1)
        }
        let newSession = UserSession(userID: signInUserID, accessToken: "token")
        session = newSession
        return newSession
    }

    func signOut() async throws {
        session = nil
    }

    func currentSession() async throws -> UserSession? {
        session
    }
}

private actor MockAppleSignInTokenProvider: AppleSignInTokenProvider {
    private let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func requestToken() async throws -> AppleSignInToken {
        if shouldFail {
            throw NSError(domain: "MockAppleSignInTokenProvider", code: 1)
        }
        return AppleSignInToken(idToken: "mock-apple-token", nonce: nil)
    }
}
