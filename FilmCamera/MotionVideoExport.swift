import AVFoundation
import CoreImage

enum MotionVideoCodec: String, Codable, CaseIterable, Identifiable {
    case h264 = "H.264", hevc = "HEVC", prores = "ProRes 422"
    var id: String {rawValue}
    var av: AVVideoCodecType {switch self {case .h264:return .h264; case .hevc:return .hevc; case .prores:return .proRes422}}
}
enum MotionVideoExport {
    static func sourceFPS(_ value:Double) -> Double {value.isFinite && value >= 1 && value <= 480 ? value : 24}
    static func encode(clip:MotionClip,range:ClosedRange<Int>,destination:URL,settings:FilmSettings,lut:CubeLUT?,codec:MotionVideoCodec,fps:Double,bitrate:Int,resolution:RawMovieResolution = .p1080,sourceTiming:Bool = false,progress:@escaping (Double)->Void) async throws {
        guard range.lowerBound >= 0,range.upperBound < clip.count,fps.isFinite,fps >= 1,fps <= 480 else {throw PortError.message("Invalid video export range or frame rate.")}
        let renderer = FilmRenderer(), first = try renderer.render(MotionProcessing.filmInput(clip.image(range.lowerBound,context:renderer.context,maxDimension:resolution.decodeLimit),grade:settings.motion),settings:settings,lut:lut)
        let size = resolution.fit(first.extent.size),width = Int(size.width),height = Int(size.height)
        let writer = try AVAssetWriter(outputURL:destination,fileType:.mov)
        var options: [String:Any] = [AVVideoCodecKey:codec.av,AVVideoWidthKey:width,AVVideoHeightKey:height]
        if codec != .prores {options[AVVideoCompressionPropertiesKey] = [AVVideoAverageBitRateKey:max(1_000_000,min(500_000_000,bitrate))]}
        let input = AVAssetWriterInput(mediaType:.video,outputSettings:options)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferIOSurfacePropertiesKey as String:[:]])
        guard writer.canAdd(input) else {throw PortError.message("The selected codec is unavailable on this iOS device.")}
        writer.add(input)
        guard writer.startWriting() else {throw writer.error ?? PortError.message("Cannot open movie encoder.")}
        writer.startSession(atSourceTime:.zero)
        var completed = false
        defer {if !completed {writer.cancelWriting(); try? FileManager.default.removeItem(at:destination)}}
        for index in range {
            let presentation = sourceTiming ? clip.relativeTime(index,from:range.lowerBound) : Double(index-range.lowerBound)/fps
            try Task.checkCancellation()
            while !input.isReadyForMoreMediaData {
                try Task.checkCancellation()
                guard writer.status == .writing else {throw writer.error ?? PortError.message("Movie encoding failed.")}
                try await Task.sleep(nanoseconds:2_000_000)
            }
            try autoreleasepool {
                let image = index == range.lowerBound ? first : try renderer.render(MotionProcessing.filmInput(clip.image(index,context:renderer.context,maxDimension:resolution.decodeLimit),grade:settings.motion),settings:settings,lut:lut,time:presentation)
                guard let pool = adaptor.pixelBufferPool else {throw PortError.message("Movie pixel pool is unavailable.")}
                var pixel: CVPixelBuffer?
                guard CVPixelBufferPoolCreatePixelBuffer(nil,pool,&pixel) == kCVReturnSuccess,let pixel else {throw PortError.message("Cannot allocate movie frame.")}
                let normalized = image.transformed(by:CGAffineTransform(translationX:-image.extent.minX,y:-image.extent.minY))
                let scaled = normalized.transformed(by:CGAffineTransform(scaleX:Double(width)/normalized.extent.width,y:Double(height)/normalized.extent.height))
                renderer.context.render(scaled,to:pixel,bounds:CGRect(x:0,y:0,width:width,height:height),colorSpace:CGColorSpaceCreateDeviceRGB())
                guard adaptor.append(pixel,withPresentationTime:CMTime(seconds:presentation,preferredTimescale:600_000)) else {throw writer.error ?? PortError.message("Cannot write movie frame.")}
            }
            progress(Double(index-range.lowerBound+1)/Double(range.count))
        }
        if sourceTiming {writer.endSession(atSourceTime:CMTime(seconds:clip.endTime(after:range.upperBound,from:range.lowerBound),preferredTimescale:600_000))}
        input.markAsFinished()
        await writer.finishWriting()
        try Task.checkCancellation()
        guard writer.status == .completed else {throw writer.error ?? PortError.message("Movie finalization failed.")}
        completed = true
    }
}
