import Foundation
import Network
import XCTest
@testable import FilmCamera

final class BMCBonjourProbeTests: XCTestCase {
    func testStandardType() async throws {
        try await probe(type: "_bmd-cam-control._tcp", id: "00000000-0000-0000-0000-000000000001")
    }
    func testAndroidSpecificType() async throws {
        try await probe(type: "_bmd-cam-control-android._tcp", id: "00000000-0000-0000-0000-000000000002")
    }
    private func probe(type: String, id: String) async throws {
        let listener = try NWListener(using: .tcp, on: .any)
        let txt = NWTXTRecord(["name": "Camera", "slate_name": "A", "model_name": "Phone", "proto": "5.0"])
        listener.service = NWListener.Service(name: id, type: type, domain: nil, txtRecord: txt)
        listener.newConnectionHandler = { $0.cancel() }
        listener.stateUpdateHandler = { print("listener state:", $0) }
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: type, domain: nil), using: .tcp)
        let found = expectation(description: "Discovered " + type)
        found.assertForOverFulfill = false
        browser.stateUpdateHandler = { print("browser state:", $0) }
        browser.browseResultsChangedHandler = { results, _ in
            for result in results {
                guard case let .service(name, _, _, _) = result.endpoint, name == id,
                      case let .bonjour(record) = result.metadata else { continue }
                let keys = ["name", "slate_name", "model_name", "proto", "ctrl_uuid", "ctrl_name", "ctrl_slate_name", "ctrl_model_name", "ctrl_proto"]
                let attributes = Dictionary(uniqueKeysWithValues: keys.compactMap { key in record[key].map { (key, Data($0.utf8)) } })
                guard let parsed = BMCDiscoveryRecord(serviceName: name, attributes: attributes),
                      parsed.name == "Camera", parsed.slateName == "A", parsed.major == 5 else { continue }
                found.fulfill()
            }
        }
        let queue = DispatchQueue(label: "BMCBonjourProbe")
        listener.start(queue: queue)
        browser.start(queue: queue)
        defer { browser.cancel(); listener.cancel() }
        await fulfillment(of: [found], timeout: 15)
    }
}
