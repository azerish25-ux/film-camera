import XCTest
import AVFoundation
@testable import FilmCamera

final class RawSequenceTests: XCTestCase {
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
