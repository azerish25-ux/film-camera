import Vision
import CoreImage

/// Native iOS substitute for the APK's OpenCV point-of-interest tracker.
final class MotionPOI {
    private let lock = NSLock()
    private var pending: CGPoint?
    private var request: VNTrackObjectRequest?
    private var handler = VNSequenceRequestHandler()
    func select(_ point:CGPoint) {lock.lock(); pending = point; lock.unlock()}
    func reset() {lock.lock(); pending = nil; request = nil; handler = VNSequenceRequestHandler(); lock.unlock()}
    func update(_ image:CIImage) throws -> CGPoint? {
        lock.lock(); defer {lock.unlock()}
        if let point = pending {
            let rectangle = CGRect(x:min(0.9,max(0,point.x-0.05)),y:min(0.9,max(0,1-point.y-0.05)),width:0.1,height:0.1)
            request = VNTrackObjectRequest(detectedObjectObservation:VNDetectedObjectObservation(boundingBox:rectangle))
            request?.trackingLevel = .accurate; pending = nil; handler = VNSequenceRequestHandler()
        }
        guard let request else {return nil}
        try handler.perform([request],on:image)
        guard let result = request.results?.first as? VNDetectedObjectObservation,result.confidence > 0.6 else {self.request = nil; return nil}
        request.inputObservation = result
        return CGPoint(x:result.boundingBox.midX,y:1-result.boundingBox.midY)
    }
}
