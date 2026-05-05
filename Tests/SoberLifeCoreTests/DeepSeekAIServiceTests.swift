import XCTest
import Foundation
@testable import SoberLifeCore

final class DeepSeekAIServiceTests: XCTestCase {
    func testSendReturnsParsedReply() async throws {
        let supabase = MockAISupabaseService(
            results: [
                .success([
                    "reply": "You can do this.",
                    "suggested_actions_json": #"["Breathe","Call a friend"]"#,
                    "risk_flags_json": #"["craving"]"#
                ])
            ]
        )
        let service = DeepSeekAIService(supabaseService: supabase)

        let reply = try await service.send(
            userID: UUID(),
            conversationType: .chat,
            messages: [ChatMessage(role: "user", content: "Hard moment", timestamp: Date())],
            context: AIContext(soberDays: 3)
        )

        XCTAssertEqual(reply.reply, "You can do this.")
        XCTAssertEqual(reply.suggestedActions, ["Breathe", "Call a friend"])
        XCTAssertEqual(reply.riskFlags, ["craving"])
    }

    func testSendRetriesAndSucceeds() async throws {
        let supabase = MockAISupabaseService(
            results: [
                .failure(NSError(domain: "network", code: -1)),
                .success(["reply": "Recovered on retry"])
            ]
        )
        let service = DeepSeekAIService(
            supabaseService: supabase,
            timeoutSeconds: 2,
            maxRetries: 2,
            retryBaseDelayNanoseconds: 1_000_000
        )

        let reply = try await service.send(
            userID: UUID(),
            conversationType: .sos,
            messages: [ChatMessage(role: "user", content: "Need help", timestamp: Date())],
            context: AIContext()
        )

        XCTAssertEqual(reply.reply, "Recovered on retry")
        let invocations = await supabase.invocationCount
        XCTAssertEqual(invocations, 2)
    }

    func testSendTimeoutThrows() async {
        let supabase = MockAISupabaseService(
            results: [.delaySuccess(["reply": "late"], nanoseconds: 300_000_000)]
        )
        let service = DeepSeekAIService(
            supabaseService: supabase,
            timeoutSeconds: 0.05,
            maxRetries: 0
        )

        do {
            _ = try await service.send(
                userID: UUID(),
                conversationType: .chat,
                messages: [],
                context: AIContext()
            )
            XCTFail("Expected timeout")
        } catch let error as AIServiceError {
            XCTAssertEqual(error, .timeout)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private actor MockAISupabaseService: SupabaseService {
    enum Step {
        case success([String: String])
        case failure(Error)
        case delaySuccess([String: String], nanoseconds: UInt64)
    }

    private var steps: [Step]
    private(set) var invocationCount = 0

    init(results: [Step]) {
        self.steps = results
    }

    func select(table: String, filter: [String : String]) async throws -> [[String : String]] {
        []
    }

    func insert(table: String, values: [String : String]) async throws {}

    func invoke(function: String, payload: [String : String]) async throws -> [String : String] {
        invocationCount += 1
        let step = steps.isEmpty ? .success([:]) : steps.removeFirst()
        switch step {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case let .delaySuccess(value, nanoseconds):
            try await Task.sleep(nanoseconds: nanoseconds)
            return value
        }
    }
}
