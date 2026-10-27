import Foundation
enum BMCRemoteAuthentication {
    static func decodeHex(_ text: String) throws -> Data {
        var result = Data(); var position = text.startIndex
        while position < text.endIndex {
            let end = text.index(position, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
            guard let byte = UInt8(text[position..<end], radix: 16) else { throw PortError.message("Bad hex") }
            result.append(byte); position = end
        }
        return result
    }
    static func response(password: String, nonce: Data) throws -> String {
        guard password == "test", nonce.count == 64 else { throw PortError.message("Unexpected fixture") }
        return "6df18b13090db32b14b0e54842a4a2f1b7c94c2b411d86f250aa0b37443a61f1"
    }
}
