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

    
    func testVectorFeed() throws {
    
        let vals:Array<Float> = [1.0, 2.0, 3.0]
        let feed = VectorFeed(vals: vals)
        XCTAssertFalse(feed.finished)
    
        for i in 0..<feed.length {
            feed.emit()
            XCTAssertEqual(feed.outputBuffers![0].get(), [vals[i]])
        }
        XCTAssertTrue(feed.finished)
        feed.emit()
        XCTAssertEqual(feed.outputBuffers![0].get(), nil)
        
        feed.loadFrom(array: [5.0])
        XCTAssertFalse(feed.finished)
    }
    func testLoadVectorFeeds() throws {
        let m = Matrix(rowdata: [[2.0, 3.0], [4.0, 5.0]])
        let feeds = [VectorFeed(), VectorFeed()]
        XCTAssertTrue(feeds[0].finished)
        loadVectorFeeds(from: m, to: feeds)
        XCTAssertEqual(feeds[0].length, 2)
        XCTAssertFalse(feeds[0].finished)
        for i in 0..<2 {
            feeds[0].emit()
            XCTAssertEqual(feeds[0].outputBuffers![0].get(), [m[i,0]])
        }
    }

    func testMA() throws {
        let feed1 = VectorFeed(vals: [1.0, 2.0])
        let feed2 = VectorFeed(vals: [2.0, 3.0])
        let ma = MA(inputs: [feed1.outputBuffers![0], feed2.outputBuffers![0]])
        XCTAssertEqual(ma.acc, 0.0)
        feed1.emit()
        feed2.emit()
        ma.consume()
        XCTAssertEqual(ma.acc, 2.0)
        
        feed1.emit()
        feed2.emit()
        ma.consume()
        XCTAssertEqual(ma.acc, 8.0)
        
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

    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
