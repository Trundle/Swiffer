import XCTest

import Core

class TokenizerTests: XCTestCase {
    func testString() {
        let tokens = tokenize("\"some string\"")
        XCTAssertEqual([Token.StringLiteral("some string")], tokens)
    }

    func testSingleLineComment() {
        let comment = "/// Some comment"
        // XXX make it also work with EOF instead of EOL
        let tokens = tokenize(comment + "\n")
        XCTAssertEqual([Token.Comment(comment)], tokens)
    }

    func testSimpleComment() {
        let comment = "/* Some comment */"
        let tokens = tokenize(comment)
        XCTAssertEqual([Token.Comment(comment)], tokens)
    }

    func testNestedComment() {
        let comment = "/* Some /* nested */ comment */"
        let tokens = tokenize(comment)
        XCTAssertEqual([Token.Comment(comment)], tokens)
    }

    func testNestedComment2() {
        let comment = "/*p1/*p2/*p3t3*/t2*/t1*/"
        let tokens = tokenize(comment)
        XCTAssertEqual([Token.Comment(comment)], tokens)
    }

    func testNestedComment3() {
        let comment = "/* Beginning /* nested */ /* nested 2 */*/"
        let tokens = tokenize(comment)
        XCTAssertEqual([Token.Comment(comment)], tokens)
    }

    static var allTests: [(String, (TokenizerTests) -> () throws -> Void)] = [
        ("testNestedComment", testNestedComment),
        ("testNestedComment2", testNestedComment2),
        ("testNestedComment3", testNestedComment3),
        ("testSingleLineComment", testSingleLineComment),
        ("testString", testString),
    ]
}
