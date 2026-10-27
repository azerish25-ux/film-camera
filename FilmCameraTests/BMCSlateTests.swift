import XCTest
import AVFoundation
@testable import FilmCamera

final class BMCSlateTests: XCTestCase {
    func testOlderSavedSlateDecodesAndNewChoicesUseRecoveredValues() throws {
        let old = Data(#"{"project":"P","reel":"","scene":"","take":"","camera":"","director":"","cameraOperator":"","notes":""}"#.utf8)
        var slate = try JSONDecoder().decode(BMCSlate.self, from: old)
        XCTAssertEqual(slate.project, "P")
        XCTAssertNil(slate.dayNight)
        XCTAssertNil(slate.environment)
        XCTAssertNil(slate.goodTake)
        slate.dayNight = .night
        slate.environment = .interior
        slate.goodTake = true
        let restored = try JSONDecoder().decode(BMCSlate.self, from: JSONEncoder().encode(slate))
        XCTAssertEqual(restored, slate)
        XCTAssertEqual(restored.fields["com.blackmagic-design.camera.dayNight"], "Night")
        XCTAssertEqual(restored.fields["com.blackmagic-design.camera.environment"], "Interior")
        XCTAssertEqual(restored.fields["com.blackmagic-design.camera.goodTake"], "1")
        slate.goodTake = false
        XCTAssertEqual(slate.fields["com.blackmagic-design.camera.goodTake"], "0")
    }
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
        slate.dayNight = .day
        slate.environment = .exterior
        slate.goodTake = true
        try await MediaExporter().exportVideo(source: input, destination: output, settings: FilmSettings(), lut: nil, slate: slate)
        let metadata = try await AVURLAsset(url: output).loadMetadata(for: .quickTimeMetadata)
        func value(_ key: String) async throws -> String? {
            guard let item = metadata.first(where: { ($0.key as? String) == key }) else { return nil }
            return try await item.load(.stringValue)
        }
        let scene = try await value("com.blackmagic-design.camera.scene")
        let take = try await value("com.blackmagic-design.camera.take")
        let reel = try await value("com.blackmagic-design.camera.reelNumber")
        let dayNight = try await value("com.blackmagic-design.camera.dayNight")
        let environment = try await value("com.blackmagic-design.camera.environment")
        let goodTake = try await value("com.blackmagic-design.camera.goodTake")
        XCTAssertEqual(scene, "12A")
        XCTAssertEqual(take, "3")
        XCTAssertEqual(reel, "A001")
        XCTAssertEqual(dayNight, "Day")
        XCTAssertEqual(environment, "Exterior")
        XCTAssertEqual(goodTake, "1")
    }
}
