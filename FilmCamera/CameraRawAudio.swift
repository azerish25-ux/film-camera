import AVFoundation
import AudioToolbox

extension CameraController {
    func handleRawAudio(_ sample:CMSampleBuffer) {
        guard let writer = rawAudioWriterSnapshot() else {return}
        guard let format = CMSampleBufferGetFormatDescription(sample),let description = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee,
              description.mFormatID == kAudioFormatLinearPCM,description.mBitsPerChannel == 16,
              description.mFormatFlags & (kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsNonInterleaved) == 0,
              description.mSampleRate.isFinite,(8000...192000).contains(description.mSampleRate),
              (1...8).contains(Int(description.mChannelsPerFrame)),let block = CMSampleBufferGetDataBuffer(sample) else {
            if !rawAudioFormatReported {rawAudioFormatReported = true; queue.async {self.setRawAudioWriter(nil); self.report(PortError.message("Microphone output is not supported 16-bit PCM. RAW frames are still being saved."))}}
            return
        }
        let length = CMBlockBufferGetDataLength(block)
        guard length > 0,length <= 1_048_576 else {return}
        var data = Data(count:length)
        let status = data.withUnsafeMutableBytes {CMBlockBufferCopyDataBytes(block,atOffset:0,dataLength:length,destination:$0.baseAddress!)}
        guard status == kCMBlockBufferNoErr else {return}
        let timestamp = RawCaptureClock.nanoseconds(CMSampleBufferGetPresentationTimeStamp(sample).seconds)
        let rate = Int(description.mSampleRate.rounded()),channels = Int(description.mChannelsPerFrame),previous = rawAudioTask
        rawAudioTask = Task {
            await previous?.value
            do {try await writer.appendPCM(data,timestampNs:timestamp,sampleRate:rate,channels:channels)}
            catch {self.queue.async {guard let context = self.rawCapture,context.writer === writer else {return}; self.report(error); self.requestRawStop()}}
        }
    }
}
