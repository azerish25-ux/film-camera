import Foundation

/// Checked, memory-mapped reader for MOTION version 2/3 indexed containers.
struct MotionContainer {
    struct Frame {let offset:Int; let timestamp:Int64}
    let data: Data
    let version: Int
    let metadata: [String:Any]
    let frames: [Frame]
    let indexStart: Int
    init(url: URL) throws {try self.init(data:Data(contentsOf:url,options:.mappedIfSafe))}
    init(data: Data) throws {
        guard data.count >= 16, Array(data.prefix(7)) == Array("MOTION ".utf8) else {throw PortError.message("Invalid MotionCam container header.")}
        self.data = data; version = Int(data[7])
        guard version == 2 || version == 3 else {throw PortError.message("Legacy MotionCam v1/ZIP containers require conversion to v2 or v3 first.")}
        let trailer = version == 3 ? 24 : 8
        guard data.count >= 8+trailer else {throw PortError.message("Truncated container.")}
        let end = data.count-trailer
        let magic = try data.motionUInt32(end+(version == 3 ? 8 : 0))
        guard magic == (version == 3 ? 0x8A905612 : 0x34884CED) else {throw PortError.message("Container is incomplete: frame index is missing.")}
        let count = Int(try data.motionUInt32(end+(version == 3 ? 12 : 4)))
        guard count > 0, count <= 1_000_000, count <= (end-8)/16 else {throw PortError.message("Invalid container frame count (limit one million frames).")}
        let start: Int
        if version == 3 {let pointer = try data.motionUInt64(end+16); guard pointer >= 16,pointer <= UInt64(end-count*16) else {throw PortError.message("Invalid index start.")}; start = Int(pointer)}
        else {start = end-count*16}
        if version == 3 {
            guard try data.motionUInt32(end) == 0, try data.motionUInt32(end+4) == 16,
                  try data.motionUInt64(end+16) == UInt64(start) else {throw PortError.message("Invalid container index offset.")}
        }
        indexStart = start
        let headerType = try data.motionUInt32(8), headerLength = Int(try data.motionUInt32(12))
        guard headerType == (version == 3 ? 3 : 1),headerLength <= 16_777_216,headerLength <= start-16 else {throw PortError.message("Invalid container metadata.")}
        guard let meta = try JSONSerialization.jsonObject(with:data.subdata(in:16..<16+headerLength)) as? [String:Any] else {throw PortError.message("Container metadata must be an object.")}
        metadata = meta
        var list: [Frame] = []; list.reserveCapacity(count)
        for i in 0..<count {
            let offset = try data.motionUInt64(start+i*16), timestamp = try data.motionUInt64(start+i*16+8)
            guard offset >= UInt64(16+headerLength),offset < UInt64(start),timestamp <= UInt64(Int64.max) else {throw PortError.message("Frame index points outside the container.")}
            let time = Int64(timestamp)
            list.append(Frame(offset:Int(offset),timestamp:time))
        }
        frames = list.sorted {$0.timestamp < $1.timestamp}
    }
    func chunk(at offset: Int) throws -> (type:UInt32,payload:Range<Int>,next:Int) {
        guard offset >= 8, offset <= indexStart-8 else {throw PortError.message("Truncated frame chunk.")}
        let type = try data.motionUInt32(offset), size = Int(try data.motionUInt32(offset+4))
        guard size <= indexStart-offset-8 else {throw PortError.message("Chunk exceeds container bounds.")}
        return (type,(offset+8)..<(offset+8+size),offset+8+size)
    }
    func frame(_ index: Int) throws -> (pixels:Data,metadata:[String:Any]) {
        guard frames.indices.contains(index) else {throw PortError.message("Frame selection is out of range.")}
        let first = try chunk(at:frames[index].offset)
        let second = try chunk(at:first.next)
        let pixelType: UInt32 = version == 3 ? 2 : 0, metaType: UInt32 = version == 3 ? 3 : 1
        let pixels: Range<Int>, json: Range<Int>
        if first.type == pixelType && second.type == metaType {pixels = first.payload; json = second.payload}
        else if first.type == metaType && second.type == pixelType {json = first.payload; pixels = second.payload}
        else {throw PortError.message("Frame has invalid pixel/metadata chunks.")}
        guard json.count <= 16_777_216, let object = try JSONSerialization.jsonObject(with:data.subdata(in:json)) as? [String:Any] else {throw PortError.message("Invalid frame JSON.")}
        return (data.subdata(in:pixels),metadata.merging(object){_,new in new})
    }
    var fps: Double {
        guard frames.count > 1, let last = frames.last, let first = frames.first,last.timestamp > first.timestamp else {return 24}
        return Double(frames.count-1)*1e9/Double(last.timestamp-first.timestamp)
    }
}

extension Data {
    func motionUInt32(_ offset: Int) throws -> UInt32 {
        guard offset >= 0,offset <= count-4 else {throw PortError.message("Unexpected end of binary data.")}
        return (0..<4).reduce(UInt32(0)) {$0 | UInt32(self[offset+$1]) << ($1*8)}
    }
    func motionUInt64(_ offset: Int) throws -> UInt64 {
        let lo = try motionUInt32(offset), hi = try motionUInt32(offset+4)
        return UInt64(lo) | UInt64(hi)<<32
    }
    mutating func motionAppend<T: FixedWidthInteger>(_ number: T) {
        var little = number.littleEndian
        Swift.withUnsafeBytes(of:&little) {append(contentsOf:$0)}
    }
}
