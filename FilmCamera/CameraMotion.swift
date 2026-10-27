import UIKit
import CoreImage

extension CameraController {
    func capturePreRoll(mode: MotionCaptureMode,directory:URL) {
        DispatchQueue.main.async {self.processing = true}
        let state = current(), opts = options()
        frames.async {
            defer {DispatchQueue.main.async {self.processing = false}}
            do {
                let captured = self.preRoll.latest(mode == .zsl ? 1 : mode == .night ? self.suggestedMergeCount : 30)
                let images: [CIImage]
                if mode == .night {images = [try MotionPreRoll.merge(captured,align:true)]}
                else {images = captured.map {CIImage(cgImage:$0)}}
                guard !images.isEmpty else {throw PortError.message("Camera pre-roll is empty.")}
                for image in images {
                    let rendered = try self.renderer.render(image,settings:state.0,lut:state.1)
                    guard let cg = self.renderer.context.createCGImage(rendered,from:rendered.extent),let data = UIImage(cgImage:cg).jpegData(compressionQuality:min(1,max(0.1,opts.jpegQuality/100))) else {throw PortError.message("Cannot encode capture.")}
                    let url = directory.appendingPathComponent("Motion-\(UUID().uuidString).jpg"); try data.write(to:url,options:.atomic)
                    DispatchQueue.main.async {self.onMedia?(url)}
                }
            } catch {self.report(error)}
        }
    }
    func toggleTimelapse(to url:URL) {
        frames.async {
            if self.timelapseTarget != nil {self.finishTimelapse(); return}
            let opts = self.options(); self.timelapseTarget = url
            self.timelapseDeadline = opts.unlimited ? .greatestFiniteMagnitude : max(0.01,opts.totalMinutes)*60
            if opts.saveGyro {do {try self.motionLogger.begin(); self.logging = true} catch {self.report(error)}}
            DispatchQueue.main.async {self.recording = true}
        }
    }
    func finishTimelapse() {
        frames.async {
            guard let target = self.timelapseTarget else {return}
            self.timelapseTarget = nil
            if self.logging {self.logging = false; do {try self.motionLogger.finish(to:target.deletingPathExtension().appendingPathExtension("gcsv"))} catch {self.report(error)}}
            let writer = self.timelapse; self.timelapse = nil
            writer?.finish {result in DispatchQueue.main.async {self.recording = false; switch result {case .success(let url): self.onMedia?(url); case .failure(let error): self.message = error.localizedDescription}}}
            if writer == nil {DispatchQueue.main.async {self.recording = false}}
        }
    }
}
