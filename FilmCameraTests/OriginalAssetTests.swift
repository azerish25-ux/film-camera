import XCTest
import CoreImage
import AVFoundation
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
    func testTemperatureTintUsesAndroidIntegerDivision() {
        let values = OriginalFilmPipeline.curve(temperature:5000,tint:-3)
        let blue = (138.5177312231*log(40)-305.0447927307+1)/255
        XCTAssertEqual(Double(values[197]),blue,accuracy:0.000001)
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
    private func readPixels(_ image: CIImage) -> [UInt8] {
        let width = Int(image.extent.width), height = Int(image.extent.height)
        var bytes = [UInt8](repeating:0,count:width*height*4)
        let context = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
        bytes.withUnsafeMutableBytes {context.render(image,toBitmap:$0.baseAddress!,rowBytes:width*4,bounds:image.extent,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())}
        return bytes
    }
    func testEveryFilmThroughProductionPipelineAgainstAndroidChain() throws {
        var bytes = [UInt8](repeating:255,count:128*96*4)
        for k in 0..<(128*96) {
            bytes[k*4] = UInt8((k%23)*255/22)
            bytes[k*4+1] = UInt8(((k/23)%23)*255/22)
            bytes[k*4+2] = UInt8(((k/529)%23)*255/22)
        }
        let source = CIImage(bitmapData:Data(bytes),bytesPerRow:512,size:CGSize(width:128,height:96),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
        let renderer = FilmRenderer()
        var report: [[String:Any]] = []
        for (index,film) in OriginalFilm.all.enumerated() {
            var settings = FilmSettings(); settings.look = film.name; settings["blur"] = 0
            settings["scratches"] = 0; settings["verticalScratch"] = 1; settings.curveY = settings.curveX
            let name = String(format:"chain-film-%02d",index)
            let url = try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"rgba"))
            let expected = Array(try Data(contentsOf:url))
            let actual = readPixels(try renderer.render(source,settings:settings,time:0))
            var maximum = 0, sum = 0
            for y in 0..<96 {for x in 0..<128 {for channel in 0..<3 {
                let delta = abs(Int(actual[(y*128+x)*4+channel])-Int(expected[((95-y)*128+x)*4+channel]))
                maximum = max(maximum,delta); sum += delta
            }}}
            let mean = Double(sum)/Double(128*96*3)
            XCTAssertLessThanOrEqual(maximum,3,film.name); XCTAssertLessThan(mean,0.5,film.name)
            report.append(["film":film.name,"maximumByteError":maximum,"meanByteError":mean])
        }
        let attachment = XCTAttachment(data:try JSONSerialization.data(withJSONObject:report,options:.prettyPrinted),uniformTypeIdentifier:"public.json")
        attachment.name = "Production pipeline Android comparison"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testEveryFilmAndFrameOnLandscapeAndPortraitImages() throws {
        let renderer = FilmRenderer()
        for size in [CGSize(width:256,height:192),CGSize(width:192,height:256)] {
            let source = CIImage(color:CIColor(red:0.32,green:0.52,blue:0.72)).cropped(to:CGRect(origin:.zero,size:size))
            for film in OriginalFilm.all {for frame in FilmFrame.allCases {
                var settings = FilmSettings(); settings.look = film.name; settings.frame = frame
                let image = try renderer.render(source,settings:settings,time:0)
                XCTAssertNotNil(renderer.context.createCGImage(image,from:image.extent),"\(film.name) / \(frame)")
                XCTAssertEqual(image.extent.width < image.extent.height,size.width < size.height)
            }}
        }
    }
    func testEveryAnimatedAssetDecodesAcrossLoopBoundary() throws {
        let sampler = OriginalAssetSampler()
        let names = Set(FilmFrame.allCases.compactMap(\.originalVideo)+FilmBurn.clips)
        XCTAssertEqual(names.count,14)
        for name in names {
            let url = try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"mp4"))
            let duration = AVURLAsset(url:url).duration.seconds
            XCTAssertTrue(duration.isFinite && duration > 0,name)
            for time in [0,0.25,duration-0.001,duration,duration+0.25] {
                let frame = try sampler.frame(name,time:time)
                XCTAssertGreaterThan(frame.width,0,name); XCTAssertGreaterThan(frame.height,0,name)
            }
        }
    }
    func testTemporalEffectsAndBurnRollsRenderAcrossSeeking() throws {
        let source = CIImage(color:CIColor(red:0.4,green:0.5,blue:0.6)).cropped(to:CGRect(x:0,y:0,width:256,height:192))
        let renderer = FilmRenderer()
        for roll in 0..<7 {
            var settings = FilmSettings(); settings["burn"] = 1; settings["burnClip"] = Double(roll)
            settings["grain"] = 0.4; settings["flicker"] = 100; settings["jitter"] = 30; settings["shake"] = 30
            settings["scratches"] = 100; settings["leakRed"] = 1; settings["leakBlue"] = 1; settings["leakHoles"] = 1
            settings.frame = .super16
            for time in [0,0.04,0.08,1,0.1,0] {
                let image = try renderer.render(source,settings:settings,time:time)
                XCTAssertNotNil(renderer.context.createCGImage(image,from:image.extent),"Roll \(roll) at \(time)")
            }
        }
    }

    func testSubthresholdGrainUsesAndroidBypass() throws {
        let source = CIImage(color:CIColor(red:0.3,green:0.5,blue:0.7)).cropped(to:CGRect(x:0,y:0,width:128,height:96))
        var settings = FilmSettings(); settings["blur"] = 0; settings["scratches"] = 0; settings["verticalScratch"] = 1
        let renderer = FilmRenderer()
        let bypass = readPixels(try renderer.render(source,settings:settings,time:0))
        settings["grain"] = 0.009
        let subthreshold = readPixels(try renderer.render(source,settings:settings,time:0))
        XCTAssertEqual(bypass,subthreshold,"Android j4.p.d selects the no-grain shader below 0.01")
    }
    func testFogVariesIndependentlyOfFilmBreath() {
        var settings = FilmSettings(); settings["leakBlue"] = 0.5; settings["flicker"] = 0
        let dynamics = FilmDynamics()
        dynamics.advance(settings:settings,width:1280,height:720,time:0)
        // java.util.Random(22).nextFloat() == 0.7322219, in j4.p.e's
        // independent 25-sample fog buffer, even with film breath disabled.
        XCTAssertEqual(dynamics.fogAmplitude,((0.7322219-0.5)/25*0.8+1)*0.5,accuracy:0.000001)
    }

    func testFastShakeUsesOriginalThreeSampleBuffer() {
        var settings = FilmSettings(); settings["shake"] = 30
        let dynamics = FilmDynamics()
        dynamics.advance(settings:settings,width:1280,height:720,time:0)
        // java.util.Random(22).nextInt(90) == 52; j4.p.I0 has 3 slots.
        XCTAssertEqual(dynamics.fastShake,(52-30*0.8)/720/5/3,accuracy:0.0000001)
    }
    func testVideoResolutionProcessingPaths() throws {
        for size in [CGSize(width:1280,height:720),CGSize(width:1920,height:1080),CGSize(width:3840,height:2160)] {
            let source = CIImage(color:CIColor(red:0.25,green:0.5,blue:0.8)).cropped(to:CGRect(origin:.zero,size:size))
            var settings = FilmSettings(); settings["halation"] = 0.5; settings["halationRadius"] = 7
            settings["blur"] = 4; settings["grain"] = 0.3; settings.look = OriginalFilm.all[1].name
            let renderer = FilmRenderer(), output = try renderer.render(source,settings:settings,time:0)
            XCTAssertEqual(output.extent.size,size)
            XCTAssertNotNil(renderer.context.createCGImage(output,from:output.extent))
        }
    }

}
