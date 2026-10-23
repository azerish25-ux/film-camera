import Foundation

/// Per-frame state from j4.p: 9-frame gate weave, 25-frame film breath,
/// short-lived dirt/scratches, and 8/20/45-sample leak traces.
final class FilmDynamics {
    struct Ring {
        var values: [Double]
        var index = 0
        init(_ count: Int, fill: Double = 0) {values = Array(repeating:fill,count:count)}
        mutating func push(_ value: Double) {values[index] = value; index = (index+1)%values.count}
        var mean: Double {values.reduce(0,+)/Double(values.count)}
    }
    private var random = JavaRandom(seed:0x16)
    private var x = Ring(9), y = Ring(9), shake = Ring(5)
    private var breath = [Ring(25),Ring(25),Ring(25)], fog = Ring(25)
    private var red = Ring(8,fill:1), holesX = Ring(20), holesY = Ring(45)
    private var redTarget = 1.0, holesTargetX = 1.0, holesTargetY = 0.0
    private var redNext = 0.0, holesNextX = 0.0, holesNextY = 0.0
    private var previousHolesX = 0.0, previousHolesY = 0.0
    private(set) var frame = 0
    private(set) var shiftX = 0.0, shiftY = 0.0, fastShake = 0.0
    private(set) var breathRGB = [Double](repeating:0,count:3)
    private(set) var fogAmplitude = 0.0
    private(set) var redTop = 1.0, redBottom = 1.0
    private(set) var holeTopX = 0.0, holeBottomX = 0.0, holeTopY = 0.0, holeBottomY = 0.0
    private(set) var stainX = 0, stainY = 0, stainW = 0, stainH = 0, stainTime = 0
    private(set) var stainMask = [Float](repeating:1,count:576)
    private(set) var scratchX = 0.0, scratchY = 0.0, scratchVX = 0.0, scratchVY = 0.0, scratchLength = 0.0, scratchTime = 0
    private(set) var scratchD = [Float](repeating:0,count:100)
    private(set) var verticalX = [Float](repeating:0,count:8), verticalT = [Float](repeating:0,count:8), verticalTime = 0
    func advance(settings s: FilmSettings, width: Int, height: Int, time: Double) {
        let jitter = Int(s["jitter"]*Double(height)/720), vertical = Int(s["shake"]*Double(height)/720)
        if jitter > 0 {x.push(Double(random.int(jitter*3))/Double(width)); y.push(Double(random.int(jitter*3+1))/Double(height))}
        shiftX = jitter > 0 ? x.mean : 0; shiftY = jitter > 0 ? y.mean : 0
        if vertical > 0 {shake.push((Double(random.int(vertical*3))-Double(vertical)*0.8)/Double(height)/5)}
        fastShake = vertical > 0 ? max(0,shake.mean)*(frame%2 == 0 ? 1 : -1) : 0
        let amount = Int(s["flicker"])
        for channel in 0..<3 {
            if amount > 0 {breath[channel].push(Double(random.int(amount)-amount/2)/255)}
            breathRGB[channel] = amount > 0 ? breath[channel].mean : 0
        }
        fog.push(amount > 0 ? Double(random.int(amount)-amount/2)/255 : 0)
        fogAmplitude = min(1,max(0,(fog.mean*0.8+1)*s["leakBlue"]))
        if time >= redNext {
            let value = random.unit()*s["leakRed"]
            redTarget = value > 0 ? 1-pow(value,1/(value*40)) : 1
            redNext = time+max(0,random.gaussian()*170+30)/1000
        }
        red.push(redTarget); redTop = redBottom; redBottom = red.mean
        if time >= holesNextX {
            let value = random.unit()*s["leakHoles"]
            holesTargetX = value > 0 ? 1-pow(value,1/(value*40)) : 1
            holesNextX = time+max(0,random.gaussian()*170+100)/1000
        }
        if time >= holesNextY {holesTargetY = random.unit()*s["leakHoles"]; holesNextY = time+max(0,random.gaussian()*170+200)/1000}
        holesX.push(holesTargetX); holesY.push(holesTargetY)
        holeTopX = holesX.mean; holeBottomX = previousHolesX; holeTopY = holesY.mean; holeBottomY = previousHolesY
        previousHolesX = holeTopX; previousHolesY = holeTopY
        dirt(s,width:width,height:height)
        frame += 1
    }
    private func dirt(_ s: FilmSettings, width: Int,height: Int) {
        let odds = max(0,100-Int(s["scratches"]))
        func trigger() -> Bool {odds == 0 || (s["scratches"] > 0 && random.int(odds) == 0)}
        stainTime -= 1
        if stainTime <= 0 && trigger() {
            stainTime = 1; stainW = random.int(22)+2; stainH = random.int(22)+2
            stainX = random.int(max(1,width-stainW)); stainY = random.int(max(1,height-stainH))
            var offsets = (0..<9).map {_ in random.unit()*1.2+0.5}; offsets[4] = 0
            let directions = [(-1,-1),(-1,1),(1,-1),(1,1),(0,0),(0,-1),(0,1),(-1,0),(1,0)]
            stainMask = [Float](repeating:1,count:576)
            for row in 0..<stainH {for column in 0..<stainW {
                let px = (Double(column)+0.5)*6/Double(stainH), py = (Double(row)+0.5)*6/Double(stainW)
                for (n,direction) in directions.enumerated() {
                    let dx = px-(Double(direction.0)*offsets[n]+3), dy = py-(Double(direction.1)*offsets[n]+3)
                    if dx*dx+dy*dy < 1.44 {stainMask[row*24+column] = 0.4}
                }
            }}
        }
        scratchTime -= 1
        if scratchTime <= 0 && trigger() {
            scratchTime = 1
            let dx = Double(random.int(200)-100), dy = Double(random.int(200)-100), length = sqrt(dx*dx+dy*dy)+1e-6
            scratchX = Double(random.int(max(1,width-100))+50); scratchY = Double(random.int(max(1,height-100))+50)
            scratchVX = dx/length; scratchVY = dy/length; scratchLength = Double(random.int(92)+8)
            var phase = 0.0
            for index in 0..<Int(scratchLength) {phase += random.unit()*2; scratchD[index] = Float(scratchLength*0.05*cos(0.1*phase))}
        }
        verticalTime -= 1
        if verticalTime <= 0 && random.int(15) == 0 {
            verticalTime = 60; verticalX[0] = Float(random.int(max(1,width-150))+150); verticalT[0] = Float(random.unit()*0.5+0.5)
        } else {verticalX[0] = verticalX[7]; verticalT[0] = verticalT[7]}
        for index in 1..<8 {verticalX[index] = verticalX[index-1]+Float(random.unit()*2-1); verticalT[index] = Float(1-random.unit()*0.7)}
    }
}
struct JavaRandom {
    private var state: UInt64
    private var cachedGaussian: Double?
    init(seed: UInt64) {state = (seed ^ 0x5DEECE66D) & ((1<<48)-1)}
    mutating func bits(_ count: Int) -> UInt64 {state = (state &* 0x5DEECE66D &+ 11) & ((1<<48)-1); return state >> (48-count)}
    mutating func unit() -> Double {Double(bits(24))/Double(1<<24)}
    mutating func int(_ bound: Int) -> Int {
        guard bound > 0 else {return 0}
        if bound & (bound-1) == 0 {return Int((UInt64(bound)*bits(31))>>31)}
        while true {let b = Int(bits(31)), v = b%bound; if b-v+(bound-1) < Int(Int32.max) {return v}}
    }
    private mutating func double() -> Double {Double((bits(26)<<27)+bits(27))/Double(UInt64(1)<<53)}
    mutating func gaussian() -> Double {
        if let cachedGaussian {self.cachedGaussian = nil; return cachedGaussian}
        while true {
            let x = 2*double()-1, y = 2*double()-1, s = x*x+y*y
            if s >= 1 || s == 0 {continue}
            let factor = sqrt(-2*log(s)/s)
            cachedGaussian = y*factor; return x*factor
        }
    }
}
