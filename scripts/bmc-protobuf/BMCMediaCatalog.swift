import Foundation
import SwiftProtobuf

enum BMCMediaListScope: Sendable {
    case all, lastDay, lastHour
    case lastSession(Date?), currentSession(Date?)
}

struct BMCMediaCatalogResult: Sendable {
    let clips: [CamAppMediaSyncClip]
    let unhandled: [CamAppMediaSyncMessage]
}

/// Encodes recovered list requests and separates list responses from other
/// media-sync messages. The caller owns session timestamps and the receive loop.
actor BMCMediaCatalog {
    private let sender: any BMCMediaSender
    private var requesting = false

    init(sender: any BMCMediaSender) { self.sender = sender }

    func request(scope: BMCMediaListScope, now: Date = Date(), includeThumbnails: Bool) async throws {
        guard !requesting else { throw PortError.message("A media list request is already being sent.") }
        requesting = true
        defer { requesting = false }
        let cutoff: Date?
        switch scope {
        case .all: cutoff = nil
        case .lastDay: cutoff = now.addingTimeInterval(-86_400)
        case .lastHour: cutoff = now.addingTimeInterval(-3_600)
        case .lastSession(let date), .currentSession(let date): cutoff = date ?? now
        }
        var request = CamAppMediaSyncListClipsRequest()
        if let cutoff {
            let seconds = cutoff.timeIntervalSince1970
            guard seconds.isFinite, seconds >= 0, seconds < Double(UInt64.max) else { throw PortError.message("Invalid media list cutoff.") }
            request.cutoffTs = UInt64(seconds)
        }
        request.includeThumbnails = includeThumbnails
        var message = CamAppMediaSyncMessage(); message.listClipsRequest = request
        var root = CamAppMediaSyncRootMessage(); root.messages = [message]
        try await sender.sendBinary(root.serializedData())
    }

    func accept(_ data: Data) throws -> BMCMediaCatalogResult {
        let root = try CamAppMediaSyncRootMessage(serializedBytes: data)
        var clips: [CamAppMediaSyncClip] = []
        var unhandled: [CamAppMediaSyncMessage] = []
        for message in root.messages {
            if case .listClipsResponse(let response)? = message.message { clips.append(contentsOf: response.clips) }
            else { unhandled.append(message) }
        }
        return BMCMediaCatalogResult(clips: clips, unhandled: unhandled)
    }
}

