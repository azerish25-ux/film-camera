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
        let sample = try XCTUnwrap(trackOutput.copyNextSampleBuffer())
        print("Timecode reader sample count: \(CMSampleBufferGetNumSamples(sample)); total size: \(CMSampleBufferGetTotalSampleSize(sample)); valid: \(CMSampleBufferIsValid(sample)); ready: \(CMSampleBufferDataIsReady(sample))")
        let block = try XCTUnwrap(CMSampleBufferGetDataBuffer(sample))
        var bytes = [UInt8](repeating: 0, count: 4)
        let result = bytes.withUnsafeMutableBytes { CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: 4, destination: $0.baseAddress!) }
        XCTAssertEqual(result, kCMBlockBufferNoErr)
        XCTAssertEqual(bytes, Array(timecode.sample))
    }
}

