import XCTest
import Foundation
@testable import SoberLifeAppShell

@MainActor
final class SessionStateFactoryTests: XCTestCase {
    func testPlaceholderFactoryCreatesSignedOutState() {
        let wiring = AuthWiring(
            supabaseURL: URL(string: "https://project.supabase.co")!,
            supabaseAnonKey: "anon-key"
        )

        let sessionState = SessionStateFactory.makePlaceholderSessionState(wiring: wiring)

        XCTAssertEqual(sessionState.authState, .signedOut)
        XCTAssertNil(sessionState.authErrorMessage)
    }
}
