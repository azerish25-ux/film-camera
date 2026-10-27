import AVFoundation

extension CameraController {
    func handleRawPhoto(_ photo:AVCapturePhoto,error:Error?) -> Bool {
        guard let context = rawCapture,context.activeID == photo.resolvedSettings.uniqueID else {return false}
        if let error {report(error); requestRawStop(); return true}
        guard photo.isRawPhoto,let data = photo.fileDataRepresentation() else {report(PortError.message("Native RAW photo delivery failed.")); requestRawStop(); return true}
        let timestamp = RawCaptureClock.nanoseconds(photo.timestamp.seconds)
        context.writing = true
        Task {
            do {
                try await context.writer.appendFrame(data,timestampNs:timestamp)
                self.queue.async {
                    guard self.rawCapture?.id == context.id else {return}
                    context.writing = false; context.count += 1; context.lastTimestamp = timestamp
                    if context.firstTimestamp == nil {context.firstTimestamp = timestamp}
                    let seconds = Double(timestamp-(context.firstTimestamp ?? timestamp))/1e9
                    let fps = seconds > 0 ? Double(max(0,context.count-1))/seconds : 0
                    let text = String(format:"RAW • %d frames • %.2f fps",context.count,fps)
                    DispatchQueue.main.async {self.captureStats = text}
                    self.advanceRawCapture(context)
                }
            } catch {
                self.queue.async {guard self.rawCapture?.id == context.id else {return}; context.writing = false; self.report(error); self.requestRawStop()}
            }
        }
        return true
    }
    func handleRawCaptureFinished(_ settings:AVCaptureResolvedPhotoSettings,error:Error?) -> Bool {
        guard let context = rawCapture,context.activeID == settings.uniqueID else {return false}
        photoInFlight = false; context.activeID = nil
        if let error {report(error); requestRawStop()}
        advanceRawCapture(context); return true
    }
}
