import XCTest
@testable import FilmCamera

final class BMCAudioMeterTests: XCTestCase {
    func testPeakMeterTracksFullScaleAndSilence() throws {
        var meter = try BMCAudioMeter(sampleRate: 48_000, channels: 1, mode: .ppm18)
        XCTAssertNil(meter.process([Int16](repeating: 0, count: 479)))
        let silent = try XCTUnwrap(meter.process([0])).first!
        XCTAssertLessThan(silent.level, -90)
        let full = try XCTUnwrap(meter.process([Int16](repeating: 32767, count: 480))).first!
        XCTAssertEqual(full.level, 0, accuracy: 0.02)
        XCTAssertEqual(full.peak, 0, accuracy: 0.02)
    }
    func testVUMeterRequiresItsCompleteWindowAndSeparatesChannels() throws {
        var meter = try BMCAudioMeter(sampleRate: 48_000, channels: 2, mode: .vu18)
        let frame = [Int16(32767), Int16(0)]
        var samples = [Int16](); for _ in 0..<(466 * 17) { samples.append(contentsOf: frame) }
        let readings = try XCTUnwrap(meter.process(samples))
        XCTAssertEqual(readings.count, 2)
        XCTAssertGreaterThan(readings[0].level, 20)
        XCTAssertEqual(readings[1].level, -68.39, accuracy: 0.1)
        XCTAssertThrowsError(try BMCAudioMeter(sampleRate: 0, channels: 1, mode: .vu18))
    }
}
