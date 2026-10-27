import Foundation
enum PortError: Error { case message(String) }
@main struct Check {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 3, minute: 4, second: 5))!
        let code = try BMCTimecode(timeOfDay: date, framesPerSecond: 24, calendar: calendar)
        precondition(code.frameNumber == (3 * 3600 + 4 * 60 + 5) * 24)
        print("Time-of-day calculation passed")
    }
}
