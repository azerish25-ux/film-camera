import Foundation
import SwiftProtobuf
import XCTest
@testable import FilmCamera

private actor FakeCatalogSender: BMCMediaSender {
    private var packets: [Data] = []
    func sendBinary(_ data: Data) async throws { packets.append(data) }
    func sent() -> [Data] { packets }
}

final class BMCMediaCatalogTests: XCTestCase {
    func testListScopesAndResponseRouting() async throws {
        let sender = FakeCatalogSender()
        let catalog = BMCMediaCatalog(sender: sender)
        let now = Date(timeIntervalSince1970: 3601)
        try await catalog.request(scope: .all, now: now, includeThumbnails: true)
        try await catalog.request(scope: .lastHour, now: now, includeThumbnails: true)
        let packets = await sender.sent()
        XCTAssertEqual(packets, [Data([0x0a, 0x04, 0x0a, 0x02, 0x18, 0x01]), Data([0x0a, 0x06, 0x0a, 0x04, 0x08, 0x01, 0x18, 0x01])])

        var clip = CamAppMediaSyncClip(); clip.clipID = "A"; clip.fileName = "clip.mov"
        var list = CamAppMediaSyncListClipsResponse(); list.clips = [clip]
        var response = CamAppMediaSyncMessage(); response.listClipsResponse = list
        var unrelated = CamAppMediaSyncMessage(); unrelated.clipDataStopRequest = CamAppMediaSyncClipDataStopRequest()
        var root = CamAppMediaSyncRootMessage(); root.messages = [response, unrelated]
        let result = try await catalog.accept(root.serializedData())
        XCTAssertEqual(result.clips.map(\.clipID), ["A"])
        XCTAssertEqual(result.unhandled.count, 1)
        guard case .clipDataStopRequest(_)? = result.unhandled.first?.message else { return XCTFail("Expected unrelated message") }
    }
}
