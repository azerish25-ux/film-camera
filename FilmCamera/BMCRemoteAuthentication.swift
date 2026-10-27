import CryptoKit
import Foundation
import Security

/// The APK's v5 signaling challenge calculation. Transport and pairing are
/// deliberately separate and have not yet been implemented.
enum BMCRemoteAuthentication {
    static func makeNonce() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else { throw PortError.message("Cannot generate a remote pairing nonce.") }
        return Data(bytes)
    }
    static func decodeHex(_ input: String) throws -> Data {
        let text = input.utf8.count.isMultiple(of: 2) ? input : "0" + input
        let bytes = Array(text.utf8)
        var result = Data(); result.reserveCapacity(bytes.count / 2)
        func nibble(_ byte: UInt8) -> UInt8? {
            switch byte {
            case 48...57: return byte - 48
            case 65...70: return byte - 65 + 10
            case 97...102: return byte - 97 + 10
            default: return nil
            }
        }
        for index in stride(from: 0, to: bytes.count, by: 2) {
            guard let high = nibble(bytes[index]), let low = nibble(bytes[index + 1]) else { throw PortError.message("Invalid remote camera challenge encoding.") }
            result.append(high * 16 + low)
        }
        return result
    }
    static func response(password: String, nonce: Data) throws -> String {
        guard nonce.count == 64 else { throw PortError.message("Invalid remote camera challenge.") }
        let firstSalt: [UInt8] = [0x0e, 0x7b, 0x97, 0xa6, 0x7b, 0xd5, 0xd0, 0xed]
        let secondSalt: [UInt8] = [0x55, 0x81, 0x3b, 0x67, 0x55, 0xc0, 0x37, 0xb1]
        let inner = SHA256.hash(data: Data(password.utf8) + Data(firstSalt))
        let outer = SHA256.hash(data: nonce + Data(inner) + Data(secondSalt))
        return outer.map { String(format: "%02x", $0) }.joined()
    }
}
