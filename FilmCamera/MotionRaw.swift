import Foundation

enum MotionRaw {
    static func dimensions(_ metadata: [String:Any]) throws -> (Int,Int) {
        guard let w = (metadata["width"] as? NSNumber)?.intValue,let h = (metadata["height"] as? NSNumber)?.intValue,w > 0,h > 0,w <= 16384,h <= 16384,w <= 50_000_000/h else {throw PortError.message("Invalid RAW dimensions (maximum 50 megapixels).")}
        return (w,h)
    }
    /// Codec 6: 12-bit base, MSB-first residuals, even/odd Bayer blocks.
    static func decodeBlocks(_ data: Data, width: Int, height: Int) throws -> [UInt16] {
        _ = try dimensions(["width":width,"height":height])
        let padded = (width+31) & ~31
        var result = [UInt16](repeating:0,count:width*height), cursor = 0
        func block() throws -> [UInt16] {
            guard cursor <= data.count-2 else {throw PortError.message("Truncated RAW block header.")}
            let mode = Int(data[cursor]>>4), base = UInt16(data[cursor]&15)<<8 | UInt16(data[cursor+1])
            cursor += 2
            let bits = mode <= 10 ? mode : 16, length = bits*2
            guard length <= data.count-cursor else {throw PortError.message("Truncated RAW block payload.")}
            var values = [UInt16](repeating:base,count:16)
            for i in 0..<16 {
                var residual: UInt16 = 0
                for j in 0..<bits {let bit = i*bits+j; residual = (residual<<1) | UInt16((data[cursor+bit/8] >> (7-bit%8))&1)}
                values[i] = base &+ residual
            }
            cursor += length; return values
        }
        for y in 0..<height {for x in stride(from:0,to:padded,by:32) {
            let even = try block(), odd = try block()
            for i in 0..<16 {
                if x+i*2 < width {result[y*width+x+i*2] = even[i]}
                if x+i*2+1 < width {result[y*width+x+i*2+1] = odd[i]}
            }
        }}
        return result
    }
    static func unpack(_ data: Data, metadata: [String:Any]) throws -> [UInt16] {
        let (w,h) = try dimensions(metadata)
        if (metadata["isCompressed"] as? Bool) == true || (metadata["compressionType"] as? Int ?? 0) != 0 {
            let compression = metadata["compressionType"] as? Int ?? 6
            guard compression == 0 || compression == 6 else {throw PortError.message("This file uses RAW codec \(compression); the supplied 1.2.7 specification describes codec 6.")}
            return try decodeBlocks(data,width:w,height:h)
        }
        let format = (metadata["pixelFormat"] as? String ?? "raw16").lowercased()
        let bits = format == "raw10" ? 10 : format == "raw12" ? 12 : format == "raw16" ? 16 : 0
        guard bits > 0, (bits != 10 || w%4 == 0), (bits != 12 || w%2 == 0) else {throw PortError.message("Unsupported RAW pixel packing.")}
        let rowBytes = (metadata["rowStride"] as? Int) ?? ((w*bits+7)/8)
        guard rowBytes >= (w*bits+7)/8,rowBytes <= data.count/h else {throw PortError.message("Invalid RAW row stride.")}
        var out = [UInt16](repeating:0,count:w*h)
        for y in 0..<h {for x in 0..<w {
            let row = y*rowBytes
            if bits == 16 {out[y*w+x] = UInt16(data[row+x*2]) | UInt16(data[row+x*2+1])<<8}
            if bits == 10 {let g = row+(x/4)*5; out[y*w+x] = UInt16(data[g+x%4])<<2 | UInt16((data[g+4] >> ((x%4)*2))&3)}
            if bits == 12 {let g = row+(x/2)*3; out[y*w+x] = UInt16(data[g+x%2])<<4 | UInt16((data[g+2] >> ((x%2)*4))&15)}
        }}
        return out
    }
}
