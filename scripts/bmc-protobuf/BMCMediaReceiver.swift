import Foundation

struct BMCMediaProgress: Sendable {
    let clipID: String
    let offset: UInt64
    let totalSize: UInt64
    let isClosed: Bool
}

/// Validates and appends ordered media-sync chunks to a caller-opened file.
/// The caller must not use the handle concurrently and owns the destination.
actor BMCMediaReceiver {
    private let handle: FileHandle
    private let clipID: String
    private let totalSize: UInt64
    private var offset: UInt64
    private var closed = false

    init(handle: FileHandle, clipID: String, offset: UInt64, totalSize: UInt64) throws {
        guard !clipID.isEmpty, offset <= totalSize, try handle.seekToEnd() == offset else {
            throw PortError.message("Media destination does not match the requested resume offset.")
        }
        self.handle = handle
        self.clipID = clipID
        self.offset = offset
        self.totalSize = totalSize
    }

    var isComplete: Bool { offset == totalSize }
    var progress: BMCMediaProgress { BMCMediaProgress(clipID: clipID, offset: offset, totalSize: totalSize, isClosed: closed) }

    func accept(_ chunk: CamAppMediaSyncClipDataResponse) throws {
        guard !closed, chunk.clipID == clipID, chunk.offset == offset,
              !chunk.data.isEmpty, UInt64(chunk.data.count) <= totalSize - offset else {
            throw PortError.message("Media chunk does not match the expected clip or offset.")
        }
        var checksum = BMCMediaChecksum()
        checksum.update(chunk.data)
        guard checksum.value == chunk.dataCrc32 else { throw PortError.message("Media chunk checksum failed.") }
        do {
            try handle.seek(toOffset: offset)
            try handle.write(contentsOf: chunk.data)
            offset += UInt64(chunk.data.count)
        } catch {
            try? handle.truncate(atOffset: offset)
            throw error
        }
    }

    func close() throws {
        guard !closed else { return }
        try handle.close()
        closed = true
    }
}

