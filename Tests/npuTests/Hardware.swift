//
//  Hardware.swift
//  npuTests
//
//  Created by Brian Timar on 4/20/20.
//

import XCTest
@testable import npu

class Hardware: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testWordInit() {
        let vals: Array<Int8> = [4, -1]
        let w = ByteWord(vals: vals)
        XCTAssertEqual(w.size, vals.count)
        XCTAssertEqual(w.vals, vals)
    }
    
    func testWordSet() {
        let size = 4;
        var w = ByteWord(size: size);
        XCTAssertThrowsError(try w.set(vals: [1, 2]))
        
        try! w.set(vals: [1, 2, 3, 4])
        XCTAssertEqual(w.byte(at: 0), 1)
    }

    func testRegister() throws {
        let size = 4
        let reg = Register(size: size)
        let vals: Array<Int8> = [1, 2, 3, 4]
        var word = ByteWord(size: size)
        try! word.set(vals:vals)
        reg.setInput(input: word)
        XCTAssertEqual(word.vals, reg.getOutput().vals)
    }
    
    func testChannel() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let r1 = Register(vals: [2, 3])
        let r2 = Register(vals: [4, 0])
        var c = try! Channel(size: 2, inputCell: r1, outputCell: r2)
        c.tick()
        
        XCTAssertEqual(r1.vals, [2, 3])
        XCTAssertEqual(r2.vals, [2, 3])
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
