import XCTest
import SwiftProtobuf
@testable import BMCProtocolCheck

final class BMCProtocolTests: XCTestCase {
    func testStartRecordingWireFixture() throws {
        var request = CamAppControlStartRecordingRequest()
        request.dimScreen = true
        var message = CamAppControlControllerMessage()
        message.messageID = 7
        message.startRecordingRequest = request
        var packet = CamAppControlControllerMessages()
        packet.messages = [message]
        let data = try packet.serializedData()
        XCTAssertEqual(Array(data), [0x0a, 0x06, 0x08, 0x07, 0x4a, 0x02, 0x08, 0x01])
        let decoded = try CamAppControlControllerMessages(serializedBytes: data)
        XCTAssertEqual(decoded.messages.first?.messageID, 7)
        XCTAssertEqual(decoded.messages.first?.startRecordingRequest.dimScreen, true)
    }

    func testRecordingCommandsUseRecoveredEnvelopes() throws {
        let start = try BMCControlMessages.startRecording(messageID: 7, dimScreen: true)
        let stop = try BMCControlMessages.stopRecording(messageID: 7)
        XCTAssertEqual(Array(start), [0x0a, 0x06, 0x08, 0x07, 0x4a, 0x02, 0x08, 0x01])
        XCTAssertEqual(Array(stop), [0x0a, 0x04, 0x08, 0x07, 0x52, 0x00])
        let decoded = try CamAppControlControllerMessages(serializedBytes: stop)
        guard case .stopRecordingRequest(_)? = decoded.messages.first?.message else {
            return XCTFail("Expected a stop-recording request")
        }
    }
}

