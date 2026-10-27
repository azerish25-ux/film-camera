import XCTest

final class BMCDiscoveryUITests: XCTestCase {
    func testDiscoveryCanStartAndStopWithoutCameraHardware() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let controls = app.buttons["Camera controls"]
        XCTAssertTrue(controls.waitForExistence(timeout: 15))
        controls.tap()
        let remote = app.buttons["Remote cameras"]
        for _ in 0..<8 where !remote.isHittable { app.swipeUp() }
        XCTAssertTrue(remote.isHittable)
        remote.tap()
        let find = app.buttons["findRemoteCameras"]
        if !find.isHittable { app.swipeUp() }
        XCTAssertTrue(find.waitForExistence(timeout: 5))
        find.tap()
        let stop = app.buttons["Stop searching"]
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        stop.tap()
        XCTAssertTrue(find.waitForExistence(timeout: 5))
    }
}

