
/// Elements which respond to a clock signal
protocol Clocked {
    func tick()
    func tock()
}

/// A memory unit
class Mem: Clocked {

    let size: Int

    init(size:Int) {
        self.size = size
    }

    func tick() {}
    func tock() {}

}

