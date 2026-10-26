import XCTest
@testable import FilmCamera

final class MotionCamTests: XCTestCase {
    func testRecoveredExposureAndMergeBoundaries() {
        XCTAssertEqual(MotionExposure.ramp.count, 50)
        XCTAssertEqual(MotionExposure.isoSteps.count, 29)
        XCTAssertEqual(MotionExposure.shutters.count, 57)
        XCTAssertEqual(MotionExposure.shutterNanoseconds(fps:24, angle:180), 20_833_333)
        XCTAssertEqual(MotionExposure.shutterNanoseconds(fps:-1, angle:180), 16_666_667)
        XCTAssertEqual(MotionExposure.mergeCount(ev:8, shadows:1), 4)
        XCTAssertEqual(MotionExposure.mergeCount(ev:7.996875, shadows:1), 6)
        XCTAssertEqual(MotionExposure.mergeCount(ev:6, shadows:16), 12)
        XCTAssertEqual(MotionExposure.mergeCount(ev:0, shadows:1), 12)
        XCTAssertEqual(MotionExposure.ev(aperture:2, seconds:0.01, iso:100), log2(400), accuracy:1e-8)
    }
    func testRecoveredSliderEquations() {
        XCTAssertEqual(MotionGrade.value(.shadows, progress:50), 8)
        XCTAssertEqual(MotionGrade.value(.exposure, progress:16), 0)
        XCTAssertEqual(MotionGrade.value(.whitePoint, progress:50), 1)
        XCTAssertEqual(MotionGrade.value(.temperature, progress:2500), 4500)
        XCTAssertEqual(MotionGrade.value(.tint, progress:150), 0)
        XCTAssertEqual(MotionGrade.value(.saturation, progress:75), 1.5)
        XCTAssertEqual(MotionGrade.value(.sharpen0, progress:25), 1.5)
    }
    func testLegacyFilmSettingsStillDecode() throws {
        let settings = FilmSettings()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(settings)) as? [String:Any])
        object.removeValue(forKey:"motion")
        let decoded = try JSONDecoder().decode(FilmSettings.self, from:JSONSerialization.data(withJSONObject:object))
        XCTAssertFalse(decoded.motion.enabled)
        var edited = decoded
        edited.motion.enabled = true
        edited.motion.exposure = 1.25
        XCTAssertEqual(try JSONDecoder().decode(FilmSettings.self,from:JSONEncoder().encode(edited)), edited)
    }
    func testContainerRejectsBadHeaderAndTruncation() throws {
        XCTAssertThrowsError(try MotionContainer(data:Data("garbage!".utf8)))
        XCTAssertThrowsError(try MotionContainer(data:Data("MOTION \u{3}".utf8)))
    }
}
