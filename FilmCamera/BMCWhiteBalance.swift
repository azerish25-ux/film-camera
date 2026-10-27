import AVFoundation

enum BMCWhiteBalancePreset: String, CaseIterable, Identifiable {
    case sunny, tungsten, fluorescent, shady, cloudy
    var id: String { rawValue }
    var value: BMCWhiteBalance {
        switch self {
        case .sunny: return BMCWhiteBalance(temperature: 5600, tint: 10)
        case .tungsten: return BMCWhiteBalance(temperature: 3200, tint: 0)
        case .fluorescent: return BMCWhiteBalance(temperature: 4000, tint: 15)
        case .shady: return BMCWhiteBalance(temperature: 4500, tint: 15)
        case .cloudy: return BMCWhiteBalance(temperature: 6500, tint: 10)
        }
    }
}

struct BMCWhiteBalance: Equatable {
    var temperature: Double
    var tint: Double

    static func clampGain(_ gain: Float, maximum: Float) -> Float {
        guard gain.isFinite, maximum.isFinite, maximum >= 1 else { return 1 }
        return min(maximum, max(1, gain))
    }

    func apply(to device: AVCaptureDevice) throws {
        guard temperature.isFinite, tint.isFinite, Float(temperature).isFinite, Float(tint).isFinite,
              device.isWhiteBalanceModeSupported(.locked),
              device.isLockingWhiteBalanceWithCustomDeviceGainsSupported else {
            throw PortError.message("Manual white balance is unavailable on this camera.")
        }
        let values = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: Float(temperature), tint: Float(tint))
        var gains = device.deviceWhiteBalanceGains(for: values)
        let maximum = device.maxWhiteBalanceGain
        gains.redGain = Self.clampGain(gains.redGain, maximum: maximum)
        gains.greenGain = Self.clampGain(gains.greenGain, maximum: maximum)
        gains.blueGain = Self.clampGain(gains.blueGain, maximum: maximum)
        device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
    }
}
