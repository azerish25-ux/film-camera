import CoreImage
import UIKit

struct MotionClip {
    let url: URL
    let container: MotionContainer?
    let sequence: RawSequenceManifest?
    init(url:URL) throws {
        self.url = url
        if url.pathExtension.lowercased() == "rawseq" {
            let manifest = try RawSequenceManifest.load(url)
            guard !manifest.frames.isEmpty else {throw PortError.message("This RAW sequence has no completed frames yet.")}
            sequence = manifest; container = nil
        } else {
            sequence = nil
            container = url.pathExtension.lowercased() == "mcraw" ? try MotionContainer(url:url) : nil
            if container == nil {_ = try MotionProcessing.decode(url)}
        }
    }
    var count: Int {sequence?.frames.count ?? container?.frames.count ?? 1}
    var fps: Double {sequence?.fps ?? container?.fps ?? 24}
    var isSequence: Bool {container != nil || sequence != nil}
    var isTimelapse: Bool {sequence?.timelapse ?? (container != nil && fps < 1)}
    var sourceDisplayFPS: Double {isTimelapse ? 24 : fps}
    func timestampNs(_ index:Int) -> Int64 {sequence?.frames[index].timestampNs ?? container?.frames[index].timestamp ?? Int64(Double(index)*1e9/fps)}
    func relativeTime(_ index:Int,from first:Int) -> Double {Double(timestampNs(index)-timestampNs(first))/1e9}
    func endTime(after index:Int,from first:Int) -> Double {
        if index+1 < count {return relativeTime(index+1,from:first)}
        if let sequence,sequence.complete {return Double(sequence.endTimestampNs-timestampNs(first))/1e9}
        return relativeTime(index,from:first)+1/max(0.001,fps)
    }
    func extractAudio(range:ClosedRange<Int>,to destination:URL) throws -> Bool {
        if let container {return try MotionAudio.extract(container:container,range:range,to:destination)}
        if let sequence {
            let start = timestampNs(range.lowerBound)
            let end = start+Int64((endTime(after:range.upperBound,from:range.lowerBound)*1e9).rounded())
            return try RawSequenceAudio.extract(directory:url,manifest:sequence,startNs:start,endNs:end,to:destination)
        }
        return false
    }
    func captureSidecars(range:ClosedRange<Int>) throws -> [(String,Data)] {
        guard let sequence else {return []}
        var info: [String:Any] = ["format":"Super16 RAW sensor timing v1","frameTimestampUnits":"nanoseconds","sourceStartTimestamp":String(timestampNs(range.lowerBound)),"sourceEndTimestamp":String(timestampNs(range.lowerBound)+Int64((endTime(after:range.upperBound,from:range.lowerBound)*1e9).rounded()))]
        info["frames"] = range.map {["exportedFile":String(format:"%06d.dng",$0-range.lowerBound),"sensorTimestamp":String(timestampNs($0))]}
        var result: [(String,Data)] = []
        if let origin = sequence.gyroOriginTimestampNs {
            info["motionLogOriginTimestamp"] = String(origin)
            let difference = timestampNs(range.lowerBound).subtractingReportingOverflow(origin)
            guard !difference.overflow else {throw PortError.message("Gyro timestamp offset overflows the capture clock.")}
            info["motionLogOffsetSeconds"] = Double(difference.partialValue)/1e9
            info["motionLogIsUntrimmed"] = true
            let source = url.appendingPathComponent("motion.gcsv").resolvingSymlinksInPath()
            if source.path.hasPrefix(url.resolvingSymlinksInPath().path+"/"),FileManager.default.fileExists(atPath:source.path),(try source.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0) <= 64_000_000 {result.append(("motion.gcsv",try Data(contentsOf:source)))}
        }
        result.append(("capture-timing.json",try JSONSerialization.data(withJSONObject:info,options:[.prettyPrinted,.sortedKeys])))
        return result
    }
    func dng(_ index:Int) throws -> Data {
        guard (0..<count).contains(index) else {throw PortError.message("Frame selection is out of range.")}
        if let sequence {
            let source = url.appendingPathComponent(sequence.frames[index].file)
            guard (try source.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0) <= 128_000_000 else {throw PortError.message("RAW frame exceeds 128 MB.")}
            return try Data(contentsOf:source)
        }
        guard let container else {guard url.pathExtension.lowercased() == "dng" else {throw PortError.message("This source is not RAW DNG.")}; return try Data(contentsOf:url)}
        let frame = try container.frame(index)
        return try MotionDNG.encode(pixels:MotionRaw.unpack(frame.pixels,metadata:frame.metadata),metadata:frame.metadata)
    }
    func image(_ index:Int,context:CIContext,maxDimension:Double? = nil) throws -> CIImage {
        guard (0..<count).contains(index) else {throw PortError.message("Frame selection is out of range.")}
        if let sequence {return try MotionProcessing.decode(url.appendingPathComponent(sequence.frames[index].file),maxDimension:maxDimension)}
        if container == nil {return try MotionProcessing.decode(url,maxDimension:maxDimension)}
        let data = try dng(index)
        guard let filter = CIRAWFilter(imageData:data,identifierHint:"com.adobe.raw-image") else {throw PortError.message("Cannot create RAW frame decoder.")}
        if let maxDimension {filter.scaleFactor = Float(min(1,maxDimension/Double(max(filter.nativeSize.width,filter.nativeSize.height))))}
        guard let image = filter.outputImage,
              let cg = context.createCGImage(image,from:image.extent) else {throw PortError.message("iOS could not develop this camera's DNG frame.")}
        return CIImage(cgImage:cg)
    }
}

enum MotionFixture {
    /// Deterministic camera-free input used by simulator integration tests.
    static func container(includeAudio:Bool = false, width:Int = 320, height:Int = 240) throws -> Data {
        var meta: [String:Any] = ["width":width,"height":height,"isCompressed":true,"compressionType":6,"sensorArrangment":"rggb","blackLevel":[0,0,0,0],"whiteLevel":4095,"colorMatrix1":[0.64,0.33,0.03,0.21,0.71,0.08,0.02,0.12,0.86],"asShotNeutral":[1,1,1],"model":"MotionCam CI fixture"]
        if includeAudio {meta["extraData"] = ["audioSampleRate":8000,"audioChannels":1]}
        var d = Data("MOTION \u{3}".utf8)
        func chunk(_ type:UInt32,_ payload:Data) {d.motionAppend(type); d.motionAppend(UInt32(payload.count)); d.append(payload)}
        chunk(3,try JSONSerialization.data(withJSONObject:meta,options:.sortedKeys))
        var offsets: [(UInt64,UInt64)] = []
        for frame in 0..<3 {
            offsets.append((UInt64(d.count),UInt64(frame)*41_666_667))
            var pixels = Data()
            for y in 0..<height {for x in 0..<((width+31)/32) {
                for phase in 0..<2 {
                    let base = 400+y*4+x*100+phase*200+frame*100
                    pixels.append(UInt8(base>>8)); pixels.append(UInt8(base&255))
                }
            }}
            pixels.append(0)
            chunk(2,pixels); chunk(3,try JSONSerialization.data(withJSONObject:meta,options:.sortedKeys))
            if includeAudio {
                var pcm = Data(); for _ in 0..<333 {pcm.motionAppend(Int16(1000+frame*100))}
                chunk(5,pcm); var time = Data(); time.motionAppend(UInt64(frame)*41_666_667); chunk(6,time)
            }
        }
        let start = UInt64(d.count)
        for (offset,time) in offsets {d.motionAppend(offset); d.motionAppend(time)}
        d.motionAppend(UInt32(0)); d.motionAppend(UInt32(16)); d.motionAppend(UInt32(0x8A905612)); d.motionAppend(UInt32(offsets.count)); d.motionAppend(start)
        return d
    }
}
