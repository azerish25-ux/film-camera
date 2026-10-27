import XCTest
import AVFoundation
@testable import FilmCamera

final class BMCSlateTests: XCTestCase {
    @MainActor func testSlateIsWrittenToExportedMovie() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let input = try await MediaExportTests.movie(in: folder)
        let output = folder.appendingPathComponent("slate.mov")
        var slate = BMCSlate()
        slate.scene = "12A"
        slate.take = "3"
        slate.reel = "A001"
        slate.project = "Test project"
        try await MediaExporter().exportVideo(source: input, destination: output, settings: FilmSettings(), lut: nil, slate: slate)
        let metadata = try await AVURLAsset(url: output).loadMetadata(for: .quickTimeMetadata)
        func value(_ key: String) async throws -> String? {
            guard let item = metadata.first(where: { ($0.key as? String) == key }) else { return nil }
            return try await item.load(.stringValue)
        }
        let scene = try await value("com.blackmagic-design.camera.scene")
        let take = try await value("com.blackmagic-design.camera.take")
        let reel = try await value("com.blackmagic-design.camera.reelNumber")
        XCTAssertEqual(scene, "12A")
        XCTAssertEqual(take, "3")
        XCTAssertEqual(reel, "A001")
    }
}
