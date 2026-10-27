import Foundation
import XCTest
import SwiftProtobuf
@testable import BMCProtocolCheck

private actor FakeMediaSender: BMCMediaSender {
    private var packets: [Data] = []
    func sendBinary(_ data: Data) async throws { packets.append(data) }
    func sent() -> [Data] { packets }
}

final class BMCMediaTransferTests: XCTestCase {
    func testRequestsRemainingRangeAndRoutesValidatedChunk() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("12".utf8)))
        defer { try? FileManager.default.removeItem(at: url) }
        let receiver = try BMCMediaReceiver(handle: FileHandle(forWritingTo: url), clipID: "A", offset: 2, totalSize: 6)
        let sender = FakeMediaSender()
        let transfer = BMCMediaTransfer(sender: sender, receiver: receiver)
        try await transfer.requestRemaining()
        try await transfer.requestStop()
        let sent = await sender.sent()
        XCTAssertEqual(sent, [Data([0x0a, 0x09, 0x22, 0x07, 0x0a, 0x01, 0x41, 0x10, 0x02, 0x18, 0x04]), Data([0x0a, 0x05, 0x2a, 0x03, 0x0a, 0x01, 0x41])])

        var chunk = CamAppMediaSyncClipDataResponse()
        chunk.clipID = "A"; chunk.offset = 2; chunk.data = Data("3456".utf8)
        var crc = BMCMediaChecksum(); crc.update(chunk.data); chunk.dataCrc32 = crc.value
        var response = CamAppMediaSyncMessage(); response.clipDataResponse = chunk
        var unrelated = CamAppMediaSyncMessage(); unrelated.listClipsResponse = CamAppMediaSyncListClipsResponse()
        var packet = CamAppMediaSyncRootMessage(); packet.messages = [response, unrelated]
        let unhandled = try await transfer.accept(packet.serializedData())
        XCTAssertEqual(unhandled.count, 1)
        guard case .listClipsResponse(_)? = unhandled.first?.message else { return XCTFail("Expected unrelated response") }
        let complete = await receiver.isComplete
        XCTAssertTrue(complete)
        XCTAssertEqual(try Data(contentsOf: url), Data("123456".utf8))
        try await receiver.close()
    }
}

