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
        
        for i in 0..<feed.length {
            feed.outputBuffer.openRequest()
            feed.emit()
            XCTAssertEqual(feed.outputBuffer.get(), [vals[i]])
        }
        
        feed.emit()
        XCTAssertEqual(feed.outputBuffer.get(), nil)
    }
    func testLoadVectorFeeds() throws {
        let m = Matrix(rowdata: [[2.0, 3.0], [4.0, 5.0]])
        let feeds = [VectorFeed(), VectorFeed()]
        
        loadVectorFeeds(from: m, to: feeds, by: "columns")
        XCTAssertEqual(feeds[0].length, 2)
        XCTAssertFalse(feeds[0].isEmpty)
        for i in 0..<2 {
            feeds[0].outputBuffer.openRequest()
            feeds[0].emit()
            XCTAssertEqual(feeds[0].outputBuffer.get(), [m[i,0]])
        }
    }

    func testMA() throws {
        let feed1 = VectorFeed(vals: [1.0, 2.0])
        let feed2 = VectorFeed(vals: [2.0, 3.0])
        let ma = MA(leftInput: feed1.outputBuffer, topInput: feed2.outputBuffer, numAcc: feed1.length)
        ma.consume()
        feed1.emit()
        feed2.emit()
        
        XCTAssertEqual(ma.acc, 0.0)
        ma.consume()
        feed1.emit()
        feed2.emit()
        XCTAssertEqual(ma.acc, 2.0)
        ma.consume()
        feed1.emit()
        feed2.emit()
        XCTAssertEqual(ma.acc, 8.0)
        
    }
    

    func testMACArrayBuild() throws {
        let leftFeeds = [VectorFeed(vals:[1.0]), VectorFeed(vals:[2.0])]
        let topFeeds = [VectorFeed(vals:[3.0]), VectorFeed(vals: [4.0])]
        let mac = MACArray(leftFeeds: leftFeeds, topFeeds: topFeeds)
        XCTAssertEqual(mac.rows, leftFeeds.count)
        XCTAssertEqual(mac.cols, topFeeds.count)
        
        var maCt = 0
        var feedCt = 0
        for cell in mac {
            if cell is MA {
                maCt += 1
            }
            else if cell is VectorFeed {
                feedCt += 1
            }
        }
        XCTAssertEqual(maCt, mac.rows * mac.cols)
        XCTAssertEqual(feedCt, mac.rows + mac.cols)
    }
    
    func testMACRun() throws {
        let leftFeeds = [VectorFeed(vals:[1.0], label:"lf0"), VectorFeed(vals:[2.0], label:"lf1")]
        let topFeeds = [VectorFeed(vals:[3.0], label: "tf0"), VectorFeed(vals: [4.0], label:"tf1")]
        let mac = MACArray(leftFeeds: leftFeeds, topFeeds: topFeeds)
        let numSteps = 1
        mac.runMADriven(numsteps: numSteps)
        let res = mac.accMatrix()
        XCTAssertEqual(res[0, 0], 3.0)
        XCTAssertEqual(res[0,1], 4.0)
        XCTAssertEqual(res[1,0], 6.0)
        XCTAssertEqual(res[1, 1], 8.0)
    }

    
    func testMACMatMul() throws {
        let leftMat = Matrix(rowdata: [[1.0, 3.0, 4.0], [-5.0, 0.0, 2.0]])
        let topMat = Matrix(rowdata: [[2.0, 2.0], [-3.0, 2.0], [0.0, 4.0]])
        
        let mac = MACArray(rows: leftMat.rows, cols: topMat.cols)
        assert(mac.leftFeeds.count == leftMat.rows )
        assert(mac.topFeeds.count == topMat.cols)
        let prod = mac.matMul(leftMat: leftMat, topMat: topMat)
        let target = leftMat * topMat
        AssertClose((target-prod).l2norm(), 0.0)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
