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


/* A computational unit - for example, a memory cell or a multiply-acc cell.
    Generally, has inputs, outputs, and an internal state.
    Class only, because the Channel expects reference types.*/
protocol Cell : Clocked {

    /// input and output are both ByteWords
    var inputSize: Int { get}
    var outputSize: Int {get }
    
    func setInput(to: Array<dataType>)
    func getOutput() -> Array<dataType>
    
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

/// A  cell with a single register that serves as both input and output
class Register : Cell {
    let size: Int
    var vals: Array<dataType>
    
    var outputSize: Int { get {
        return size
        }}
    
    var inputSize: Int { get {
        return size
        }}
    
    init(vals: Array<dataType>) {
        self.size = vals.count
        self.vals = vals
    }
    
    init( size: Int) {
        self.size = size
        self.vals = Array<dataType>(repeating: 0.0, count: size)
    }

    func setInput(to input: Array<dataType>) {
        self.vals = input
    }
    
    func getOutput() -> Array<dataType> {
        return self.vals
    }
    
    func tick() {}
    func tock() {}
    
}

/// A buffer which holds a single vector of data; used to feed a MACArray
/// when the vector is exhausted, yields 0
class VectorBuf: Cell {
    
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
    func setInput(to vals: Array<dataType>) {
        self.vals = vals
    }
    
    func tick() {}
    
    func tock() {
        if current < length {
            current += 1
        }
    }
    
    func isEmpty() -> Bool {
        return current >= length
    }
}


/* Performs a  multiply-add.
 At each timestep, two inputs are multiplied, added to the register, then rounded and stored.*/
class MA : Cell {

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
    
    init(size: Int) {
        self.size = size
        cells = [[MA]]()
        for _ in 0..<size {
            var row = [MA]()
            for _ in 0..<size {
                row.append(MA())
            }
            cells.append(row)
        }
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
