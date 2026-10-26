import Foundation

/// Streaming signed 16-bit little-endian PCM. Caller serializes access.
final class RawPCMWriter {
    let rate: Int
    let channels: Int
    private let handle: FileHandle
    private var frames: Int64 = 0
    private var closed = false
    init(url:URL,rate:Int,channels:Int) throws {
        guard (8000...192000).contains(rate),(1...8).contains(channels) else {throw PortError.message("Unsupported PCM microphone format.")}
        self.rate = rate; self.channels = channels
        guard FileManager.default.createFile(atPath:url.path,contents:Self.header(bytes:0,rate:rate,channels:channels)) else {throw PortError.message("Cannot create microphone sidecar.")}
        handle = try FileHandle(forUpdating:url); try handle.seekToEnd()
    }
    static func header(bytes:UInt32,rate:Int,channels:Int) -> Data {
        var d = Data("RIFF".utf8); d.motionAppend(UInt32(36)+bytes); d.append(Data("WAVEfmt ".utf8))
        d.motionAppend(UInt32(16)); d.motionAppend(UInt16(1)); d.motionAppend(UInt16(channels)); d.motionAppend(UInt32(rate))
        d.motionAppend(UInt32(rate*channels*2)); d.motionAppend(UInt16(channels*2)); d.motionAppend(UInt16(16))
        d.append(Data("data".utf8)); d.motionAppend(bytes); return d
    }
    func append(_ data:Data,atFrame requested:Int64) throws {
        guard !closed,data.count%(channels*2) == 0,requested >= 0 else {throw PortError.message("Invalid microphone buffer.")}
        let gap = max(0,requested-frames)
        guard gap <= Int64(rate*5) else {throw PortError.message("Microphone interruption exceeded five seconds.")}
        let skipped = max(0,frames-requested),incoming = Int64(data.count/(channels*2))
        let available = max(0,incoming-skipped),bytes = (frames+gap+available)*Int64(channels*2)
        guard bytes <= Int64(UInt32.max)-36 else {throw PortError.message("PCM sidecar reached the RIFF file-size limit.")}
        if gap > 0 {try zeros(bytes:Int(gap)*channels*2); frames += gap}
        if available > 0 {try handle.write(contentsOf:data.subdata(in:Int(skipped)*channels*2..<data.count)); frames += available}
    }
    private func zeros(bytes:Int) throws {
        var remaining = bytes; let block = Data(repeating:0,count:16_384)
        while remaining > 0 {let n = min(remaining,block.count); try handle.write(contentsOf:block.prefix(n)); remaining -= n}
    }
    func checkpoint() throws {
        guard !closed else {return}; try handle.seek(toOffset:0)
        try handle.write(contentsOf:Self.header(bytes:UInt32(frames*Int64(channels*2)),rate:rate,channels:channels)); try handle.seekToEnd()
    }
    func trimEnd(toFrame count:Int64) throws {
        guard !closed,count >= 0 else {return}; frames = min(frames,count)
        try handle.truncate(atOffset:UInt64(44+frames*Int64(channels*2))); try handle.seekToEnd()
    }
    func finish() throws {guard !closed else {return}; try checkpoint(); try handle.synchronize(); try handle.close(); closed = true}
    deinit {try? handle.close()}
}
