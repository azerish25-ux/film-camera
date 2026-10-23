import AVFoundation
import UIKit

final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var preview: UIImage?
    @Published var message: String?
    @Published var ready = false
    @Published var recording = false
    @Published var processing = false
    @Published var audioEnabled = false
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label:"film.camera")
    private let frames = DispatchQueue(label:"film.frames")
    private let photo = AVCapturePhotoOutput()
    private let movie = AVCaptureMovieFileOutput()
    private let video = AVCaptureVideoDataOutput()
    private var device: AVCaptureDevice?
    private var position: AVCaptureDevice.Position = .back
    private let renderer = FilmRenderer()
    private let lock = NSLock()
    private var film = FilmSettings()
    private var lut: CubeLUT?
    private var snapshot: (FilmSettings,CubeLUT?) = (FilmSettings(),nil)
    private var onPhoto: ((UIImage) -> Void)?
    var onMovie: ((URL,FilmSettings,CubeLUT?) -> Void)?
    private var lastFrame = CMTime.zero
    func update(_ settings: FilmSettings, lut: CubeLUT?) { lock.lock(); film = settings; self.lut = lut; lock.unlock() }
    private func current() -> (FilmSettings,CubeLUT?) { lock.lock(); defer { lock.unlock() }; return (film,lut) }
    func start() {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return }
        Task {
            let granted = await AVCaptureDevice.requestAccess(for:.video)
            guard granted else { DispatchQueue.main.async { self.message = "Camera access is disabled. Enable it in Settings, or import media in Editor." }; return }
            let audio = await AVCaptureDevice.requestAccess(for:.audio)
            DispatchQueue.main.async { self.audioEnabled = audio }
            queue.async {
                do {
                    if self.session.inputs.isEmpty { try self.configure(audio:audio) }
                    self.session.startRunning()
                    DispatchQueue.main.async { self.ready = true }
                } catch { self.report(error) }
            }
        }
    }
    func stop() { queue.async { if self.movie.isRecording { self.movie.stopRecording() }; self.session.stopRunning() } }
    private func configure(audio: Bool) throws {
        session.beginConfiguration(); defer { session.commitConfiguration() }
        session.sessionPreset = .hd1920x1080
        try addCamera()
        if audio, let mic = AVCaptureDevice.default(for:.audio) {
            let input = try AVCaptureDeviceInput(device:mic)
            if session.canAddInput(input) { session.addInput(input) }
        }
        for output in [photo as AVCaptureOutput,movie,video] {
            guard session.canAddOutput(output) else { throw PortError.message("Camera output is unavailable.") }
            session.addOutput(output)
        }
        video.alwaysDiscardsLateVideoFrames = true
        video.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
        video.setSampleBufferDelegate(self,queue:frames)
        orient()
    }
    private func addCamera() throws {
        guard let found = AVCaptureDevice.default(.builtInWideAngleCamera,for:.video,position:position) else { throw PortError.message("No camera on this device. Use Editor to import media.") }
        let input = try AVCaptureDeviceInput(device:found)
        guard session.canAddInput(input) else { throw PortError.message("Cannot open camera.") }
        session.addInput(input); device = found
    }
    private func orient() {
        for connection in [video.connection(with:.video),photo.connection(with:.video),movie.connection(with:.video)].compactMap({$0}) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported { connection.automaticallyAdjustsVideoMirroring = false; connection.isVideoMirrored = position == .front }
        }
    }
    func flip() {
        queue.async {
            guard !self.movie.isRecording else { return }
            self.session.beginConfiguration()
            let old = self.session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first { $0.device.hasMediaType(.video) }
            if let old { self.session.removeInput(old) }
            self.position = self.position == .back ? .front : .back
            do { try self.addCamera() } catch { if let old, self.session.canAddInput(old) { self.session.addInput(old); self.device = old.device }; self.report(error) }
            self.orient(); self.session.commitConfiguration()
        }
    }
    func controls(zoom: Double, bias: Double, focus: Double?, iso: Double?, shutter: Double?, torch: Bool, fps: Double) {
        queue.async {
            guard let d = self.device else { return }
            do {
                try d.lockForConfiguration(); defer { d.unlockForConfiguration() }
                d.videoZoomFactor = min(d.maxAvailableVideoZoomFactor,max(d.minAvailableVideoZoomFactor,zoom))
                d.setExposureTargetBias(Float(min(Double(d.maxExposureTargetBias),max(Double(d.minExposureTargetBias),bias))))
                if let focus, d.isFocusModeSupported(.locked) { d.setFocusModeLocked(lensPosition:Float(focus)) }
                else if d.isFocusModeSupported(.continuousAutoFocus) { d.focusMode = .continuousAutoFocus }
                if let iso, let shutter, d.isExposureModeSupported(.custom) {
                    let duration = CMTime(seconds:min(max(shutter,d.activeFormat.minExposureDuration.seconds),d.activeFormat.maxExposureDuration.seconds),preferredTimescale:1_000_000)
                    d.setExposureModeCustom(duration:duration,iso:Float(min(Double(d.activeFormat.maxISO),max(Double(d.activeFormat.minISO),iso))))
                } else if d.isExposureModeSupported(.continuousAutoExposure) { d.exposureMode = .continuousAutoExposure }
                if d.hasTorch, d.isTorchModeSupported(torch ? .on : .off) { d.torchMode = torch ? .on : .off }
                if d.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate <= fps && $0.maxFrameRate >= fps }) {
                    d.activeVideoMinFrameDuration = CMTime(value:1,timescale:Int32(fps)); d.activeVideoMaxFrameDuration = d.activeVideoMinFrameDuration
                }
            } catch { self.report(error) }
        }
    }
    func capture(_ completion: @escaping (UIImage) -> Void) {
        queue.async {
            guard self.session.isRunning, !self.movie.isRecording else { return }
            self.snapshot = self.current(); self.onPhoto = completion
            self.photo.capturePhoto(with:AVCapturePhotoSettings(),delegate:self)
        }
    }
    func toggleRecording() {
        queue.async {
            guard self.session.isRunning else { return }
            if self.movie.isRecording { self.movie.stopRecording() }
            else {
                self.snapshot = self.current()
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
                self.movie.startRecording(to:url,recordingDelegate:self)
                DispatchQueue.main.async { self.recording = true }
            }
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error { report(error); return }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data:data) else { report(PortError.message("Photo decoding failed.")); return }
        do {
            let result = try renderer.photo(image,settings:snapshot.0,lut:snapshot.1)
            DispatchQueue.main.async { self.onPhoto?(result); self.onPhoto = nil }
        } catch { report(error) }
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let saved = snapshot
        DispatchQueue.main.async {
            self.recording = false
            if let error, (error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool != true { self.message = error.localizedDescription; try? FileManager.default.removeItem(at:outputFileURL) }
            else { self.onMovie?(outputFileURL,saved.0,saved.1) }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard time.seconds-lastFrame.seconds > 1/24.0, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastFrame = time
        do {
        let state = current(), image = try renderer.render(CIImage(cvPixelBuffer:buffer),settings:state.0,lut:state.1,time:time.seconds)
        let scale = min(1,720/image.extent.width)
        let small = image.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
        if let cg = renderer.context.createCGImage(small,from:small.extent) { DispatchQueue.main.async { self.preview = UIImage(cgImage:cg) } }
        } catch {report(error)}
    }
    private func report(_ error: Error) { DispatchQueue.main.async { self.message = error.localizedDescription } }
}
