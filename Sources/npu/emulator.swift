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
    
    init(vals: Array<Int8>) {
        self.vals = vals
        self.size = vals.count
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
    var inputSize: Int { get}
    var outputSize: Int {get }
    
    mutating func setInput(input: ByteWord)
    func getOutput() -> ByteWord
    
}

/* A channel, or bus, which just carries bits from one place to another.
 Always connects exactly two Cells.
 */
struct Channel : Clocked {
    
    let size: Int
    var inputCell: Cell
    var outputCell: Cell
    
    init(size: Int, inputCell: Cell, outputCell: Cell) throws {
        
        guard ((size == outputCell.inputSize) &&
            (size == inputCell.outputSize)) else {
            throw HardwareError.invalidSize
        }
        self.size = size
        self.inputCell = inputCell
        self.outputCell = outputCell
    }
    
//    At the beginning of the cycle, presents output of one cell to the input of the other
    mutating func tick() {
        self.outputCell.setInput(input:
            self.inputCell.getOutput())
    }
//    Nothing else to do
    mutating func tock() { }
    
}

/// A  cell with a single register that serves as both input and output
struct Register : Cell {
    let size: Int
    var register: ByteWord
    
    var outputSize: Int { get {
        return size
        }}
    
    var inputSize: Int { get {
        return size
        }}
    
    init(size: Int) {
        self.size = size
        self.register = ByteWord(size: size)
    }
    

    mutating func setInput(input: ByteWord) {
        self.register = input
    }
    
    func getOutput() -> ByteWord {
        return self.register
    }
    
    func tick() {}
    func tock() {}
    
}

///// A memory unit
//struct Mem: Cell {
//
////    size of the memory in bytes
//    let size: Int
//    var input: ByteWord
//    var output: ByteWord
//
//    init(size:Int) {
//        self.size = size
//        self.input = ByteWord(size: self.size)
//        self.output = ByteWord(size: self.size)
//    }
//
//    mutating func tick() {}
//    mutating func tock() {}
//
//}

