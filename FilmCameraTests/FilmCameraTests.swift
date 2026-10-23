import XCTest
import CoreImage
@testable import FilmCamera
final class FilmCameraTests: XCTestCase {
    func testLUTValidation() throws {
        let cube = "LUT_3D_SIZE 2\n0 0 0\n1 0 0\n0 1 0\n1 1 0\n0 0 1\n1 0 1\n0 1 1\n1 1 1"
        XCTAssertEqual(try CubeLUT.parse(cube,name:"Identity").rgba.count,32)
        XCTAssertThrowsError(try CubeLUT.parse("LUT_3D_SIZE 200",name:"Invalid"))
        XCTAssertThrowsError(try CubeLUT.parse(cube+"\nNaN 1 1",name:"Invalid"))
    }
    func testSettingsClampAndRoundTrip() throws {
        var settings = FilmSettings(); settings["exposure"] = 100
        XCTAssertEqual(settings["exposure"],3)
        settings["exposure"] = .nan; XCTAssertEqual(settings["exposure"],3)
        XCTAssertEqual(try JSONDecoder().decode(FilmSettings.self,from:JSONEncoder().encode(settings)),settings)
    }
    func testAllEffectsRenderFiniteOutput() throws {
        let renderer = FilmRenderer(), source = CIImage(color:CIColor(red:0.4,green:0.6,blue:0.8)).cropped(to:CGRect(x:0,y:0,width:128,height:96))
        for spec in Adjustment.all {
            var settings = FilmSettings(); settings[spec.id] = spec.range.upperBound
            let result = try renderer.render(source,settings:settings,time:0.5)
            XCTAssertNotNil(renderer.context.createCGImage(result,from:result.extent),spec.id)
        }
        for frame in FilmFrame.allCases {
            var settings = FilmSettings(); settings.frame = frame
            let result = try renderer.render(source,settings:settings)
            XCTAssertGreaterThan(result.extent.width,0); XCTAssertNotNil(renderer.context.createCGImage(result,from:result.extent))
        }
    }
    @MainActor func testPersistenceAndPreset() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let store = FilmStore(root:root); store.state.settings["exposure"] = 1.2
        try store.savePreset("My film")
        let restored = FilmStore(root:root)
        XCTAssertEqual(restored.state.presets.first?.name,"My film")
        XCTAssertEqual(restored.state.settings["exposure"],1.2)
        XCTAssertThrowsError(try restored.savePreset("  "))
    }
}
