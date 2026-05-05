#if os(iOS)
import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

@MainActor
public final class LiveAppleSignInTokenProvider: NSObject, AppleSignInTokenProvider {
    private let presentationAnchorProvider: @MainActor () -> ASPresentationAnchor
    private var continuation: CheckedContinuation<AppleSignInToken, Error>?
    private var currentNonce: String?

    public init(presentationAnchorProvider: @escaping @MainActor () -> ASPresentationAnchor) {
        self.presentationAnchorProvider = presentationAnchorProvider
    }

    public func requestToken() async throws -> AppleSignInToken {
        let nonce = Self.randomNonce(length: 32)
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remaining > 0 && random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
extension LiveAppleSignInTokenProvider: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer {
            continuation = nil
            currentNonce = nil
        }

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            continuation?.resume(throwing: NSError(domain: "LiveAppleSignInTokenProvider", code: 2))
            return
        }

        continuation?.resume(returning: AppleSignInToken(idToken: idToken, nonce: currentNonce))
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer {
            continuation = nil
            currentNonce = nil
        }
        continuation?.resume(throwing: error)
    }
}

@MainActor
extension LiveAppleSignInTokenProvider: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchorProvider()
    }
}
#endif
