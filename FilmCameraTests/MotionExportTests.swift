import XCTest
import AVFoundation
import CoreImage
@testable import FilmCamera

final class MotionExportTests: XCTestCase {
    func testSourceFrameRatePreservesNormalTiming() {
        XCTAssertEqual(MotionVideoExport.sourceFPS(29.97),29.97)
        XCTAssertEqual(MotionVideoExport.sourceFPS(480),480)
        XCTAssertEqual(MotionVideoExport.sourceFPS(0.2),24)
        XCTAssertEqual(MotionVideoExport.sourceFPS(.nan),24)
    }
    func testCinemaDNGZIP64WithAudio() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:root)}
        let source = root.appendingPathComponent("clip.mcraw"),destination = root.appendingPathComponent("CinemaDNG.zip")
        try MotionFixture.container(includeAudio:true).write(to:source)
        let job = MotionExportJob(source:source,destination:destination,first:0,last:2,settings:FilmSettings(),lut:nil,kind:"CinemaDNG ZIP",codec:.h264,fps:24,bitrate:1_000_000)
        try await MotionJobRunner.run(job) {_ in}
        let data = try Data(contentsOf:destination)
        XCTAssertEqual(try data.motionUInt32(0),0x04034b50)
        let attachment = XCTAttachment(data:data,uniformTypeIdentifier:"public.zip-archive"); attachment.name = "CinemaDNG-ZIP64"; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testInterruptedQueueDoesNotAutomaticallyRepeatFailedWork() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:root)}
        var job = MotionExportJob(source:root.appendingPathComponent("source.mcraw"),destination:root.appendingPathComponent("Motion-test.mov"),first:0,last:1,settings:FilmSettings(),lut:nil,kind:"Movie",codec:.h264,fps:24,bitrate:2_000_000)
        job.status = "Rendering"
        try JSONEncoder().encode([job]).write(to:root.appendingPathComponent("motion-export-queue.json"))
        let workspace = MotionWorkspace(); workspace.configure(root:root)
        XCTAssertFalse(workspace.busy); XCTAssertEqual(workspace.jobs.count,1)
        XCTAssertEqual(workspace.jobs.first?.status,"Interrupted — retry")
    }
    func testPCMExtractionAndTrim() throws {
        let container = try MotionContainer(data:MotionFixture.container(includeAudio:true))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".wav")
        defer {try? FileManager.default.removeItem(at:url)}
        XCTAssertTrue(try MotionAudio.extract(container:container,range:1...2,to:url))
        let data = try Data(contentsOf:url)
        XCTAssertEqual(String(data:data.prefix(4),encoding:.ascii),"RIFF")
        XCTAssertEqual(try data.motionUInt32(24),8000)
        XCTAssertEqual(UInt16(data[44]) | UInt16(data[45])<<8,1100)
        XCTAssertGreaterThan(data.count,44)
    }
    func testExplicitFrameRateChangeDoesNotDesynchronizeAudio() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:root)}
        let source = root.appendingPathComponent("clip.mcraw"),destination = root.appendingPathComponent("changed-fps.mov")
        var data = try MotionFixture.container(includeAudio:true)
        let container = try MotionContainer(data:data)
        for frame in 0..<3 {
            var time = Data(); time.motionAppend(UInt64((Double(frame)*1e9/23.976).rounded()))
            let start = container.indexStart+frame*16+8
            data.replaceSubrange(start..<start+8,with:time)
        }
        try data.write(to:source)
        let job = MotionExportJob(source:source,destination:destination,first:0,last:2,settings:FilmSettings(),lut:nil,kind:"Movie",codec:.h264,fps:24,bitrate:2_000_000)
        try await MotionJobRunner.run(job) {_ in}
        let audio = try await AVURLAsset(url:destination).loadTracks(withMediaType:.audio)
        XCTAssertTrue(audio.isEmpty,"Explicitly retimed frames must not retain audio at the old playback speed")
    }
    func testRawFramesProducePlayableMovieWithAudio() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:directory)}
        let input = directory.appendingPathComponent("source.mcraw"),output = directory.appendingPathComponent("output.mov")
        try MotionFixture.container(includeAudio:true).write(to:input)
        var settings = FilmSettings(); settings.motion.enabled = true; settings.motion.exposure = 0.25
        let job = MotionExportJob(source:input,destination:output,first:0,last:2,settings:settings,lut:nil,kind:"Movie",codec:.h264,fps:24,bitrate:2_000_000)
        try await MotionJobRunner.run(job) {_ in}
        let asset = AVURLAsset(url:output),duration = try await asset.load(.duration)
        XCTAssertGreaterThan(duration.seconds,0.08)
        let video = try await asset.loadTracks(withMediaType:.video),audio = try await asset.loadTracks(withMediaType:.audio)
        XCTAssertEqual(video.count,1); XCTAssertEqual(audio.count,1)
    }
    func testPreRollMemoryBoundAndAveraging() throws {
        let context = CIContext(),bounds = CGRect(x:0,y:0,width:16,height:16)
        let black = try XCTUnwrap(context.createCGImage(CIImage(color:.black).cropped(to:bounds),from:bounds))
        let white = try XCTUnwrap(context.createCGImage(CIImage(color:.white).cropped(to:bounds),from:bounds))
        let ring = MotionPreRoll(); ring.append(black,limit:1024); ring.append(white,limit:1024)
        XCTAssertEqual(ring.latest(30).count,1)
        let average = try MotionPreRoll.merge([black,white])
        var pixel = [Float](repeating:0,count:4)
        context.render(average,toBitmap:&pixel,rowBytes:16,bounds:CGRect(x:8,y:8,width:1,height:1),format:.RGBAf,colorSpace:CGColorSpace(name:CGColorSpace.linearSRGB)!)
        XCTAssertEqual(pixel[0],0.5,accuracy:0.05)
        XCTAssertThrowsError(try MotionPreRoll.merge([]))
    }
}
