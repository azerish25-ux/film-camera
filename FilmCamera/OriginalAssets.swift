import Foundation
import AVFoundation
import CoreImage

final class OriginalAssetSampler {
    private var generators: [String: AVAssetImageGenerator] = [:]
    private var frames: [String: (Int,CGImage)] = [:]
    private var durations: [String:Double] = [:]
    private var rates: [String:Double] = [:]
    func frame(_ name: String, time: Double) throws -> CGImage {
        guard let url = Bundle.main.url(forResource:name,withExtension:"mp4") else {throw PortError.message("Missing original frame film \(name)")}
        let generator: AVAssetImageGenerator
        if let cached = generators[name] {generator = cached}
        else {
            let asset = AVURLAsset(url:url)
            generator = AVAssetImageGenerator(asset:asset)
            generator.requestedTimeToleranceBefore = .zero; generator.requestedTimeToleranceAfter = .zero
            generator.appliesPreferredTrackTransform = true; generators[name] = generator
            durations[name] = asset.duration.seconds
            rates[name] = Double(asset.tracks(withMediaType:.video).first?.nominalFrameRate ?? 24)
        }
        let duration = durations[name] ?? 0, rate = max(1,rates[name] ?? 24)
        let seconds = duration.isFinite && duration > 0 ? max(0,time).truncatingRemainder(dividingBy:duration) : 0
        let index = Int(seconds*rate)
        if let cached = frames[name], cached.0 == index {return cached.1}
        let image = try generator.copyCGImage(at:CMTime(seconds:Double(index)/rate,preferredTimescale:60000),actualTime:nil)
        frames[name] = (index,image); return image
    }
}
extension FilmFrame {
    var originalShader: String {
        switch self {
        case .framed: return "c_f25852e"
        case .kiev: return "c_f25864q"
        case .super16: return "c_f25850c"
        case .sixteen: return "c_f25849b"
        case .raw2: return "c_f25848a"
        case .bolex: return "c_f25853f"
        case .beaulieu: return "c_f25854g"
        case .eight: return "c_f25851d"
        default: return "c_f25855h"
        }
    }
    var originalMask: String? {
        switch self {
        case .super16: return "2259c520d9189575d3aaf0917020e5169b061b31"
        case .sixteen: return "5d449fd4eccf157610c7424886f669ecb801c570"
        case .eight: return "ab3e7a3b1f83b9c9cb22906a99c963af9e367d34"
        case .raw2: return "533ddf7a2e5735a50bbd989c6dd492b83340edbd"
        case .bolex: return "0c2f3fcd78b56ff4abf74fe1ec57517c917ce454"
        case .beaulieu: return "70e656d91d96d2a87ef1a5e5cad996670cc29a93"
        case .kiev: return "25917224e2d0b1d8495cea0ee4ea650980bc86ad"
        default: return nil
        }
    }
    var originalVideo: String? {
        switch self {
        case .super16: return "749ced71a03805d69d45f2288576b067dea10364"
        case .sixteen: return "cc444fda578d964236bd148cf2fde485d52e3cc2"
        case .eight: return "14937b4f0eb590ddd915af2f55d17ab2a254cc0b"
        case .raw2: return "122f2e1a898866409d09098fdf387269a3d13481"
        case .bolex: return "e4e611d54153de5ceeeb349ad8b90e9f9fa268c7"
        case .beaulieu: return "8429d111b29661ad2eeed91378cb8e3bb325c5e2"
        case .kiev: return "af13dd8934d9a4dd2120747371e1f69240484845"
        default: return nil
        }
    }
    var blurPadding: Double {
        switch self {case .super16:return 0.11; case .sixteen,.raw2:return 0.15; case .eight,.bolex:return 0.16; default:return 0}
    }
}

extension FilmFrame {
    var holeGeometry: (Double,Double,Double) {
        switch self {
        case .super16:return (0.77,1.4,-0.35)
        case .sixteen:return (0.77,1.4,-0.39)
        case .raw2:return (0.63,1.4,-0.35)
        case .bolex:return (0.86,1,-0.44)
        case .kiev:return (0.71,1.4,-0.35)
        default:return (1,1,0)
        }
    }
}

enum FilmBurn {
    static let clips = ["fb6de461e7725ac8c6adc93ce40d9be33058f87b","7279f61845c546ea5a98521a24361e0fd7f1dab8","ebf7742d8724b91d81f26c099a7b84aafced9c9c","219d4a1d9955023fb00ee040507bfba392157e26","a071faf6bfb388993c6db6ead6942ffd89da9334","917d6d8b0e4a29253b6f0bcd1626c5f7483b1a78","0a4c51f6cc776d9a4c73e2eb83acf7e777e2b0e5"]
}

extension FilmFrame {
    /// Android's container ratios (o4.h5), including the full scanned gate.
    func outputSize(for source: CGSize) -> CGSize {
        guard let ratio else {return source}
        let target = source.width < source.height ? 1/ratio : ratio
        let width = min(source.width,source.height*target)
        let height = min(source.height,source.width/target)
        return CGSize(width:max(2,floor(width/2)*2),height:max(2,floor(height/2)*2))
    }
}
