import XCTest
final class FilmCameraUITests: XCTestCase {
    func testNavigationAndPresetPersistence() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        app.tabBars.buttons["Presets"].tap()
        let name = app.textFields["presetName"]; XCTAssertTrue(name.waitForExistence(timeout:10)); name.tap(); name.typeText("CI Film")
        app.buttons["savePreset"].tap()
        XCTAssertTrue(app.buttons["CI Film"].waitForExistence(timeout:5))
        app.tabBars.buttons["Gallery"].tap(); XCTAssertTrue(app.navigationBars["Gallery"].exists)
        app.tabBars.buttons["Settings"].tap(); XCTAssertTrue(app.staticTexts["Super 16 for iOS"].exists)
        let attachment = XCTAttachment(screenshot:app.screenshot()); attachment.lifetime = .keepAlways; add(attachment)
        app.terminate(); app.launch(); app.tabBars.buttons["Presets"].tap(); XCTAssertTrue(app.buttons["CI Film"].waitForExistence(timeout:5))
    }
}
