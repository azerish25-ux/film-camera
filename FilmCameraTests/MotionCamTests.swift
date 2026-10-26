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
    func testRecoveredSliderEquations() {
        XCTAssertEqual(MotionGrade.value(.shadows, progress:50), 8)
        XCTAssertEqual(MotionGrade.value(.exposure, progress:16), 0)
        XCTAssertEqual(MotionGrade.value(.whitePoint, progress:50), 1)
        XCTAssertEqual(MotionGrade.value(.temperature, progress:2500), 4500)
        XCTAssertEqual(MotionGrade.value(.tint, progress:150), 0)
        XCTAssertEqual(MotionGrade.value(.saturation, progress:75), 1.5)
        XCTAssertEqual(MotionGrade.value(.sharpen0, progress:25), 1.5)
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
        XCTAssertEqual(pixels.count,64*48)
        XCTAssertEqual(pixels[0],500); XCTAssertEqual(pixels[1],700)
        let dng = try MotionDNG.encode(pixels:pixels,metadata:frame.metadata)
        XCTAssertEqual(Array(dng.prefix(4)),[0x49,0x49,42,0])
        let filter = try XCTUnwrap(CIRAWFilter(imageData:dng,identifierHint:"com.adobe.raw-image"))
        let image = try XCTUnwrap(filter.outputImage)
        XCTAssertNotNil(CIContext().createCGImage(image,from:image.extent))
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
    }
}
