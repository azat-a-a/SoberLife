import XCTest
@testable import SoberLifeCore

final class SupabaseJWTTests: XCTestCase {
    func testDetectsPlaceholder() {
        XCTAssertFalse(SupabaseJWT.isLikelyUserAccessToken("placeholder-token"))
        XCTAssertFalse(SupabaseJWT.isLikelyUserAccessToken("not-a-jwt"))
        XCTAssertTrue(SupabaseJWT.isLikelyUserAccessToken("aaa.bbb.ccc"))
    }
}
