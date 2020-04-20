import XCTest

import npuTests

var tests = [XCTestCaseEntry]()
tests += npuTests.allTests()
XCTMain(tests)
