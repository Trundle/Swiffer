import XCTest

@testable import CoreTestSuite

var tests = [XCTestCaseEntry]()
tests += CoreTestSuite.allTests()
XCTMain(tests)
