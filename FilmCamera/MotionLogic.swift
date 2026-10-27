import Foundation

enum MotionCaptureMode: String, Codable, CaseIterable, Identifiable {
    case photo = "Photo", zsl = "ZSL", night = "Night", burst = "Burst", rawVideo = "Video", timelapse = "Timelapse"
    var id: String {rawValue}
    var title: String {self == .rawVideo ? "RAW sequence" : rawValue}
}

enum MotionExposure {
    struct Pair: Equatable {let iso: Int; let seconds: Double}
    static let frameRates = [60,50,48,30,25,24,15,10,5,2,1,480,240,120]
    static let isoSteps = [12,16,20,25,32,40,50,64,80,100,125,160,200,250,320,400,500,640,800,1000,1250,1600,2000,2500,3200,4000,5000,6400,12800]
    static let shutters: [Double] = [30,25,20,15,13,10,8,6,5,4,3.2,2.5,2,1.6,1.3,1,0.8,0.6,0.5,0.4,0.3] + [4.0,5,6,8,10,13,15,20,25,30,40,50,60,80,100,125,160,200,250,320,400,500,640,800,1000,1250,1600,2000,2500,3200,4000,5000,6400,8000,10000,100000].map {1/$0}
    static let ramp: [Pair] = {
        var a = [0.000125,0.00015625,0.0002,0.00025,0.0003125,0.0004,0.0005,0.000625,0.0008,0.001,0.00125,0.0015625,0.002,0.0025,0.003125,0.004,0.005,0.00625,0.008,0.01,0.0125,1.0/60].map {Pair(iso:100,seconds:$0)}
        a += [125,160,200,250,320,400].map {Pair(iso:$0,seconds:1.0/60)}
        a += [0.02,0.025,1.0/30].map {Pair(iso:400,seconds:$0)}
        a += [500,640,800,1000].map {Pair(iso:$0,seconds:1.0/30)}
        a += [0.04,0.05,1.0/15,1.0/13,0.1].map {Pair(iso:1000,seconds:$0)}
        a += [1250,1600,2000,2500,3200].map {Pair(iso:$0,seconds:0.1)}
        a += [0.125,1.0/6,0.2,0.25,1.0/3].map {Pair(iso:3200,seconds:$0)}
        return a
    }()
    static func ev(aperture: Double, seconds: Double, iso: Double) -> Double {
        log2(max(1e-12,aperture*aperture)/max(1e-12,seconds)) - log2(max(1e-12,iso/100))
    }
    static func nearest(aperture: Double, seconds: Double, iso: Double) -> Pair {
        let target = ev(aperture:aperture,seconds:seconds,iso:iso)
        return ramp.min {abs(ev(aperture:aperture,seconds:$0.seconds,iso:Double($0.iso))-target) < abs(ev(aperture:aperture,seconds:$1.seconds,iso:Double($1.iso))-target)}!
    }
    static func shutterNanoseconds(fps: Int, angle: Int) -> Int64 {
        guard angle > 0, fps != 0 else {return 0}
        return Int64((1e9 * Double(min(360,angle)) / (Double(fps < 0 ? 30 : fps)*360)).rounded())
    }
    static func display(seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else {return "Auto"}
        return seconds > 0.39 ? String(format:"%.1f",seconds) : "1/\(Int((1/seconds).rounded()))"
    }
    static func mergeCount(ev: Double, shadows: Double) -> Int {
        let base = ev > 7.996875 ? 4 : ev > 5.996875 ? 6 : ev > 3.996875 ? 8 : 12
        return min(12,base + (shadows > 7.996875 ? 4 : 0) + (shadows > 15.999756 ? 2 : 0))
    }
    static func shadowKey(ev: Double) -> Double {
        min(0.5,1.03-8/(log2(pow(10,min(80,max(-80,ev)))+1)+8))
    }
    static func estimate(histogram: [Double], ev: Double) -> (shadows:Double,exposure:Double) {
        guard histogram.count > 1, histogram.allSatisfy({$0.isFinite && $0 >= 0}), histogram.reduce(0,+) > 0 else {return (1,0)}
        let n = histogram.count, total = histogram.reduce(0,+), trim = Int((Double(n)*0.005+0.5).rounded(.down))
        var weighted = 0.0, count = 0.0, cumulative = 0.0, percentile = n-1
        for i in 0..<n {
            let weight = histogram[i]/total
            if i >= trim && i < n-trim {weighted += weight*log(Double(i)/Double(n)+1e-5); count += weight}
            cumulative += weight
            if cumulative >= 0.995 && percentile == n-1 {percentile = i}
        }
        let average = exp(weighted/(count+1e-5))
        let shadows = pow(2,min(5,max(0,shadowKey(ev:ev)/max(1e-10,average))))
        return (shadows,min(2,log2(Double(n)/Double(percentile+1))))
    }
}

struct MotionGrade: Codable, Equatable {
    var enabled = false
    var exposure = 0.0
    var shadows = 1.0
    var highlights = 0.0
    var whitePoint = 1.0
    var contrast = 0.5
    var blacks = 0.0
    var saturation = 1.0
    var temperature = 6500.0
    var tint = 0.0
    var sharpen0 = 1.5
    var sharpen1 = 1.5
    var pop = 1.0
    var greens = 0.0
    var blues = 0.0
    var denoise = 0.0
    var cropWidth = 0.0
    var cropHeight = 0.0
    var squeezeX = 1.0
    var squeezeY = 1.0
    var flip180 = false
    enum Parameter: String, CaseIterable {
        case shadows,highlights,whitePoint,contrast,blacks,exposure,saturation,greens,blues,temperature,tint,sharpen0,sharpen1,pop,spatialDenoiseLevel
    }
    static func value(_ parameter: Parameter, progress p: Double) -> Double {
        switch parameter {
        case .shadows: return pow(2,p/100*6)
        case .highlights: return p/12.5
        case .whitePoint: return p * -0.005+1.25
        case .contrast: return p/100
        case .blacks: return p/400
        case .exposure: return (p-16)/4
        case .saturation: return p > 50 ? 1+(p-50)/50 : p/100*2
        case .greens,.blues: return (p-50)/100*40
        case .temperature: return p+2000
        case .tint: return p-150
        case .sharpen0,.sharpen1: return 1+p/50
        case .pop: return 1+p/100
        case .spatialDenoiseLevel: return p-1
        }
    }
    static let denoiseWeights: [[Double]] = [[0,0,0,0],[0.5,0,0,0],[1,0.5,0,0],[2,1,1,0],[4,2,1,1],[4,4,2,1]]
    mutating func validate() {
        func clean(_ x:Double,_ range:ClosedRange<Double>,_ fallback:Double) -> Double {x.isFinite ? min(range.upperBound,max(range.lowerBound,x)) : fallback}
        exposure = clean(exposure,-4...4,0); shadows = clean(shadows,1...64,1)
        highlights = clean(highlights,0...8,0); whitePoint = clean(whitePoint,0.5...1.5,1)
        contrast = clean(contrast,0...1,0.5); blacks = clean(blacks,0...0.25,0)
        saturation = clean(saturation,0...2,1); temperature = clean(temperature,2000...12000,6500)
        tint = clean(tint,-150...150,0); sharpen0 = clean(sharpen0,1...3,1.5)
        sharpen1 = clean(sharpen1,1...3,1.5); pop = clean(pop,1...2,1)
        greens = clean(greens,-20...20,0); blues = clean(blues,-20...20,0)
        denoise = clean(denoise,0...5,0); cropWidth = clean(cropWidth,0...90,0)
        cropHeight = clean(cropHeight,0...90,0); squeezeX = clean(squeezeX,0.5...2,1); squeezeY = clean(squeezeY,0.5...2,1)
    }
}

struct MotionFocusState {
    enum Mode {case continuous, selected, locked, manual}
    private(set) var mode: Mode = .continuous
    private(set) var point: SIMD2<Double>?
    private var selectedAt = 0.0
    mutating func select(_ p: SIMD2<Double>, time: Double) -> Bool {
        if let old = point, hypot(p.x-old.x,p.y-old.y) < 0.05 {return false}
        point = p; selectedAt = time; mode = .selected; return true
    }
    mutating func lock() {mode = .locked}
    mutating func manual() {mode = .manual}
    mutating func reset() {mode = .continuous; point = nil}
    mutating func update(time: Double, settled: Bool) -> Bool {
        if mode == .selected && settled && time-selectedAt >= 5 {reset(); return true}; return false
    }
}

struct MotionOrientation {
    enum Orientation: Int {case portrait = 0, reversePortrait = 1, landscape = 2, reverseLandscape = 3}
    private(set) var orientation: Orientation = .portrait
    private var pitches: [Double] = [], rolls: [Double] = []
    mutating func update(pitch: Double, roll: Double) -> Orientation {
        guard pitch.isFinite,roll.isFinite else {return orientation}
        pitches.append(pitch.rounded()); rolls.append(roll.rounded())
        if pitches.count > 32 {pitches.removeFirst(); rolls.removeFirst()}
        guard pitches.count == 32 else {return orientation}
        let p = (pitches.reduce(0,+)/32).rounded(), r = (rolls.reduce(0,+)/32).rounded()
        if ((orientation == .portrait || orientation == .reversePortrait) && abs(r) < 30) || abs(p) >= 30 {orientation = p > 0 ? .reversePortrait : .portrait}
        else {orientation = r > 0 ? .reverseLandscape : .landscape}
        return orientation
    }
}
