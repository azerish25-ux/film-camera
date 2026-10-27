import Foundation

enum PortError: Error { case message(String) }
private struct CatalogEntry: Decodable { let id: UUID; let dimension: Int; let file: String }

@main struct PureLogicMain {
    static func main() throws {
        let tc = try BMCTimecode(secondsOfDay: 3600, framesPerSecond: 24, startingFrame: 7)
        precondition(tc.frameNumber == 86407 && Array(tc.sample) == [0, 1, 0x51, 0x87])
        var ppm = try BMCAudioMeter(sampleRate: 48_000, channels: 1, mode: .ppm18)
        guard let reading = ppm.process([Int16](repeating: 32767, count: 480))?.first else { fatalError("No PPM reading") }
        precondition(abs(reading.level) < 0.02 && abs(reading.peak) < 0.02)
        var vu = try BMCAudioMeter(sampleRate: 48_000, channels: 2, mode: .vu18)
        var samples = [Int16](); for _ in 0..<(466 * 17) { samples.append(contentsOf: [32767, 0]) }
        guard let values = vu.process(samples), values.count == 2 else { fatalError("No VU readings") }
        precondition(values[0].level > 20 && abs(values[1].level + 68.39) < 0.1)
        let message = BMCSignalingMessage.connectionRequest("digest")
        let encoded = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(BMCSignalingMessage.self, from: encoded)
        precondition(decoded == message)
        let root = URL(fileURLWithPath: "FilmCamera/Resources/BMCLUTs", isDirectory: true)
        let catalog = try JSONDecoder().decode([CatalogEntry].self, from: Data(contentsOf: root.appendingPathComponent("bmc-luts.json")))
        precondition(catalog.count == 41 && Set(catalog.map(\.id)).count == 41)
        for entry in catalog {
            precondition(entry.dimension == 33)
            let bytes = try Data(contentsOf: root.appendingPathComponent(entry.file))
            precondition(bytes.count == 33 * 33 * 33 * 4)
        }
        print("BMC platform-independent checks passed")
    }
}
