//
//  Word.swift
//  npuTests
//
//  Created by Brian Timar on 4/18/20.
//

import XCTest
@testable import npu

class Word: XCTestCase {
    

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSize() {
        
        let size = 4
        let w = ByteWord(size: size)
        XCTAssertEqual(size, w.size)
        
    }

    func testSet() {
        let size = 4;
        var w = ByteWord(size: size);
        XCTAssertThrowsError(try w.set(vals: [1, 2]))
        
        try! w.set(vals: [1, 2, 3, 4])
        XCTAssertEqual(w.byte(at: 0), 1)
    }
    

    
    

}
