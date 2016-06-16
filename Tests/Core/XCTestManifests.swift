import XCTest

#if !os(OSX)
    public func allTests() -> [XCTestCaseEntry] {
     return [
         testCase(TokenizerTests.allTests),
     ]
 }
#endif
