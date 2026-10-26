import XCTest
import CoreImage
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
    func testRecordingStatsUseMonotonicSamples() {
        var stats = MotionStatistics()
        for i in 0..<25 {stats.append(time:Double(i)/24)}
        stats.append(time:0); stats.append(time:.nan); stats.drop()
        XCTAssertEqual(stats.fps,24,accuracy:1e-8)
        XCTAssertEqual(stats.captured,25); XCTAssertEqual(stats.dropped,1)
        XCTAssertEqual(stats.dropFraction,1.0/26,accuracy:1e-8)
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
    func testAPKIlluminantLabelsArePreserved() throws {
        for (name,code) in [("standarda",17),("standardb",18),("standardc",19),("d50",23),("d55",20),("d65",21),("d75",22)] {XCTAssertEqual(try MotionDNG.illuminant(name,fallback:0),UInt16(code))}
        XCTAssertEqual(try MotionDNG.illuminant(nil,fallback:21),21)
        XCTAssertThrowsError(try MotionDNG.illuminant("unknown",fallback:21))
        XCTAssertThrowsError(try MotionDNG.illuminant(NSNumber(value:-1),fallback:21))
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
    func testIndexedContainerFrameSelectionAndDNG() throws {
        let data = try MotionFixture.container(),container = try MotionContainer(data:data)
        XCTAssertEqual(container.frames.count,3)
        XCTAssertEqual(container.fps,24,accuracy:0.001)
        let frame = try container.frame(1),pixels = try MotionRaw.unpack(frame.pixels,metadata:frame.metadata)
        XCTAssertEqual(pixels.count,320*240)
        XCTAssertEqual(pixels[0],500); XCTAssertEqual(pixels[1],700)
        let dng = try MotionDNG.encode(pixels:pixels,metadata:frame.metadata)
        XCTAssertEqual(Array(dng.prefix(4)),[0x49,0x49,42,0])
        let filter = try XCTUnwrap(CIRAWFilter(imageData:dng,identifierHint:"com.adobe.raw-image"))
        let image = try XCTUnwrap(filter.outputImage)
        let rendered = CIContext().createCGImage(image,from:image.extent)
        if rendered == nil {let attachment = XCTAttachment(data:dng,uniformTypeIdentifier:"com.adobe.raw-image"); attachment.name = "Rejected-generated-DNG"; attachment.lifetime = .keepAlways; add(attachment); let details = XCTAttachment(string:"RAW extent: \(image.extent), properties: \(filter.properties)"); details.lifetime = .keepAlways; add(details)}
        XCTAssertNotNil(rendered)
        XCTAssertThrowsError(try container.frame(3))
        for length in [0,7,8,16,data.count-1] {XCTAssertThrowsError(try MotionContainer(data:data.prefix(length)))}
        var corrupt = data; corrupt[corrupt.count-8] = 255
        XCTAssertThrowsError(try MotionContainer(data:corrupt))
    }
    func testAllRawBlockModesAndBayerInterleaving() throws {
        for mode in 0...15 {
            let bits = mode <= 10 ? mode : 16
            let values = (0..<16).map {UInt16(($0*7) & (bits == 0 ? 0 : (1<<bits)-1))}
            func block(base:Int) -> Data {
                var d = Data([UInt8(mode<<4 | (base>>8)),UInt8(base&255)])
                var payload = [UInt8](repeating:0,count:bits*2)
                for i in 0..<16 {for j in 0..<bits {let bit = i*bits+j; let value = (values[i] >> (bits-1-j)) & 1; payload[bit/8] |= UInt8(value) << (7-bit%8)}}
                d.append(contentsOf:payload); return d
            }
            var d = block(base:100); d.append(block(base:200))
            let pixels = try MotionRaw.decodeBlocks(d,width:31,height:1)
            for x in 0..<31 {XCTAssertEqual(pixels[x],values[x/2] &+ UInt16(x%2 == 0 ? 100 : 200),"mode \(mode), sample \(x)")}
            XCTAssertThrowsError(try MotionRaw.decodeBlocks(d.dropLast(),width:32,height:1))
        }
    }
    func testPackedRaw10And12() throws {
        XCTAssertEqual(try MotionRaw.unpack(Data([0,1,2,255,0b11100100]),metadata:["width":4,"height":1,"pixelFormat":"raw10"]),[0,5,10,1023])
        XCTAssertEqual(try MotionRaw.unpack(Data([0x12,0xab,0xc3]),metadata:["width":2,"height":1,"pixelFormat":"raw12"]),[0x123,0xabc])
        XCTAssertThrowsError(try MotionRaw.unpack(Data(),metadata:["width":16384,"height":16384]))
        XCTAssertThrowsError(try MotionDNG.encode(pixels:[0],metadata:["width":1,"height":1]))
    }
    func testFocusHysteresisTimeoutAndOrientation() {
        var focus = MotionFocusState()
        XCTAssertTrue(focus.select(SIMD2(0.5,0.5),time:0))
        XCTAssertFalse(focus.select(SIMD2(0.51,0.51),time:1))
        XCTAssertFalse(focus.update(time:4.99,settled:true))
        XCTAssertTrue(focus.update(time:5,settled:true))
        XCTAssertTrue(focus.select(SIMD2(0.5,0.5),time:6)); focus.lock()
        XCTAssertFalse(focus.update(time:100,settled:true))
        var orientation = MotionOrientation()
        for _ in 0..<32 {_ = orientation.update(pitch:0,roll:60)}
        XCTAssertEqual(orientation.orientation,.reverseLandscape)
        for _ in 0..<32 {_ = orientation.update(pitch:-60,roll:0)}
        XCTAssertEqual(orientation.orientation,.portrait)
    }
    func testGyroflowInterpolationAndInvalidTimelines() throws {
        let samples = [MotionSample(time:1,value:SIMD3(1,2,3)),MotionSample(time:2,value:SIMD3(2,3,4))]
        let text = try MotionGyroflow.encode(gyro:samples,accel:samples,model:"CI Phone",startMilliseconds:123)
        XCTAssertTrue(text.contains("tscale,0.5000000000")); XCTAssertTrue(text.contains("id,CI.Phone"))
        XCTAssertTrue(text.contains("1,150000000,250000000,350000000,150000000,250000000,350000000,"))
        XCTAssertThrowsError(try MotionGyroflow.encode(gyro:[],accel:samples,model:"CI",startMilliseconds:0))
        XCTAssertThrowsError(try MotionGyroflow.encode(gyro:Array(samples.reversed()),accel:samples,model:"CI",startMilliseconds:0))
    }
    func testGradeAndAidsRenderAndBypass() throws {
        let context = CIContext(),source = CIImage(color:CIColor(red:0.4,green:0.5,blue:0.6)).cropped(to:CGRect(x:0,y:0,width:32,height:24))
        let bypass = MotionProcessing.grade(source,MotionGrade())
        XCTAssertEqual(bypass.extent,source.extent)
        var grade = MotionGrade(); grade.enabled = true; grade.exposure = 1; grade.cropWidth = 50
        let result = MotionProcessing.grade(source,grade)
        XCTAssertEqual(result.extent.width,16)
        XCTAssertNotNil(context.createCGImage(result,from:result.extent))
        let aid = try MotionProcessing.aids(source,clipping:true,peaking:true,sensitivity:0.03)
        XCTAssertNotNil(context.createCGImage(aid,from:aid.extent))
        let mapped = try MotionViewfinder.render(source,shadows:2,contrast:0.5,saturation:1)
        XCTAssertNotNil(context.createCGImage(mapped,from:mapped.extent))
    }
    func testRecoveredViewfinderPixels() throws {
        let context = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
        let bounds = CGRect(x:0,y:0,width:8,height:8)
        func pixel(_ image:CIImage) -> [Float] {
            var out = [Float](repeating:0,count:4)
            context.render(image,toBitmap:&out,rowBytes:16,bounds:CGRect(x:4,y:4,width:1,height:1),format:.RGBAf,colorSpace:nil)
            return out
        }
        let black = CIImage(color:.black).cropped(to:bounds),white = CIImage(color:.white).cropped(to:bounds)
        let dark = pixel(try MotionProcessing.aids(black,clipping:true,peaking:false,sensitivity:0.03))
        XCTAssertEqual(dark[0],1,accuracy:0.001); XCTAssertEqual(dark[1],1,accuracy:0.001); XCTAssertEqual(dark[2],0,accuracy:0.001)
        let bright = pixel(try MotionProcessing.aids(white,clipping:true,peaking:false,sensitivity:0.03))
        XCTAssertEqual(bright[0],1,accuracy:0.001); XCTAssertEqual(bright[1],0,accuracy:0.001)
        let gray = CIImage(color:CIColor(red:0.25,green:0.25,blue:0.25)).cropped(to:bounds)
        let mapped = pixel(try MotionViewfinder.render(gray,shadows:2,contrast:0.5,saturation:1))
        let gamma = pow(0.5/1.5,1/2.2),b = gamma/(1-gamma),expected = 1/(1+pow(b,-1.5))
        XCTAssertEqual(Double(mapped[0]),expected,accuracy:0.005)
    }
}
