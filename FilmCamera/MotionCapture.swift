import AVFoundation
import CoreImage
import Vision

struct MotionCaptureOptions: Codable, Equatable {
    var mode: MotionCaptureMode = .photo
    var saveDNG = false
    var saveJPEG = true
    var jpegQuality = 95.0
    var clipping = false
    var peaking = false
    var sensitivity = 0.03
    var shutterAngle = 0
    var saveGyro = false
    var interval = 5.0
    var totalMinutes = 10.0
    var unlimited = false
    var memoryMB = 128
    var audio = true
    var aeLock = false
    var awbLock = false
    var gradedViewfinder = false
    var trackPOI = false
    var autoNight = false
    var stabilization = true
}

/// Bounded RGB pre-roll. iOS video output is processed, not Bayer RAW.
final class MotionPreRoll {
    private var frames: [CGImage] = []
    private var bytes = 0
    func append(_ image: CGImage, limit: Int) {
        let cost = image.bytesPerRow*image.height
        guard cost <= limit else {return}
        while !frames.isEmpty && (frames.count >= 30 || bytes+cost > limit) {let old = frames.removeFirst(); bytes -= old.bytesPerRow*old.height}
        frames.append(image); bytes += cost
    }
    func latest(_ count: Int) -> [CGImage] {Array(frames.suffix(max(0,count)))}
    func clear() {frames.removeAll(); bytes = 0}
    static func merge(_ frames: [CGImage],align:Bool = false) throws -> CIImage {
        guard let first = frames.first else {throw PortError.message("Wait for the camera preview before capturing.")}
        var result = CIImage(cgImage:first)
        var mergedCount = 1
        for frame in frames.dropFirst() {
            var next = CIImage(cgImage:frame)
            if align {
                let request = VNTranslationalImageRegistrationRequest(targetedCGImage:first)
                if (try? VNImageRequestHandler(cgImage:frame).perform([request])) != nil,
                   let observation = request.results?.first as? VNImageTranslationAlignmentObservation {
                    next = next.transformed(by:observation.alignmentTransform).cropped(to:result.extent).composited(over:CIImage(cgImage:first))
                } else {continue}
            }
            let weight = 1/Double(mergedCount+1); mergedCount += 1
            result = result.applyingFilter("CIDissolveTransition",parameters:["inputTargetImage":next,"inputTime":weight])
        }
        return result
    }
}

/// Streaming writer; calls are serialized by CameraController.frames.
final class MotionTimelapse {
    let url: URL
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let context = CIContext(options:[.cacheIntermediates:false])
    private(set) var count = 0
    private(set) var dropped = 0
    private var last = -Double.greatestFiniteMagnitude
    private let interval: Double
    private let size: CGSize
    init(url: URL, size: CGSize, interval: Double) throws {
        self.url = url; self.interval = max(0.25,interval)
        self.size = CGSize(width:max(2,floor(size.width/2)*2),height:max(2,floor(size.height/2)*2))
        writer = try AVAssetWriter(outputURL:url,fileType:.mov)
        input = AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:Int(self.size.width),AVVideoHeightKey:Int(self.size.height)])
        input.expectsMediaDataInRealTime = true
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,kCVPixelBufferWidthKey as String:Int(self.size.width),kCVPixelBufferHeightKey as String:Int(self.size.height),kCVPixelBufferIOSurfacePropertiesKey as String:[:]])
        guard writer.canAdd(input) else {throw PortError.message("Timelapse encoder is unavailable.")}
        writer.add(input)
        guard writer.startWriting() else {throw writer.error ?? PortError.message("Cannot start timelapse.")}
        writer.startSession(atSourceTime:.zero)
    }
    func append(_ image: CIImage,time: Double) throws {
        guard time-last >= interval else {return}
        guard writer.status == .writing else {throw writer.error ?? PortError.message("Timelapse writer stopped.")}
        guard input.isReadyForMoreMediaData else {dropped += 1; return}
        guard let pool = adaptor.pixelBufferPool else {throw PortError.message("Timelapse buffer pool is unavailable.")}
        var pixel: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil,pool,&pixel) == kCVReturnSuccess, let pixel else {throw PortError.message("Cannot allocate timelapse frame.")}
        let scaled = image.transformed(by:CGAffineTransform(scaleX:size.width/image.extent.width,y:size.height/image.extent.height))
        context.render(scaled,to:pixel,bounds:CGRect(origin:.zero,size:size),colorSpace:CGColorSpaceCreateDeviceRGB())
        guard adaptor.append(pixel,withPresentationTime:CMTime(value:Int64(count),timescale:24)) else {throw writer.error ?? PortError.message("Timelapse encoding failed.")}
        count += 1; last = time
    }
    func finish(_ completion: @escaping (Result<URL,Error>) -> Void) {
        guard count > 0 else {writer.cancelWriting(); try? FileManager.default.removeItem(at:url); completion(.failure(PortError.message("No timelapse frames were recorded."))); return}
        input.markAsFinished(); writer.finishWriting {[self] in
            if writer.status == .completed {completion(.success(url))}
            else {try? FileManager.default.removeItem(at:url); completion(.failure(writer.error ?? PortError.message("Timelapse finalization failed.")))}
        }
    }
}
