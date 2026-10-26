import CoreImage
import UIKit

struct MotionClip {
    let url: URL
    let container: MotionContainer?
    init(url:URL) throws {
        self.url = url
        container = url.pathExtension.lowercased() == "mcraw" ? try MotionContainer(url:url) : nil
        if container == nil {_ = try MotionProcessing.decode(url)}
    }
    var count: Int {container?.frames.count ?? 1}
    var fps: Double {container?.fps ?? 24}
    func dng(_ index:Int) throws -> Data {
        guard let container else {guard url.pathExtension.lowercased() == "dng" else {throw PortError.message("This source is not Bayer RAW.")}; return try Data(contentsOf:url)}
        let frame = try container.frame(index)
        return try MotionDNG.encode(pixels:MotionRaw.unpack(frame.pixels,metadata:frame.metadata),metadata:frame.metadata)
    }
    func image(_ index:Int,context:CIContext) throws -> CIImage {
        if container == nil {return try MotionProcessing.decode(url)}
        let data = try dng(index)
        guard let filter = CIRAWFilter(imageData:data,identifierHint:"com.adobe.raw-image"),let image = filter.outputImage,
              let cg = context.createCGImage(image,from:image.extent) else {throw PortError.message("iOS could not develop this camera's DNG frame.")}
        return CIImage(cgImage:cg)
    }
}

enum MotionFixture {
    /// Deterministic camera-free input used by simulator integration tests.
    static func container(includeAudio:Bool = false) throws -> Data {
        var meta: [String:Any] = ["width":64,"height":48,"isCompressed":true,"compressionType":6,"sensorArrangment":"rggb","blackLevel":[0,0,0,0],"whiteLevel":4095,"colorMatrix1":[0.64,0.33,0.03,0.21,0.71,0.08,0.02,0.12,0.86],"asShotNeutral":[1,1,1],"model":"MotionCam CI fixture"]
        if includeAudio {meta["extraData"] = ["audioSampleRate":8000,"audioChannels":1]}
        var d = Data("MOTION \u{3}".utf8)
        func chunk(_ type:UInt32,_ payload:Data) {d.motionAppend(type); d.motionAppend(UInt32(payload.count)); d.append(payload)}
        chunk(3,try JSONSerialization.data(withJSONObject:meta,options:.sortedKeys))
        var offsets: [(UInt64,UInt64)] = []
        for frame in 0..<3 {
            offsets.append((UInt64(d.count),UInt64(frame)*41_666_667))
            var pixels = Data()
            for y in 0..<48 {for x in 0..<2 {
                for phase in 0..<2 {
                    let base = 400+y*20+x*300+phase*200+frame*100
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
