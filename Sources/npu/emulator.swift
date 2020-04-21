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
    func set(to newval: Array<dataType>){
        assert(newval.count == size, "invalid input to buffer of size \(size)")
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
/// when the vector is exhausted, yields 0
class VectorBuf {
    
    let length : Int
    let inputSize: Int
    let outputSize: Int = 1
    var vals: Array<dataType>
    private var current: Int
    
    init(length: Int){
        self.length = length
        self.inputSize = length
        self.vals = Array<dataType>(repeating: 0, count: length)
//        index of the next item to be served
        current = 0
    }
    
    func getOutput() -> Array<dataType> {
        if current >= length {
            return [0]
        }
        else {
        return [vals[current]]
        }
    }
    
    func loadFrom(array: [dataType]) {
        self.vals = array
    }
    
    func setInput(to vals: Array<dataType>) {
        loadFrom(array: vals)
    }
    
    /** Shifts the vector buffer down by one, exposing the next element*/
    func advance() {
        if current < length {
                   current += 1
               }
    }
    
    /// Returns the number of elements remaining in the buffer
    var remaining: Int {
        return length - current
    }
    
    
    func isEmpty() -> Bool {
        return current >= length
    }
}

/// Defines a matrix buffer which can be used to feed the MAC array
class MatrixBuffer {
    let numChannels: Int
    let length: Int
    var channels: [VectorBuf]
    
    /**
     -Parameter numChannels: number of vector channels which constitute the buffer
        -Parameter length: the length of each channel
     */
    init(numChannels:Int, length:Int) {
        self.numChannels = numChannels
        self.length = length
        channels = [VectorBuf]()
        for _ in 0..<numChannels {
            channels.append(VectorBuf(length: length))
        }
    }
    
    /** loads data from a raw array
        each column in the array is treated as a channel.*/
    func loadFrom(matrix: Matrix) {
        assert(matrix.rows == length && matrix.cols == numChannels, "invalid matrix shape")
        for colIndex in 0..<matrix.cols {
            channels[colIndex].loadFrom(array: matrix[0..<matrix.rows, colIndex])
        }
        
    }
    


    /**
        returns output of the buffer at the given index
 */
    func getOutput(at index:Int) -> [dataType] {
        return channels[index].getOutput()
    }
    /** advances the channel at the given index*/
    func advance(at index: Int) {
        channels[index].advance()
    }
    
    /// number of elements remaining in the given channel
    func remaining(at index: Int) -> Int {
        channels[index].remaining
    }
    
    ///Checks whether all channels are emptied
    func isEmpty() -> Bool {
        channels.allSatisfy({v in v.isEmpty()})
    }
}
    



/* Performs a  multiply-add.
 At each timestep, two inputs are multiplied, added to the register, then rounded and stored.*/
class MA {

    let inputSize = 2
    let outputSize = 1
    var inputs = Array<Float>(repeating:0, count: 2)
    var acc: Float  = 0

    init() {
    }

    func setInput(to input: Array<Float>) {
        self.inputs = input
    }

    func getOutput() -> Array<Float> {
        return [self.acc]
    }

    func tick() {
    }
    /// updates accumulator based on the inputs
    func tock() {
        self.acc += self.inputs[0] * self.inputs[1]
    }
    
    /// resets the accumulator to zero
    func reset() {
        self.acc = 0
    }
}



/// an array of MA cells, which can be used to perform systolic matmul
class MACArray : Clocked {
    
    let size: Int
    var cells: Array<Array<MA>>
    var inputA: MatrixBuffer
    var inputB: MatrixBuffer
    
    init(size: Int, inputA: MatrixBuffer, inputB: MatrixBuffer) throws {
        self.size = size
        
        guard (inputA.numChannels == size) && (inputB.numChannels == size) else {
            throw HardwareError.invalidSize
        }
        
        cells = [[MA]]()
        for _ in 0..<size {
            var row = [MA]()
            for _ in 0..<size {
                row.append(MA())
            }
            cells.append(row)
        }
        self.inputA = inputA
        self.inputB = inputB
        
    }
    
    
    func tick() {
    }
    
    func tock() {
    }
    
    /// Returns array holding the current accumulator states
    func accArray() -> [[Float]] {
        var accs = [[Float]]()
        for i in 0..<size {
            var row = [Float]()
            for j in 0..<size {
                row.append(cells[i][j].acc)
            }
            accs.append(row)
        }
        return accs
    }
    
}
