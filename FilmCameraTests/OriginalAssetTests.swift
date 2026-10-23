import XCTest
import CoreImage
import UIKit
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
    func testSmallCubeIsResampledToOriginal64CubedLayout() throws {
        let text = "LUT_3D_SIZE 2\nDOMAIN_MIN 0 0 0\nDOMAIN_MAX 2 2 2\n0 0 0\n1 0 0\n0 1 0\n1 1 0\n0 0 1\n1 0 1\n0 1 1\n1 1 1"
        let cube = try CubeLUT.parse(text,name:"Domain")
        let rgb = cube.textureRGB()
        XCTAssertEqual(rgb.count,64*64*64*3)
        XCTAssertEqual(rgb[63*3],128)
        XCTAssertEqual(rgb[0],0)
    }
    func testNeutralPipelinePreservesNonblackSourcePixels() throws {
        let pixel: [UInt8] = [76,128,179,255]
        let bytes = Array(repeating:pixel,count:128*96).flatMap {$0}
        let source = CIImage(bitmapData:Data(bytes),bytesPerRow:128*4,size:CGSize(width:128,height:96),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
        var settings = FilmSettings(); settings["blur"] = 0; settings["scratches"] = 0; settings["verticalScratch"] = 1
        settings.curveY = settings.curveX
        let result = try FilmRenderer().render(source,settings:settings,time:0)
        var output = [UInt8](repeating:0,count:128*96*4)
        let context = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
        output.withUnsafeMutableBytes {context.render(result,toBitmap:$0.baseAddress!,rowBytes:128*4,bounds:result.extent,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())}
        let center = (48*128+64)*4
        XCTAssertEqual(Double(output[center]),76,accuracy:12)
        XCTAssertEqual(Double(output[center+1]),128,accuracy:12)
        XCTAssertEqual(Double(output[center+2]),179,accuracy:12)
    }
    func testOriginalFrameContainerRatios() {
        for frame in [FilmFrame.super16,.sixteen,.raw2,.classic,.beaulieu,.kiev] {XCTAssertEqual(frame.ratio,4.0/3)}
        for frame in [FilmFrame.eight,.framed,.bolex,.wide] {XCTAssertEqual(frame.ratio,16.0/9)}
        XCTAssertEqual(FilmFrame.super16.outputSize(for:CGSize(width:1280,height:720)),CGSize(width:960,height:720))
        XCTAssertEqual(FilmFrame.bolex.outputSize(for:CGSize(width:960,height:720)),CGSize(width:960,height:540))
    }
    func testFilmReadbackPreservesVerticalImageOrder() throws {
        var bytes = [UInt8]()
        for row in 0..<96 {for _ in 0..<128 {bytes += row < 48 ? [200,80,40,255] : [40,80,200,255]}}
        let source = CIImage(bitmapData:Data(bytes),bytesPerRow:512,size:CGSize(width:128,height:96),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
        var settings = FilmSettings(); settings["blur"] = 0; settings["scratches"] = 0; settings["verticalScratch"] = 1; settings.curveY = settings.curveX
        let result = try FilmRenderer().render(source,settings:settings)
        var output = [UInt8](repeating:0,count:bytes.count)
        let context = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
        output.withUnsafeMutableBytes {context.render(result,toBitmap:$0.baseAddress!,rowBytes:512,bounds:result.extent,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())}
        XCTAssertEqual(Double(output[(24*128+64)*4]),200,accuracy:15)
        XCTAssertEqual(Double(output[(72*128+64)*4]),40,accuracy:15)
    }
    func testRGBHistogramMatchesSourceChannels() throws {
        let pixel: [UInt8] = [76,128,179,255]
        let bytes = Array(repeating:pixel,count:128*96).flatMap {$0}
        let image = CIImage(bitmapData:Data(bytes),bytesPerRow:512,size:CGSize(width:128,height:96),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
        let bins = FilmHistogram.values(image)
        guard bins.count == 1024 else {XCTFail("Histogram did not return 256 RGBA bins"); return}
        for (channel,expected) in [76,128,179].enumerated() {
            let peak = (0..<256).max {bins[$0*4+channel] < bins[$1*4+channel]} ?? -1
            XCTAssertEqual(Double(peak),Double(expected),accuracy:1)
            XCTAssertGreaterThan(bins[peak*4+channel],0)
        }
    }
    func testSavedCurveValidationRepairsMalformedData() {
        var settings = FilmSettings(); settings.curveX = [0,1]; settings.curveY = [1]
        settings.values["exposure"] = 100; settings.values["grain"] = .nan
        settings.validate()
        XCTAssertEqual(settings.curveX.count,6); XCTAssertEqual(settings.curveY.count,6)
        XCTAssertEqual(settings["exposure"],3); XCTAssertEqual(settings["grain"],0)
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
