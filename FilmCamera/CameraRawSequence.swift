import AVFoundation

extension CameraController {
    func toggleRawSequence(to url:URL,timelapse:Bool = false,maximumFrames:Int? = nil) {
        queue.async {
            if self.rawCapture != nil {self.requestRawStop(); return}
            guard self.session.isRunning,!self.movie.isRecording,!self.photoInFlight else {return}
            let options = self.options(),preset = self.session.sessionPreset,dimensions = self.photo.maxPhotoDimensions,proRAW = self.photo.isAppleProRAWEnabled
            self.session.beginConfiguration(); if self.session.outputs.contains(self.movie) {self.session.removeOutput(self.movie)}
            if self.session.canSetSessionPreset(.photo) {self.session.sessionPreset = .photo}
            self.session.commitConfiguration(); self.photo.isAppleProRAWEnabled = self.photo.isAppleProRAWSupported
            guard let format = self.photo.availableRawPhotoPixelFormatTypes.first(where:{AVCapturePhotoOutput.isBayerRAWPixelFormat($0)}) ?? self.photo.availableRawPhotoPixelFormatTypes.first else {
                self.restoreRawConfiguration(preset:preset,dimensions:dimensions,proRAW:proRAW)
                self.report(PortError.message("This lens does not support native RAW photos. Use processed Video or import a RAW clip.")); return
            }
            do {
                if let size = self.device?.activeFormat.supportedMaxPhotoDimensions.max(by:{Int64($0.width)*Int64($0.height) < Int64($1.width)*Int64($1.height)}) {self.photo.maxPhotoDimensions = size}
                let writer = try RawSequenceWriter(url:url,timelapse:timelapse,settings:self.current().0)
                let context = RawCaptureContext(writer:writer,url:url,options:options,timelapse:timelapse,maximumFrames:maximumFrames,preset:preset,dimensions:dimensions,proRAW:proRAW,format:format,audio:self.rawAudioAvailable && options.audio)
                self.rawCapture = context
                self.frames.async {self.rawAudioTask = nil; self.rawAudioFormatReported = false}
                self.setRawAudioWriter(context.allowAudio ? writer : nil)
                if options.saveGyro {do {try context.logger.begin(); context.logging = true} catch {self.report(error)}}
                DispatchQueue.main.async {self.rawRecording = true; self.recording = true; self.captureStats = "Preparing native RAW sequence…"}
                self.scheduleRawPhoto(context)
            } catch {self.restoreRawConfiguration(preset:preset,dimensions:dimensions,proRAW:proRAW); self.report(error)}
        }
    }
    func stopRawSequence() {queue.async {self.requestRawStop()}}
    func requestRawStop() {
        guard let context = rawCapture,!context.finishing else {return}
        context.stopping = true
        if context.stopTimestamp == nil {context.stopTimestamp = RawCaptureClock.nanoseconds()}
        setRawAudioWriter(nil)
        DispatchQueue.main.async {self.captureStats = "Finishing pending RAW frame…"}
        advanceRawCapture(context)
    }
    func scheduleRawPhoto(_ context:RawCaptureContext) {
        guard rawCapture?.id == context.id,!context.finishing,!photoInFlight,!context.writing else {return}
        if context.stopping || ProcessInfo.processInfo.systemUptime >= context.deadline {requestRawStop(); return}
        if let max = context.maximumFrames,context.count >= max {requestRawStop(); return}
        let delay = max(0,context.nextShot-ProcessInfo.processInfo.systemUptime)
        queue.asyncAfter(deadline:.now()+delay) {
            guard self.rawCapture?.id == context.id,!context.stopping,!self.photoInFlight,!context.writing else {self.advanceRawCapture(context); return}
            guard self.session.isRunning else {self.requestRawStop(); return}
            if self.photo.captureReadiness != .ready {context.nextShot = ProcessInfo.processInfo.systemUptime+0.1; self.scheduleRawPhoto(context); return}
            do {
                if let free = try context.url.resourceValues(forKeys:[.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage,free < 512_000_000 {throw PortError.message("Storage is almost full. Completed RAW frames were preserved.")}
                let settings = AVCapturePhotoSettings(rawPixelFormatType:context.format)
                settings.photoQualityPrioritization = .speed; settings.maxPhotoDimensions = self.photo.maxPhotoDimensions
                context.activeID = settings.uniqueID; context.nextShot = ProcessInfo.processInfo.systemUptime+context.interval
                self.photoInFlight = true; self.photo.capturePhoto(with:settings,delegate:self)
            } catch {self.report(error); self.requestRawStop()}
        }
    }
    func advanceRawCapture(_ context:RawCaptureContext) {
        guard rawCapture?.id == context.id,!context.finishing,!photoInFlight,!context.writing else {return}
        if !context.stopping {scheduleRawPhoto(context); return}
        context.finishing = true; setRawAudioWriter(nil)
        frames.async {
            let pending = self.rawAudioTask; self.rawAudioTask = nil
            Task {
                await pending?.value
                let stop = context.stopTimestamp ?? RawCaptureClock.nanoseconds()
                if context.logging {do {try context.logger.finish(to:context.url.appendingPathComponent("motion.gcsv")); if let origin = context.logger.sampleOriginTime {await context.writer.setGyroOrigin(RawCaptureClock.nanoseconds(origin))}} catch {self.report(error)}}
                let saved: Bool
                do {await context.writer.stopAudio(at:stop); try await context.writer.finish(endTimestampNs:stop); saved = true; DispatchQueue.main.async {self.onMedia?(context.url)}} catch {saved = false; self.report(error)}
                self.queue.async {
                    guard self.rawCapture?.id == context.id else {return}
                    self.rawCapture = nil; self.restoreRawConfiguration(preset:context.oldPreset,dimensions:context.oldDimensions,proRAW:context.oldProRAW)
                    DispatchQueue.main.async {self.rawRecording = false; self.recording = false; self.captureStats = saved ? "RAW sequence saved" : "RAW capture stopped"}
                }
            }
        }
    }
    func restoreRawConfiguration(preset:AVCaptureSession.Preset,dimensions:CMVideoDimensions,proRAW:Bool) {
        session.beginConfiguration()
        if session.canSetSessionPreset(preset) {session.sessionPreset = preset}
        if !session.outputs.contains(movie),session.canAddOutput(movie) {session.addOutput(movie)}
        session.commitConfiguration(); photo.isAppleProRAWEnabled = proRAW && photo.isAppleProRAWSupported
        if let allowed = device?.activeFormat.supportedMaxPhotoDimensions {if allowed.contains(where:{$0.width == dimensions.width && $0.height == dimensions.height}) {photo.maxPhotoDimensions = dimensions} else if let maximum = allowed.max(by:{Int64($0.width)*Int64($0.height) < Int64($1.width)*Int64($1.height)}) {photo.maxPhotoDimensions = maximum}}
        publishCapabilities()
    }
}
