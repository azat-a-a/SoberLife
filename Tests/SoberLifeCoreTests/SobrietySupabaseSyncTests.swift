import XCTest
import Foundation
@testable import SoberLifeCore

final class SobrietySupabaseSyncTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(SyncMockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(SyncMockURLProtocol.self)
        super.tearDown()
    }

    func testSyncOnboardingProfileInsertsWhenNoCurrentRecord() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let profile = SobrietyProfileSnapshot(
            sobrietyStartDate: start,
            dailyAlcoholCost: 12.5,
            displayName: "Quit completely"
        )

        var step = 0
        SyncMockURLProtocol.handler = { request in
            defer { step += 1 }
            let url = request.url!.absoluteString
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!

            switch step {
            case 0:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertTrue(url.contains("/rest/v1/users"))
                XCTAssertTrue(url.contains("id=eq.\(userId.uuidString)"))
                return (response, Data())
            case 1:
                XCTAssertEqual(request.httpMethod, "GET")
                XCTAssertTrue(url.contains("/rest/v1/sobriety_records"))
                XCTAssertTrue(url.contains("user_id=eq.\(userId.uuidString)"))
                XCTAssertTrue(url.contains("is_current=eq.true"))
                let body = #"[]"#.data(using: .utf8)!
                let ok = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (ok, body)
            case 2:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue(url.hasSuffix("/rest/v1/sobriety_records"))
                XCTAssertEqual(request.value(forHTTPHeaderField: "Prefer"), "return=minimal")
                let rawBody = try XCTUnwrap(Self.httpBodyData(from: request))
                let obj = try XCTUnwrap(
                    try JSONSerialization.jsonObject(with: rawBody) as? [String: Any]
                )
                XCTAssertEqual(obj["user_id"] as? String, userId.uuidString)
                XCTAssertEqual(obj["is_current"] as? Bool, true)
                XCTAssertNil(obj["end_date"] as? NSNull)
                return (response, Data())
            default:
                XCTFail("Unexpected request step \(step): \(url)")
                return (response, Data())
            }
        }

        let service = HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        )
        let sync = SobrietySupabaseSync(http: service)
        try await sync.syncOnboardingProfile(userId: userId, profile: profile, bearerToken: "jwt")
        XCTAssertEqual(step, 3)
    }

    func testSyncOnboardingProfilePatchesExistingCurrentRecord() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let recordId = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let profile = SobrietyProfileSnapshot(
            sobrietyStartDate: start,
            dailyAlcoholCost: nil,
            displayName: nil
        )

        var step = 0
        SyncMockURLProtocol.handler = { request in
            defer { step += 1 }
            let url = request.url!.absoluteString
            let empty = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!

            switch step {
            case 0:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertTrue(url.contains("/rest/v1/users"))
                return (empty, Data())
            case 1:
                XCTAssertEqual(request.httpMethod, "GET")
                let row =
                    #"[{"id":"\#(recordId.uuidString)","user_id":"\#(userId.uuidString)","start_date":"2023-01-01T00:00:00Z","end_date":null,"is_current":true}]"#
                let ok = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (ok, Data(row.utf8))
            case 2:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertTrue(url.contains("/rest/v1/sobriety_records"))
                XCTAssertTrue(url.contains("id=eq.\(recordId.uuidString)"))
                let rawBody = try XCTUnwrap(Self.httpBodyData(from: request))
                let patch = try XCTUnwrap(
                    try JSONSerialization.jsonObject(with: rawBody) as? [String: Any]
                )
                XCTAssertNotNil(patch["start_date"] as? String)
                XCTAssertEqual(patch["is_current"] as? Bool, true)
                XCTAssertNil(patch["end_date"])
                return (empty, Data())
            default:
                XCTFail("Unexpected request")
                return (empty, Data())
            }
        }

        let sync = SobrietySupabaseSync(http: HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        ))
        try await sync.syncOnboardingProfile(userId: userId, profile: profile, bearerToken: "jwt")
        XCTAssertEqual(step, 3)
    }

    func testSyncRelapseClosesCurrentInsertsNewAndPatchesUser() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let recordId = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let newStart = Date(timeIntervalSince1970: 1_710_000_000)
        let occurred = Date(timeIntervalSince1970: 1_710_008_640)

        let profile = SobrietyProfileSnapshot(
            sobrietyStartDate: newStart,
            dailyAlcoholCost: 9,
            displayName: "Reduce drinking"
        )

        var step = 0
        SyncMockURLProtocol.handler = { request in
            defer { step += 1 }
            let url = request.url!.absoluteString
            let empty = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!

            switch step {
            case 0:
                XCTAssertEqual(request.httpMethod, "GET")
                XCTAssertTrue(url.contains("sobriety_records"))
                let row =
                    #"[{"id":"\#(recordId.uuidString)","user_id":"\#(userId.uuidString)","start_date":"2023-06-01T00:00:00Z","end_date":null,"is_current":true}]"#
                let ok = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (ok, Data(row.utf8))
            case 1:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertTrue(url.contains("sobriety_records"))
                XCTAssertTrue(url.contains("id=eq.\(recordId.uuidString)"))
                let rawBody = try XCTUnwrap(Self.httpBodyData(from: request))
                let patch = try XCTUnwrap(
                    try JSONSerialization.jsonObject(with: rawBody) as? [String: Any]
                )
                XCTAssertNotNil(patch["end_date"] as? String)
                XCTAssertEqual(patch["is_current"] as? Bool, false)
                return (empty, Data())
            case 2:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertTrue(url.hasSuffix("/rest/v1/sobriety_records"))
                return (empty, Data())
            case 3:
                XCTAssertEqual(request.httpMethod, "PATCH")
                XCTAssertTrue(url.contains("/rest/v1/users"))
                XCTAssertTrue(url.contains("id=eq.\(userId.uuidString)"))
                return (empty, Data())
            default:
                XCTFail("Unexpected request")
                return (empty, Data())
            }
        }

        let sync = SobrietySupabaseSync(http: HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        ))
        try await sync.syncRelapse(
            userId: userId,
            profileAfterRelapse: profile,
            newPeriodStart: newStart,
            occurredAt: occurred,
            bearerToken: "jwt"
        )
        XCTAssertEqual(step, 4)
    }

    func testFetchHistorySnapshotMapsClosedRecordsToRelapseEvents() async throws {
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        SyncMockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertTrue(request.url!.absoluteString.contains("/rest/v1/sobriety_records"))
            let body =
                #"[{"id":"10000000-0000-0000-0000-000000000001","user_id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","start_date":"2024-01-01T00:00:00Z","end_date":"2024-01-10T00:00:00Z","is_current":false},{"id":"10000000-0000-0000-0000-000000000002","user_id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","start_date":"2024-01-11T00:00:00Z","end_date":null,"is_current":true}]"#
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(body.utf8))
        }

        let sync = SobrietySupabaseSync(http: HTTPSupabaseService(
            baseURL: URL(string: "https://project.supabase.co")!,
            anonKey: "anon-key",
            session: makeSession()
        ))
        let snapshot = try await sync.fetchHistorySnapshot(userId: userId, bearerToken: "jwt")
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.relapseEvents.count, 1)
        XCTAssertEqual(snapshot?.relapseEvents.first?.streakAtRelapseDays, 10)
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SyncMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// `URLRequest.httpBody` is often nil under `URLProtocol`; the bytes may only be on `httpBodyStream`.
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

private final class SyncMockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("SyncMockURLProtocol.handler is not set")
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
