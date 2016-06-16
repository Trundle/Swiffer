import XCTest

import Core

class TokenizerTests: XCTestCase {
    func testAlwaysTrue() {
        XCTAssertTrue(true)
    }

    static var allTests: [(String, (TokenizerTests) -> () throws -> Void)] = [
        ("testAlwaysTrue", testAlwaysTrue),
    ]
}
