import XCTest
@testable import FilmCamera

final class BMCWhiteBalanceTests: XCTestCase {
    func testWhiteBalanceGainsAreSafeForHardware() {
        XCTAssertEqual(BMCWhiteBalance.clampGain(0.2, maximum: 4), 1)
        XCTAssertEqual(BMCWhiteBalance.clampGain(8, maximum: 4), 4)
        XCTAssertEqual(BMCWhiteBalance.clampGain(2.5, maximum: 4), 2.5)
        XCTAssertEqual(BMCWhiteBalance.clampGain(.nan, maximum: 4), 1)
        XCTAssertEqual(BMCWhiteBalance.clampGain(2, maximum: .nan), 1)
    }
    func testRecoveredPresetValues() {
        XCTAssertEqual(BMCWhiteBalancePreset.sunny.value, BMCWhiteBalance(temperature: 5600, tint: 10))
        XCTAssertEqual(BMCWhiteBalancePreset.tungsten.value, BMCWhiteBalance(temperature: 3200, tint: 0))
        XCTAssertEqual(BMCWhiteBalancePreset.fluorescent.value, BMCWhiteBalance(temperature: 4000, tint: 15))
        XCTAssertEqual(BMCWhiteBalancePreset.shady.value, BMCWhiteBalance(temperature: 4500, tint: 15))
        XCTAssertEqual(BMCWhiteBalancePreset.cloudy.value, BMCWhiteBalance(temperature: 6500, tint: 10))
    }
}
