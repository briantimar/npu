//
//  Created by Brian Timar on 4/21/20.
//

import Foundation

struct Matrix {
    let rows: Int
    let cols: Int
    var data: [[dataType]]
    
    init(rows: Int, cols:Int) {
        self.rows = rows
        self.cols = cols
        data = Array<Array<dataType>>(repeating: Array<dataType>(repeating: 0, count: cols),
                                      count: rows)
    }
    
    /** initialize a matrix from an array of rows*/
    init(rowdata: [[dataType]]) {
        assert(rowdata.count > 0, "must provide nonempty row array")
        rows = rowdata.count
        for r in rowdata {
            assert(r.count == rowdata[0].count, "nonuniform array data")
        }
        cols = rowdata[0].count
        data = rowdata
        
    }
    
    subscript(r: Int, c: Int) -> dataType {
        get {
            return data[r][c]
        }
        set(newVal) {
            data[r][c] = newVal
        }
    }
}
