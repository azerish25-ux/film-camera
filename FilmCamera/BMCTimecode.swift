import Foundation

/// The integer-fps starting sample used by the APK's MOV timecode editor.
/// Writing and associating a timecode track is a separate, unfinished step.
struct BMCTimecode: Equatable {
    let frameNumber: Int32
    let framesPerSecond: Int
    init(timeOfDay date: Date, framesPerSecond: Int, calendar: Calendar = .current) throws {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        guard let hour = components.hour, let minute = components.minute, let second = components.second else {
            throw PortError.message("Cannot determine the recording time.")
        }
        try self.init(secondsOfDay: hour * 3600 + minute * 60 + second, framesPerSecond: framesPerSecond, startingFrame: 0)
    }
    init(secondsOfDay: Int, framesPerSecond: Int, startingFrame: Int) throws {
        guard (0..<86_400).contains(secondsOfDay), (1...255).contains(framesPerSecond),
              (0..<framesPerSecond).contains(startingFrame) else {
            throw PortError.message("Invalid timecode components.")
        }
        let number = Int64(secondsOfDay) * Int64(framesPerSecond) + Int64(startingFrame)
        guard number <= Int64(Int32.max) else { throw PortError.message("Timecode is out of range.") }
        frameNumber = Int32(number)
        self.framesPerSecond = framesPerSecond
    }
    var sample: Data {
        var bigEndian = frameNumber.bigEndian
        return withUnsafeBytes(of: &bigEndian) { Data($0) }
    }
}
