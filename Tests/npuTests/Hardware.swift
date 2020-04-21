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
    
  
    func AssertClose(_ x1:Float, _ x2:Float, eps:Float=1e-6) {
        XCTAssertLessThan(abs(x1 - x2), eps)
    }
    
    func testRegister() throws {
        let size = 4
        let reg = Register(size: size)
        let vals: Array<Float> = [1, 2, 3, 4]
        reg.setInput(to: vals)
        XCTAssertEqual(vals, reg.getOutput())
    }
    
    func testChannel() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let r1 = Register(vals: [2.0, 3.0])
        let r2 = Register(vals: [4.0, 0.0])
        var c = try! Channel(size: 2, inputCell: r1, outputCell: r2)
        c.tick()

        XCTAssertEqual(r1.vals, [2, 3])
        XCTAssertEqual(r2.vals, [2, 3])
    }
    
    func testMA() throws {
        let ma = MA()
        ma.setInput(to: [2.0, 3.0])
        ma.tick()
        ma.tock()
        AssertClose(ma.getOutput()[0], 6.0)
        ma.setInput(to: [1.0, 5.0])
        ma.tick()
        ma.tock()
        AssertClose(ma.getOutput()[0], 11.0)
        ma.reset()
        AssertClose(ma.getOutput()[0], 0.0)
    }

    func testMACArray() throws {
        let size = 2
        let mac = MACArray(size:size)
        let accs = mac.accArray()
        for row in accs {
            for el in row {
                AssertClose(el, 0)
            }
        }
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
