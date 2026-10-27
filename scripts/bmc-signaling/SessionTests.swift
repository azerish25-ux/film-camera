import XCTest
import Foundation
@testable import BMCSignalingCheck

private actor FakeSignalingChannel: BMCSignalingChannel {
    var responses: [String]
    var sent: [String] = []
    var closed = false
    init(responses: [String]) { self.responses = responses }
    func send(text: String) async throws { sent.append(text) }
    func receiveText() async throws -> String {
        if !responses.isEmpty { return responses.removeFirst() }
        try await Task.sleep(nanoseconds: 60_000_000_000)
        throw PortError.message("Fake channel did not receive a response.")
    }
    func close() async { closed = true }
    func snapshot() -> ([String], Bool) { (sent, closed) }
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
}

