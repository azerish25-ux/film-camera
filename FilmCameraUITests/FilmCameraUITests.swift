import XCTest
final class FilmCameraUITests: XCTestCase {
    func testNavigationAndPresetPersistence() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        app.tabBars.buttons["Presets"].tap()
        let name = app.textFields["presetName"]; XCTAssertTrue(name.waitForExistence(timeout:10)); name.tap(); name.typeText("CI Film")
        app.buttons["savePreset"].tap()
        XCTAssertTrue(app.buttons["CI Film"].waitForExistence(timeout:5))
        app.tabBars.buttons["Gallery"].tap(); XCTAssertTrue(app.navigationBars["Gallery"].exists)
        app.tabBars.buttons["Settings"].tap(); XCTAssertTrue(app.staticTexts["A local film camera and editor."].waitForExistence(timeout:5))
        let attachment = XCTAttachment(screenshot:app.screenshot()); attachment.lifetime = .keepAlways; add(attachment)
        app.terminate(); app.launch(); app.tabBars.buttons["Presets"].tap(); XCTAssertTrue(app.buttons["CI Film"].waitForExistence(timeout:5))
    }
    func testEditorPhotoExportToGallery() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing","--editor-fixture"]; app.launch()
        app.tabBars.buttons["Editor"].tap()
        let export = app.buttons["exportMedia"]
        XCTAssertTrue(export.waitForExistence(timeout:15)); export.tap()
        XCTAssertTrue(app.buttons["Share export"].waitForExistence(timeout:30))
        app.tabBars.buttons["Gallery"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"label CONTAINS %@", ".jpg")).firstMatch.waitForExistence(timeout:10))
        let attachment = XCTAttachment(screenshot:app.screenshot()); attachment.name = "Exported gallery media"; attachment.lifetime = .keepAlways; add(attachment)
    }

}

