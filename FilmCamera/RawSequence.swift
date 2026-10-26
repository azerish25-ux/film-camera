import Foundation

struct RawSequenceManifest: Codable {
    struct Frame: Codable {let file:String; let timestampNs:Int64}
    var frames: [Frame] = []
    var complete = false
    var endTimestampNs: Int64 = 0
    var timelapse = false
    var version = 1
    var audioStartTimestampNs: Int64?
    var audioSampleRate: Int?
    var audioChannels: Int?
    var captureSettings: FilmSettings?
    var gyroOriginTimestampNs: Int64?
    static func load(_ directory:URL) throws -> RawSequenceManifest {
        let file = directory.appendingPathComponent("sequence.json")
        guard (try file.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0) < 128_000_000 else {throw PortError.message("RAW sequence index is too large.")}
        let manifest = try JSONDecoder().decode(Self.self,from:Data(contentsOf:file))
        guard manifest.version == 1,manifest.frames.count <= 1_000_000 else {throw PortError.message("Unsupported RAW sequence index.")}
        let root = directory.resolvingSymlinksInPath().standardizedFileURL.path+"/"
        var previous: Int64 = -1
        for frame in manifest.frames {
            guard frame.timestampNs >= 0,frame.timestampNs <= 8_000_000_000_000_000_000,frame.timestampNs > previous,!frame.file.contains("/"),!frame.file.contains("\\"),!frame.file.contains(".."),frame.file.lowercased().hasSuffix(".dng") else {throw PortError.message("Invalid RAW sequence frame entry.")}
            let url = directory.appendingPathComponent(frame.file).resolvingSymlinksInPath().standardizedFileURL
            guard url.path.hasPrefix(root),(try url.resourceValues(forKeys:[.isRegularFileKey]).isRegularFile) == true else {throw PortError.message("RAW sequence frame is missing or leaves its directory.")}
            previous = frame.timestampNs
        }
        if manifest.complete,let last = manifest.frames.last {guard manifest.endTimestampNs > last.timestampNs,manifest.endTimestampNs <= 8_000_000_000_000_000_000 else {throw PortError.message("Invalid RAW sequence end time.")}}
        if let origin = manifest.audioStartTimestampNs {guard origin >= 0,let rate = manifest.audioSampleRate,(8000...192000).contains(rate),let channels = manifest.audioChannels,(1...8).contains(channels) else {throw PortError.message("Invalid sequence audio metadata.")}}
        if let origin = manifest.gyroOriginTimestampNs {guard origin >= 0,origin <= 8_000_000_000_000_000_000 else {throw PortError.message("Invalid sequence gyro timestamp.")}}
        return manifest
    }
    var fps: Double {
        guard !timelapse,frames.count > 1,let first = frames.first,let last = frames.last,last.timestampNs > first.timestampNs else {return timelapse ? 24 : 1}
        return Double(frames.count-1)*1e9/Double(last.timestampNs-first.timestampNs)
    }
}

/// Preserves each original DNG and journals completed frames atomically.
actor RawSequenceWriter {
    nonisolated let url: URL
    private var manifest: RawSequenceManifest
    private var audio: RawPCMWriter?
    private var closed = false
    private var audioCutoff: Int64?
    init(url:URL,timelapse:Bool,settings:FilmSettings? = nil) throws {
        self.url = url; manifest = RawSequenceManifest(timelapse:timelapse,captureSettings:settings)
        guard !FileManager.default.fileExists(atPath:url.path) else {throw PortError.message("RAW sequence already exists.")}
        try FileManager.default.createDirectory(at:url,withIntermediateDirectories:true)
        try JSONEncoder().encode(manifest).write(to:url.appendingPathComponent("sequence.json"),options:.atomic)
    }
    func appendFrame(_ data:Data,timestampNs:Int64) throws {
        guard !closed,timestampNs >= 0,timestampNs <= 7_999_999_999_999_000_000,manifest.frames.count < 1_000_000,data.count >= 8,data.count <= 128_000_000,
              (Array(data.prefix(2)) == [0x49,0x49] || Array(data.prefix(2)) == [0x4d,0x4d]),
              manifest.frames.last.map({timestampNs > $0.timestampNs}) ?? true else {throw PortError.message("Invalid or out-of-order RAW photo frame.")}
        let name = String(format:"%06d.dng",manifest.frames.count)
        try data.write(to:url.appendingPathComponent(name),options:.atomic)
        manifest.frames.append(.init(file:name,timestampNs:timestampNs))
        try audio?.checkpoint(); try journal()
    }
    func appendPCM(_ data:Data,timestampNs:Int64,sampleRate:Int,channels:Int) throws {
        guard !closed,!manifest.timelapse,timestampNs >= 0 else {return}
        if let audioCutoff,timestampNs >= audioCutoff {return}
        if audio == nil {
            audio = try RawPCMWriter(url:url.appendingPathComponent("audio.wav"),rate:sampleRate,channels:channels)
            manifest.audioStartTimestampNs = timestampNs; manifest.audioSampleRate = sampleRate; manifest.audioChannels = channels
        }
        guard sampleRate == manifest.audioSampleRate,channels == manifest.audioChannels,let start = manifest.audioStartTimestampNs else {throw PortError.message("Microphone format changed during RAW recording.")}
        var payload = data
        if let cutoff = audioCutoff {
            let frames = max(0,Int(Double(cutoff-timestampNs)*Double(sampleRate)/1e9))
            payload = data.prefix(min(data.count,frames*channels*2))
        }
        try audio?.append(payload,atFrame:Int64((Double(timestampNs-start)*Double(sampleRate)/1e9).rounded()))
    }
    func setGyroOrigin(_ timestampNs:Int64) {manifest.gyroOriginTimestampNs = timestampNs}
    func stopAudio(at timestampNs:Int64) {audioCutoff = timestampNs}
    func finish(endTimestampNs:Int64) throws {
        guard !closed else {return}; closed = true
        guard let last = manifest.frames.last else {try audio?.finish(); try? FileManager.default.removeItem(at:url); throw PortError.message("No RAW frames were captured.")}
        manifest.endTimestampNs = max(last.timestampNs+1_000_000,endTimestampNs)
        if let origin = manifest.audioStartTimestampNs,let rate = manifest.audioSampleRate {try audio?.trimEnd(toFrame:max(0,Int64(Double((audioCutoff ?? manifest.endTimestampNs)-origin)*Double(rate)/1e9)))}
        try audio?.finish(); manifest.complete = true; try journal()
    }
    private func journal() throws {try JSONEncoder().encode(manifest).write(to:url.appendingPathComponent("sequence.json"),options:.atomic)}
}
