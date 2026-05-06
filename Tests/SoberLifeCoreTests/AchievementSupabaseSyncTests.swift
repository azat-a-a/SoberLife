import XCTest
import Foundation
@testable import SoberLifeCore

final class AchievementSupabaseSyncTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(AchievementMockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(AchievementMockURLProtocol.self)
        super.tearDown()
    }

    func testFetchUnlockedMilestoneDaysParsesMilestonePrefix() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        AchievementMockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url!.absoluteString.contains("/rest/v1/achievements"))
            let body = #"[{"type":"milestone_7"},{"type":"milestone_30"},{"type":"other"}]"#
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }

        let sync = AchievementSupabaseSync(http: HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        ))
        let days = try await sync.fetchUnlockedMilestoneDays(userId: userId, bearerToken: "jwt")
        XCTAssertEqual(days, Set([7, 30]))
    }

    func testUpsertMilestoneUsesMergeDuplicates() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        AchievementMockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url!.absoluteString.hasSuffix("/rest/v1/achievements"))
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Prefer"),
                "return=minimal,resolution=merge-duplicates"
            )
            let raw = try XCTUnwrap(Self.httpBodyData(from: request))
            let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: raw) as? [String: Any])
            XCTAssertEqual(obj["user_id"] as? String, userId.uuidString)
            XCTAssertEqual(obj["type"] as? String, "milestone_7")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let sync = AchievementSupabaseSync(http: HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        ))
        try await sync.upsertMilestone(userId: userId, milestoneDays: 7, bearerToken: "jwt")
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AchievementMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func httpBodyData(from request: URLRequest) -> Data? {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var out = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                out.append(buffer, count: read)
            } else if read < 0 {
                return nil
            } else {
                break
            }
        }
        return out
    }
}

private final class AchievementMockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("AchievementMockURLProtocol.handler is not set")
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
