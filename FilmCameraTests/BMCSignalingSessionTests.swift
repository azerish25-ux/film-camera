import XCTest
import Foundation
@testable import FilmCamera

private actor FakeSignalingChannel: BMCSignalingChannel {
    var responses: [String]
    var sent: [String] = []
    var sentBinary: [Data] = []
    var closed = false
    let stallGoodbye: Bool
    init(responses: [String], stallGoodbye: Bool = false) { self.responses = responses; self.stallGoodbye = stallGoodbye }
    func send(text: String) async throws {
        if stallGoodbye && text.contains("bye_message") { try await Task.sleep(nanoseconds: 60_000_000_000) }
        sent.append(text)
    }
    func send(binary: Data) async throws { sentBinary.append(binary) }
    func receiveText() async throws -> String {
        if !responses.isEmpty { return responses.removeFirst() }
        try await Task.sleep(nanoseconds: 60_000_000_000)
        throw PortError.message("Fake channel did not receive a response.")
    }
    func receiveFrame() async throws -> BMCWebSocketFrame { .text(try await receiveText()) }
    func close() async { closed = true }
    func snapshot() -> ([String], Bool) { (sent, closed) }
    func binarySnapshot() -> [Data] { sentBinary }
}

final class BMCSignalingSessionTests: XCTestCase {
    private let participant = BMCParticipant(uuid: "00000000-0000-0000-0000-000000000001", modelName: "phone", deviceName: "Camera", slateName: "A", major: 5, minor: 0)

    func testAuthorizesInOrderAndKeepsChannelOpen() async throws {
        let nonce = (0..<64).map { String(format: "%02x", $0) }.joined()
        let hello = #"{"type":"hello_response","data":{"nonce":"\#(nonce)","info":{"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0},"status":"ready"}}"#
        let channel = FakeSignalingChannel(responses: [hello, #"{"type":"conn_response","data":{"status":"authorized"}}"#])
        try await BMCSignalingAuthenticator.authenticate(channel: channel, participant: participant, password: "test", nonce: Data(repeating: 1, count: 32))
        let (sent, closed) = await channel.snapshot()
        XCTAssertFalse(closed)
        XCTAssertEqual(sent.count, 2)
        guard case .helloRequest = try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(sent[0].utf8)),
              case .connectionRequest(let digest) = try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(sent[1].utf8)) else { return XCTFail("Unexpected handshake messages") }
        XCTAssertEqual(digest, "6df18b13090db32b14b0e54842a4a2f1b7c94c2b411d86f250aa0b37443a61f1")
    }

    func testTimeoutClosesChannel() async throws {
        let channel = FakeSignalingChannel(responses: [])
        do {
            try await BMCSignalingAuthenticator.authenticate(channel: channel, participant: participant, password: "test", nonce: Data(repeating: 1, count: 32), timeoutNanoseconds: 20_000_000)
            XCTFail("Expected a timeout")
        } catch { }
        let (_, closed) = await channel.snapshot()
        XCTAssertTrue(closed)
    }

    func testUnexpectedResponseClosesChannel() async throws {
        let channel = FakeSignalingChannel(responses: [#"{"type":"conn_response","data":{"status":"authorized"}}"#])
        do {
            try await BMCSignalingAuthenticator.authenticate(channel: channel, participant: participant, password: "test", nonce: Data(repeating: 1, count: 32))
            XCTFail("Expected an out-of-order response to fail")
        } catch { }
        let (sent, closed) = await channel.snapshot()
        XCTAssertTrue(closed)
        XCTAssertEqual(sent.count, 1)
    }

    func testBinaryMessagesRequireAuthorization() async throws {
        let nonce = (0..<64).map { String(format: "%02x", $0) }.joined()
        let hello = #"{"type":"hello_response","data":{"nonce":"\#(nonce)","info":{"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0},"status":"ready"}}"#
        let channel = FakeSignalingChannel(responses: [hello, #"{"type":"conn_response","data":{"status":"authorized"}}"#])
        let session = BMCRemoteSignalingSession(channel: channel)
        do {
            try await session.sendBinary(Data([1, 2, 3]))
            XCTFail("Expected authorization to be required")
        } catch { }
        do {
            try await session.sendSignaling(.sdpOffer("offer"))
            XCTFail("Expected authorization to be required")
        } catch { }
        try await session.authorize(participant: participant, password: "test")
        try await session.sendBinary(Data([1, 2, 3]))
        try await session.sendSignaling(.sdpOffer("offer"))
        let sent = await channel.binarySnapshot()
        XCTAssertEqual(sent, [Data([1, 2, 3])])
        let (texts, _) = await channel.snapshot()
        let last = try XCTUnwrap(texts.last)
        XCTAssertEqual(try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(last.utf8)), .sdpOffer("offer"))
        await session.close()
        let (afterClose, closed) = await channel.snapshot()
        let goodbye = try XCTUnwrap(afterClose.last)
        XCTAssertEqual(try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(goodbye.utf8)), .bye("app_suspended"))
        XCTAssertTrue(closed)
    }

    func testAuthorizedSessionCanSendMediaRangeRequest() async throws {
        let nonce = (0..<64).map { String(format: "%02x", $0) }.joined()
        let hello = #"{"type":"hello_response","data":{"nonce":"\#(nonce)","info":{"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0},"status":"ready"}}"#
        let channel = FakeSignalingChannel(responses: [hello, #"{"type":"conn_response","data":{"status":"authorized"}}"#])
        let session = BMCRemoteSignalingSession(channel: channel)
        try await session.authorize(participant: participant, password: "test", nonce: Data(repeating: 1, count: 32))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data()))
        defer { try? FileManager.default.removeItem(at: url) }
        let receiver = try BMCMediaReceiver(handle: FileHandle(forWritingTo: url), clipID: "A", offset: 0, totalSize: 4)
        let transfer = BMCMediaTransfer(sender: session, receiver: receiver)
        try await transfer.requestRemaining()
        let packets = await channel.binarySnapshot()
        XCTAssertEqual(packets, [Data([0x0a, 0x07, 0x22, 0x05, 0x0a, 0x01, 0x41, 0x18, 0x04])])
        try await receiver.close()
        await session.close()
    }

    func testCloseCancelsStalledGoodbye() async throws {
        let nonce = (0..<64).map { String(format: "%02x", $0) }.joined()
        let hello = #"{"type":"hello_response","data":{"nonce":"\#(nonce)","info":{"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0},"status":"ready"}}"#
        let channel = FakeSignalingChannel(responses: [hello, #"{"type":"conn_response","data":{"status":"authorized"}}"#], stallGoodbye: true)
        let session = BMCRemoteSignalingSession(channel: channel)
        try await session.authorize(participant: participant, password: "test", nonce: Data(repeating: 1, count: 32))
        await session.close()
        let (_, closed) = await channel.snapshot()
        XCTAssertTrue(closed)
    }
}
