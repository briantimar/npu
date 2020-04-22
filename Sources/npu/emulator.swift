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
    var label: String { get }
}

/** A vector-valued float buffer
    Currently, stores just a single value!*/
class Buffer {
    
    let size: Int
    var val: Array<dataType>? = nil
    var hasRequest: Bool = false
    let label:String
    
    init(size: Int, label:String="") {
        self.size = size
        self.label = label
    }
    
    init(array: Array<dataType>, label:String="") {
        size = array.count
        val = array
        self.label=label
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
    var isFull : Bool {
        !isEmpty
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
    let label: String
    
    init(vals: Array<dataType>, label:String="") {
        self.size = vals.count
        self.vals = vals
        outputBuffers = [Buffer(array: vals)]
        self.label = label
    }
    
    init( size: Int, label:String = "") {
        self.size = size
        self.vals = Array<dataType>(repeating: 0.0, count: size)
        self.label = label
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
    var outputBuffers: [Buffer]?
    /** A convention - vectorfeed never demands computation*/
    let finished: Bool = true
    let label: String
   
    /// index of the next item to be served
    private var current: Int = 0
    
    init(label:String = ""){
        vals = [dataType]()
        self.label = label
        outputBuffers = [Buffer(size: 1, label:"\(label)_outBuf")]
    }
    
    init(vals: Array<dataType>, label:String = ""){
        self.vals = vals
        self.label = label
        outputBuffers = [Buffer(size: 1, label:"\(label)_outBuf")]
    }
    
    var length: Int {
        vals.count
    }
    var outputBuffer: Buffer {
        outputBuffers![0]
    }
    
    var currentValue : Array<dataType>? {
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
            outputBuffer.set(to: currentValue!)
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
    var outputBuffers: [Buffer]?
    /// Number of accumulation steps to perform
    var numAcc: Int = 0
    
    /// Named buffers
    let leftInput: Buffer
    let topInput: Buffer
    let rightOutput: Buffer
    let bottomOutput: Buffer
    
    /// hold inputs for pass-through
    private var leftInpCache: dataType? = nil
    private var topInpCache: dataType? = nil
    
    /// number of acc steps performed in a particular computation
    private var accSteps: Int = 0
    let label: String
    
    init(leftInput: Buffer, topInput: Buffer, numAcc:Int = 0, label:String = "") {
        self.label = label
        outputBuffers = [Buffer(size: 1, label:"\(label)_rightOutBuf"), Buffer(size:1, label:"\(label)_bottomOutBuf")]
        inputBuffers = [leftInput, topInput]
        self.leftInput = leftInput
        self.topInput = topInput
        rightOutput = outputBuffers![0]
        bottomOutput = outputBuffers![1]
        self.numAcc = numAcc
        
    }
    
    private var bothInputsFull : Bool {
        leftInput.isFull && topInput.isFull
    }

    /// performs a single mul-acc step
    func compute(leftVal: dataType, topVal: dataType) {
        acc += leftVal * topVal
        accSteps += 1
    }
    
    /** If both inputs are present, performs a compute step.
        If more compute is required, lodges the appropriate requests*/
    func consume() {
        if bothInputsFull {
            let leftVal = leftInput.get()![0]
            let topVal = topInput.get()![0]
            compute(leftVal: leftVal, topVal: topVal)
            // cache the inputs locally for pass-through
            leftInpCache = leftVal
            topInpCache = topVal
        }
        // submit pull requests if more to do
        if !finished {
            for inpBuf in inputBuffers! {
                if inpBuf.isEmpty {
                    inpBuf.openRequest()
                }
            }
        }
    }
    /** If any output buffer requests data, fill it from the cache if possible*/
    func emit() {
        if rightOutput.hasRequest && (leftInpCache != nil) {
            rightOutput.set(to: [leftInpCache!])
            rightOutput.closeRequest()
        }
        if bottomOutput.hasRequest && (topInpCache != nil) {
            bottomOutput.set(to: [topInpCache!])
            bottomOutput.closeRequest()
        }
    }
    
    var finished: Bool {
        accSteps == numAcc
    }
        
    /// resets the accumulator to zero
    func reset() {
        acc = 0
        accSteps = 0
    }
}


/// an array of MA cells, which can be used to perform systolic matmul
/// data is drawn from two feeds: one on the left, and one on the top
class MACArray : Sequence, IteratorProtocol {

    var MACells: [[MA]]
    /// Number of rows in the array
    let rows: Int
    /// Number of cols in the array
    let cols: Int
    let leftFeeds: [VectorFeed]
    let topFeeds: [VectorFeed]
    private var cellCt:Int = 0
    
    init(leftFeeds: [VectorFeed], topFeeds: [VectorFeed]) {
        self.leftFeeds = leftFeeds
        self.topFeeds = topFeeds
        rows = leftFeeds.count
        cols = topFeeds.count

        MACells = [[MA]]()
        
        // This stitches together the buffers in the MA grid
        var upperBufs: [Buffer] = topFeeds.map({v in v.outputBuffer})
        var newCell: MA
        for ir in 0..<rows {
            var row = [MA]()
            var leftInput = leftFeeds[ir].outputBuffer
            for ic in 0..<cols {
                newCell = MA(leftInput: leftInput, topInput: upperBufs[ic], label: "MA(\(ir),\(ic))")
                row.append(newCell)
                leftInput = newCell.rightOutput
                upperBufs[ic] = newCell.bottomOutput
            }
            MACells.append(row)
        }
    }
    
    /** Runs the computation defined by the current state of the feeds and cells.
        While all cells are not finished, each consumes and then emits*/
    func run() {
        var allFinished = false
        var t = 0
        while !allFinished {
            allFinished = true
            t += 1
            for cell in self {
            
                if cell is MA && cell.finished {
                }
                if !cell.finished {
                    cell.consume()
                    allFinished = false
                }
            }
            for cell in self {
                cell.emit()
            }
        }
    }
    
    /** resets the state of all MA cells, with each demaning the given number of steps*/
    private func resetMAToSteps(numsteps: Int) {
        for i in 0..<rows {
           for j in 0..<cols {
            MACells[i][j].reset()
            MACells[i][j].numAcc = numsteps
           }
        }
    }
    
    /** Computes with each MA demanding a given number of mul-acc steps*/
    func runMADriven(numsteps:Int){
        resetMAToSteps(numsteps: numsteps)
        run()
    }
    
    func makeIterator() -> MACArray {
        cellCt = 0
        return self
    }
    
    func next() -> Cell? {
        defer {
            cellCt += 1
        }
        if cellCt < rows * cols {
            return MACells[cellCt / cols][cellCt % cols]
        }
        else if cellCt < rows * cols + rows {
            return leftFeeds[cellCt - rows * cols]
        }
        else if cellCt < rows * cols + rows + cols {
            return topFeeds[cellCt - rows*cols - rows]
        }
        else {
            return nil
        }
    }
    
    /// Returns array holding the current accumulator states
    func accMatrix() -> Matrix {
        var accs = Matrix(rows:rows, cols: cols)
        for i in 0..<rows {
            for j in 0..<cols {
                accs[i,j] = MACells[i][j].acc
            }
        }
        return accs
    }

}

