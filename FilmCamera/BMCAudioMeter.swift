import Foundation

/// Translation of the APK meter's per-channel sample windows and decay state.
/// Live microphone routing and Android/device reference comparison remain open.
struct BMCAudioMeter {
    enum Mode: String, Codable, CaseIterable, Identifiable {
        case vu18, vu20, ppm18, ppm20
        var id: String { rawValue }
        var title: String {
            switch self { case .vu18: return "VU -18 dBFS"; case .vu20: return "VU -20 dBFS"; case .ppm18: return "PPM -18 dBFS"; case .ppm20: return "PPM -20 dBFS" }
        }
    }
    struct Reading: Equatable { let level: Double; let peak: Double }
    private struct Channel {
        var count = 0
        var sum = 0.0
        var maximum = 0.0
        var windows: [Double] = []
        var rollingSum = 0.0
        var level = 0
        var peak = 0
        var hold = 0
    }
    private let mode: Mode
    private let windowSize: Int
    private let rollingCount: Int
    private let levelDecay: Int
    private let peakDecay: Int
    private let holdCount: Int
    private let vuDecay: Int
    private let sineCorrection: Int
    private var channels: [Channel]
    private let reference = 20 * log10(32767.0)

    init(sampleRate: Int, channels: Int, mode: Mode) throws {
        guard (1...384_000).contains(sampleRate), (1...8).contains(channels) else { throw PortError.message("Invalid audio meter format.") }
        self.mode = mode
        rollingCount = Int((165.0 / 10.0).rounded())
        let interval = (mode == .vu18 || mode == .vu20) ? 165.0 / Double(rollingCount) : 10.0
        windowSize = max(1, Int((Double(sampleRate) * interval / 1000).rounded()))
        levelDecay = Int((2000 / (1700 / interval)).rounded())
        peakDecay = levelDecay
        holdCount = Int(1000 / interval)
        vuDecay = Int((4500 / (165 / interval)).rounded())
        sineCorrection = Int(abs(2000 * log10(0.63661975)).rounded())
        self.channels = Array(repeating: Channel(), count: channels)
    }

    mutating func process(_ samples: [Int16]) -> [Reading]? {
        guard !samples.isEmpty else { return nil }
        var updated = false
        for (index, sample) in samples.enumerated() {
            let channel = index % channels.count
            let magnitude = abs(Double(sample))
            channels[channel].count += 1
            channels[channel].sum += magnitude
            channels[channel].maximum = max(channels[channel].maximum, magnitude)
            guard channels[channel].count == windowSize else { continue }
            let sum = channels[channel].sum, peak = channels[channel].maximum
            channels[channel].count = 0; channels[channel].sum = 0; channels[channel].maximum = 0
            channels[channel].windows.append(sum); channels[channel].rollingSum += sum
            if channels[channel].windows.count > rollingCount {
                let oldest = channels[channel].windows.removeFirst()
                channels[channel].rollingSum -= oldest
            }
            if mode == .ppm18 || mode == .ppm20 {
                let value = Self.centibel(peak)
                channels[channel].level = max(0, channels[channel].level - levelDecay, value)
                if value > channels[channel].peak { channels[channel].peak = value; channels[channel].hold = 0 }
                channels[channel].hold += 1
                if channels[channel].hold > holdCount { channels[channel].peak = max(0, channels[channel].peak - peakDecay) }
                updated = true
            } else if channels[channel].windows.count == rollingCount {
                let mean = channels[channel].rollingSum / Double(windowSize * rollingCount)
                let value = Self.centibel(mean) + sineCorrection
                channels[channel].level = max(0, channels[channel].level - vuDecay, value)
                updated = true
            }
        }
        guard updated else { return nil }
        return channels.map { channel in
            switch mode {
            case .vu18, .vu20:
                let offset = mode == .vu18 ? 18.0 : 20.0
                let value = Double(channel.level) / 100 + offset - reference
                return Reading(level: value, peak: value)
            case .ppm18, .ppm20:
                return Reading(level: Double(channel.level) / 100 - reference, peak: Double(channel.peak) / 100 - reference)
            }
        }
    }
    private static func centibel(_ value: Double) -> Int { value <= 0 ? 0 : Int((2000 * log10(value)).rounded()) }
}
