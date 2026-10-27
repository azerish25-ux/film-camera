import AVFoundation
import CoreMedia

/// Remuxes a simple MOV and associates a single TimeCode32 sample with its
/// video tracks. Source is never modified and unsupported extra tracks fail.
enum BMCTimecodeWriter {
    static func write(source: URL, destination: URL, timecode: BMCTimecode, framesPerSecond: Int) async throws {
        guard framesPerSecond == timecode.framesPerSecond, !FileManager.default.fileExists(atPath: destination.path), source != destination else {
            throw PortError.message("Cannot create timecode output at this location.")
        }
        let asset = AVURLAsset(url: source)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)
        guard duration.isNumeric, duration.seconds > 0, tracks.contains(where: { $0.mediaType == .video }),
              tracks.allSatisfy({ $0.mediaType == .video || $0.mediaType == .audio }) else {
            throw PortError.message("This movie contains tracks that the timecode writer cannot preserve.")
        }
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mov)
        do {
            writer.metadata = try await asset.load(.metadata)
            var streams: [(AVAssetReaderTrackOutput, AVAssetWriterInput)] = []
            var videoInputs: [AVAssetWriterInput] = []
            for track in tracks {
                let descriptions = try await track.load(.formatDescriptions)
                guard let format = descriptions.first else { throw PortError.message("Movie track format is unavailable.") }
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
                let input = AVAssetWriterInput(mediaType: track.mediaType, outputSettings: nil, sourceFormatHint: format)
                if track.mediaType == .video { input.transform = try await track.load(.preferredTransform); videoInputs.append(input) }
                guard reader.canAdd(output), writer.canAdd(input) else { throw PortError.message("Movie tracks cannot be remuxed.") }
                reader.add(output); writer.add(input); streams.append((output, input))
            }
            var description: CMTimeCodeFormatDescription?
            let frameDuration = Int64((Float(1) / Float(framesPerSecond) * 1_000_000_000).rounded())
            let formatStatus = CMTimeCodeFormatDescriptionCreate(allocator: kCFAllocatorDefault, timeCodeFormatType: kCMTimeCodeFormatType_TimeCode32, frameDuration: CMTime(value: frameDuration, timescale: 1_000_000_000), frameQuanta: UInt32(framesPerSecond), flags: 0, extensions: nil, formatDescriptionOut: &description)
            guard formatStatus == noErr, let description else { throw PortError.message("Cannot create timecode format.") }
            let input = AVAssetWriterInput(mediaType: .timecode, outputSettings: nil, sourceFormatHint: description)
            guard writer.canAdd(input) else { throw PortError.message("Timecode output is unavailable.") }
            writer.add(input)
            for video in videoInputs {
                let association = AVAssetTrack.AssociationType.timecode.rawValue
                guard video.canAddTrackAssociation(withTrackOf: input, type: association) else { throw PortError.message("Cannot associate the timecode track.") }
                video.addTrackAssociation(withTrackOf: input, type: association)
            }
            let sample = try sampleBuffer(timecode: timecode, duration: duration, description: description)
            guard writer.startWriting(), reader.startReading() else { throw writer.error ?? reader.error ?? PortError.message("Cannot begin timecode remux.") }
            writer.startSession(atSourceTime: .zero)
            var lastProgress = Date()
            while !input.isReadyForMoreMediaData {
                try Task.checkCancellation()
                guard writer.status == .writing, Date().timeIntervalSince(lastProgress) < 60 else { throw writer.error ?? PortError.message("Timecode writer stalled.") }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
            guard input.append(sample) else { throw writer.error ?? PortError.message("Cannot write timecode sample.") }
            input.markAsFinished()
            while !streams.isEmpty {
                try Task.checkCancellation()
                guard writer.status == .writing, reader.status != .failed, reader.status != .cancelled else { throw writer.error ?? reader.error ?? PortError.message("Timecode remux stopped.") }
                var progressed = false
                for index in streams.indices.reversed() {
                    let (output, streamInput) = streams[index]
                    guard streamInput.isReadyForMoreMediaData else { continue }
                    if let sample = output.copyNextSampleBuffer() {
                        guard streamInput.append(sample) else { throw writer.error ?? PortError.message("Cannot write movie sample.") }
                    } else { streamInput.markAsFinished(); streams.remove(at: index) }
                    progressed = true
                }
                if progressed { lastProgress = Date() }
                else {
                    guard Date().timeIntervalSince(lastProgress) < 60 else { throw PortError.message("Timecode remux stalled.") }
                    try await Task.sleep(nanoseconds: 10_000_000)
                }
            }
            guard reader.status == .completed else { throw reader.error ?? PortError.message("Timecode source did not finish reading.") }
            await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? PortError.message("Timecode output failed.") }
        } catch {
            reader.cancelReading(); writer.cancelWriting()
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    private static func sampleBuffer(timecode: BMCTimecode, duration: CMTime, description: CMTimeCodeFormatDescription) throws -> CMSampleBuffer {
        var block: CMBlockBuffer?
        let create = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: 4, blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0, dataLength: 4, flags: 0, blockBufferOut: &block)
        guard create == kCMBlockBufferNoErr, let block else { throw PortError.message("Cannot allocate timecode sample.") }
        let status = timecode.sample.withUnsafeBytes { CMBlockBufferReplaceDataBytes(with: $0.baseAddress!, blockBuffer: block, offsetIntoDestination: 0, dataLength: 4) }
        guard status == kCMBlockBufferNoErr else { throw PortError.message("Cannot fill timecode sample.") }
        var timing = CMSampleTimingInfo(duration: duration, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        var size = 4
        var sample: CMSampleBuffer?
        let result = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: block, formatDescription: description, sampleCount: 1, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleSizeEntryCount: 1, sampleSizeArray: &size, sampleBufferOut: &sample)
        guard result == noErr, let sample else { throw PortError.message("Cannot create timecode sample.") }
        return sample
    }
}
