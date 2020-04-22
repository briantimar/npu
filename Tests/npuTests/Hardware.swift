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
    

    
    func testBuffer() throws {
        let size = 2
        let buf = Buffer(size:size)
        XCTAssertTrue(buf.isEmpty)
        buf.set(to: [2.0, 4.0])
        
        let data:[Float] = buf.get()!
        XCTAssertTrue(buf.isEmpty)
        XCTAssertEqual(data[0], 2.0)
        XCTAssertEqual(data[1], 4.0)
                       
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

//    func testMACArray() throws {
//        let size = 2
//        let inputA = MatrixBuffer(numChannels: size, length: 2)
//        let inputB = MatrixBuffer(numChannels: size, length: 2)
//        let mac = try! MACArray(size:size, inputA: inputA, inputB: inputB)
//        let accs = mac.accArray()
//        for row in accs {
//            for el in row {
//                AssertClose(el, 0)
//            }
//        }
//    }
    
    func testVectorFeed() throws {
    
        let vals:Array<Float> = [1.0, 2.0, 3.0]
        let feed = VectorFeed(vals: vals)
        XCTAssertFalse(feed.finished)
    
        for i in 0..<feed.length {
            feed.emit()
            XCTAssertEqual(feed.outputBuffers![0].get(), [vals[i]])
        }
        XCTAssertTrue(feed.finished)
        
    }
    
//    func testMatrixBuf() throws {
//        let numChannels = 2
//        let length = 2
//        let mb = MatrixBuffer(numChannels: numChannels, length: length)
//
//        let initData = Matrix(rowdata: [[2.0, 4.0], [-1.0, 0.0]])
//
//        mb.loadFrom(matrix: initData)
//        XCTAssertEqual(mb.getOutput(at: 0), [dataType(2.0)])
//        XCTAssertEqual(mb.getOutput(at: 1), [dataType(4.0)])
//        mb.advance(at: 0)
//        XCTAssertEqual(mb.getOutput(at: 0), [dataType(-1.0)])
//        XCTAssertEqual(mb.getOutput(at: 1), [dataType(4.0)])
//
//        XCTAssertEqual(mb.remaining(at: 0), 1)
//        XCTAssertEqual(mb.remaining(at: 1), 2)
//    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
