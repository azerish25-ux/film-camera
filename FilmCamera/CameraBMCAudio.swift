import AVFoundation
import AudioToolbox

extension CameraController {
    // AVCaptureAudioDataOutput is consumed on the frames queue. Never retain a
    // CMSampleBuffer or block the audio callback while publishing UI updates.
    func handleBMCAudioMeter(_ sample: CMSampleBuffer) {
        let options = bmcAudioMeterOptions()
        guard options.0 else { bmcMeter = nil; bmcMeterFormat = ""; return }
        guard let format = CMSampleBufferGetFormatDescription(sample),
              let description = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee,
              description.mFormatID == kAudioFormatLinearPCM, description.mBitsPerChannel == 16,
              description.mFormatFlags & kAudioFormatFlagIsSignedInteger != 0,
              description.mFormatFlags & (kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsNonInterleaved) == 0,
              description.mSampleRate.isFinite, description.mSampleRate >= 1, description.mSampleRate <= 384_000,
              (1...8).contains(Int(description.mChannelsPerFrame)), let block = CMSampleBufferGetDataBuffer(sample) else {
            if !bmcMeterUnavailableReported { bmcMeterUnavailableReported = true; DispatchQueue.main.async { self.bmcAudioUnavailable = true; self.bmcAudioReadings = [] } }
            return
        }
        let length = CMBlockBufferGetDataLength(block), channelCount = Int(description.mChannelsPerFrame)
        guard length > 0, length <= 1_048_576, length % (2 * channelCount) == 0 else { return }
        var bytes = Data(count: length)
        guard bytes.withUnsafeMutableBytes({ CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: $0.baseAddress!) }) == kCMBlockBufferNoErr else { return }
        let rate = Int(description.mSampleRate.rounded())
        let signature = "\(rate):\(channelCount):\(options.1.rawValue)"
        if bmcMeterFormat != signature {
            bmcMeter = try? BMCAudioMeter(sampleRate: rate, channels: channelCount, mode: options.1)
            bmcMeterFormat = signature
        }
        var samples = [Int16](); samples.reserveCapacity(length / 2)
        bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            for index in stride(from: 0, to: raw.count, by: 2) {
                let value = UInt16(raw[index]) | (UInt16(raw[index + 1]) << 8)
                samples.append(Int16(bitPattern: value))
            }
        }
        guard let readings = bmcMeter?.process(samples) else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - bmcMeterLastUpdate >= 0.1 else { return }
        bmcMeterLastUpdate = now
        bmcMeterUnavailableReported = false
        DispatchQueue.main.async { self.bmcAudioUnavailable = false; self.bmcAudioReadings = readings }
    }
}
