import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

@main struct FilmCameraApp: App {
    @StateObject private var store = FilmStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store).preferredColorScheme(.dark) } }
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
            Picker("Film frame",selection:$store.state.settings.frame) { ForEach(FilmFrame.allCases) {Text($0.rawValue).tag($0)} }
            Picker("Color",selection:$store.state.settings.look) { ForEach(FilmSettings.looks,id:\.self) {Text($0).tag($0)} }
            Picker("LUT",selection:$store.state.settings.lutID) {
                Text("None").tag(nil as UUID?)
                ForEach(store.state.luts) {Text($0.name).tag(Optional($0.id))}
            }
            DisclosureGroup("Characteristic curve") {
                ForEach(0..<6,id:\.self) {index in
                    VStack(alignment:.leading) {
                        Text("Input \(Int(store.state.settings.curveX[index]))")
                        Slider(value:$store.state.settings.curveY[index],in:0...255).accessibilityLabel("Curve point \(index+1)")
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
                    Slider(value:Binding(get:{store.state.settings[item.id]},set:{store.state.settings[item.id] = $0}),in:item.range).accessibilityLabel(item.label)
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:16) {
                    ZStack {
                        Color.black
                        if let image = camera.preview { Image(uiImage:image).resizable().scaledToFit() }
                        else { VStack(spacing:12) {Image(systemName:"camera.aperture").font(.system(size:48)); Text(camera.message ?? "Opening camera…").multilineTextAlignment(.center); Button("Open Settings") { if let url = URL(string:UIApplication.openSettingsURLString) {UIApplication.shared.open(url)} } }.padding() }
                        if camera.recording { VStack {Label("REC",systemImage:"record.circle.fill").foregroundStyle(.red).padding(); Spacer()} }
                    }.frame(height:360).clipShape(RoundedRectangle(cornerRadius:8))
                    Picker("Capture mode",selection:$videoMode) {Text("Photo").tag(false); Text("Video").tag(true)}.pickerStyle(.segmented).disabled(camera.recording || exporter.busy)
                    HStack(spacing:44) {
                        Button {camera.flip()} label: {Image(systemName:"arrow.triangle.2.circlepath.camera").font(.title2)}.accessibilityLabel("Switch camera").disabled(camera.recording)
                        Button(action:capture) {Image(systemName:camera.recording ? "stop.circle.fill" : videoMode ? "record.circle" : "circle.inset.filled").font(.system(size:66)).foregroundStyle(videoMode ? .red : .white)}.accessibilityLabel(camera.recording ? "Stop recording" : videoMode ? "Record video" : "Take photo").disabled(!camera.ready || exporter.busy || camera.processing)
                        Button {tools.toggle()} label: {Image(systemName:"slider.horizontal.3").font(.title2)}.accessibilityLabel("Camera controls")
                    }
                    if exporter.busy {ProgressView("Processing film",value:exporter.progress); Button("Cancel export") {exporter.cancel()}}
                    if tools {cameraControls}
                    DisclosureGroup("Film adjustments") {AdjustmentsView().padding(.top)}.disabled(camera.recording)
                }.padding()
            }.navigationTitle("SUPER 16").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                camera.update(store.state.settings,lut:store.selectedLUT)
                camera.onMovie = { url,settings,lut in
                    Task { @MainActor in
                        defer {try? FileManager.default.removeItem(at:url)}
                        do {try await exporter.exportVideo(source:url,destination:store.destination("mov"),settings:settings,lut:lut,resolution:fourK ? AVAssetExportPreset3840x2160 : AVAssetExportPreset1920x1080); store.refresh()} catch {store.error = error.localizedDescription}
                    }
                }
                camera.start()
            }.onDisappear {camera.stop()}
            .onChange(of:store.state.settings) {_,value in camera.update(value,lut:store.selectedLUT)}
            .onChange(of:camera.ready) {_,ready in if ready {controls()} }
            .onChange(of:camera.availableLenses) {_,lenses in if !lenses.contains(lens) {lens = "Wide"} }
            .onChange(of:scenePhase) {_,phase in if phase == .active {camera.start()} else {camera.stop()} }
            .onChange(of:camera.message) {_,value in if camera.ready {store.error = value} }
        }
    }
    private var cameraControls: some View {
        VStack(alignment:.leading) {
            Text("Hardware controls").font(.headline)
            Picker("Lens",selection:$lens) {ForEach(camera.availableLenses,id:\.self) {Text($0).tag($0)}}.onChange(of:lens) {_,value in camera.selectLens(value)}
            Toggle("Record in 4K",isOn:$fourK).onChange(of:fourK) {_,value in camera.setResolution(value)}
            if camera.ready && !camera.audioEnabled {Label("Microphone access is disabled. Video will have no sound.",systemImage:"mic.slash").font(.caption)}
            Text("Available ranges depend on the selected camera.").font(.caption).foregroundStyle(.secondary)
            Text("Zoom"); Slider(value:$zoom,in:1...8,onEditingChanged:{_ in controls()})
            Text("Exposure compensation"); Slider(value:$bias,in:-3...3,onEditingChanged:{_ in controls()})
            Toggle("Manual focus",isOn:$manualFocus).onChange(of:manualFocus) {_,_ in controls()}
            if manualFocus {Slider(value:$focus,in:0...1,onEditingChanged:{_ in controls()}).accessibilityLabel("Focus")}
            Toggle("Manual exposure",isOn:$manualExposure).onChange(of:manualExposure) {_,_ in controls()}
            if manualExposure {
                Text("ISO \(Int(iso))"); Slider(value:$iso,in:25...3200,onEditingChanged:{_ in controls()})
                Text("Shutter 1/\(Int(1/shutter))"); Slider(value:$shutter,in:(1.0/1000)...(1.0/24),onEditingChanged:{_ in controls()})
            }
            Toggle("Torch",isOn:$torch).onChange(of:torch) {_,_ in controls()}
            Picker("Frame rate",selection:$fps) {ForEach([24.0,25,30,60],id:\.self) {Text("\(Int($0)) fps").tag($0)}}.onChange(of:fps) {_,_ in controls()}
        }.disabled(camera.recording)
    }
    private func controls() {camera.controls(zoom:zoom,bias:bias,focus:manualFocus ? focus : nil,iso:manualExposure ? iso : nil,shutter:manualExposure ? shutter : nil,torch:torch,fps:fps)}
    private func capture() {
        if videoMode {camera.toggleRecording()}
        else {camera.capture {image in do {let url = store.destination("jpg"); guard let data = image.jpegData(compressionQuality:0.97) else {throw PortError.message("Photo encoding failed.")}; try data.write(to:url,options:.atomic); store.refresh()} catch {store.error = error.localizedDescription}}}
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:18) {
                    if let player {VideoPlayer(player:player).frame(height:280)}
                    else if let image = comparison ? original : preview {Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:360)}
                    else {ContentUnavailableView("Import a photo or film",systemImage:"film",description:Text("Apply film effects and export a local copy."))}
                    HStack {
                        PhotosPicker(selection:$selection,matching:.any(of:[.images,.videos])) {Label("Photos",systemImage:"photo")}
                        Button("Files") {importing = true}
                        if original != nil {Toggle("Original",isOn:$comparison)}
                    }.disabled(exporter.busy)
                    if video != nil {
                        Text("Trim: \(start, specifier:"%.1f") – \(end, specifier:"%.1f") s")
                        Slider(value:$start,in:0...max(0.01,duration-0.01)).onChange(of:start) {_,v in if end <= v {end = min(duration,v+0.01)}}.accessibilityLabel("Trim start")
                        Slider(value:$end,in:0.01...max(0.01,duration)).onChange(of:end) {_,v in if start >= v {start = max(0,v-0.01)}}.accessibilityLabel("Trim end")
                        Picker("Export resolution",selection:$resolution) {Text("720p").tag(AVAssetExportPreset1280x720); Text("1080p").tag(AVAssetExportPreset1920x1080); Text("4K").tag(AVAssetExportPreset3840x2160)}
                    }
                    if original != nil || video != nil {
                        Button("Export to Gallery",action:export).buttonStyle(.borderedProminent).disabled(exporter.busy).accessibilityIdentifier("exportMedia")
                        if let saved {ShareLink(item:saved) {Label("Share export",systemImage:"square.and.arrow.up")}}
                        if exporter.busy {ProgressView("Exporting",value:exporter.progress); Button("Cancel") {exporter.cancel()}}
                    }
                    DisclosureGroup("Film adjustments",isExpanded:.constant(true)) {AdjustmentsView()}.disabled(exporter.busy)
                }.padding()
            }.navigationTitle("Editor")
            .onChange(of:selection) {_,item in Task {await load(item)}}
            .task(id:store.state.settings) { await updatePreview() }
            .fileImporter(isPresented:$importing,allowedContentTypes:[.image,.movie]) {result in
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
            } else {guard let image = UIImage(contentsOfFile:url.path) else {throw PortError.message("Unsupported image.")}; clearVideo(); original = image; await updatePreview()}
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
            do {let result = try await Task.detached {try renderer.photo(original,settings:settings,lut:lut)}.value; if !Task.isCancelled {preview = result}} catch {store.error = error.localizedDescription}
        }
        if let item = player?.currentItem {
            let renderer = FilmRenderer()
            item.videoComposition = AVVideoComposition(asset:item.asset) {request in
                do {
            let result = try renderer.render(request.sourceImage,settings:settings,lut:lut,time:request.compositionTime.seconds)
                let target = request.sourceImage.extent, scale = min(request.sourceImage.extent.width/result.extent.width,request.sourceImage.extent.height/result.extent.height)
                let fit = result.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
                let centered = fit.transformed(by:CGAffineTransform(translationX:(target.width-fit.extent.width)/2,y:(target.height-fit.extent.height)/2))
                request.finish(with:centered.composited(over:CIImage(color:.black).cropped(to:target)),context:renderer.context)
            } catch {request.finish(with:error)}
            }
        }
    }
    private func export() {
        let settings = store.state.settings, lut = store.selectedLUT
        Task { @MainActor in
            do {
                if let video {let target = store.destination("mov"); try await exporter.exportVideo(source:video,destination:target,settings:settings,lut:lut,start:start,end:end,resolution:resolution); saved = target}
                else if let original {let image = try await Task.detached {try FilmRenderer().photo(original,settings:settings,lut:lut)}.value; let target = store.destination("jpg"); guard let data = image.jpegData(compressionQuality:0.97) else {throw PortError.message("Image encoding failed.")}; try data.write(to:target,options:.atomic); saved = target}
                store.refresh()
            } catch {store.error = error.localizedDescription}
        }
    }
}
