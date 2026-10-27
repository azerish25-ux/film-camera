import Foundation
import SwiftProtobuf

protocol BMCMediaSender: Sendable {
    func sendBinary(_ data: Data) async throws
}

/// Builds media-sync requests and routes matching chunks to a validated file
/// receiver. The caller owns the WebSocket receive loop and any retries.
actor BMCMediaTransfer {
    private let sender: any BMCMediaSender
    private let receiver: BMCMediaReceiver
    private var requesting = false
    private var handling = false

    init(sender: any BMCMediaSender, receiver: BMCMediaReceiver) {
        self.sender = sender
        self.receiver = receiver
    }

    func requestRemaining() async throws {
        guard !requesting else { throw PortError.message("A media request is already being sent.") }
        requesting = true
        defer { requesting = false }
        let progress = await receiver.progress
        guard !progress.isClosed, progress.offset < progress.totalSize else { throw PortError.message("The media transfer is closed or complete.") }
        var request = CamAppMediaSyncClipDataStartRequest()
        request.clipID = progress.clipID
        request.offset = progress.offset
        request.size = progress.totalSize - progress.offset
        var message = CamAppMediaSyncMessage(); message.clipDataStartRequest = request
        var root = CamAppMediaSyncRootMessage(); root.messages = [message]
        try await sender.sendBinary(root.serializedData())
    }

    func requestStop() async throws {
        guard !requesting else { throw PortError.message("A media request is already being sent.") }
        requesting = true
        defer { requesting = false }
        let progress = await receiver.progress
        guard !progress.isClosed else { throw PortError.message("The media transfer is closed.") }
        var request = CamAppMediaSyncClipDataStopRequest(); request.clipID = progress.clipID
        var message = CamAppMediaSyncMessage(); message.clipDataStopRequest = request
        var root = CamAppMediaSyncRootMessage(); root.messages = [message]
        try await sender.sendBinary(root.serializedData())
    }

    /// The APK retries a bad chunk by sending stop and start in one envelope.
    func requestRetry() async throws {
        guard !requesting else { throw PortError.message("A media request is already being sent.") }
        requesting = true
        defer { requesting = false }
        let progress = await receiver.progress
        guard !progress.isClosed, progress.offset < progress.totalSize else { throw PortError.message("The media transfer is closed or complete.") }
        var stop = CamAppMediaSyncClipDataStopRequest(); stop.clipID = progress.clipID
        var start = CamAppMediaSyncClipDataStartRequest()
        start.clipID = progress.clipID; start.offset = progress.offset; start.size = progress.totalSize - progress.offset
        var stopMessage = CamAppMediaSyncMessage(); stopMessage.clipDataStopRequest = stop
        var startMessage = CamAppMediaSyncMessage(); startMessage.clipDataStartRequest = start
        var root = CamAppMediaSyncRootMessage(); root.messages = [stopMessage, startMessage]
        try await sender.sendBinary(root.serializedData())
    }

    /// Returns messages that do not belong to this transfer for the caller to
    /// route elsewhere; matching chunks are validated and written in order.
    func accept(_ data: Data) async throws -> [CamAppMediaSyncMessage] {
        guard !handling else { throw PortError.message("A media response is already being processed.") }
        handling = true
        defer { handling = false }
        let root = try CamAppMediaSyncRootMessage(serializedBytes: data)
        let progress = await receiver.progress
        let clipID = progress.clipID
        var unhandled: [CamAppMediaSyncMessage] = []
        for message in root.messages {
            if case .clipDataResponse(let chunk)? = message.message, chunk.clipID == clipID {
                try await receiver.accept(chunk)
            } else { unhandled.append(message) }
        }
        return unhandled
    }
}

