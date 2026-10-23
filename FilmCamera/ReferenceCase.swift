import Foundation
struct ReferenceCase: Codable {
    let name: String
    let shader: String
    let floats: [String: Double]
    let vectors: [String: [Double]]
    let samplers: [String: String]
    let ints: [String: Int]
    let arrays: [String: [Float]]
}
