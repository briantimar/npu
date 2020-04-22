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
    
    func consume() {}
    
    /** Shifts the vector buffer down by one, exposing the next element*/
    func advance() {
        if current < length {
                   current += 1
               }
    }
    
    func emit() {
        outputBuffers![0].set(to: currentValue())
        advance()
    }
    
    /// Returns the number of elements remaining in the buffer
    var remaining: Int {
        return length - current
    }
    
    func isEmpty() -> Bool {
        return current >= length
    }
    
    var finished: Bool {
        isEmpty()
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
    
    init(inputs: [Buffer]) {
        assert(inputs.count == 2, "MA cell expects two input buffers")
        inputBuffers = inputs
        outputBuffers = [Buffer(size: 1), Buffer(size:1)]
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
    
    /// resets the accumulator to zero
    func reset() {
        acc = 0
    }
}


//
///// an array of MA cells, which can be used to perform systolic matmul
//class MACArray : Clocked {
//    
//    let size: Int
//    var cells: Array<Array<MA>>
//    var inputA: MatrixBuffer
//    var inputB: MatrixBuffer
//    
//    init(size: Int, inputA: MatrixBuffer, inputB: MatrixBuffer) throws {
//        self.size = size
//        
//        guard (inputA.numChannels == size) && (inputB.numChannels == size) else {
//            throw HardwareError.invalidSize
//        }
//        
//        cells = [[MA]]()
//        for _ in 0..<size {
//            var row = [MA]()
//            for _ in 0..<size {
//                row.append(MA())
//            }
//            cells.append(row)
//        }
//        self.inputA = inputA
//        self.inputB = inputB
//        
//    }
//    
//    
//    func tick() {
//    }
//    
//    func tock() {
//    }
//    
//    /// Returns array holding the current accumulator states
//    func accArray() -> [[Float]] {
//        var accs = [[Float]]()
//        for i in 0..<size {
//            var row = [Float]()
//            for j in 0..<size {
//                row.append(cells[i][j].acc)
//            }
//            accs.append(row)
//        }
//        return accs
//    }
//    
//}
