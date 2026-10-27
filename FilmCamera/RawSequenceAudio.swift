import Foundation

enum RawSequenceAudio {
    static func extract(directory:URL,manifest:RawSequenceManifest,startNs:Int64,endNs:Int64,to destination:URL) throws -> Bool {
        guard manifest.complete,!manifest.timelapse,let origin = manifest.audioStartTimestampNs,let rate = manifest.audioSampleRate,let channels = manifest.audioChannels else {return false}
        guard origin >= 0,startNs >= 0,endNs > startNs,(8000...192000).contains(rate),(1...8).contains(channels) else {throw PortError.message("Invalid sequence audio range.")}
        let source = directory.appendingPathComponent("audio.wav").resolvingSymlinksInPath()
        guard source.path.hasPrefix(directory.resolvingSymlinksInPath().path+"/") else {throw PortError.message("Audio sidecar leaves its RAW sequence.")}
        guard FileManager.default.fileExists(atPath:source.path) else {return false}
        let input = try FileHandle(forReadingFrom:source); defer {try? input.close()}
        guard let header = try input.read(upToCount:44),header.count == 44,
              String(data:header.prefix(4),encoding:.ascii) == "RIFF",String(data:header.subdata(in:36..<40),encoding:.ascii) == "data",
              try header.motionUInt32(24) == UInt32(rate),(Int(header[22]) | Int(header[23])<<8) == channels,
              header[20] == 1,header[34] == 16 else {throw PortError.message("Unsupported sequence audio sidecar.")}
        let available = Int64(try header.motionUInt32(40))/Int64(channels*2)
        guard available > 0 else {return false}
        let count = Int64((Double(endNs-startNs)*Double(rate)/1e9).rounded())
        guard endNs > startNs,count > 0,count <= Int64(UInt32.max-36)/Int64(channels*2) else {throw PortError.message("Selected audio duration exceeds RIFF limits.")}
        let offset = Int64((Double(startNs-origin)*Double(rate)/1e9).rounded())
        let prefix = min(count,max(0,-offset)),first = max(0,offset)
        let writer = try RawPCMWriter(url:destination,rate:rate,channels:channels)
        var written = prefix
        // Padding is streamed in one-second blocks to keep memory bounded.
        var lead = prefix
        while lead > 0 {let n = min(Int64(rate),lead); try writer.append(Data(repeating:0,count:Int(n)*channels*2),atFrame:prefix-lead); lead -= n}
        try input.seek(toOffset:UInt64(44+first*Int64(channels*2)))
        var remaining = min(count-written,max(0,available-first))
        while remaining > 0 {
            let frames = min(4096,remaining)
            guard let data = try input.read(upToCount:Int(frames)*channels*2),data.count == Int(frames)*channels*2 else {throw PortError.message("Truncated microphone sidecar.")}
            try writer.append(data,atFrame:written); written += frames; remaining -= frames
        }
        while written < count {let n = min(Int64(rate),count-written); try writer.append(Data(repeating:0,count:Int(n)*channels*2),atFrame:written); written += n}
        try writer.finish(); return true
    }
}
