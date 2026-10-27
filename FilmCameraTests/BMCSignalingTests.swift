import XCTest
@testable import FilmCamera

final class BMCSignalingTests: XCTestCase {
    func testDecodeHelloAndEncodeConnectionRequest() throws {
        let json = #"{"type":"hello_response","data":{"nonce":"aabb","info":{"uuid":"00000000-0000-0000-0000-000000000001","model_name":"phone","device_name":"Camera","slate_name":"A","proto_major":5,"proto_minor":0},"status":"ready"}}"#
        let decoded = try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(json.utf8))
        guard case let .helloResponse(hello) = decoded else { return XCTFail("Expected hello response") }
        XCTAssertEqual(hello.info.deviceName, "Camera")
        XCTAssertEqual(hello.info.major, 5)
        XCTAssertEqual(hello.nonce, "aabb")
        XCTAssertEqual(hello.status, "ready")
        let encoded = try JSONEncoder().encode(BMCSignalingMessage.connectionRequest("digest"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["type"] as? String, "conn_request")
        XCTAssertEqual((object["data"] as? [String: Any])?["password"] as? String, "digest")
    }
    func testRejectsUnknownTypeAndMissingPayload() {
        for text in [#"{"type":"other","data":{}}"#, #"{"type":"conn_request","data":{}}"#] {
            XCTAssertThrowsError(try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(text.utf8)))
        }
    }
    func testValueMessagesRoundTrip() throws {
        let messages: [BMCSignalingMessage] = [
            .connectionRequest("abc"), .connectionResponse("authorized"),
            .iceCandidate("candidate"), .sdpOffer("offer"), .sdpAnswer("answer"), .bye("app_suspended")
        ]
        for message in messages {
            let encoded = try JSONEncoder().encode(message)
            XCTAssertEqual(try JSONDecoder().decode(BMCSignalingMessage.self, from: encoded), message)
        }
    }
}
