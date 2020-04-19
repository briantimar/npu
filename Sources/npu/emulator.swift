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
    func tick()
    func tock()
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
    static let defaultByteValue: UInt8 = 0
    
    
    let sizeInBytes : Int
    var vals: Array<UInt8>
    
    init(sizeInBytes : Int) {
        self.sizeInBytes = sizeInBytes
        self.vals = Array(repeating: ByteWord.defaultByteValue, count: sizeInBytes)
    }
    
    /// size of the word in bits
    var size: Int {
        return ByteWord.byteSize * self.sizeInBytes
    }
    
    /// set ByteWord values from integer array.
    mutating func set(vals: [UInt8]) throws {
        guard (vals.count == self.sizeInBytes) else {
            throw HardwareError.invalidSize
        }
        self.vals = vals
    }
    
    /// get the byte value at a give position
    func byte(at index: Int) -> UInt8 {
        return self.vals[index]
    }
}

/* A computational unit - for example, a memory cell or a multiply-acc cell.
//    Generally, has inputs, outputs, and an internal state.*/
//class Cell : Clocked {
//
//    /// internal state
//    var state: ByteWord
//    /// input and output are both ByteWords
//    var input, output: ByteWord
//
//
//    /// called by the master clock to obtain output
//    func emitOutput() -> ByteWord {
//        return self.state
//    }
//
//    /// override this to define how the state is updated
//    func computeState() {}
//
//    func tick() {}
//    func tock() {}
//
//}
//
///// A memory unit
//class Mem: Clocked {
//
////    size of the memory in bits
//    let size: Int
//
//    init(size:Int) {
//        self.size = size
//    }
//
//    public func tick() {}
//    public func tock() {}
//
//
//
//}

