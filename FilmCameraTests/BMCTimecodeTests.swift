import XCTest
import AVFoundation
@testable import FilmCamera

final class BMCTimecodeTests: XCTestCase {
    func testRecoveredFrameNumberIsEncodedBigEndian() throws {
        let timecode = try BMCTimecode(secondsOfDay: 3600, framesPerSecond: 24, startingFrame: 7)
        XCTAssertEqual(timecode.frameNumber, 86407)
        XCTAssertEqual(Array(timecode.sample), [0, 1, 0x51, 0x87])
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 86400, framesPerSecond: 24, startingFrame: 0))
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 0, framesPerSecond: 24, startingFrame: 24))
        XCTAssertThrowsError(try BMCTimecode(secondsOfDay: 0, framesPerSecond: 0, startingFrame: 0))
    }
    func testTimeOfDayUsesTheRecordingCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 1, day: 2, hour: 3, minute: 4, second: 5)))
        let timecode = try BMCTimecode(timeOfDay: date, framesPerSecond: 24, calendar: calendar)
        XCTAssertEqual(timecode.frameNumber, (3 * 3600 + 4 * 60 + 5) * 24)
    }
    func testWritesReadableAssociatedTimecodeTrackWithoutDroppingAudio() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try await MediaExportTests.movie(in: folder)
        let output = folder.appendingPathComponent("timecode.mov")
        let timecode = try BMCTimecode(secondsOfDay: 3600, framesPerSecond: 24, startingFrame: 7)
        try await BMCTimecodeWriter.write(source: source, destination: output, timecode: timecode, framesPerSecond: 24)
        let movie = XCTAttachment(contentsOfFile: output)
        movie.name = "timecode-output.mov"; movie.lifetime = .keepAlways; add(movie)
        let asset = AVURLAsset(url: output)
        let audio = try await asset.loadTracks(withMediaType: .audio)
        let video = try await asset.loadTracks(withMediaType: .video)
        let tracks = try await asset.loadTracks(withMediaType: .timecode)
        XCTAssertEqual(audio.count, 1); XCTAssertEqual(video.count, 1); XCTAssertEqual(tracks.count, 1)
        let associations = try await XCTUnwrap(video.first).loadAssociatedTracks(ofType: .timecode)
        XCTAssertEqual(associations.count, 1)
        let descriptions = try await XCTUnwrap(tracks.first).load(.formatDescriptions)
        let format = try XCTUnwrap(descriptions.first)
        XCTAssertEqual(CMTimeCompare(CMTimeCodeFormatDescriptionGetFrameDuration(format), CMTime(value: 41_666_668, timescale: 1_000_000_000)), 0)
        let reader = try AVAssetReader(asset: asset)
        let trackOutput = AVAssetReaderTrackOutput(track: try XCTUnwrap(tracks.first), outputSettings: nil)
        XCTAssertTrue(reader.canAdd(trackOutput)); reader.add(trackOutput); XCTAssertTrue(reader.startReading())
        var candidate = trackOutput.copyNextSampleBuffer()
        var emptyMarkers = 0
        while let current = candidate, CMSampleBufferGetNumSamples(current) == 0, emptyMarkers < 16 {
            emptyMarkers += 1
            candidate = trackOutput.copyNextSampleBuffer()
        }
        let sample = try XCTUnwrap(candidate)
        XCTAssertGreaterThan(CMSampleBufferGetNumSamples(sample), 0)
        let block = try XCTUnwrap(CMSampleBufferGetDataBuffer(sample))
        var bytes = [UInt8](repeating: 0, count: 4)
        let result = bytes.withUnsafeMutableBytes { CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: 4, destination: $0.baseAddress!) }
        XCTAssertEqual(result, kCMBlockBufferNoErr)
        XCTAssertEqual(bytes, Array(timecode.sample))
    }

    @MainActor func testTimecodeRemuxPreservesExportedSlate() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try await MediaExportTests.movie(in: folder)
        let exported = folder.appendingPathComponent("exported.mov")
        let timed = folder.appendingPathComponent("timed.mov")
        var slate = BMCSlate(); slate.scene = "12A"
        try await MediaExporter().exportVideo(source: source, destination: exported, settings: FilmSettings(), lut: nil, slate: slate)
        let code = try BMCTimecode(secondsOfDay: 3600, framesPerSecond: 24, startingFrame: 0)
        try await BMCTimecodeWriter.write(source: exported, destination: timed, timecode: code, framesPerSecond: 24)
        let asset = AVURLAsset(url: timed)
        let metadata = try await asset.loadMetadata(for: .quickTimeMetadata)
        let scene = try XCTUnwrap(metadata.first { ($0.key as? String) == "com.blackmagic-design.camera.scene" })
        let value = try await scene.load(.stringValue)
        let tracks = try await asset.loadTracks(withMediaType: .timecode)
        XCTAssertEqual(value, "12A")
        XCTAssertEqual(tracks.count, 1)
    }
}
