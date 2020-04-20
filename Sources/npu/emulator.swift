/// Anything which provides a master clock signal
protocol Clock {
    // Time on the global clock
    var time: Float { get }

    // half-cycles for the clock
    // sets internal state for the 'up' cycle
    func tick()
//    actions for the 'down' cycle
    func tock()
}

/// Elements which respond to a clock signal
protocol Clocked {
    mutating func tick()
    mutating func tock()
}

/// Elements which yield values at the beginning of a cycle
protocol Emits {
    func emit()
}

/// Elements which consume values at the beginning of a cycle
protocol Reads {
    func read()
}

enum HardwareError: Error {
    case invalidSize
}

/// A fixed-size ByteWord
struct ByteWord {
    
    static let byteSize = 8
    static let defaultByteValue: Int8 = 0
    
    
    let size : Int
    var vals: Array<Int8>
    
    init(size : Int) {
        self.size = size
        self.vals = Array(repeating: ByteWord.defaultByteValue, count: size)
    }
    
    /// set ByteWord values from integer array.
    mutating func set(vals: [Int8]) throws {
        guard (vals.count == self.size) else {
            throw HardwareError.invalidSize
        }
        self.vals = vals
    }
    
    /// get the byte value at a give position
    func byte(at index: Int) -> Int8 {
        return self.vals[index]
    }
}

/* A computational unit - for example, a memory cell or a multiply-acc cell.
    Generally, has inputs, outputs, and an internal state.*/
protocol Cell : Clocked {

    /// input and output are both ByteWords
    var input: ByteWord {get set}
    var output: ByteWord {get set}
    
}

/* A channel, or bus, which just carries bits from one place to another.
 Always connects exactly two Cells.
 */
struct Channel : Clocked {
    
    let size: Int
    var inputCell: Cell
    var outputCell: Cell
    
    init(size: Int, inputCell: Cell, outputCell: Cell) throws {
        
        guard ((size == outputCell.output.size) &&
            (size == outputCell.input.size)) else {
            throw HardwareError.invalidSize
        }
        self.size = size
        self.inputCell = inputCell
        self.outputCell = outputCell
    }
    
//    At the beginning of the cycle, presents output of one cell to the input of the other
    mutating func tick() {
        self.outputCell.input = self.inputCell.output
    }
//    Nothing else to do
    mutating func tock() { }
    
}


/// A memory unit
struct Mem: Cell {

//    size of the memory in bytes
    let size: Int
    var input: ByteWord
    var output: ByteWord

    init(size:Int) {
        self.size = size
        self.input = ByteWord(size: self.size)
        self.output = ByteWord(size: self.size)
    }

    mutating func tick() {}
    mutating func tock() {}

}

