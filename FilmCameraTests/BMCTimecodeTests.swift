import XCTest
@testable import FilmCamera

final class BMCTimecodeTests: XCTestCase {
    func testRecoveredFrameNumberIsEncodedBigEndian() throws {
        let timecode = try BMCTimecode(secondsOfDay: 3600, framesPerSecond: 24, startingFrame: 7)
        XCTAssertEqual(timecode.frameNumber, 86407)
        XCTAssertEqual(Array(timecode.sample), [0, 1, 0x51, 0x87])
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 86400, framesPerSecond: 24, startingFrame: 0))
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 0, framesPerSecond: 24, startingFrame: 24))
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 0, framesPerSecond: 0, startingFrame: 0))
    }
}
