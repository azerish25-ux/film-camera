import Foundation
import AVFoundation

enum MotionAudio {
    /// Extract 16-bit PCM chunks to a bounded RIFF WAV, aligned to the selected frame range.
    static func extract(container:MotionContainer,range:ClosedRange<Int>,to destination:URL) throws -> Bool {
        guard container.version == 3 else {return false}
        let extra = container.metadata["extraData"] as? [String:Any] ?? container.metadata
        guard let rate = (extra["audioSampleRate"] as? NSNumber)?.intValue,let channels = (extra["audioChannels"] as? NSNumber)?.intValue,rate >= 8000,rate <= 192000,channels > 0,channels <= 8 else {return false}
        let startTime = container.frames[range.lowerBound].timestamp
        let finalTime = container.frames[range.upperBound].timestamp
        let duration = max(1,Int64(1e9/max(0.001,container.fps)))
        guard finalTime <= Int64.max-duration else {throw PortError.message("Audio timestamp overflow.")}
        let endTime = finalTime+duration
        var cursor = 16+Int(try container.data.motionUInt32(12)), chunks: [(Range<Int>,Int64)] = []
        while cursor < container.indexStart {
            let item = try container.chunk(at:cursor)
            if item.type == 5 {
                let meta = try container.chunk(at:item.next)
                guard meta.type == 6,meta.payload.count >= 8,item.payload.count%(channels*2) == 0 else {throw PortError.message("Invalid PCM audio chunk.")}
                let time = try container.data.motionUInt64(meta.payload.lowerBound)
                guard time <= UInt64(Int64.max) else {throw PortError.message("Invalid audio timestamp.")}
                chunks.append((item.payload,Int64(time))); cursor = meta.next
            } else if item.type == 4 {
                guard item.payload.count >= 16 else {throw PortError.message("Invalid audio index.")}
                let count = try container.data.motionUInt64(item.payload.lowerBound)
                guard count <= UInt64((container.indexStart-item.next)/16) else {throw PortError.message("Invalid audio offset table.")}
                cursor = item.next+Int(count)*16
            } else {cursor = item.next}
        }
        guard !chunks.isEmpty else {return false}
        let samples = Int((Double(endTime-startTime)/1e9*Double(rate)).rounded(.up))
        guard samples > 0,samples <= 256_000_000/(channels*2) else {throw PortError.message("Selected audio exceeds the 256 MB extraction limit.")}
        var pcm = Data(repeating:0,count:samples*channels*2)
        for (payload,time) in chunks {
            let sourceSamples = payload.count/(channels*2)
            let position = Int((Double(time-startTime)*Double(rate)/1e9).rounded())
            let skip = max(0,-position), target = max(0,position)
            let count = min(sourceSamples-skip,samples-target)
            if count > 0 {
                let from = payload.lowerBound+skip*channels*2
                let to = target*channels*2
                pcm.replaceSubrange(to..<to+count*channels*2,with:container.data[from..<from+count*channels*2])
            }
        }
        var wav = Data("RIFF".utf8); wav.motionAppend(UInt32(36+pcm.count)); wav.append(Data("WAVEfmt ".utf8))
        wav.motionAppend(UInt32(16)); wav.motionAppend(UInt16(1)); wav.motionAppend(UInt16(channels)); wav.motionAppend(UInt32(rate))
        wav.motionAppend(UInt32(rate*channels*2)); wav.motionAppend(UInt16(channels*2)); wav.motionAppend(UInt16(16))
        wav.append(Data("data".utf8)); wav.motionAppend(UInt32(pcm.count)); wav.append(pcm)
        try wav.write(to:destination,options:.atomic); return true
    }
    static func mux(video:URL,audio:URL,to destination:URL) async throws {
        let movie = AVURLAsset(url:video),sound = AVURLAsset(url:audio),composition = AVMutableComposition()
        let duration = try await movie.load(.duration)
        guard let videoTrack = try await movie.loadTracks(withMediaType:.video).first,let audioTrack = try await sound.loadTracks(withMediaType:.audio).first,
              let v = composition.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid),let a = composition.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid) else {throw PortError.message("Cannot compose movie/audio tracks.")}
        try v.insertTimeRange(CMTimeRange(start:.zero,duration:duration),of:videoTrack,at:.zero)
        v.preferredTransform = try await videoTrack.load(.preferredTransform)
        let audioDuration = try await sound.load(.duration)
        try a.insertTimeRange(CMTimeRange(start:.zero,duration:CMTimeMinimum(duration,audioDuration)),of:audioTrack,at:.zero)
        guard let export = AVAssetExportSession(asset:composition,presetName:AVAssetExportPresetPassthrough) else {throw PortError.message("Audio muxer is unavailable.")}
        export.outputURL = destination; export.outputFileType = .mov
        await withTaskCancellationHandler(operation:{await export.export()},onCancel:{export.cancelExport()})
        if Task.isCancelled {try? FileManager.default.removeItem(at:destination); throw CancellationError()}
        guard export.status == .completed else {try? FileManager.default.removeItem(at:destination); throw export.error ?? PortError.message("Audio muxing failed.")}
    }
}
