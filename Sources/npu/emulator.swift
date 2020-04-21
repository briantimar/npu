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


enum HardwareError: Error {
    case invalidSize
}


/* A computational unit - for example, a memory cell or a multiply-acc cell.
    Generally, has inputs, outputs, and an internal state.*/
protocol Cell : Clocked {

    /// input and output are both ByteWords
    var inputSize: Int { get}
    var outputSize: Int {get }
    
    mutating func setInput(to: Array<Float>)
    func getOutput() -> Array<Float>
    
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
        self.outputCell.setInput(to:
            self.inputCell.getOutput())
    }
//    Nothing else to do
    mutating func tock() { }

}

/// A  cell with a single register that serves as both input and output
class Register : Cell {
    let size: Int
    var vals: Array<Float>
    
    var outputSize: Int { get {
        return size
        }}
    
    var inputSize: Int { get {
        return size
        }}
    
    init(vals: Array<Float>) {
        self.size = vals.count
        self.vals = vals
    }
    
    init( size: Int) {
        self.size = size
        self.vals = Array<Float>(repeating: 0.0, count: size)
    }

    func setInput(to input: Array<Float>) {
        self.vals = input
    }
    
    func getOutput() -> Array<Float> {
        return self.vals
    }
    
    func tick() {}
    func tock() {}
    
}


/* Performs a fused multiply-add.
 At each timestep, two inputs are multiplied, added to the register, then rounded and stored.*/
//class FMA : Cell {
//
//    let inputSize = 1
//    let outputSize = 1
//    var inputs = Array<Int8>(repeating:0, count: 2)
//    var acc: Int16 = 0
//
//    init() {
//    }
//
//    func setInput(input: ByteWord) {
//        self.inputs = input.vals
//    }
//
//    func getOutput() -> ByteWord {
//        return ByteWord(vals: [self])
//    }
//
//    func tick() {
//
//    }
//    func tock() {
//
//    }
//}
