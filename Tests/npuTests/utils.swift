//
//  utils.swift
//  npuTests
//
//  Created by Brian Timar on 4/21/20.
//

import XCTest
@testable import npu

class utils: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMatrix() throws {
        let rows = 2
        let cols = 2
        var m = Matrix(rows:rows, cols: cols)
        for i in 0..<rows {
            for j in 0..<cols {
                XCTAssertEqual(m[i,j], 0.0)
            }
        }
        m[0, 1] = 2.0
        XCTAssertEqual(m[0,1], 2.0)
    }

    func testMatrixInit() throws {
        let row1: [Float] = [2.0, 3.0]
        let row2: [Float] = [4.0, 5.0]
        let m = Matrix(rowdata: [row1, row2])
        XCTAssertEqual(m[0,1], 3.0)
        XCTAssertEqual(m[1,0],4.0)
    }
    
    func testMatrixSlice() throws {
       let row1: [Float] = [2.0, 3.0]
       let row2: [Float] = [4.0, 5.0]
       let m = Matrix(rowdata: [row1, row2])
       let r1 = m[0..<2, 1]
        XCTAssertEqual(r1.count, 2)
        XCTAssertEqual(r1[0], 3.0)
        XCTAssertEqual(r1[1], 5.0)
        
        let r2 = m[0, 1..<2]
        XCTAssertEqual(r2.count, 1)
        XCTAssertEqual(r2[0], 3.0)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
