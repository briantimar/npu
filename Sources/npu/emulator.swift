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
    
    /// size of the word in bytes
    let byteSize : Int
    var vals: Array<UInt8>
    
    init(byteSize : Int) {
        self.byteSize = byteSize
        let _default : UInt8 = 0
        self.vals = Array(repeating: _default, count: byteSize)
    }
    
    /// size of the word in bits
    var size: Int {
        return 8 * self.byteSize
    }
    
    /// set ByteWord values from integer array.
    mutating func set(vals: [UInt8]) throws {
        guard (vals.count == self.byteSize) else {
            throw HardwareError.invalidSize
        }
        self.vals = vals
    }
    
    /// get the byte value at a give position
    func byte(at index: Int) -> UInt8 {
        return self.vals[index]
    }
}

/// a fixed-width bit channel
struct Channel  {
//    size of the channel in bytes
    let byteSize: Int
//    size of the channel in bits
    var size: Int {
        return 8 * self.byteSize
    }
}



/// A memory unit
class Mem: Clocked {

//    size of the memory in bits
    let size: Int

    init(size:Int) {
        self.size = size
    }
    
    public func tick() {}
    public func tock() {}

    
    
}

