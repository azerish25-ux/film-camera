import XCTest
import SwiftProtobuf
@testable import BMCProtocolCheck

final class ProtocolTests: XCTestCase {
    func testStartRecordingWireFixture() throws {
        var request = CamAppControlStartRecordingRequest()
        request.dimScreen = true
        var message = CamAppControlControllerMessage()
        message.messageID = 7
        message.startRecordingRequest = request
        var packet = CamAppControlControllerMessages()
        packet.messages = [message]
        let bytes = try packet.serializedData()
        XCTAssertEqual(Array(bytes), [0x0a, 0x06, 0x08, 0x07, 0x4a, 0x02, 0x08, 0x01])
        let decoded = try CamAppControlControllerMessages(serializedData: bytes)
        XCTAssertEqual(decoded.messages.first?.messageID, 7)
        XCTAssertEqual(decoded.messages.first?.startRecordingRequest.dimScreen, true)
    }
}
