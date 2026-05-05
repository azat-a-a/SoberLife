import XCTest
import Foundation
@testable import SoberLifeCore

final class AIConversationRESTMapperTests: XCTestCase {
    func testRoundTripMessages() {
        let original = [
            ChatMessage(role: "user", content: "Hi", timestamp: Date(timeIntervalSince1970: 1_700_000_000)),
            ChatMessage(role: "assistant", content: "Hello", timestamp: Date(timeIntervalSince1970: 1_700_000_600))
        ]
        let lines = AIConversationRESTMapper.encodeLines(original)
        let back = AIConversationRESTMapper.decodeLines(lines)
        XCTAssertEqual(back.count, 2)
        XCTAssertEqual(back[0].role, "user")
        XCTAssertEqual(back[0].content, "Hi")
        XCTAssertEqual(back[1].role, "assistant")
        XCTAssertEqual(back[1].content, "Hello")
    }
}
