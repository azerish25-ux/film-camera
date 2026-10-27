import CryptoKit
import Foundation

struct BMCLUTDescriptor: Codable, Identifiable {
    let id: UUID
    let profile: String
    let name: String
    let file: String
    let dimension: Int
    let sha256: String
}

enum BMCLUTCatalog {
    static let all: [BMCLUTDescriptor] = {
        guard let url = Bundle.main.url(forResource: "bmc-luts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([BMCLUTDescriptor].self, from: data),
              entries.count == 41, Set(entries.map(\.id)).count == entries.count,
              entries.allSatisfy({ $0.dimension == 33 }) else { return [] }
        return entries
    }()
    static var profiles: [String] { Array(Set(all.map(\.profile))).sorted() }

    static func load(_ descriptor: BMCLUTDescriptor) throws -> CubeLUT {
        guard descriptor.dimension == 33, descriptor.file.hasSuffix(".rgba"),
              let url = Bundle.main.url(forResource: (descriptor.file as NSString).deletingPathExtension, withExtension: "rgba") else {
            throw PortError.message("The built-in BMC lookup table is missing.")
        }
        let bytes = try Data(contentsOf: url)
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        guard bytes.count == 33 * 33 * 33 * 4, digest == descriptor.sha256 else {
            throw PortError.message("The built-in BMC lookup table is invalid.")
        }
        return CubeLUT(id: descriptor.id, name: "BMC \(descriptor.profile) • \(descriptor.name)", dimension: 33,
                       rgba: bytes.map { Float($0) / 255 }, domainMin: [0, 0, 0], domainMax: [1, 1, 1])
    }
}
