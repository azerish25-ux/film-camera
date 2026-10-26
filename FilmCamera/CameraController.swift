import AVFoundation
import UIKit

final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var preview: UIImage?
    @Published var message: String?
    @Published var ready = false
    @Published var recording = false
    @Published var processing = false
    @Published var audioEnabled = false
    @Published var histogram: [Float] = []
    private var histogramEnabled = false
    @Published var rawSupported = false
    @Published var captureStats = ""
    var motionOptions = MotionCaptureOptions()
    let preRoll = MotionPreRoll()
    let motionLogger = MotionLogger()
    var logging = false
    var rawDestination: URL?
    var timelapse: MotionTimelapse?
    var timelapseTarget: URL?
    var timelapseStarted = 0.0
    var timelapseDeadline = Double.greatestFiniteMagnitude
    var onMedia: ((URL) -> Void)?
    @Published var availableLenses: [String] = ["Wide"]
    private var selectedLens = "Wide"
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label:"film.camera")
    let frames = DispatchQueue(label:"film.frames")
    private let photo = AVCapturePhotoOutput()
    private let movie = AVCaptureMovieFileOutput()
    private let video = AVCaptureVideoDataOutput()
    private var device: AVCaptureDevice?
    private var position: AVCaptureDevice.Position = .back
    let renderer = FilmRenderer()
    private let lock = NSLock()
    private var film = FilmSettings()
    private var lut: CubeLUT?
    private var snapshot: (FilmSettings,CubeLUT?) = (FilmSettings(),nil)
    private var onPhoto: ((UIImage) -> Void)?
    var onMovie: ((URL,FilmSettings,CubeLUT?) -> Void)?
    private var lastFrame = CMTime.zero
    private var photoInFlight = false
    private var rotationAngle = 90.0
    private var orientationObserver: NSObjectProtocol?
    override init() {
        super.init()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(forName:UIDevice.orientationDidChangeNotification,object:nil,queue:.main) {[weak self] _ in
            let orientation = UIDevice.current.orientation
            let angle: Double
            switch orientation {
            case .portrait: angle = 90
            case .portraitUpsideDown: angle = 270
            case .landscapeLeft: angle = 0
            case .landscapeRight: angle = 180
            default: return
            }
            self?.queue.async {[weak self] in
                guard let self, !self.movie.isRecording else {return}
                self.rotationAngle = angle; self.orient()
            }
        }
    }
    deinit {
        if let orientationObserver {NotificationCenter.default.removeObserver(orientationObserver)}
        DispatchQueue.main.async {UIDevice.current.endGeneratingDeviceOrientationNotifications()}
    }
    func update(_ settings: FilmSettings, lut: CubeLUT?) { lock.lock(); film = settings; self.lut = lut; lock.unlock() }
    func updateMotion(_ options: MotionCaptureOptions) {lock.lock(); motionOptions = options; lock.unlock()}
    func options() -> MotionCaptureOptions {lock.lock(); defer {lock.unlock()}; return motionOptions}
    func enableHistogram(_ enabled: Bool) {lock.lock(); histogramEnabled = enabled; lock.unlock()}
    private func needsHistogram() -> Bool {lock.lock(); defer {lock.unlock()}; return histogramEnabled}
    func current() -> (FilmSettings,CubeLUT?) { lock.lock(); defer { lock.unlock() }; return (film,lut) }
    func start() {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }
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
    func stop() { finishTimelapse(); queue.async { if self.movie.isRecording { self.movie.stopRecording() }; self.session.stopRunning(); self.frames.async {self.preRoll.clear()}; DispatchQueue.main.async {self.ready = false} } }
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
        photo.isAppleProRAWEnabled = photo.isAppleProRAWSupported
        DispatchQueue.main.async {self.rawSupported = !self.photo.availableRawPhotoPixelFormatTypes.isEmpty}
        orient()
    }
    private func addCamera() throws {
        let types: [String:AVCaptureDevice.DeviceType] = ["Wide":.builtInWideAngleCamera,"Ultra wide":.builtInUltraWideCamera,"Telephoto":.builtInTelephotoCamera]
        guard let found = AVCaptureDevice.default(types[selectedLens] ?? .builtInWideAngleCamera,for:.video,position:position) else { throw PortError.message("No camera on this device. Use Editor to import media.") }
        let input = try AVCaptureDeviceInput(device:found)
        guard session.canAddInput(input) else { throw PortError.message("Cannot open camera.") }
        session.addInput(input); device = found
        let available = types.keys.sorted().filter {AVCaptureDevice.default(types[$0]!,for:.video,position:position) != nil}
        DispatchQueue.main.async {self.availableLenses = available}
    }
    private func orient() {
        for connection in [video.connection(with:.video),photo.connection(with:.video),movie.connection(with:.video)].compactMap({$0}) {
            if connection.isVideoRotationAngleSupported(rotationAngle) { connection.videoRotationAngle = rotationAngle }
            if connection.isVideoMirroringSupported { connection.automaticallyAdjustsVideoMirroring = false; connection.isVideoMirrored = position == .front }
        }
    }
    func flip() {
        queue.async {
            guard !self.movie.isRecording else { return }
            self.session.beginConfiguration()
            let old = self.session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first { $0.device.hasMediaType(.video) }
            if let old { self.session.removeInput(old) }
            self.position = self.position == .back ? .front : .back; self.selectedLens = "Wide"
            do { try self.addCamera() } catch { if let old, self.session.canAddInput(old) { self.session.addInput(old); self.device = old.device }; self.report(error) }
            self.orient(); self.session.commitConfiguration()
        }
    }
    func selectLens(_ name: String) {
        queue.async {
            guard !self.movie.isRecording else {return}
            self.session.beginConfiguration(); defer {self.session.commitConfiguration()}
            let old = self.session.inputs.compactMap {$0 as? AVCaptureDeviceInput}.first {$0.device.hasMediaType(.video)}
            if let old {self.session.removeInput(old)}
            let previous = self.selectedLens; self.selectedLens = name
            do {try self.addCamera(); self.orient()} catch {
                self.selectedLens = previous
                if let old, self.session.canAddInput(old) {self.session.addInput(old); self.device = old.device}
                self.report(error)
            }
        }
    }
    func setResolution(_ fourK: Bool) {
        queue.async {
            guard !self.movie.isRecording else {return}
            let preset: AVCaptureSession.Preset = fourK ? .hd4K3840x2160 : .hd1920x1080
            self.session.beginConfiguration(); defer {self.session.commitConfiguration()}
            if self.session.canSetSessionPreset(preset) {self.session.sessionPreset = preset}
            else {self.report(PortError.message("This camera does not support the selected resolution."))}
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
                    let duration = CMTime(seconds:min(max(shutter,d.activeFormat.minExposureDuration.seconds),min(1/fps,d.activeFormat.maxExposureDuration.seconds)),preferredTimescale:1_000_000)
                    d.setExposureModeCustom(duration:duration,iso:Float(min(Double(d.activeFormat.maxISO),max(Double(d.activeFormat.minISO),iso))))
                } else if d.isExposureModeSupported(.continuousAutoExposure) { d.exposureMode = .continuousAutoExposure }
                if d.hasTorch, d.isTorchModeSupported(torch ? .on : .off) { d.torchMode = torch ? .on : .off }
                let opts = self.options()
                if opts.aeLock,d.isExposureModeSupported(.locked) {d.exposureMode = .locked}
                if d.isWhiteBalanceModeSupported(opts.awbLock ? .locked : .continuousAutoWhiteBalance) {d.whiteBalanceMode = opts.awbLock ? .locked : .continuousAutoWhiteBalance}
                if opts.shutterAngle > 0,d.isExposureModeSupported(.custom) {
                    let seconds = Double(MotionExposure.shutterNanoseconds(fps:Int(fps),angle:opts.shutterAngle))/1e9
                    d.setExposureModeCustom(duration:CMTime(seconds:min(d.activeFormat.maxExposureDuration.seconds,max(d.activeFormat.minExposureDuration.seconds,seconds)),preferredTimescale:1_000_000_000),iso:AVCaptureDevice.currentISO)
                }
                if d.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.minFrameRate <= fps && $0.maxFrameRate >= fps }) {
                    d.activeVideoMinFrameDuration = CMTime(value:1,timescale:Int32(fps)); d.activeVideoMaxFrameDuration = d.activeVideoMinFrameDuration
                }
            } catch { self.report(error) }
        }
    }
    func capture(rawURL: URL? = nil, _ completion: @escaping (UIImage) -> Void) {
        queue.async {
            guard self.session.isRunning, !self.movie.isRecording, !self.photoInFlight else { return }
            if rawURL != nil && self.photo.availableRawPhotoPixelFormatTypes.isEmpty {self.report(PortError.message("RAW capture is unavailable on this lens. Disable Save DNG or select another camera.")); return}
            self.photoInFlight = true; self.rawDestination = rawURL
            DispatchQueue.main.async {self.processing = true}
            self.snapshot = self.current(); self.onPhoto = completion
            let settings: AVCapturePhotoSettings
            if rawURL != nil,let format = self.photo.availableRawPhotoPixelFormatTypes.first {settings = AVCapturePhotoSettings(rawPixelFormatType:format,processedFormat:[AVVideoCodecKey:AVVideoCodecType.jpeg])}
            else {settings = AVCapturePhotoSettings()}
            self.photo.capturePhoto(with:settings,delegate:self)
        }
    }
    func toggleRecording() {
        queue.async {
            guard self.session.isRunning, !self.photoInFlight else { return }
            if self.movie.isRecording { self.movie.stopRecording() }
            else {
                self.snapshot = self.current()
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
                if let connection = self.movie.connection(with:.audio) {connection.isEnabled = self.options().audio}
                if self.options().saveGyro {do {try self.motionLogger.begin(); self.logging = true} catch {self.report(error)}}
                self.movie.startRecording(to:url,recordingDelegate:self)
                DispatchQueue.main.async { self.recording = true }
            }
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        queue.async {
            if let error {self.report(error); return}
            if photo.isRawPhoto {
                do {guard let url = self.rawDestination,let data = photo.fileDataRepresentation() else {throw PortError.message("Cannot encode DNG.")}; try data.write(to:url,options:.atomic); DispatchQueue.main.async {self.onMedia?(url)}} catch {self.report(error)}
                return
            }
            guard let data = photo.fileDataRepresentation(), let image = UIImage(data:data) else {self.report(PortError.message("Photo decoding failed.")); return}
            do {
                let result = try self.renderer.photo(image,settings:self.snapshot.0,lut:self.snapshot.1)
                let completion = self.onPhoto; self.onPhoto = nil
                DispatchQueue.main.async {completion?(result)}
            } catch {self.onPhoto = nil; self.report(error)}
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput,didFinishCaptureFor resolvedSettings:AVCaptureResolvedPhotoSettings,error:Error?) {
        queue.async {self.photoInFlight = false; self.rawDestination = nil; if let error {self.report(error)}; DispatchQueue.main.async {self.processing = false}}
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        queue.async {if self.logging {self.logging = false; do {try self.motionLogger.finish(to:outputFileURL.deletingPathExtension().appendingPathExtension("gcsv"))} catch {self.report(error)}}}
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
        let raw = CIImage(cvPixelBuffer:buffer)
        let previewScale = min(1,1280/max(raw.extent.width,raw.extent.height))
        let source = raw.transformed(by:CGAffineTransform(scaleX:previewScale,y:previewScale))
        let opts = options()
        if let cg = renderer.context.createCGImage(source,from:source.extent) {preRoll.append(cg,limit:max(16,min(512,opts.memoryMB))*1024*1024)}
        let state = current(), image = try renderer.render(source,settings:state.0,lut:state.1,time:time.seconds)
        if let target = timelapseTarget {
            if timelapse == nil {timelapse = try MotionTimelapse(url:target,size:image.extent.size,interval:opts.interval); timelapseStarted = time.seconds}
            try timelapse?.append(image,time:time.seconds)
            if time.seconds-timelapseStarted >= timelapseDeadline {finishTimelapse()}
        }
        let scale = min(1,720/image.extent.width)
        let small = image.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
        let bins = needsHistogram() ? FilmHistogram.values(image) : []
        let display = try MotionProcessing.aids(small,clipping:opts.clipping,peaking:opts.peaking,sensitivity:opts.sensitivity)
        let stats = timelapse.map {"\($0.count) frames • \($0.dropped) dropped"} ?? ""
        if let cg = renderer.context.createCGImage(display,from:display.extent) { DispatchQueue.main.async { self.preview = UIImage(cgImage:cg); self.histogram = bins; self.captureStats = stats } }
        } catch {report(error)}
    }
    func report(_ error: Error) { DispatchQueue.main.async { self.message = error.localizedDescription } }
    func focus(at point:CGPoint,locked:Bool = false) {
        queue.async {
            guard let d = self.device else {return}
            do {try d.lockForConfiguration(); defer {d.unlockForConfiguration()}
                if d.isFocusPointOfInterestSupported {d.focusPointOfInterest = point}
                if d.isExposurePointOfInterestSupported {d.exposurePointOfInterest = point}
                if d.isFocusModeSupported(.autoFocus) {d.focusMode = .autoFocus}
                if d.isExposureModeSupported(locked ? .locked : .continuousAutoExposure) {d.exposureMode = locked ? .locked : .continuousAutoExposure}
            } catch {self.report(error)}
            if !locked {self.queue.asyncAfter(deadline:.now()+5) {
                guard let d = self.device else {return}
                do {try d.lockForConfiguration(); defer {d.unlockForConfiguration()}; if d.isFocusModeSupported(.continuousAutoFocus) {d.focusMode = .continuousAutoFocus}} catch {self.report(error)}
            }}
        }
    }
}
