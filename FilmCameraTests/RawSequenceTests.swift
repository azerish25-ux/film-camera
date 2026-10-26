import XCTest
import AVFoundation
@testable import FilmCamera

final class RawSequenceTests: XCTestCase {
    func testMovieSizingKeepsFullSensorAspectWithinEncoderBounds() {
        XCTAssertEqual(RawMovieResolution.p1080.fit(CGSize(width:4032,height:3024)),CGSize(width:1440,height:1080))
        XCTAssertEqual(RawMovieResolution.p1080.fit(CGSize(width:3024,height:4032)),CGSize(width:1080,height:1440))
        XCTAssertEqual(RawMovieResolution.p4k.fit(CGSize(width:8064,height:6048)),CGSize(width:2880,height:2160))
    }

    func testRawSequenceAudioTrimUsesSensorClock() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".rawseq")
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
        defer {try? FileManager.default.removeItem(at:root); try? FileManager.default.removeItem(at:destination)}
        let writer = try RawSequenceWriter(url:root,timelapse:false)
        var pcm = Data()
        for _ in 0..<32_000 {pcm.motionAppend(Int16(1000))}
        try await writer.appendPCM(pcm,timestampNs:500_000_000,sampleRate:8000,channels:1)
        let container = try MotionContainer(data:MotionFixture.container())
        for index in 0..<3 {
            let frame = try container.frame(index)
            try await writer.appendFrame(MotionDNG.encode(pixels:MotionRaw.unpack(frame.pixels,metadata:frame.metadata),metadata:frame.metadata),timestampNs:1_000_000_000+Int64(index)*1_250_000_000)
        }
        try await writer.finish(endTimestampNs:4_000_000_000)
        let clip = try MotionClip(url:root)
        let job = MotionExportJob(source:root,destination:destination,first:0,last:2,settings:FilmSettings(),lut:nil,kind:"Movie",codec:.h264,fps:24,bitrate:2_000_000,sourceTiming:true)
        try await MotionJobRunner.run(job) {_ in}
        let asset = AVURLAsset(url:destination)
        let tracks = try await asset.loadTracks(withMediaType:.audio),duration = try await asset.load(.duration)
        XCTAssertEqual(tracks.count,1); XCTAssertEqual(duration.seconds,3,accuracy:0.1)
        let trimmed = root.appendingPathComponent("trim.wav")
        XCTAssertTrue(try clip.extractAudio(range:1...2,to:trimmed))
        let bytes = try Data(contentsOf:trimmed)
        XCTAssertEqual(try bytes.motionUInt32(40),28_000)
    }

    func testRawSequenceJournalsFramesAndPreservesOriginalDNG() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".rawseq")
        defer {try? FileManager.default.removeItem(at:root)}
        let writer = try RawSequenceWriter(url:root,timelapse:false)
        let container = try MotionContainer(data:MotionFixture.container())
        for index in 0..<3 {
            let frame = try container.frame(index)
            let dng = try MotionDNG.encode(pixels:MotionRaw.unpack(frame.pixels,metadata:frame.metadata),metadata:frame.metadata)
            try await writer.appendFrame(dng,timestampNs:1_000_000_000+Int64(index)*1_250_000_000)
        }
        let journal = try RawSequenceManifest.load(root)
        XCTAssertFalse(journal.complete); XCTAssertEqual(journal.frames.count,3)
        try await writer.finish(endTimestampNs:4_000_000_000)
        let clip = try MotionClip(url:root)
        XCTAssertEqual(clip.count,3); XCTAssertEqual(clip.fps,0.8,accuracy:1e-8)
        XCTAssertEqual(try clip.dng(1),try Data(contentsOf:root.appendingPathComponent("000001.dng")))
        XCTAssertTrue(try RawSequenceManifest.load(root).complete)
    }
    func testSequenceRejectsEscapingFramePaths() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".rawseq")
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:root)}
        let manifest = RawSequenceManifest(frames:[.init(file:"../secret.dng",timestampNs:1)],complete:true,endTimestampNs:2)
        try JSONEncoder().encode(manifest).write(to:root.appendingPathComponent("sequence.json"))
        XCTAssertThrowsError(try RawSequenceManifest.load(root))
    }
    func testSourceTimingUsesRealFrameTimestamps() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".rawseq")
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
        defer {try? FileManager.default.removeItem(at:root); try? FileManager.default.removeItem(at:destination)}
        let writer = try RawSequenceWriter(url:root,timelapse:false)
        let container = try MotionContainer(data:MotionFixture.container())
        for index in 0..<3 {
            let frame = try container.frame(index)
            try await writer.appendFrame(MotionDNG.encode(pixels:MotionRaw.unpack(frame.pixels,metadata:frame.metadata),metadata:frame.metadata),timestampNs:1_000_000_000+Int64(index)*1_250_000_000)
        }
        try await writer.finish(endTimestampNs:4_000_000_000)
        let clip = try MotionClip(url:root)
        try await MotionVideoExport.encode(clip:clip,range:0...2,destination:destination,settings:FilmSettings(),lut:nil,codec:.h264,fps:24,bitrate:2_000_000,sourceTiming:true) {_ in}
        let duration = try await AVURLAsset(url:destination).load(.duration).seconds
        XCTAssertEqual(duration,3,accuracy:0.1)
    }
}
