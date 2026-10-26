import Foundation

/// Uncompressed TIFF/DNG writer preserving Bayer samples and calibration.
enum MotionDNG {
    struct Tag {let id:UInt16; let type:UInt16; let count:UInt32; let bytes:Data}
    static func encode(pixels:[UInt16], metadata:[String:Any]) throws -> Data {
        let (w,h) = try MotionRaw.dimensions(metadata)
        guard pixels.count == w*h else {throw PortError.message("RAW sample count does not match dimensions.")}
        let patterns: [String:[UInt8]] = ["rggb":[0,1,1,2],"bggr":[2,1,1,0],"grbg":[1,0,2,1],"gbrg":[1,2,0,1]]
        guard let pattern = patterns[(metadata["sensorArrangment"] as? String ?? metadata["sensorArrangement"] as? String ?? "").lowercased()],let white = metadata["whiteLevel"] as? NSNumber,white.intValue > 0,white.intValue <= 65535,let black = metadata["blackLevel"] as? [NSNumber],black.count == 4,let matrix = metadata["colorMatrix1"] as? [NSNumber],matrix.count == 9,let neutral = metadata["asShotNeutral"] as? [NSNumber],neutral.count == 3 else {throw PortError.message("Missing Bayer pattern, levels, color matrix or white balance; cannot invent camera calibration.")}
        var tags: [Tag] = []
        func numbers<T:FixedWidthInteger>(_ a:[T]) -> Data {var d = Data(); for x in a {d.motionAppend(x)}; return d}
        func short(_ id:UInt16,_ a:[UInt16]) {tags.append(Tag(id:id,type:3,count:UInt32(a.count),bytes:numbers(a)))}
        func long(_ id:UInt16,_ a:[UInt32]) {tags.append(Tag(id:id,type:4,count:UInt32(a.count),bytes:numbers(a)))}
        func bytes(_ id:UInt16,_ a:[UInt8]) {tags.append(Tag(id:id,type:1,count:UInt32(a.count),bytes:Data(a)))}
        func text(_ id:UInt16,_ s:String) {let d = Data((s+"\0").utf8); tags.append(Tag(id:id,type:2,count:UInt32(d.count),bytes:d))}
        func rational(_ id:UInt16,_ a:[NSNumber],signed:Bool) throws {
            var d = Data()
            for n in a {
                let v = n.doubleValue
                guard v.isFinite,abs(v) <= 2000,signed || v >= 0 else {throw PortError.message("Invalid DNG calibration value.")}
                if signed {d.motionAppend(Int32((v*1_000_000).rounded())); d.motionAppend(Int32(1_000_000))}
                else {d.motionAppend(UInt32((v*1_000_000).rounded())); d.motionAppend(UInt32(1_000_000))}
            }
            tags.append(Tag(id:id,type:signed ? 10 : 5,count:UInt32(a.count),bytes:d))
        }
        long(254,[0]); long(256,[UInt32(w)]); long(257,[UInt32(h)])
        short(258,[16]); short(259,[1]); short(262,[32803]); long(273,[0])
        short(274,[1]); short(277,[1]); long(278,[UInt32(h)]); long(279,[UInt32(w*h*2)]); short(284,[1])
        short(33421,[2,2]); bytes(33422,pattern); bytes(50706,[1,4,0,0]); bytes(50707,[1,1,0,0])
        text(50708,metadata["model"] as? String ?? "MotionCam RAW")
        bytes(50710,[0,1,2]); short(50711,[1]); short(50713,[2,2])
        try rational(50714,black,signed:false); long(50717,[white.uint32Value])
        try rational(50721,matrix,signed:true); try rational(50728,neutral,signed:false)
        short(50778,[(metadata["calibrationIlluminant1"] as? NSNumber)?.uint16Value ?? 21])
        if let m = metadata["colorMatrix2"] as? [NSNumber],m.count == 9 {try rational(50722,m,signed:true); short(50779,[(metadata["calibrationIlluminant2"] as? NSNumber)?.uint16Value ?? 17])}
        for (name,id) in [("forwardMatrix1",UInt16(50964)),("forwardMatrix2",UInt16(50965))] {if let m = metadata[name] as? [NSNumber],m.count == 9 {try rational(id,m,signed:true)}}
        long(50829,[0,0,UInt32(h),UInt32(w)])
        tags.sort {$0.id < $1.id}
        let extraStart = 8+2+tags.count*12+4
        var extra = Data(), entries = Data()
        let extraSize = tags.filter {$0.bytes.count > 4}.reduce(0) {$0+$1.bytes.count+($1.bytes.count%2)}
        let pixelStart = extraStart+extraSize
        for t in tags {
            entries.motionAppend(t.id); entries.motionAppend(t.type); entries.motionAppend(t.count)
            if t.id == 273 {entries.motionAppend(UInt32(pixelStart))}
            else if t.bytes.count <= 4 {entries.append(t.bytes); entries.append(Data(repeating:0,count:4-t.bytes.count))}
            else {entries.motionAppend(UInt32(extraStart+extra.count)); extra.append(t.bytes); if extra.count%2 != 0 {extra.append(0)}}
        }
        var output = Data([0x49,0x49,42,0,8,0,0,0]); output.motionAppend(UInt16(tags.count)); output.append(entries); output.motionAppend(UInt32(0)); output.append(extra)
        for p in pixels {output.motionAppend(p)}
        return output
    }
}
