import XCTest
@testable import FilmCamera

final class BMCGuideTests: XCTestCase {
    func testGuideFitsInsideImageAndIsCentered() {
        let wide = CGRect(x: 10, y: 20, width: 1600, height: 900)
        let square = BMCGuideGeometry.frame(in: wide, ratio: 1)
        XCTAssertEqual(square, CGRect(x: 360, y: 20, width: 900, height: 900))
        let cinema = BMCGuideGeometry.frame(in: wide, ratio: 2.4)
        XCTAssertEqual(cinema.midX, wide.midX, accuracy: 0.001)
        XCTAssertEqual(cinema.midY, wide.midY, accuracy: 0.001)
        XCTAssertEqual(cinema.width / cinema.height, 2.4, accuracy: 0.001)
    }

    func testRecoveredGuideRatios() {
        XCTAssertEqual(BMCGuideRatio.allCases.count, 11)
        XCTAssertEqual(BMCGuideRatio.portrait.value, 9.0 / 16.0, accuracy: 0.00001)
        XCTAssertEqual(BMCGuideRatio.cinema276.value, 2.76, accuracy: 0.00001)
    }
}
