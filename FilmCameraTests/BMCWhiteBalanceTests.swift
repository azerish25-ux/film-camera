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
}
