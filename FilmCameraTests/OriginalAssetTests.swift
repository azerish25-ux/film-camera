import XCTest
import CoreImage
@testable import FilmCamera
final class OriginalAssetTests: XCTestCase {
    func testCompleteOriginalCatalogAndPresets() throws {
        XCTAssertEqual(OriginalFilm.all.count,88)
        XCTAssertEqual(FilmPreset.originals.count,10)
        for film in OriginalFilm.all where !film.asset.isEmpty {
            let url = try XCTUnwrap(Bundle.main.url(forResource:film.asset,withExtension:"lut"))
            XCTAssertEqual(try Data(contentsOf:url).count,64*64*64*3,film.name)
        }
    }
    func testCharacteristicCurveUsesRecoveredNaturalSpline() {
        let x: [Double] = [0,50,100,150,200,255]
        XCTAssertEqual(FilmCurve.samples(x:x,y:x),(0...255).map(Double.init))
        let faded = FilmCurve.samples(x:x,y:[30,50,100,150,200,255])
        XCTAssertEqual(faded[0],30); XCTAssertEqual(faded[50],50); XCTAssertEqual(faded[255],255)
        XCTAssertEqual(faded.count,256)
    }
    func testJavaRandomMatchesKnownSequence() {
        var random = JavaRandom(seed:0)
        XCTAssertEqual(random.int(100),60)
        XCTAssertEqual(random.int(100),48)
        XCTAssertEqual(random.int(100),29)
    }
    func testEveryPresetRendersWithItsOriginalAssets() throws {
        let source = CIImage(color:CIColor(red:0.3,green:0.5,blue:0.7)).cropped(to:CGRect(x:0,y:0,width:192,height:144))
        let renderer = FilmRenderer()
        for preset in FilmPreset.originals {
            let result = try renderer.render(source,settings:preset.settings,time:0)
            let cg = try XCTUnwrap(renderer.context.createCGImage(result,from:result.extent),preset.name)
            let attachment = XCTAttachment(image:UIImage(cgImage:cg)); attachment.name=preset.name; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
