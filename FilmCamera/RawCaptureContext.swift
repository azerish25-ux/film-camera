import AVFoundation

final class RawCaptureContext {
    let id = UUID()
    let writer: RawSequenceWriter
    let url: URL
    let interval: Double
    let maximumFrames: Int?
    let deadline: Double
    let oldPreset: AVCaptureSession.Preset
    let oldDimensions: CMVideoDimensions
    let oldProRAW: Bool
    let format: OSType
    let logger = MotionLogger()
    var logging = false
    var allowAudio: Bool
    var stopping = false
    var finishing = false
    var writing = false
    var activeID: Int64?
    var count = 0
    var firstTimestamp: Int64?
    var lastTimestamp: Int64 = 0
    var stopTimestamp: Int64?
    var nextShot = ProcessInfo.processInfo.systemUptime
    init(writer:RawSequenceWriter,url:URL,options:MotionCaptureOptions,timelapse:Bool,maximumFrames:Int?,preset:AVCaptureSession.Preset,dimensions:CMVideoDimensions,proRAW:Bool,format:OSType,audio:Bool) {
        self.writer = writer; self.url = url; self.maximumFrames = maximumFrames
        let requested = maximumFrames != nil ? 0.1 : timelapse ? options.interval : options.rawInterval
        interval = requested.isFinite ? min(3600,max(0.1,requested)) : 1
        deadline = timelapse && !options.unlimited ? ProcessInfo.processInfo.systemUptime+min(180,max(1,options.totalMinutes.isFinite ? options.totalMinutes : 10))*60 : .greatestFiniteMagnitude
        oldPreset = preset; oldDimensions = dimensions; oldProRAW = proRAW; self.format = format
        allowAudio = audio && !timelapse && maximumFrames == nil
    }
}
enum RawCaptureClock {
    static func nanoseconds(_ seconds:Double = ProcessInfo.processInfo.systemUptime) -> Int64 {
        let time = seconds.isFinite && seconds >= 0 && seconds < 1e9 ? seconds : ProcessInfo.processInfo.systemUptime
        return Int64((time*1e9).rounded())
    }
}
