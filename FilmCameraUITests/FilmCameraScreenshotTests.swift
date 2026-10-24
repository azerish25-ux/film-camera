import XCTest

final class FilmCameraScreenshotTests: XCTestCase {
    func testFifteenScreenshots() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--editor-fixture"]
        app.launch()
        func shot(_ name: String) {
            Thread.sleep(forTimeInterval: 1.5)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func reveal(_ element: XCUIElement, limit: Int = 16) {
            for _ in 0..<limit {
                if element.exists && element.isHittable { return }
                app.swipeUp()
            }
            XCTAssertTrue(element.exists && element.isHittable)
        }
        shot("01-Camera-Photo")
        app.buttons["Video"].tap()
        shot("02-Camera-Video")
        app.buttons["Camera controls"].tap()
        app.swipeUp()
        shot("03-Camera-Hardware-Controls")
        app.tabBars.buttons["Editor"].tap()
        XCTAssertTrue(app.images["editorPreview"].waitForExistence(timeout: 90))
        shot("04-Editor-Film-Preview")
        app.switches["RGB histogram"].tap()
        shot("05-Editor-RGB-Histogram")
        app.switches["RGB histogram"].tap()
        let frame = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Film frame")).firstMatch
        reveal(frame)
        frame.tap()
        shot("06-Film-Frame-Choices")
        app.tapCoordinate(x: 0.05, y: 0.20)
        let color = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Color,")).firstMatch
        reveal(color)
        color.tap()
        shot("07-Film-Color-Choices")
        app.tapCoordinate(x: 0.05, y: 0.20)
        let curve = app.buttons["Characteristic curve"]
        reveal(curve)
        curve.tap()
        shot("08-Characteristic-Curve")
        app.buttons["Characteristic curve"].tap()
        reveal(app.sliders["Grain amount"])
        shot("09-Film-Grain-Adjustments")
        reveal(app.sliders["Halation"])
        shot("10-Halation-Adjustments")
        for _ in 0..<18 { app.swipeDown() }
        let export = app.buttons["exportMedia"]
        reveal(export)
        export.tap()
        XCTAssertTrue(app.buttons["shareExport"].waitForExistence(timeout: 120))
        app.tabBars.buttons["Gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", ".jpg")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 30))
        shot("11-Gallery-Film-Roll")
        photo.tap()
        shot("12-Gallery-Photo-Detail")
        app.buttons["Done"].tap()
        app.tabBars.buttons["Presets"].tap()
        shot("13-Original-Camera-Presets")
        app.swipeUp()
        app.swipeUp()
        shot("14-Film-Looks-Library")
        app.tabBars.buttons["Settings"].tap()
        shot("15-Settings-And-Help")
    }
}

private extension XCUIApplication {
    func tapCoordinate(x: CGFloat, y: CGFloat) {
        coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
    }
}

