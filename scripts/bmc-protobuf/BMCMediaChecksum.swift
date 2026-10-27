import Foundation

/// IEEE CRC-32, matching java.util.zip.CRC32 used by the APK for clip chunks.
struct BMCMediaChecksum {
    private var state: UInt32 = 0xffff_ffff

    mutating func update(_ bytes: Data) {
        for byte in bytes {
            state ^= UInt32(byte)
            for _ in 0..<8 {
                let polynomial: UInt32 = state & 1 == 0 ? 0 : 0xedb8_8320
                state = (state >> 1) ^ polynomial
            }
        }
    }

    var value: UInt32 { state ^ 0xffff_ffff }
}

