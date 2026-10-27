import XCTest
import AVFoundation
@testable import FilmCamera

final class BMCMovieCodecTests: XCTestCase {
    func testCaptureAndExportCodecMappings() {
        XCTAssertEqual(BMCMovieCodec.h264.captureType, .h264)
        XCTAssertEqual(BMCMovieCodec.hevc.captureType, .hevc)
        XCTAssertEqual(BMCMovieCodec.hevc.exportPreset(fourK: true), AVAssetExportPresetHEVC3840x2160)
        XCTAssertEqual(BMCMovieCodec.supportedCaptureCodecs([.hevc], canChoose: true), [.hevc])
        XCTAssertEqual(BMCMovieCodec.supportedCaptureCodecs([.h264, .hevc], canChoose: false), [])
    }
    @MainActor func testHEVCExportUsesHEVCWhenSupported() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = try await MediaExportTests.movie(in: folder)
        let asset = AVURLAsset(url: source)
        let preset = BMCMovieCodec.hevc.exportPreset(fourK: false)
        guard AVAssetExportSession.exportPresets(compatibleWith: asset).contains(preset) else {
            XCTAssertEqual(preset, AVAssetExportPresetHEVC1920x1080)
            return
        }
        let output = folder.appendingPathComponent("hevc.mov")
        try await MediaExporter().exportVideo(source: source, destination: output, settings: FilmSettings(), lut: nil, resolution: preset)
        let result = AVURLAsset(url: output)
        let video = try await result.loadTracks(withMediaType: .video)
        let audio = try await result.loadTracks(withMediaType: .audio)
        let formats = try await XCTUnwrap(video.first).load(.formatDescriptions)
        XCTAssertEqual(CMFormatDescriptionGetMediaSubType(try XCTUnwrap(formats.first)), kCMVideoCodecType_HEVC)
        XCTAssertEqual(audio.count, 1)
    }
}
