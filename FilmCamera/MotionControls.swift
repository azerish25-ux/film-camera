import SwiftUI

struct MotionGradeControls: View {
    @Binding var grade: MotionGrade
    var body: some View {
        Toggle("MotionCam development",isOn:$grade.enabled).accessibilityIdentifier("motionGradeEnabled")
        if grade.enabled {
            control("RAW exposure",value:$grade.exposure,range:-4...4)
            control("Shadow multiplier",value:$grade.shadows,range:1...64)
            control("Highlight recovery",value:$grade.highlights,range:0...8)
            control("White point",value:$grade.whitePoint,range:0.5...1.5)
            control("Black point",value:$grade.blacks,range:0...0.25)
            control("RAW contrast",value:$grade.contrast,range:0...1)
            control("RAW saturation",value:$grade.saturation,range:0...2)
            control("RAW temperature",value:$grade.temperature,range:2000...12000)
            control("RAW tint",value:$grade.tint,range:-150...150)
            control("Green balance",value:$grade.greens,range:-20...20)
            control("Blue balance",value:$grade.blues,range:-20...20)
            control("Sharpness",value:$grade.sharpen0,range:1...3)
            control("Fine detail",value:$grade.sharpen1,range:1...3)
            control("Local contrast",value:$grade.pop,range:1...2)
            control("Spatial denoise",value:$grade.denoise,range:0...5)
            control("Horizontal crop %",value:$grade.cropWidth,range:0...90)
            control("Vertical crop %",value:$grade.cropHeight,range:0...90)
            control("Desqueeze X",value:$grade.squeezeX,range:0.5...2)
            control("Desqueeze Y",value:$grade.squeezeY,range:0.5...2)
            Toggle("Rotate 180°",isOn:$grade.flip180)
        }
    }
    private func control(_ title:String,value:Binding<Double>,range:ClosedRange<Double>) -> some View {
        VStack(alignment:.leading) {HStack {Text(title); Spacer(); Text(value.wrappedValue,format:.number.precision(.fractionLength(2))).monospacedDigit().foregroundStyle(.secondary)}; Slider(value:value,in:range).accessibilityLabel(title)}
    }
}
struct MotionCaptureControls: View {
    @Binding var options: MotionCaptureOptions
    let rawSupported: Bool
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Picker("MotionCam mode",selection:$options.mode) {ForEach(MotionCaptureMode.allCases) {Text($0.title).tag($0)}}.accessibilityIdentifier("motionCaptureMode")
            Text("ZSL/Night/Burst use processed pre-roll unless Save DNG is enabled. RAW sequence preserves native DNG/ProRAW frames at still-capture speeds. The Video switch records processed video.").font(.caption).foregroundStyle(.secondary)
            if options.mode == .rawVideo {Text("RAW interval: \(options.rawInterval,specifier:"%.2f") seconds"); Slider(value:$options.rawInterval,in:0.25...5,step:0.25); Text("Actual RAW rate depends on photo readiness and storage. This is not high-frame-rate Bayer video.").font(.caption)}
            Toggle("Save DNG",isOn:$options.saveDNG).disabled(!rawSupported && !options.saveDNG)
            if !rawSupported {Text("RAW still capture is unavailable on this camera.").font(.caption)}
            Toggle("Save JPEG",isOn:$options.saveJPEG)
            Toggle("Auto Night in dim scenes",isOn:$options.autoNight)
            Text("JPEG quality \(Int(options.jpegQuality))"); Slider(value:$options.jpegQuality,in:10...100,step:1)
            Toggle("Clipping overlay",isOn:$options.clipping)
            Toggle("MotionCam graded viewfinder",isOn:$options.gradedViewfinder)
            Toggle("Focus peaking",isOn:$options.peaking)
            Toggle("Track focus point",isOn:$options.trackPOI)
            if options.peaking {Text("Peaking threshold"); Slider(value:$options.sensitivity,in:0.001...0.1)}
            Toggle("Lock auto exposure",isOn:$options.aeLock)
            Toggle("Lock white balance",isOn:$options.awbLock)
            Picker("Shutter angle",selection:$options.shutterAngle) {Text("Off").tag(0); ForEach([45,90,144,172,180,270,360],id:\.self) {Text("\($0)°").tag($0)}}
            Toggle("Record microphone",isOn:$options.audio)
            Toggle("Video stabilization",isOn:$options.stabilization)
            Toggle("Save Gyroflow motion log",isOn:$options.saveGyro)
            Text("Motion logs are limited to 30 minutes at 100 Hz.").font(.caption)
            Stepper("Pre-roll memory: \(options.memoryMB) MB",value:$options.memoryMB,in:16...512,step:16)
            if options.mode == .timelapse {
                Text("Interval \(options.interval,specifier:"%.2f") seconds"); Slider(value:$options.interval,in:0.25...60,step:0.25)
                Toggle("Unlimited duration",isOn:$options.unlimited)
                if !options.unlimited {Stepper("Duration \(Int(options.totalMinutes)) minutes",value:$options.totalMinutes,in:1...180)}
                Text("Timelapse is silent and plays at 24 fps. Keep the app in the foreground.").font(.caption)
            }
        }
    }
}
