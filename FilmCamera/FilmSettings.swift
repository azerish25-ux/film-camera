import Foundation

enum FilmFrame: String, Codable, CaseIterable, Identifiable {
    case original = "Original", super16 = "Super 16mm", sixteen = "16mm", eight = "Super 8mm Canon", wide = "16:9", classic = "4:3", scope = "2.39:1", framed = "Super 16 frame", raw2 = "Super 16 raw 2", bolex = "Bolex", beaulieu = "Beaulieu", kiev = "Kiev16U"
    var id: String { rawValue }
    var ratio: Double? {
        switch self {
        case .original: return nil
        case .super16, .framed, .raw2, .bolex: return 1.66
        case .wide: return 16.0/9
        case .scope: return 2.39
        default: return 4.0/3
        }
    }
    var perforations: Bool { [.super16,.sixteen,.eight,.raw2,.bolex,.beaulieu,.kiev].contains(self) }
}
struct Adjustment: Identifiable {
    let id: String
    let label: String
    let range: ClosedRange<Double>
    let initial: Double
    static let all: [Adjustment] = [
        .init(id:"exposure",label:"Exposure",range:-3...3,initial:0),
        .init(id:"contrast",label:"Contrast",range:0...2,initial:1),
        .init(id:"saturation",label:"Saturation",range:0...2,initial:1),
        .init(id:"temperature",label:"Temperature",range:2000...10000,initial:6600),
        .init(id:"tint",label:"Tint",range:-100...100,initial:0),
        .init(id:"grain",label:"Grain amount",range:0...1,initial:0),
        .init(id:"grainSize",label:"Grain size",range:0...1,initial:0.5),
        .init(id:"grainChroma",label:"Grain chroma",range:0...1,initial:0),
        .init(id:"grainShadows",label:"Grain shadows",range:0...1,initial:0),
        .init(id:"grainSmoothness",label:"Grain smoothness",range:0...1,initial:0),
        .init(id:"vignette",label:"Vignette",range:0...1,initial:0),
        .init(id:"halation",label:"Halation",range:0...1,initial:0),
        .init(id:"halationRadius",label:"Halation radius",range:0...19,initial:0),
        .init(id:"halationCutoff",label:"Halation cutoff",range:0...0.995,initial:0.35),
        .init(id:"halationGreen",label:"Halation green",range:0...1,initial:0.3),
        .init(id:"halationBlue",label:"Halation blue",range:0...1,initial:0.04),
        .init(id:"blur",label:"Blur",range:0...19,initial:0),
        .init(id:"chroma",label:"Chromatic aberration",range:0...19,initial:0),
        .init(id:"flicker",label:"Film breath",range:0...100,initial:0),
        .init(id:"jitter",label:"Slow shift",range:0...30,initial:0),
        .init(id:"shake",label:"Fast shake",range:0...30,initial:0),
        .init(id:"scratches",label:"Scratches intensity",range:0...100,initial:0),
        .init(id:"verticalScratch",label:"Vertical scratch",range:0...1,initial:0),
        .init(id:"scratchColor",label:"Scratches color",range:0...1,initial:0.8),
        .init(id:"leakRed",label:"Red light leak",range:0...1,initial:0),
        .init(id:"leakBlue",label:"Blue light leak",range:0...1,initial:0),
        .init(id:"leakHoles",label:"Perforation light leak",range:0...1,initial:0),
        .init(id:"perfColor",label:"Perforation color",range:0...1,initial:0.85)
    ]
}
struct FilmSettings: Codable, Equatable {
    var values: [String: Double] = [:]
    var frame: FilmFrame = .original
    var look = "Normal Mode"
    var lutID: UUID?
    var curveX: [Double] = [0,50,100,150,200,255]
    var curveY: [Double] = [30,50,100,150,200,255]
    subscript(_ key: String) -> Double {
        get { values[key] ?? Adjustment.all.first(where: { $0.id == key })?.initial ?? 0 }
        set {
            guard let spec = Adjustment.all.first(where: { $0.id == key }), newValue.isFinite else { return }
            values[key] = min(spec.range.upperBound, max(spec.range.lowerBound, newValue))
        }
    }
    static var looks: [String] {OriginalFilm.all.map(\.name)}
}
struct FilmPreset: Codable, Identifiable {
    var id = UUID()
    var name: String
    var settings: FilmSettings
}
struct CubeLUT: Codable, Identifiable {
    var id = UUID()
    var name: String
    let dimension: Int
    let rgba: [Float]
    let domainMin: [Float]
    let domainMax: [Float]
    static func parse(_ text: String, name: String) throws -> CubeLUT {
        var size = 0, colors: [Float] = [], low: [Float] = [0,0,0], high: [Float] = [1,1,1]
        for line in text.components(separatedBy: .newlines) {
            let p = line.components(separatedBy:"#")[0].split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard let key = p.first else { continue }
            switch key {
            case "TITLE": continue
            case "LUT_3D_SIZE":
                guard p.count == 2, let n = Int(p[1]), (2...64).contains(n) else { throw PortError.message("LUT size must be 2-64.") }
                size = n
            case "DOMAIN_MIN", "DOMAIN_MAX":
                let v = p.dropFirst().compactMap(Float.init)
                guard v.count == 3, v.allSatisfy({ $0.isFinite }) else { throw PortError.message("Invalid LUT domain.") }
                if key == "DOMAIN_MIN" { low = v } else { high = v }
            default:
                let v = p.compactMap(Float.init)
                guard v.count == 3, v.allSatisfy({ $0.isFinite }), colors.count < 64*64*64*4 else { throw PortError.message("Invalid CUBE data.") }
                colors.append(contentsOf:v + [1])
            }
        }
        guard size > 1, colors.count == size*size*size*4, zip(low,high).allSatisfy({ $0 < $1 }) else { throw PortError.message("Incomplete CUBE table.") }
        return CubeLUT(name:name,dimension:size,rgba:colors,domainMin:low,domainMax:high)
    }
}
enum PortError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
