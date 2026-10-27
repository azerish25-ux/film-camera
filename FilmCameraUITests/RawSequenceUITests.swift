import XCTest

final class RawSequenceUITests: XCTestCase {
    func testNativeDNGSequenceScrubAndSourceTimedMovieExport() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing","--raw-sequence-fixture"]; app.launch()
        let open = app.buttons["rawWorkspace"]
        XCTAssertTrue(open.waitForExistence(timeout:15))
        if !open.isHittable {app.swipeUp()}; open.tap()
        XCTAssertTrue(app.images["motionRawPreview"].waitForExistence(timeout:90))
        app.sliders["RAW frame"].adjust(toNormalizedSliderPosition:0.5)
        let export = app.buttons["motionExportMovie"]
        for _ in 0..<4 {if export.isHittable {break}; app.swipeUp()}
        XCTAssertTrue(export.isHittable); export.tap()
        XCTAssertTrue(app.buttons["motionShareExport"].waitForExistence(timeout:90))
        let attachment = XCTAttachment(screenshot:app.screenshot())
        attachment.name = "Native RAW sequence movie export"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
