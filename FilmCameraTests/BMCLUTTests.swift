import XCTest
@testable import FilmCamera

final class BMCLUTTests: XCTestCase {
    func testRecoveredCatalogAndCubeData() throws {
        XCTAssertEqual(BMCLUTCatalog.all.count, 41)
        XCTAssertEqual(Set(BMCLUTCatalog.all.map(\.profile)), Set(["P3_D65", "Rec.2020", "Rec.709", "Samsung_Log_HDR"]))
        let descriptor = try XCTUnwrap(BMCLUTCatalog.all.first { $0.profile == "Rec.709" && $0.name == "Cinema Teal" })
        let cube = try BMCLUTCatalog.load(descriptor)
        XCTAssertEqual(cube.dimension, 33)
        XCTAssertEqual(cube.rgba.count, 33 * 33 * 33 * 4)
        XCTAssertEqual(cube.rgba[0], 6.0 / 255.0, accuracy: 0.000001)
        XCTAssertEqual(cube.rgba[1], 1.0 / 255.0, accuracy: 0.000001)
    }
    @MainActor func testBuiltInSelectionSurvivesLibraryReload() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = try XCTUnwrap(BMCLUTCatalog.all.first?.id)
        let store = FilmStore(root: root); store.state.settings.lutID = id; store.persist()
        let restored = FilmStore(root: root)
        XCTAssertEqual(restored.state.settings.lutID, id)
        XCTAssertEqual(restored.selectedLUT?.id, id)
    }
}
