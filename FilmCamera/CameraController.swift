import AVFoundation
import UIKit

final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var preview: UIImage?
    @Published var message: String?
    @Published var ready = false
    @Published var recording = false
    @Published var processing = false
    @Published var audioEnabled = false
    @Published var histogram: [Float] = []
    private var histogramEnabled = false
    @Published var rawRecording = false
    var rawCapture: RawCaptureContext?
    let rawAudio = AVCaptureAudioDataOutput()
    var rawAudioAvailable = false
    var rawAudioTask: Task<Void,Never>?
    var rawAudioFormatReported = false
    private var rawAudioWriter: RawSequenceWriter?
    @Published var rawSupported = false
    @Published var captureStats = ""
    @Published var sceneEV = 10.0
    @Published var sceneShadows = 1.0
    @Published var sceneExposure = 0.0
    var suggestedMergeCount = 12
    private var lastAnalysisTime = 0.0
    var motionOptions = MotionCaptureOptions()
    private var monitorOptions = BMCMonitorOptions()
    private var bmcFocusOptions = BMCFocusOptions()
    let preRoll = MotionPreRoll()
    let motionLogger = MotionLogger()
    var logging = false
    var rawDestination: URL?
    var timelapse: MotionTimelapse?
    var timelapseTarget: URL?
    var timelapseStarted = 0.0
    var timelapseDeadline = Double.greatestFiniteMagnitude
    var onMedia: ((URL) -> Void)?
    private var focusState = MotionFocusState()
    private let poi = MotionPOI()
    @Published var availableLenses: [String] = ["Wide"]
    @Published var availableFrameRates: [Double] = [24,30]
    private var selectedLens = "Wide"
    let session = AVCaptureSession()
    let queue = DispatchQueue(label:"film.camera")
    let frames = DispatchQueue(label:"film.frames")
    let photo = AVCapturePhotoOutput()
    let movie = AVCaptureMovieFileOutput()
    private let video = AVCaptureVideoDataOutput()
    var device: AVCaptureDevice?
    private var position: AVCaptureDevice.Position = .back
    let renderer = FilmRenderer()
    private let lock = NSLock()
    private var film = FilmSettings()
    private var lut: CubeLUT?
    private var snapshot: (FilmSettings,CubeLUT?) = (FilmSettings(),nil)
    private var onPhoto: ((UIImage) -> Void)?
    var onMovie: ((URL,FilmSettings,CubeLUT?) -> Void)?
    private var lastFrame = CMTime.zero
    private var zebraShift = 0
    private var statistics = MotionStatistics()
    private var lastStatsTime = 0.0
    private var statsText = ""
    var photoInFlight = false
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
                guard let self, !self.movie.isRecording,self.rawCapture == nil else {return}
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
    func updateMonitor(_ options: BMCMonitorOptions) {lock.lock(); monitorOptions = options; lock.unlock()}
    private func monitor() -> BMCMonitorOptions {lock.lock(); defer {lock.unlock()}; return monitorOptions}
    func updateBMCFocus(_ options: BMCFocusOptions) {lock.lock(); bmcFocusOptions = options; lock.unlock()}
    private func bmcFocus() -> BMCFocusOptions {lock.lock(); defer {lock.unlock()}; return bmcFocusOptions}
    func setRawAudioWriter(_ writer:RawSequenceWriter?) {lock.lock(); rawAudioWriter = writer; lock.unlock()}
    func rawAudioWriterSnapshot() -> RawSequenceWriter? {lock.lock(); defer {lock.unlock()}; return rawAudioWriter}
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
                    if !self.session.isRunning {self.frames.async {self.statistics = MotionStatistics(); self.lastStatsTime = 0}; self.session.startRunning()}
                    DispatchQueue.main.async { self.ready = true }
                } catch { self.report(error) }
            }
        }
    }
    func stop() { stopRawSequence(); finishTimelapse(); queue.async { if self.movie.isRecording { self.movie.stopRecording() }; self.session.stopRunning(); self.frames.async {self.preRoll.clear(); self.poi.reset()}; DispatchQueue.main.async {self.ready = false} } }
    private func configure(audio: Bool) throws {
        session.beginConfiguration(); defer { session.commitConfiguration(); publishCapabilities() }
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
        if audio,session.canAddOutput(rawAudio) {session.addOutput(rawAudio); rawAudio.setSampleBufferDelegate(self,queue:frames); rawAudioAvailable = true}
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
    func publishCapabilities() {
        let ranges = device?.activeFormat.videoSupportedFrameRateRanges ?? []
        let rates = MotionExposure.frameRates.map(Double.init).filter {fps in ranges.contains {$0.minFrameRate <= fps && $0.maxFrameRate >= fps}}.sorted()
        let supportsRAW = !photo.availableRawPhotoPixelFormatTypes.isEmpty
        DispatchQueue.main.async {self.availableFrameRates = rates.isEmpty ? [24,30] : rates; self.rawSupported = supportsRAW}
    }
    func flip() {
        queue.async {
            guard !self.movie.isRecording,self.rawCapture == nil,!self.photoInFlight else { return }
            self.session.beginConfiguration()
            let old = self.session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first { $0.device.hasMediaType(.video) }
            if let old { self.session.removeInput(old) }
            self.position = self.position == .back ? .front : .back; self.selectedLens = "Wide"
            do { try self.addCamera() } catch { if let old, self.session.canAddInput(old) { self.session.addInput(old); self.device = old.device }; self.report(error) }
            self.orient(); self.session.commitConfiguration(); self.publishCapabilities()
        }
    }
    func selectLens(_ name: String) {
        queue.async {
            guard !self.movie.isRecording,self.rawCapture == nil,!self.photoInFlight else {return}
            self.session.beginConfiguration(); defer {self.session.commitConfiguration(); self.publishCapabilities()}
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
            guard !self.movie.isRecording,self.rawCapture == nil,!self.photoInFlight else {return}
            let preset: AVCaptureSession.Preset = fourK ? .hd4K3840x2160 : .hd1920x1080
            self.session.beginConfiguration(); defer {self.session.commitConfiguration(); self.publishCapabilities()}
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
                for connection in [self.movie.connection(with:.video),self.video.connection(with:.video)].compactMap({$0}) where connection.isVideoStabilizationSupported {connection.preferredVideoStabilizationMode = opts.stabilization ? .standard : .off}
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
            guard self.session.isRunning, !self.movie.isRecording, !self.photoInFlight,self.rawCapture == nil else { return }
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
            guard self.session.isRunning, !self.photoInFlight,self.rawCapture == nil,self.session.outputs.contains(self.movie) else { return }
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
            if self.handleRawPhoto(photo,error:error) {return}
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
        queue.async {if self.handleRawCaptureFinished(resolvedSettings,error:error) {return}; self.photoInFlight = false; self.rawDestination = nil; self.onPhoto = nil; if let error {self.report(error)}; DispatchQueue.main.async {self.processing = false}}
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        queue.async {
        if self.logging {self.logging = false; do {try self.motionLogger.finish(to:outputFileURL.deletingPathExtension().appendingPathExtension("gcsv"))} catch {self.report(error)}}
        let saved = self.snapshot
        DispatchQueue.main.async {
            self.recording = false
            if let error, (error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool != true { self.message = error.localizedDescription; try? FileManager.default.removeItem(at:outputFileURL) }
            else { self.onMovie?(outputFileURL,saved.0,saved.1) }
        }
        }
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === rawAudio {handleRawAudio(sampleBuffer); return}
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        statistics.append(time:time.seconds)
        if time.seconds-lastStatsTime >= 0.5 {
            lastStatsTime = time.seconds
            statsText = String(format:"%.1f fps • %d dropped",statistics.fps,statistics.dropped)
        }
        guard time.seconds-lastFrame.seconds > 1/24.0, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastFrame = time
        do {
        let raw = CIImage(cvPixelBuffer:buffer)
        let previewScale = min(1,1280/max(raw.extent.width,raw.extent.height))
        let source = raw.transformed(by:CGAffineTransform(scaleX:previewScale,y:previewScale))
        let opts = options()
        if time.seconds-lastAnalysisTime >= 0.25 && (opts.autoNight || opts.mode == .night || opts.mode == .zsl) {
            lastAnalysisTime = time.seconds
            let gray = source.applyingFilter("CIColorMatrix",parameters:["inputRVector":CIVector(x:1.0/3,y:1.0/3,z:1.0/3,w:0),"inputGVector":CIVector(x:1.0/3,y:1.0/3,z:1.0/3,w:0),"inputBVector":CIVector(x:1.0/3,y:1.0/3,z:1.0/3,w:0)])
            let histogram = FilmHistogram.values(gray)
            let bins = stride(from:0,to:histogram.count,by:4).map {Double(histogram[$0])}
            queue.async {
                let ev = self.device.map {MotionExposure.ev(aperture:Double($0.lensAperture),seconds:$0.exposureDuration.seconds,iso:Double($0.iso))} ?? 10
                let estimate = MotionExposure.estimate(histogram:bins,ev:ev)
                self.frames.async {self.suggestedMergeCount = MotionExposure.mergeCount(ev:ev,shadows:estimate.shadows)}
                DispatchQueue.main.async {self.sceneEV = ev; self.sceneShadows = estimate.shadows; self.sceneExposure = estimate.exposure}
            }
        }
        if opts.trackPOI,let tracked = try poi.update(source) {focus(at:tracked,tracking:true)}
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
        let toneMapped = opts.gradedViewfinder ? try MotionViewfinder.render(small,shadows:state.0.motion.shadows,contrast:state.0.motion.contrast,saturation:state.0.motion.saturation) : small
        let aids = try MotionProcessing.aids(toneMapped,clipping:opts.clipping,peaking:opts.peaking,sensitivity:opts.sensitivity)
        let monitorOptions = monitor()
        if monitorOptions.zebra { zebraShift = zebraShift >= 16 ? 0 : zebraShift + 1 }
        let monitored = try BMCMonitor.render(aids,options:monitorOptions,zebraShift:Double(zebraShift))
        let display = try BMCFocus.render(monitored,source:small,options:bmcFocus())
        let stats = timelapse.map {"\($0.count) frames • \($0.dropped) dropped"} ?? statsText
        if let cg = renderer.context.createCGImage(display,from:display.extent) { DispatchQueue.main.async { self.preview = UIImage(cgImage:cg); self.histogram = bins; if !self.rawRecording {self.captureStats = stats} } }
        } catch {if timelapseTarget != nil {finishTimelapse()}; report(error)}
    }
    func report(_ error: Error) { DispatchQueue.main.async { self.message = error.localizedDescription } }
    func captureOutput(_ output:AVCaptureOutput,didDrop sampleBuffer:CMSampleBuffer,from connection:AVCaptureConnection) {statistics.drop()}
    func focus(at point:CGPoint,locked:Bool = false,tracking:Bool = false) {
        if !tracking && options().trackPOI {poi.select(point)}
        queue.async {
            guard let d = self.device else {return}
            let now = ProcessInfo.processInfo.systemUptime
            guard self.focusState.select(SIMD2(point.x,point.y),time:now) else {return}
            if locked {self.focusState.lock()}
            let sensorPoint: CGPoint
            switch Int(self.rotationAngle) {
            case 90: sensorPoint = CGPoint(x:point.y,y:1-point.x)
            case 180: sensorPoint = CGPoint(x:1-point.x,y:1-point.y)
            case 270: sensorPoint = CGPoint(x:1-point.y,y:point.x)
            default: sensorPoint = point
            }
            do {try d.lockForConfiguration(); defer {d.unlockForConfiguration()}
                if d.isFocusPointOfInterestSupported {d.focusPointOfInterest = sensorPoint}
                if d.isExposurePointOfInterestSupported {d.exposurePointOfInterest = sensorPoint}
                if d.isFocusModeSupported(.autoFocus) {d.focusMode = .autoFocus}
                if d.isExposureModeSupported(locked ? .locked : .continuousAutoExposure) {d.exposureMode = locked ? .locked : .continuousAutoExposure}
            } catch {self.report(error)}
            if !locked && !self.options().trackPOI {self.queue.asyncAfter(deadline:.now()+5) {
                guard let d = self.device else {return}
                guard self.focusState.update(time:ProcessInfo.processInfo.systemUptime,settled:!d.isAdjustingFocus) else {return}
                do {try d.lockForConfiguration(); defer {d.unlockForConfiguration()}; if d.isFocusModeSupported(.continuousAutoFocus) {d.focusMode = .continuousAutoFocus}} catch {self.report(error)}
            }}
        }
    }
}
