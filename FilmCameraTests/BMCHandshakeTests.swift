import XCTest
@testable import FilmCamera

final class BMCHandshakeTests: XCTestCase {
    func testClientHandshakeRequiresOrderedAuthorization() throws {
        let peer = BMCParticipant(uuid: "00000000-0000-0000-0000-000000000001", modelName: "phone", deviceName: "Camera", slateName: "A", major: 5, minor: 0)
        var client = BMCClientHandshake()
        XCTAssertThrowsError(try client.receive(.connectionResponse("authorized"), password: "test"))
        let hello = try client.begin(info: peer, nonce: Data(repeating: 1, count: 32))
        guard case let .helloRequest(payload) = hello else { return XCTFail("Expected hello request") }
        XCTAssertEqual(payload.nonce.count, 64)
        let challenge = BMCHello(nonce: (0..<64).map { String(format: "%02x", $0) }.joined(), info: peer, controllerInfo: nil, status: "ready")
        let response = try client.receive(.helloResponse(challenge), password: "test")
        XCTAssertEqual(response, .connectionRequest("6df18b13090db32b14b0e54842a4a2f1b7c94c2b411d86f250aa0b37443a61f1"))
        XCTAssertNil(try client.receive(.connectionResponse("authorized"), password: "test"))
        XCTAssertTrue(client.authorized)
        XCTAssertThrowsError(try client.receive(.helloResponse(challenge), password: "test"))
    }
    func testBusyAndMalformedChallengeDoNotAuthorize() throws {
        let peer = BMCParticipant(uuid: "1", modelName: "phone", deviceName: "Camera", slateName: "A", major: 5, minor: 0)
        var client = BMCClientHandshake()
        _ = try client.begin(info: peer, nonce: Data(repeating: 0, count: 32))
        XCTAssertThrowsError(try client.receive(.helloResponse(BMCHello(nonce: "00", info: peer, controllerInfo: nil, status: "busy")), password: "test"))
        XCTAssertFalse(client.authorized)
    }
}
