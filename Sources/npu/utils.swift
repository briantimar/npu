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
    
    // slices will return new arrays
    // right now sharing memory is a hassle with the row-based format
    
    // TODO these could be merged...
    
    /// slice part of a column from the matrix
    subscript(r: Range<Int>, c: Int) -> [dataType] {
        get {
            var colslice = [dataType]()
            for ir in r {
                colslice.append(data[ir][c])
            }
            return colslice
        }
    }
    
    /// slice part of a row from the matrix
    subscript(r: Int, c:Range<Int>) -> [dataType] {
        get {
            var rowslice = [dataType]()
            for ic in c {
                rowslice.append(data[r][ic])
            }
            return rowslice
        }
    }
}

/// Iterator over the elements in a Matrix

extension Matrix {
    struct MatrixIterator : Sequence, IteratorProtocol {
        let rowdata: [[dataType]]
        var ct:Int = 0
        var rows: Int
        var cols: Int
        
        init(rows:Int, cols:Int, rowdata: [[dataType]]){
            self.rows = rows
            self.cols = cols
            self.rowdata = rowdata
        }
        mutating func makeIterator() -> Matrix.MatrixIterator {
            ct = 0
            return self
        }
        mutating func next() -> dataType? {
            guard ct < rows * cols else{
                return nil
            }
            defer {
                ct += 1
            }
            return rowdata[ct / cols][ct % cols]
        }
    }
    
    /// Returns a sequence holding all elements of the array
    var elements: MatrixIterator {
        return MatrixIterator(rows: rows, cols: cols, rowdata: data)
    }
    
    /// Returns new matrix with the given function applied pointwise
    func map(_ f:(dataType)->dataType) -> Matrix {
        var mapped = Matrix(rows:rows, cols:cols)
        for i in 0..<rows {
            for j in 0..<cols {
                mapped[i,j] = f(self[i,j])
            }
        }
        return mapped
    }
    
    /// sum of all array elements
    func sum() -> dataType {
        var ct:dataType = 0
        for el in elements {
            ct += el
        }
        return ct
    }
    
    func l2norm() -> dataType {
        return self.map({x in x*x}).sum()
    }
}


extension Matrix {
    static func + (m1 : Matrix, m2: Matrix) -> Matrix {
        assert(m1.rows == m2.rows && m1.cols == m2.cols, "matrix dimensions must agree")
        var sum = Matrix(rows:m1.rows, cols: m1.cols)
        for i in 0..<m1.rows {
            for j in 0..<m2.cols {
                sum[i,j] = m1[i,j] + m2[i,j]
            }
        }
        return sum
    }
    
    static func - (m1 : Matrix, m2: Matrix) -> Matrix {
        assert(m1.rows == m2.rows && m1.cols == m2.cols, "matrix dimensions must agree")
        var sum = Matrix(rows:m1.rows, cols: m1.cols)
        for i in 0..<m1.rows {
            for j in 0..<m2.cols {
                sum[i,j] = m1[i,j] - m2[i,j]
            }
        }
        return sum
    }
    
    
}
