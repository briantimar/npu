/// Anything which provides a master clock signal
protocol Clock {
    // Time on the global clock
    var time: Float { get set }

    // half-cycles for the clock
    // sets internal state for the 'up' cycle
    func tick()
//    actions for the 'down' cycle
    func tock()
}

enum HardwareError: Error {
    case invalidSize
}

typealias dataType = Float

/// Elements which respond to a clock signal
protocol Clocked: AnyObject {
    func tick()
    func tock()
}

func step(_ element: Clocked) {
    element.tick()
    element.tock()
}

/* A computational unit - for example, a memory cell or a multiply-acc cell.
    Generally, has inputs, outputs, and an internal state.
    */
protocol Cell : AnyObject {
    /// the cell consumes from these buffers
    var inputBuffers: [Buffer]? { get }
    /// the cell emits into these buffers
    var outputBuffers: [Buffer]? { get }
    /// draw from the input buffers
    func consume()
    /// emit into the output buffers
    func emit()
    /// Indicates whether the cell's computation has terminated
    var finished: Bool { get }
}

/** A vector-valued float buffer
    Currently, stores just a single value!*/
class Buffer {
    
    let size: Int
    var val: Array<dataType>? = nil
    var hasRequest: Bool = false
    
    init(size: Int) {
        self.size = size
    }
    
    init(array: Array<dataType>) {
        size = array.count
        val = array
    }
    
    /// store a new value in the buffer
    func set(to newval: Array<dataType>?){
        assert(newval == nil || newval!.count == size, "invalid input to buffer of size \(size)")
        val = newval
    }
    
    /// draws the buffer value, if it exists
    func get() -> Array<dataType>? {
        let data = val
        val = nil
        return data
    }
    
    /// check whether the buffer is empty
    var isEmpty : Bool {
        val == nil
    }
    /// Request that this buffer be filled
    func openRequest() {
        hasRequest = true
    }
    /// Close any request
    func closeRequest() {
        hasRequest = false
    }
 
}


class GlobalClock : Clock {
    var time: Float = 0
    func tick() {
        time += 0.5
    }
    func tock() {
        time += 0.5
    }
}

/// A cell wrapper around a piece of RAM; cannot be exhausted
class RAM : Cell  {
    let size: Int
    var vals: Array<dataType>
    // register does not consume input
    var inputBuffers:[Buffer]? = nil
    var outputBuffers: [Buffer]?
    
    init(vals: Array<dataType>) {
        self.size = vals.count
        self.vals = vals
        outputBuffers = [Buffer(array: vals)]
    }
    
    init( size: Int) {
        self.size = size
        self.vals = Array<dataType>(repeating: 0.0, count: size)
    }

    func consume() {}
    
    func emit() {}
    
    /// A RAM buffer cannot be exhausted
    var finished: Bool { false }
}

/// A buffer which holds a single vector of data; used to feed a MACArray
class VectorFeed : Cell {
    
    var vals: Array<dataType>
    
    var inputBuffers: [Buffer]? = nil
    var outputBuffers: [Buffer]? = [Buffer(size: 1)]
    /** A convention - vectorfeed never demands computation*/
    let finished: Bool = true
   
    /// index of the next item to be served
    private var current: Int = 0
    
    init(){
        vals = [dataType]()
    }
    
    init(vals: Array<dataType>){
        self.vals = vals
    }
    
    var length: Int {
        vals.count
    }
    var outputBuffer: Buffer {
        outputBuffers![0]
    }
    
    func currentValue() -> Array<dataType>? {
        if current >= length {
            return nil
        }
        else {
        return [vals[current]]
        }
    }
    
    func loadFrom(array: [dataType]) {
        self.vals = array
        current = 0
    }
    
    /** A feed element is just a source, has nothing to consume */
    func consume() {}
    
    /** Shifts the vector buffer down by one, exposing the next element*/
    func advance() {
        if current < length {
                   current += 1
               }
    }
    
    /** The feed emits the next element, if requested and possible*/
    func emit() {
        if outputBuffer.hasRequest && !isEmpty {
            outputBuffer.set(to: currentValue())
            advance()
            outputBuffer.closeRequest()
        }
    }
    
    /// Returns the number of elements remaining in the buffer
    var remaining: Int {
        return length - current
    }
    
    var isEmpty: Bool {
        return current >= length
    }
    

}

/// Loads matrix data into a collection of vector feeds
/// each feed corresponds to one column
func loadVectorFeeds(from mat: Matrix, to feeds:[VectorFeed]) {
    assert(mat.cols == feeds.count, "number of feeds does not match number of cols")
    for i in 0..<mat.cols {
        feeds[i].loadFrom(array: mat[0..<mat.rows, i])
    }
}

/* Performs a  multiply-add.
 At each timestep, two inputs are multiplied, added to the register, then rounded and stored.*/
class MA : Cell{

    var acc: Float  = 0
    var inputBuffers: [Buffer]?
    var outputBuffers: [Buffer]? = [Buffer(size: 1), Buffer(size:1)]
    
    init(leftInput: Buffer, topInput: Buffer) {
        inputBuffers = [leftInput, topInput]
    }
    
    private func bothInputsReady() -> Bool {
        !(inputBuffers![0].isEmpty || inputBuffers![1].isEmpty )
    }

    func consume() {
        if bothInputsReady() {
            let inp1 = inputBuffers![0].get()!
            let inp2 = inputBuffers![1].get()!
            acc += inp1[0] * inp2[0]
            // data needs to flow into outputs for other cells
            outputBuffers![0].set(to: inp1)
            outputBuffers![1].set(to: inp2)
        }
    }
    func emit() {}
    var finished: Bool {
        !bothInputsReady()
    }
    
    var rightOutput: Buffer {
        outputBuffers![0]
    }
    var bottomOutput: Buffer {
        outputBuffers![1]
    }
    
    /// resets the accumulator to zero
    func reset() {
        acc = 0
    }
}

/// an array of MA cells, which can be used to perform systolic matmul
/// data is drawn from two feeds: one on the left, and one on the top
class MACArray {

    var cells: [[MA]]
    /// Number of rows in the array
    let rows: Int
    /// Number of cols in the array
    let cols: Int
    let leftFeeds: [VectorFeed]
    let topFeeds: [VectorFeed]

    init(leftFeeds: [VectorFeed], topFeeds: [VectorFeed]) {
        self.leftFeeds = leftFeeds
        self.topFeeds = topFeeds
        rows = leftFeeds.count
        cols = topFeeds.count

        cells = [[MA]]()
        //holds inputs from the previous row
        var upperBufs: [Buffer] = topFeeds.map({v in v.outputBuffers![0]})
        var newCell: MA
        for ir in 0..<rows {
            var row = [MA]()
            var leftInput = leftFeeds[ir].outputBuffers![0]
            for ic in 0..<cols {
                newCell = MA(leftInput: leftInput, topInput: upperBufs[ic])
                row.append(newCell)
                leftInput = newCell.rightOutput
                upperBufs[ic] = newCell.bottomOutput
            }
            cells.append(row)
        }
    }
    
    ///Run cells until all are finished; if initiailzed properly this will perform systolic matmul
//    func compute() {
//        /// make the first matrix data available at all edges
//        for feed in leftFeeds + topFeeds {
//            feed.emit()
//        }
//        
//        let done = false
//        while !done {
//            for ic in 0..<cols {
//                for ir in 0..<rows {
//                    if 
//                }
//            }
//        }
//    }

    /// Returns array holding the current accumulator states
    func accArray() -> [[Float]] {
        var accs = [[Float]]()
        for i in 0..<rows {
            var row = [Float]()
            for j in 0..<cols {
                row.append(cells[i][j].acc)
            }
            accs.append(row)
        }
        return accs
    }

}
