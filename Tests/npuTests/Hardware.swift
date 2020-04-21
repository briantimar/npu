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
        let inputA = MatrixBuffer(numChannels: size, length: 2)
        let inputB = MatrixBuffer(numChannels: size, length: 2)
        let mac = try! MACArray(size:size, inputA: inputA, inputB: inputB)
        let accs = mac.accArray()
        for row in accs {
            for el in row {
                AssertClose(el, 0)
            }
        }
    }
    
    func testVectorBuf() throws {
        let length = 3
        let buf = VectorBuf(length: length)
        let vals:Array<Float> = [1.0, 2.0, 3.0]
        var out: Float
        buf.setInput(to:vals)
        for i in 0..<3 {
            out = buf.getOutput()[0]
            AssertClose(out, vals[i])
            buf.tick()
            buf.tock()
        }
        XCTAssertTrue(buf.isEmpty())
        
    }
    
    func testMatrixBuf() throws {
        let numChannels = 2
        let length = 2
        let mb = MatrixBuffer(numChannels: numChannels, length: length)
        
        let initData = Matrix(rowdata: [[2.0, 4.0], [-1.0, 0.0]])
        
        mb.loadFrom(matrix: initData)
        XCTAssertEqual(mb.getOutput(at: 0), [dataType(2.0)])
        XCTAssertEqual(mb.getOutput(at: 1), [dataType(4.0)])
        mb.advance(at: 0)
        XCTAssertEqual(mb.getOutput(at: 0), [dataType(-1.0)])
        XCTAssertEqual(mb.getOutput(at: 1), [dataType(4.0)])
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
