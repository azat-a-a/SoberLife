import XCTest
import Foundation
import SoberLifeCore
@testable import SoberLifeAppShell

@MainActor
final class SessionStateTests: XCTestCase {
    func testSessionStartsSignedOutByDefault() {
        let session = SessionState(authService: MockAuthService())
        XCTAssertEqual(session.authState, .signedOut)
    }

    func testSignInChangesState() async {
        let userID = UUID()
        let session = SessionState(
            authService: MockAuthService(signInUserID: userID)
        )

        await session.signIn(email: "a@b.co", password: "secret")

        XCTAssertEqual(session.authState, .signedIn(userID: userID))
        XCTAssertNil(session.authErrorMessage)
    }

    func testSignOutReturnsToSignedOut() async {
        let session = SessionState(
            authService: MockAuthService(signInUserID: UUID()),
            authState: .signedIn(userID: UUID())
        )

        await session.signOut()

        XCTAssertEqual(session.authState, .signedOut)
    }

    func testSignInFailureSetsErrorMessage() async {
        let session = SessionState(
            authService: MockAuthService(shouldFailSignIn: true)
        )

        await session.signIn(email: "a@b.co", password: "secret")

        XCTAssertEqual(session.authState, .signedOut)
        XCTAssertEqual(session.authErrorMessage, "Incorrect email or password.")
    }

    func testRestoreSessionUsesCurrentSession() async {
        let userID = UUID()
        let session = SessionState(
            authService: MockAuthService(storedSession: UserSession(userID: userID, accessToken: "x"))
        )

        await session.restoreSession()

        XCTAssertEqual(session.authState, .signedIn(userID: userID))
    }

    func testAccessTokenAfterSignIn() async {
        let session = SessionState(
            authService: MockAuthService(signInUserID: UUID())
        )
        await session.signIn(email: "a@b.co", password: "secret")
        let token = await session.accessTokenIfAvailable()
        XCTAssertEqual(token, "token")
    }

    func testHandleUnauthorizedSessionSignsOutAndSetsMessage() async {
        let userID = UUID()
        let session = SessionState(
            authService: MockAuthService(storedSession: UserSession(userID: userID, accessToken: "token")),
            authState: .signedIn(userID: userID)
        )

        await session.handleUnauthorizedSession()

        XCTAssertEqual(session.authState, .signedOut)
        XCTAssertEqual(session.authErrorMessage, EmpathyCopy.sessionExpiredNeedsSignIn)
        let token = await session.accessTokenIfAvailable()
        XCTAssertNil(token)
    }

    func testSignUpShowsConfirmationCopyWhenBackendRequiresEmailVerify() async {
        let session = SessionState(
            authService: MockAuthService(signUpError: .emailNotConfirmed)
        )

        await session.signUp(email: "a@b.co", password: "secret")

        XCTAssertEqual(session.authState, .signedOut)
        XCTAssertEqual(session.authErrorMessage, EmpathyCopy.emailConfirmationRequired)
    }
}

private actor MockAuthService: AuthService {
    private let signInUserID: UUID
    private let shouldFailSignIn: Bool
    private let signUpError: AuthServiceError?
    private var session: UserSession?

    init(
        signInUserID: UUID = UUID(),
        shouldFailSignIn: Bool = false,
        signUpError: AuthServiceError? = nil,
        storedSession: UserSession? = nil
    ) {
        self.signInUserID = signInUserID
        self.shouldFailSignIn = shouldFailSignIn
        self.signUpError = signUpError
        self.session = storedSession
    }

    func signIn(email: String, password: String) async throws -> UserSession {
        if shouldFailSignIn {
            throw AuthServiceError.invalidCredentials
        }
        let newSession = UserSession(userID: signInUserID, accessToken: "token")
        session = newSession
        return newSession
    }

    func signUp(email: String, password: String) async throws -> UserSession {
        if let signUpError {
            throw signUpError
        }
        return try await signIn(email: email, password: password)
    }

    func signOut() async throws {
        session = nil
    }

    func currentSession() async throws -> UserSession? {
        session
    }
}
