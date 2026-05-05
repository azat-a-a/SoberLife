import Foundation

public struct AppleSignInToken: Sendable, Equatable {
    public let idToken: String
    public let nonce: String?

    public init(idToken: String, nonce: String?) {
        self.idToken = idToken
        self.nonce = nonce
    }
}

public protocol AppleSignInTokenProvider: Sendable {
    func requestToken() async throws -> AppleSignInToken
}

public actor PlaceholderAppleSignInTokenProvider: AppleSignInTokenProvider {
    private let token: AppleSignInToken
    private let shouldFail: Bool

    public init(token: AppleSignInToken = AppleSignInToken(idToken: "placeholder-apple-id-token", nonce: nil), shouldFail: Bool = false) {
        self.token = token
        self.shouldFail = shouldFail
    }

    public func requestToken() async throws -> AppleSignInToken {
        if shouldFail {
            throw NSError(domain: "PlaceholderAppleSignInTokenProvider", code: 1)
        }
        return token
    }
}
