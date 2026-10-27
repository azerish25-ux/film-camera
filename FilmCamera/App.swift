import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers
import CoreImage

@main struct FilmCameraApp: App {
    @StateObject private var store = FilmStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store).environmentObject(store.motionWorkspace).preferredColorScheme(.dark) } }
}
struct RootView: View {
    @EnvironmentObject var store: FilmStore
    var body: some View {
        TabView {
            CameraScreen().tabItem { Label("Camera",systemImage:"camera") }
            EditorScreen().tabItem { Label("Editor",systemImage:"slider.horizontal.3") }
            GalleryScreen().tabItem { Label("Gallery",systemImage:"photo.on.rectangle") }
            PresetsScreen().tabItem { Label("Presets",systemImage:"camera.filters") }
            SettingsScreen().tabItem { Label("Settings",systemImage:"gearshape") }
        }.tint(.orange)
        .alert("Super 16",isPresented:Binding(get:{store.error != nil},set:{if !$0 {store.error = nil}})) { Button("OK") {store.error = nil} } message: {Text(store.error ?? "")}
    }
}
struct AdjustmentsView: View {
    @EnvironmentObject var store: FilmStore
    var body: some View {
        VStack(alignment:.leading,spacing:14) {
            DisclosureGroup("MotionCam development") {MotionGradeControls(grade:$store.state.settings.motion)}
            Picker("Film frame",selection:$store.state.settings.frame) { ForEach(FilmFrame.allCases) {Text($0.rawValue).tag($0)} }
            Picker("Color",selection:$store.state.settings.look) { ForEach(FilmSettings.looks,id:\.self) {Text($0).tag($0)} }
            Picker("LUT",selection:$store.state.settings.lutID) {
                Text("None").tag(nil as UUID?)
                ForEach(store.state.luts) {Text($0.name).tag(Optional($0.id))}
                ForEach(BMCLUTCatalog.profiles,id:\.self) { profile in
                    Section("BMC \(profile)") {
                        ForEach(BMCLUTCatalog.all.filter { $0.profile == profile }) {Text($0.name).tag(Optional($0.id))}
                    }
                }
            }
            Text("BMC LUT profile conversion is not automatic; choose a table suited to your source.").font(.caption).foregroundStyle(.secondary)
            DisclosureGroup("Characteristic curve") {
                CurvePlot(x:store.state.settings.curveX,y:store.state.settings.curveY)
                ForEach(0..<6,id:\.self) {index in
                    VStack(alignment:.leading) {
                        Text("Point \(index+1): input \(Int(store.state.settings.curveX[index])), output \(Int(store.state.settings.curveY[index]))")
                        if index > 0 && index < 5 {
                            let lower = store.state.settings.curveX[index-1]+1, upper = store.state.settings.curveX[index+1]-1
                            if lower < upper {Slider(value:$store.state.settings.curveX[index],in:lower...upper,step:1).accessibilityLabel("Curve input point \(index+1)")}
                        }
                        Slider(value:$store.state.settings.curveY[index],in:0...255).accessibilityLabel("Curve output point \(index+1)")
                    }
                }
            }
            Toggle("Film burn",isOn:Binding(get:{store.state.settings["burn"] > 0.5},set:{store.state.settings["burn"] = $0 ? 1 : 0}))
            if store.state.settings["burn"] > 0.5 {
                Picker("Film burn roll",selection:Binding(get:{Int(store.state.settings["burnClip"])},set:{store.state.settings["burnClip"] = Double($0)})) {
                    ForEach(0..<7,id:\.self) {Text("Roll \($0+1)").tag($0)}
                }
            }
            ForEach(Adjustment.all.filter {!["burn","burnClip"].contains($0.id)}) { item in
                VStack(alignment:.leading) {
                    HStack { Text(item.label); Spacer(); Text(store.state.settings[item.id],format:.number.precision(.fractionLength(2))).foregroundStyle(.secondary).monospacedDigit() }
                    Slider(value:Binding(get:{store.state.settings[item.id]},set:{store.state.settings[item.id] = $0}),in:item.range,step:item.step).accessibilityLabel(item.label)
                }
            }
            Button("Reset adjustments") { store.state.settings = FilmSettings(); store.persist() }.accessibilityIdentifier("resetAdjustments")
        }.onChange(of:store.state.settings) { _,_ in store.persist() }
    }
}
struct CameraScreen: View {
    @EnvironmentObject var store: FilmStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var camera = CameraController()
    @StateObject private var exporter = MediaExporter()
    @State private var videoMode = false
    @State private var tools = false
    @State private var zoom = 1.0
    @State private var bias = 0.0
    @State private var manualFocus = false
    @State private var focus = 0.5
    @State private var manualExposure = false
    @State private var iso = 200.0
    @State private var shutter = 1.0/48
    @State private var torch = false
    @State private var fps = 24.0
    @State private var lens = "Wide"
    @State private var fourK = false
    @AppStorage("bmcMovieExportCodec") private var movieCodec = BMCMovieCodec.h264.rawValue
    @State private var showHistogram = false
    @State private var motion = MotionCaptureOptions()
    @State private var monitor = BMCMonitorOptions()
    @State private var slate = BMCSlate()
    @State private var guides = BMCGuideOptions()
    @State private var bmcFocus = BMCFocusOptions()
    @AppStorage("bmcAudioMeterEnabled") private var bmcAudioMeterEnabled = false
    @State private var bmcAudioMeterMode: BMCAudioMeter.Mode = .vu18
    @AppStorage("bmcManualWhiteBalance") private var manualWhiteBalance = false
    @AppStorage("bmcWhiteBalanceTemperature") private var whiteBalanceTemperature = 5600.0
    @AppStorage("bmcWhiteBalanceTint") private var whiteBalanceTint = 0.0
    @State private var rawWorkspace = false
    private var captureIsSequence: Bool {videoMode || motion.mode == .rawVideo || motion.mode == .timelapse || camera.rawRecording}
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:16) {
                    ZStack {
                        Color.black
                        if let image = camera.preview { Image(uiImage:image).resizable().scaledToFit().overlay {BMCGuideOverlay(imageSize:image.size,options:guides)}.overlay {CameraFocusOverlay(size:image.size) {point in manualFocus = false; camera.focus(at:point)}} }
                        else { VStack(spacing:12) {Image(systemName:"camera.aperture").font(.system(size:48)); Text(camera.message ?? "Opening camera…").multilineTextAlignment(.center); Button("Open Settings") { if let url = URL(string:UIApplication.openSettingsURLString) {UIApplication.shared.open(url)} } }.padding() }
                        if camera.recording { VStack {Label("REC",systemImage:"record.circle.fill").foregroundStyle(.red).padding(); Spacer()} }
                    }.frame(height:360).clipShape(RoundedRectangle(cornerRadius:8))
                    Picker("Capture mode",selection:$videoMode) {Text("Photo").tag(false); Text("Video").tag(true)}.pickerStyle(.segmented).disabled(camera.recording || exporter.busy)
                    DisclosureGroup("MotionCam capture") {MotionCaptureControls(options:$motion,rawSupported:camera.rawSupported)}.disabled(camera.recording || camera.processing)
                    Button("RAW workspace") {rawWorkspace = true}.accessibilityIdentifier("rawWorkspace").disabled(camera.recording || camera.processing)
                    if !camera.captureStats.isEmpty {Text(camera.captureStats).monospacedDigit()}
                    if motion.autoNight || motion.mode == .night || motion.mode == .zsl {
                        Text("Scene EV \(camera.sceneEV,specifier:"%.1f") • shadows ×\(camera.sceneShadows,specifier:"%.1f")").font(.caption)
                        Button("Use scene development estimate") {store.state.settings.motion.enabled = true; store.state.settings.motion.shadows = camera.sceneShadows; store.state.settings.motion.exposure = camera.sceneExposure; store.persist()}
                    }
                    HStack(spacing:44) {
                        Button {camera.flip(); controls()} label: {Image(systemName:"arrow.triangle.2.circlepath.camera").font(.title2)}.accessibilityLabel("Switch camera").disabled(camera.recording)
                        Button(action:capture) {Image(systemName:camera.recording ? "stop.circle.fill" : captureIsSequence ? "record.circle" : "circle.inset.filled").font(.system(size:66)).foregroundStyle(captureIsSequence ? .red : .white)}.accessibilityLabel(camera.recording ? "Stop recording" : motion.mode == .rawVideo ? "Record RAW sequence" : captureIsSequence ? "Record video" : "Take photo").disabled(!camera.ready || exporter.busy || camera.processing)
                        Button {tools.toggle()} label: {Image(systemName:"slider.horizontal.3").font(.title2)}.accessibilityLabel("Camera controls")
                    }
                    if camera.processing {ProgressView("Developing photo")}
                    if exporter.busy {ProgressView("Processing film",value:exporter.progress); Button("Cancel export") {exporter.cancel()}}
                    if tools {cameraControls}
                    DisclosureGroup("Film adjustments") {AdjustmentsView().padding(.top)}.disabled(camera.recording)
                }.padding()
            }.navigationTitle("SUPER 16").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                camera.update(store.state.settings,lut:store.selectedLUT)
                if let data = UserDefaults.standard.data(forKey:"motionCaptureOptions"),let saved = try? JSONDecoder().decode(MotionCaptureOptions.self,from:data) {motion = saved}
                camera.updateMotion(motion)
                if let data = UserDefaults.standard.data(forKey:"bmcMonitorOptions"), let saved = try? JSONDecoder().decode(BMCMonitorOptions.self,from:data) {monitor = saved}
                if let data = UserDefaults.standard.data(forKey:"bmcSlate"), let saved = try? JSONDecoder().decode(BMCSlate.self,from:data) {slate = saved}
                if let data = UserDefaults.standard.data(forKey:"bmcGuides"), let saved = try? JSONDecoder().decode(BMCGuideOptions.self,from:data) {guides = saved}
                if let data = UserDefaults.standard.data(forKey:"bmcFocus"), let saved = try? JSONDecoder().decode(BMCFocusOptions.self,from:data) {bmcFocus = saved}
                camera.updateBMCFocus(bmcFocus)
                if let raw = UserDefaults.standard.string(forKey:"bmcAudioMeterMode"), let saved = BMCAudioMeter.Mode(rawValue:raw) {bmcAudioMeterMode = saved}
                camera.updateBMCAudioMeter(enabled:bmcAudioMeterEnabled,mode:bmcAudioMeterMode)
                camera.updateMonitor(monitor)
                camera.onMedia = {_ in store.refresh()}
                camera.onMovie = { url,settings,lut in
                    Task { @MainActor in
                        defer {try? FileManager.default.removeItem(at:url)}
                        do {
                            let destination = store.destination("mov")
                            let codec = BMCMovieCodec(rawValue:movieCodec) ?? .h264
                            try await exporter.exportVideo(source:url,destination:destination,settings:settings,lut:lut,slate:slate,resolution:codec.exportPreset(fourK:fourK))
                            let sidecar = url.deletingPathExtension().appendingPathExtension("gcsv")
                            if FileManager.default.fileExists(atPath:sidecar.path) {try FileManager.default.moveItem(at:sidecar,to:destination.deletingPathExtension().appendingPathExtension("gcsv"))}
                            store.refresh()
                        } catch {store.error = error.localizedDescription}
                    }
                }
                camera.start()
            }.onDisappear {camera.stop()}
            .sheet(isPresented:$rawWorkspace) {MotionWorkspaceScreen().environmentObject(store)}
            .onChange(of:motion) {_,value in camera.updateMotion(value); controls(); if let data = try? JSONEncoder().encode(value) {UserDefaults.standard.set(data,forKey:"motionCaptureOptions")}}
            .onChange(of:monitor) {_,value in camera.updateMonitor(value); if let data = try? JSONEncoder().encode(value) {UserDefaults.standard.set(data,forKey:"bmcMonitorOptions")}}
            .onChange(of:slate) {_,value in if let data = try? JSONEncoder().encode(value) {UserDefaults.standard.set(data,forKey:"bmcSlate")}}
            .onChange(of:guides) {_,value in if let data = try? JSONEncoder().encode(value) {UserDefaults.standard.set(data,forKey:"bmcGuides")}}
            .onChange(of:bmcFocus) {_,value in camera.updateBMCFocus(value); if let data = try? JSONEncoder().encode(value) {UserDefaults.standard.set(data,forKey:"bmcFocus")}}
            .onChange(of:bmcAudioMeterEnabled) {_,value in camera.updateBMCAudioMeter(enabled:value,mode:bmcAudioMeterMode)}
            .onChange(of:bmcAudioMeterMode) {_,value in camera.updateBMCAudioMeter(enabled:bmcAudioMeterEnabled,mode:value); UserDefaults.standard.set(value.rawValue,forKey:"bmcAudioMeterMode")}
            .onChange(of:store.state.settings) {_,value in camera.update(value,lut:store.selectedLUT)}
            .onChange(of:camera.ready) {_,ready in if ready {controls()} }
            .onChange(of:camera.availableLenses) {_,lenses in if !lenses.contains(lens) {lens = "Wide"} }
            .onChange(of:camera.availableFrameRates) {_,rates in if !rates.contains(fps),let first = rates.first {fps = first; controls()} }
            .onChange(of:scenePhase) {_,phase in if phase == .active {camera.start()} else {camera.stop()} }
            .onChange(of:camera.message) {_,value in if camera.ready {store.error = value} }
        }
    }
    private var cameraControls: some View {
        VStack(alignment:.leading) {
            Text("Hardware controls").font(.headline)
            DisclosureGroup("Audio meter") {
                Toggle("Show audio meter",isOn:$bmcAudioMeterEnabled)
                if bmcAudioMeterEnabled {
                    Picker("Meter type",selection:$bmcAudioMeterMode) {ForEach(BMCAudioMeter.Mode.allCases) {Text($0.title).tag($0)}}
                    if !camera.audioEnabled {Text("Microphone access is unavailable.").font(.caption)}
                    else if camera.bmcAudioUnavailable {Text("This microphone format is not supported by the meter.").font(.caption)}
                    else {ForEach(Array(camera.bmcAudioReadings.enumerated()),id:\.offset) {index,reading in Text("Channel \(index + 1): \(reading.level, specifier:"%.1f") dB • peak \(reading.peak, specifier:"%.1f") dB").monospacedDigit().font(.caption)}}
                }
            }
            DisclosureGroup("Focus assist") {
                Toggle("BMC focus assist",isOn:$bmcFocus.enabled)
                if bmcFocus.enabled {
                    Toggle("Colored lines",isOn:$bmcFocus.coloredLines)
                    if bmcFocus.coloredLines {Picker("Line color",selection:$bmcFocus.color) {ForEach(BMCFocusColor.allCases) {Text($0.rawValue.capitalized).tag($0)}}}
                    Text("Sensitivity \(Int(bmcFocus.value))")
                    Slider(value:$bmcFocus.value,in:0...100,step:1).accessibilityLabel("Focus assist sensitivity")
                }
            }
            DisclosureGroup("Framing guides") {
                Toggle("Frame guide",isOn:$guides.framing)
                if guides.framing {Picker("Aspect ratio",selection:$guides.ratio) {ForEach(BMCGuideRatio.allCases) {Text($0.rawValue).tag($0)}}}
                Toggle("Thirds",isOn:$guides.thirds)
                Toggle("Crosshairs",isOn:$guides.crosshairs)
                Toggle("Center dot",isOn:$guides.centerDot)
                Text("Opacity \(Int(guides.opacity * 100))%")
                Slider(value:$guides.opacity,in:0.25...1,step:0.25).accessibilityLabel("Guide opacity")
            }
            DisclosureGroup("Clip slate") {
                TextField("Project",text:$slate.project)
                TextField("Reel",text:$slate.reel)
                TextField("Scene",text:$slate.scene)
                TextField("Take",text:$slate.take)
                TextField("Camera",text:$slate.camera)
                TextField("Director",text:$slate.director)
                TextField("Camera operator",text:$slate.cameraOperator)
                TextField("Notes",text:$slate.notes)
                Text("Slate fields are written to recorded movies after export.").font(.caption).foregroundStyle(.secondary)
            }.disabled(camera.recording)
            DisclosureGroup("Exposure monitoring") {
                Toggle("False color",isOn:$monitor.falseColor)
                Toggle("Zebra",isOn:$monitor.zebra)
                if monitor.zebra {
                    Text("Zebra threshold \(Int(monitor.zebraThreshold * 100))%")
                    Slider(value:$monitor.zebraThreshold,in:0...1,step:0.01).accessibilityLabel("Zebra threshold")
                    Picker("Middle gray stripes",selection:$monitor.midGray) {ForEach(BMCMonitor.MidGray.allCases) {Text($0.title).tag($0)}}
                }
                Text("Monitoring affects the preview only.").font(.caption).foregroundStyle(.secondary)
            }
            Toggle("RGB histogram",isOn:$showHistogram).onChange(of:showHistogram) {_,value in camera.enableHistogram(value)}
            if showHistogram {HistogramPlot(values:camera.histogram)}
            Picker("Lens",selection:$lens) {ForEach(camera.availableLenses,id:\.self) {Text($0).tag($0)}}.onChange(of:lens) {_,value in camera.selectLens(value); controls()}
            Toggle("Record in 4K",isOn:$fourK).disabled(camera.recording || exporter.busy).onChange(of:fourK) {_,value in camera.setResolution(value); controls()}
            Picker("Movie export codec",selection:$movieCodec) {ForEach(BMCMovieCodec.allCases) {Text($0.title).tag($0.rawValue)}}.disabled(camera.recording || exporter.busy)
            Text("Video is captured first, then exported with the selected codec.").font(.caption).foregroundStyle(.secondary)
            if camera.ready && !camera.audioEnabled {Label("Microphone access is disabled. Video will have no sound.",systemImage:"mic.slash").font(.caption)}
            Text("Available ranges depend on the selected camera.").font(.caption).foregroundStyle(.secondary)
            Text("Zoom"); Slider(value:$zoom,in:1...8,onEditingChanged:{_ in controls()})
            Text("Exposure compensation"); Slider(value:$bias,in:-3...3,onEditingChanged:{_ in controls()})
            Toggle("Manual white balance",isOn:$manualWhiteBalance).onChange(of:manualWhiteBalance) {_,_ in controls()}
            if manualWhiteBalance {
                Menu("White balance presets") {
                    ForEach(BMCWhiteBalancePreset.allCases) { preset in
                        Button(preset.rawValue.capitalized) {whiteBalanceTemperature = preset.value.temperature; whiteBalanceTint = preset.value.tint; controls()}
                    }
                }
                Text("Temperature \(Int(whiteBalanceTemperature)) K")
                Slider(value:$whiteBalanceTemperature,in:2500...10000,step:50,onEditingChanged:{_ in controls()}).accessibilityLabel("White balance temperature")
                Text("Tint \(Int(whiteBalanceTint))")
                Slider(value:$whiteBalanceTint,in:-150...150,step:1,onEditingChanged:{_ in controls()}).accessibilityLabel("White balance tint")
            }
            Toggle("Manual focus",isOn:$manualFocus).onChange(of:manualFocus) {_,_ in controls()}
            if manualFocus {Slider(value:$focus,in:0...1,onEditingChanged:{_ in controls()}).accessibilityLabel("Focus")}
            Toggle("Manual exposure",isOn:$manualExposure).onChange(of:manualExposure) {_,_ in controls()}
            if manualExposure {
                Text("ISO \(Int(iso))"); Slider(value:$iso,in:25...3200,onEditingChanged:{_ in controls()})
                Text("Shutter 1/\(Int(1/shutter))"); Slider(value:$shutter,in:(1.0/1000)...(1.0/24),onEditingChanged:{_ in controls()})
            }
            Toggle("Torch",isOn:$torch).onChange(of:torch) {_,_ in controls()}
            Picker("Frame rate",selection:$fps) {ForEach(camera.availableFrameRates,id:\.self) {Text("\(Int($0)) fps").tag($0)}}.onChange(of:fps) {_,_ in controls()}
        }.disabled(camera.recording)
    }
    private func controls() {camera.controls(zoom:zoom,bias:bias,focus:manualFocus ? focus : nil,iso:manualExposure ? iso : nil,shutter:manualExposure ? shutter : nil,torch:torch,fps:fps,whiteBalance:manualWhiteBalance ? BMCWhiteBalance(temperature:whiteBalanceTemperature,tint:whiteBalanceTint) : nil)}
    private func capture() {
        if camera.rawRecording {camera.stopRawSequence()}
        else if motion.mode == .rawVideo {camera.toggleRawSequence(to:store.destination("rawseq"))}
        else if motion.mode == .timelapse {if motion.saveDNG {camera.toggleRawSequence(to:store.destination("rawseq"),timelapse:true)} else {camera.toggleTimelapse(to:store.destination("mov"))}}
        else if videoMode {camera.toggleRecording()}
        else if motion.mode == .burst && motion.saveDNG {camera.toggleRawSequence(to:store.destination("rawseq"),maximumFrames:30)}
        else if !motion.saveDNG && (motion.mode != .photo || (motion.autoNight && camera.sceneEV < 4)) {if motion.saveJPEG {camera.capturePreRoll(mode:motion.autoNight && camera.sceneEV < 4 ? .night : motion.mode,directory:store.root)} else {store.error = "Enable Save JPEG or Save DNG before capturing."}}
        else {camera.capture(rawURL:motion.saveDNG ? store.destination("dng") : nil) {image in do {guard motion.saveJPEG else {return}; let url = store.destination("jpg"); guard let data = image.jpegData(compressionQuality:motion.jpegQuality/100) else {throw PortError.message("Photo encoding failed.")}; try data.write(to:url,options:.atomic); store.refresh()} catch {store.error = error.localizedDescription}}}
    }
}
struct MovieTransfer: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType:.movie) {SentTransferredFile($0.url)} importing: { received in
            let target = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
            try FileManager.default.copyItem(at:received.file,to:target)
            return MovieTransfer(url:target)
        }
    }
}
struct EditorScreen: View {
    @EnvironmentObject var store: FilmStore
    @StateObject private var exporter = MediaExporter()
    @State private var selection: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var preview: UIImage?
    @State private var video: URL?
    @State private var player: AVPlayer?
    @State private var duration = 1.0
    @State private var start = 0.0
    @State private var end = 1.0
    @State private var comparison = false
    @State private var resolution = AVAssetExportPreset1920x1080
    @State private var saved: URL?
    @State private var importing = false
    @State private var photoExporting = false
    @State private var histogram: [Float] = []
    @State private var showHistogram = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:18) {
                    if let player {VideoPlayer(player:player).frame(height:280)}
                    else if let image = comparison ? original : preview {Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:360).accessibilityLabel("Edited photo preview").accessibilityIdentifier("editorPreview")}
                    else {ContentUnavailableView("Import a photo or film",systemImage:"film",description:Text("Apply film effects and export a local copy."))}
                    Toggle("RGB histogram",isOn:$showHistogram).onChange(of:showHistogram) {_,_ in Task {await updatePreview()}}
                    if showHistogram {HistogramPlot(values:histogram)}
                    HStack {
                        PhotosPicker(selection:$selection,matching:.any(of:[.images,.videos])) {Label("Photos",systemImage:"photo")}
                        Button("Files") {importing = true}
                        if original != nil {Toggle("Original",isOn:$comparison)}
                    }.disabled(exporter.busy || photoExporting)
                    if video != nil {
                        Text("Trim: \(start, specifier:"%.1f") – \(end, specifier:"%.1f") s")
                        Slider(value:$start,in:0...max(0.01,duration-0.01)).onChange(of:start) {_,v in if end <= v {end = min(duration,v+0.01)}}.accessibilityLabel("Trim start")
                        Slider(value:$end,in:0.01...max(0.01,duration)).onChange(of:end) {_,v in if start >= v {start = max(0,v-0.01)}}.accessibilityLabel("Trim end")
                        Picker("Export resolution",selection:$resolution) {Text("720p").tag(AVAssetExportPreset1280x720); Text("1080p").tag(AVAssetExportPreset1920x1080); Text("4K").tag(AVAssetExportPreset3840x2160)}
                    }
                    if original != nil || video != nil {
                        Button("Export to Gallery",action:export).buttonStyle(.borderedProminent).disabled(exporter.busy || photoExporting).accessibilityIdentifier("exportMedia")
                        if let saved {ShareLink(item:saved) {Label("Share export",systemImage:"square.and.arrow.up")}.accessibilityIdentifier("shareExport")}
                        if photoExporting {ProgressView("Exporting photo")}
                        if exporter.busy {ProgressView("Exporting",value:exporter.progress); Button("Cancel") {exporter.cancel()}}
                    }
                    DisclosureGroup("Film adjustments",isExpanded:.constant(true)) {AdjustmentsView()}.disabled(exporter.busy || photoExporting)
                }.padding()
            }.navigationTitle("Editor")
            .onChange(of:selection) {_,item in Task {await load(item)}}
            .task(id:store.state.settings) {
                try? await Task.sleep(nanoseconds:150_000_000)
                if !Task.isCancelled {await updatePreview()}
            }
            .task {
                if ProcessInfo.processInfo.arguments.contains("--editor-fixture"), let url = Bundle.main.url(forResource:"EditorFixture",withExtension:"jpg") {
                    original = UIImage(contentsOfFile:url.path); await updatePreview()
                }
            }
            .fileImporter(isPresented:$importing,allowedContentTypes:[.image,.movie,.rawImage]) {result in
                switch result {
                case .success(let url): Task {await loadFile(url)}
                case .failure(let error): store.error = error.localizedDescription
                }
            }
            .onDisappear {player?.pause()}
        }
    }
    private func load(_ item: PhotosPickerItem?) async {
        guard let item else {return}
        do {
            if item.supportedContentTypes.contains(where:{$0.conforms(to:.movie)}), let movie = try await item.loadTransferable(type:MovieTransfer.self) {try await openVideo(movie.url)}
            else if let data = try await item.loadTransferable(type:Data.self), let image = UIImage(data:data) {clearVideo(); original = image; await updatePreview()}
        } catch {store.error = error.localizedDescription}
    }
    private func loadFile(_ url: URL) async {
        let access = url.startAccessingSecurityScopedResource(); defer {if access {url.stopAccessingSecurityScopedResource()}}
        do {
            if let type = UTType(filenameExtension:url.pathExtension), type.conforms(to:.movie) {
                let copy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+"."+url.pathExtension)
                try FileManager.default.copyItem(at:url,to:copy); try await openVideo(copy)
            } else {
                let decoded = try MotionProcessing.decode(url),context = CIContext(options:[.cacheIntermediates:false])
                guard let cg = context.createCGImage(decoded,from:decoded.extent) else {throw PortError.message("Unsupported image.")}
                clearVideo(); original = UIImage(cgImage:cg); await updatePreview()
            }
        } catch {store.error = error.localizedDescription}
    }
    private func clearVideo() {player?.pause(); player = nil; if let video {try? FileManager.default.removeItem(at:video)}; video = nil; saved = nil}
    private func openVideo(_ url: URL) async throws {
        let asset = AVURLAsset(url:url), length = try await asset.load(.duration).seconds
        guard length.isFinite, length > 0 else {throw PortError.message("Invalid video.")}
        clearVideo(); video = url; original = nil; preview = nil; duration = length; start = 0; end = length
        player = AVPlayer(url:url); await updatePreview()
    }
    private func updatePreview() async {
        let settings = store.state.settings, lut = store.selectedLUT
        if let original {
            let renderer = FilmRenderer()
            do {let result = try await Task.detached {try renderer.preview(original,settings:settings,lut:lut)}.value; if !Task.isCancelled {
                    preview = result
                    if showHistogram, let cg = result.cgImage {histogram = FilmHistogram.values(CIImage(cgImage:cg))}
                }} catch {store.error = error.localizedDescription}
        }
        if let item = player?.currentItem {
            let renderer = FilmRenderer()
            item.videoComposition = renderer.videoComposition(asset:item.asset,settings:settings,lut:lut,preview:true,histogram:showHistogram ? {bins in DispatchQueue.main.async {histogram = bins}} : nil)
        }
    }
    private func export() {
        guard !exporter.busy, !photoExporting else {return}
        photoExporting = original != nil
        let settings = store.state.settings, lut = store.selectedLUT
        Task { @MainActor in
            defer {photoExporting = false}
            do {
                if let video {let target = store.destination("mov"); try await exporter.exportVideo(source:video,destination:target,settings:settings,lut:lut,start:start,end:end,resolution:resolution); saved = target}
                else if let original {let image = try await Task.detached {try FilmRenderer().photo(original,settings:settings,lut:lut)}.value; let target = store.destination("jpg"); guard let data = image.jpegData(compressionQuality:0.97) else {throw PortError.message("Image encoding failed.")}; try data.write(to:target,options:.atomic); saved = target}
                store.refresh()
            } catch {store.error = error.localizedDescription}
        }
    }
}
