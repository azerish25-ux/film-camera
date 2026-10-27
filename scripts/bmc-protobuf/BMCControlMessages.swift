import Foundation
import SwiftProtobuf

/// Encodes the recovered v5 recording requests. Sending them and handling the
/// corresponding responses require an authorized data-channel session.
enum BMCControlMessages {
    static func startRecording(messageID: UInt64, dimScreen: Bool) throws -> Data {
        var request = CamAppControlStartRecordingRequest()
        request.dimScreen = dimScreen
        var message = CamAppControlControllerMessage()
        message.messageID = messageID
        message.startRecordingRequest = request
        return try packet(message)
    }

    static func stopRecording(messageID: UInt64) throws -> Data {
        var message = CamAppControlControllerMessage()
        message.messageID = messageID
        message.stopRecordingRequest = CamAppControlStopRecordingRequest()
        return try packet(message)
    }

    private static func packet(_ message: CamAppControlControllerMessage) throws -> Data {
        var messages = CamAppControlControllerMessages()
        messages.messages = [message]
        return try messages.serializedData()
    }
}

