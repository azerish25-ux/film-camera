import CoreMotion
import UIKit

struct MotionSample {let time:Double; let value:SIMD3<Double>}
enum MotionGyroflow {
    static func encode(gyro:[MotionSample],accel:[MotionSample],model:String,startMilliseconds:Int64) throws -> String {
        guard gyro.count >= 2,accel.count >= 2 else {throw PortError.message("Insufficient motion samples.")}
        for samples in [gyro,accel] {
            guard samples.allSatisfy({$0.time.isFinite && $0.value.x.isFinite && $0.value.y.isFinite && $0.value.z.isFinite}),zip(samples,samples.dropFirst()).allSatisfy({$0.time < $1.time}) else {throw PortError.message("Invalid motion timeline.")}
        }
        func step(_ samples:[MotionSample]) -> Double {let n = min(20,samples.count); return (samples[n-1].time-samples[0].time)/Double(n)}
        let period = min(step(gyro),step(accel)), start = max(gyro[0].time,accel[0].time), end = min(gyro.last!.time,accel.last!.time)
        guard period > 0,end > start,(end-start)/period <= 2_000_000 else {throw PortError.message("Invalid motion log duration.")}
        var text = "GYROFLOW IMU LOG\nversion,1.2\nid,\(model.replacingOccurrences(of:" ",with:"."))\norientation,XYZ\nfwversion,Super16-iOS\ntimestamp,\(startMilliseconds)\nvendor,Super16 MotionCam port\ntscale,\(String(format:"%.10f",period))\ngscale,0.0000000100\nascale,0.0000000100\nt,gx,gy,gz,ax,ay,az\n"
        var g = 0,a = 0
        func interpolate(_ s:[MotionSample],_ t:Double,_ i:inout Int) -> SIMD3<Double> {
            while i+1 < s.count-1 && s[i+1].time < t {i += 1}
            let f = (t-s[i].time)/(s[i+1].time-s[i].time)
            return s[i].value+(s[i+1].value-s[i].value)*f
        }
        for k in 0..<Int((end-start)/period) {
            let time = start+Double(k)*period, gv = interpolate(gyro,time,&g), av = interpolate(accel,time,&a)
            let values = [gv.x,gv.y,gv.z,av.x,av.y,av.z].map {String(Int64(($0*1e8).rounded()))}.joined(separator:",")
            text += "\(k),\(values),\n"
        }
        return text
    }
}
final class MotionLogger {
    private let manager = CMMotionManager()
    private let queue: OperationQueue = {let q = OperationQueue(); q.maxConcurrentOperationCount = 1; return q}()
    private let lock = NSLock()
    private var gyro: [MotionSample] = [],accel: [MotionSample] = []
    private var start: Int64 = 0
    func begin() throws {
        guard manager.isGyroAvailable,manager.isAccelerometerAvailable else {throw PortError.message("Motion sensors are unavailable on this device.")}
        lock.lock(); gyro = []; accel = []; start = Int64(Date().timeIntervalSince1970*1000); lock.unlock()
        manager.gyroUpdateInterval = 0.01; manager.accelerometerUpdateInterval = 0.01
        manager.startGyroUpdates(to:queue) {[weak self] sample,_ in
            guard let self,let sample else {return}; self.lock.lock(); defer {self.lock.unlock()}
            if self.gyro.count < 180_000 {self.gyro.append(MotionSample(time:sample.timestamp,value:SIMD3(sample.rotationRate.x,sample.rotationRate.y,sample.rotationRate.z)))}
        }
        manager.startAccelerometerUpdates(to:queue) {[weak self] sample,_ in
            guard let self,let sample else {return}; self.lock.lock(); defer {self.lock.unlock()}
            if self.accel.count < 180_000 {self.accel.append(MotionSample(time:sample.timestamp,value:SIMD3(sample.acceleration.x,sample.acceleration.y,sample.acceleration.z)*9.80665))}
        }
    }
    func finish(to url:URL) throws {
        manager.stopGyroUpdates(); manager.stopAccelerometerUpdates(); queue.waitUntilAllOperationsAreFinished()
        lock.lock(); let g = gyro,a = accel,t = start; gyro = []; accel = []; lock.unlock()
        let text = try MotionGyroflow.encode(gyro:g,accel:a,model:UIDevice.current.model,startMilliseconds:t)
        try text.write(to:url,atomically:true,encoding:.utf8)
    }
    deinit {manager.stopGyroUpdates(); manager.stopAccelerometerUpdates()}
}
