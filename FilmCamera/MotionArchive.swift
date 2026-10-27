import Foundation
import zlib

/// Streaming, uncompressed ZIP64; RAW sequences can exceed classic ZIP's 4 GB limit.
final class MotionArchive {
    private struct Entry {let name:Data; let size:UInt64; let crc:UInt32; let offset:UInt64}
    private let handle: FileHandle
    private var entries: [Entry] = []
    init(url:URL) throws {
        guard FileManager.default.createFile(atPath:url.path,contents:nil) else {throw PortError.message("Cannot create DNG archive.")}
        handle = try FileHandle(forWritingTo:url)
    }
    func append(name:String,data:Data) throws {
        let nameData = Data(name.utf8)
        guard !name.contains(".."),!name.hasPrefix("/"),nameData.count <= 65535,data.count <= Int(UInt32.max) else {throw PortError.message("Invalid ZIP entry.")}
        let checksum: UInt32 = data.withUnsafeBytes {raw in UInt32(crc32(0,raw.bindMemory(to:Bytef.self).baseAddress,uInt(raw.count)))}
        let offset = try handle.offset(),size = UInt64(data.count)
        var header = Data()
        header.motionAppend(UInt32(0x04034b50)); header.motionAppend(UInt16(45)); header.motionAppend(UInt16(0x800)); header.motionAppend(UInt16(0))
        header.motionAppend(UInt16(0)); header.motionAppend(UInt16(0x21)); header.motionAppend(checksum)
        header.motionAppend(UInt32.max); header.motionAppend(UInt32.max); header.motionAppend(UInt16(nameData.count)); header.motionAppend(UInt16(20))
        header.append(nameData); header.motionAppend(UInt16(1)); header.motionAppend(UInt16(16)); header.motionAppend(size); header.motionAppend(size)
        try handle.write(contentsOf:header); try handle.write(contentsOf:data)
        entries.append(Entry(name:nameData,size:size,crc:checksum,offset:offset))
    }
    func finish() throws {
        let start = try handle.offset()
        for e in entries {
            var d = Data()
            d.motionAppend(UInt32(0x02014b50)); d.motionAppend(UInt16(45)); d.motionAppend(UInt16(45)); d.motionAppend(UInt16(0x800)); d.motionAppend(UInt16(0))
            d.motionAppend(UInt16(0)); d.motionAppend(UInt16(0x21)); d.motionAppend(e.crc); d.motionAppend(UInt32.max); d.motionAppend(UInt32.max)
            d.motionAppend(UInt16(e.name.count)); d.motionAppend(UInt16(28)); d.motionAppend(UInt16(0)); d.motionAppend(UInt16(0)); d.motionAppend(UInt16(0)); d.motionAppend(UInt32(0)); d.motionAppend(UInt32.max)
            d.append(e.name); d.motionAppend(UInt16(1)); d.motionAppend(UInt16(24)); d.motionAppend(e.size); d.motionAppend(e.size); d.motionAppend(e.offset)
            try handle.write(contentsOf:d)
        }
        let end = try handle.offset()
        var d = Data()
        d.motionAppend(UInt32(0x06064b50)); d.motionAppend(UInt64(44)); d.motionAppend(UInt16(45)); d.motionAppend(UInt16(45))
        d.motionAppend(UInt32(0)); d.motionAppend(UInt32(0)); d.motionAppend(UInt64(entries.count)); d.motionAppend(UInt64(entries.count)); d.motionAppend(end-start); d.motionAppend(start)
        d.motionAppend(UInt32(0x07064b50)); d.motionAppend(UInt32(0)); d.motionAppend(end); d.motionAppend(UInt32(1))
        d.motionAppend(UInt32(0x06054b50)); d.motionAppend(UInt16(0)); d.motionAppend(UInt16(0)); d.motionAppend(UInt16.max); d.motionAppend(UInt16.max); d.motionAppend(UInt32.max); d.motionAppend(UInt32.max); d.motionAppend(UInt16(0))
        try handle.write(contentsOf:d); try handle.synchronize(); try handle.close()
    }
    deinit {try? handle.close()}
}
