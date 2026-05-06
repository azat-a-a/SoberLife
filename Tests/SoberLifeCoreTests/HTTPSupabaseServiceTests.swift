import XCTest
import Foundation
@testable import SoberLifeCore

final class HTTPSupabaseServiceTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testInvokeBuildsFunctionURLAndDecodesBody() async throws {
        let session = makeSession()
        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: session
        )

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://project.supabase.co/functions/v1/example-fn")
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer anon-key")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = #"{"user_id":"11111111-1111-1111-1111-111111111111","access_token":"abc"}"#.data(using: .utf8)!
            return (response, body)
        }

        let payload = ["hello": "world"]
        let response = try await service.invoke(function: "example-fn", payload: payload)
        XCTAssertEqual(response["access_token"], "abc")
    }

    func testRestRPCVoidPostsToRpcEndpoint() async throws {
        let urlSession = makeSession()
        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: urlSession
        )

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://project.supabase.co/rest/v1/rpc/ensure_user_profile")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer jwt")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await service.restRPCVoid(
            function: "ensure_user_profile",
            jsonBody: Data("{}".utf8),
            bearerToken: "jwt"
        )
    }

    func testRestSelectUsesUserBearer() async throws {
        let urlSession = makeSession()
        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: urlSession
        )

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url?.absoluteString.contains("/rest/v1/ai_conversations") == true)
            XCTAssertEqual(request.value(forHTTPHeaderField: "apikey"), "anon-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer user-jwt")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = #"[]"#.data(using: .utf8)!
            return (response, body)
        }

        let data = try await service.restSelectRaw(
            table: "ai_conversations",
            queryItems: [URLQueryItem(name: "limit", value: "1")],
            bearerToken: "user-jwt"
        )
        XCTAssertEqual(String(data: data, encoding: .utf8), "[]")
    }

    func testRestUpsertMergePostsWithMergeDuplicatesPrefer() async throws {
        let urlSession = makeSession()
        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: urlSession
        )

        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.url?.absoluteString,
                "https://project.supabase.co/rest/v1/notification_preferences"
            )
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer user-jwt")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Prefer"),
                "return=minimal,resolution=merge-duplicates"
            )
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await service.restUpsertMerge(
            table: "notification_preferences",
            jsonBody: Data(#"{"user_id":"00000000-0000-0000-0000-000000000001"}"#.utf8),
            bearerToken: "user-jwt"
        )
    }

    func testInvokeNon2xxThrowsStatusError() async {
        let session = makeSession()
        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: session
        )

        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await service.invoke(function: "example-fn", payload: [:])
            XCTFail("Expected error")
        } catch let error as SupabaseHTTPServiceError {
            XCTAssertEqual(error, .httpStatus(401))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("MockURLProtocol.handler is not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
