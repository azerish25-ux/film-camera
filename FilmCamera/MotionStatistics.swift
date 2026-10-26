import Foundation

struct MotionStatistics {
    private(set) var captured = 0
    private(set) var dropped = 0
    private var first: Double?
    private var last: Double?
    mutating func append(time:Double) {
        guard time.isFinite else {return}
        if let last,time <= last {return}
        if first == nil {first = time}
        last = time; captured += 1
    }
    mutating func drop() {dropped += 1}
    var fps: Double {
        guard let first,let last,last > first,captured > 1 else {return 0}
        return Double(captured-1)/(last-first)
    }
    var dropFraction: Double {captured+dropped > 0 ? Double(dropped)/Double(captured+dropped) : 0}
}
