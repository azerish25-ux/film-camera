import Foundation
import Network
import XCTest
@testable import FilmCamera

@MainActor final class BMCDiscoveryBrowserTests: XCTestCase {
    func testDiscoversAndClearsLocalMockService() async throws {
        let id = "00000000-0000-0000-0000-000000000003"
        let listener = try NWListener(using: .tcp, on: .any)
        let txt = NWTXTRecord(["name": "Camera", "slate_name": "A", "model_name": "Phone", "proto": "5.0"])
        listener.service = NWListener.Service(name: id, type: "_bmd-cam-control._tcp", domain: nil, txtRecord: txt)
        listener.newConnectionHandler = { $0.cancel() }
        listener.start(queue: DispatchQueue(label: "BMCDiscoveryTestListener"))
        defer { listener.cancel() }

        let browser = BMCDiscoveryBrowser()
        browser.start()
        XCTAssertTrue(browser.isBrowsing)
        defer { browser.stop() }
        for _ in 0..<150 {
            if browser.cameras.contains(where: { $0.id.uuidString.lowercased() == id }) { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let camera = try XCTUnwrap(browser.cameras.first { $0.id.uuidString.lowercased() == id })
        XCTAssertEqual(camera.record.name, "Camera")
        XCTAssertEqual(camera.record.major, 5)
        browser.stop()
        XCTAssertTrue(browser.cameras.isEmpty)
        XCTAssertFalse(browser.isBrowsing)
    }
}

