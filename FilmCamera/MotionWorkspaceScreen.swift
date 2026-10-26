import SwiftUI
import UniformTypeIdentifiers

struct MotionWorkspaceScreen: View {
    @EnvironmentObject var store: FilmStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = MotionWorkspace()
    @State private var importing = false
    @State private var codec: MotionVideoCodec = .h264
    @State private var fps = 24.0
    @State private var bitrate = 100.0
    @State private var deleting: URL?
    var initialURL: URL? = nil
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Button("Import RAW / MotionCam file") {importing = true}.accessibilityIdentifier("importMotionRaw")
                    if !model.sources.isEmpty {
                        DisclosureGroup("Imported sources") {
                            ForEach(model.sources,id:\.self) {url in
                                HStack {
                                    Button(url.lastPathComponent) {Task {await model.open(url,root:store.root,settings:store.state.settings,lut:store.selectedLUT)}}.lineLimit(1)
                                    Spacer()
                                    Button(role:.destructive) {deleting = url} label:{Image(systemName:"trash")}.accessibilityLabel("Delete imported source")
                                }.disabled(model.busy || model.selecting)
                            }
                        }
                    }
                    if let preview = model.preview {Image(uiImage:preview).resizable().scaledToFit().frame(maxHeight:320).accessibilityIdentifier("motionRawPreview")}
                    if let clip = model.clip {
                        Text(clip.url.lastPathComponent).lineLimit(1)
                        Text("\(clip.count) frames • \(clip.fps,specifier:"%.2f") fps")
                        if clip.count > 1 {
                            Text("Frame \(model.selected+1) of \(clip.count)")
                            Slider(value:Binding(get:{Double(model.selected)},set:{model.selected = Int($0)}),in:0...Double(clip.count-1),step:1).accessibilityLabel("RAW frame")
                            Stepper("First frame: \(model.first+1)",value:$model.first,in:0...model.last)
                            Stepper("Last frame: \(model.last+1)",value:$model.last,in:model.first...(clip.count-1))
                            Button(model.selecting ? "Measuring sharpness…" : "Select sharpest frame (up to 300)") {model.selectSharpest(settings:store.state.settings,lut:store.selectedLUT)}.disabled(model.selecting)
                        }
                        HStack {Button("Export JPEG") {enqueue("JPEG")}.accessibilityIdentifier("motionExportJPEG"); Button("Export DNG") {enqueue("DNG")}}
                        if clip.container != nil {
                            Button("Export CinemaDNG sequence") {enqueue("CinemaDNG")}
                            Button("Export CinemaDNG ZIP") {enqueue("CinemaDNG ZIP")}
                            Picker("Video codec",selection:$codec) {ForEach(MotionVideoCodec.allCases) {Text($0.rawValue).tag($0)}}
                            Stepper("Output \(Int(fps)) fps",value:$fps,in:1...120)
                            Text("Bitrate \(Int(bitrate)) Mbps"); Slider(value:$bitrate,in:1...500,step:1)
                            Button("Export movie") {enqueue("Movie")}.accessibilityIdentifier("motionExportMovie")
                            Text("DNG exports preserve source Bayer samples and calibration. JPEG/movie exports apply MotionCam development then your film look. PCM audio is preserved at source frame rate; changing fps creates a silent speed-adjusted movie. Codec support depends on iOS.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if model.busy {ProgressView("Rendering",value:model.progress); Button("Cancel current export") {model.cancel()}}
                    if let url = model.result {ShareLink(item:url).accessibilityIdentifier("motionShareExport")}
                    DisclosureGroup("MotionCam development") {MotionGradeControls(grade:$store.state.settings.motion)}
                    if !model.jobs.isEmpty {Text("Export queue").font(.headline)}
                    ForEach(model.jobs) {job in HStack {VStack(alignment:.leading) {Text(job.kind); Text(job.status).font(.caption)}; Spacer(); if !["Rendering","Queued","Finished"].contains(job.status) {Button("Retry") {model.retry(job.id)}}}}
                    if model.clip == nil {Text("Open .mcraw v2/v3, DNG or another iOS-supported RAW still. Compressed MotionCam 1.2.7 frames use codec 6. Your sources remain local.").foregroundStyle(.secondary)}
                }.padding()
            }.navigationTitle("RAW workspace").toolbar {Button("Done") {dismiss()}}
            .task {
                model.configure(root:store.root)
                if let initialURL {await model.open(initialURL,root:store.root,settings:store.state.settings,lut:store.selectedLUT)}
                else if ProcessInfo.processInfo.arguments.contains("--motion-fixture") {
                    do {let url = store.root.appendingPathComponent("CI-fixture.mcraw"); try MotionFixture.container().write(to:url); await model.open(url,root:store.root,settings:store.state.settings,lut:store.selectedLUT)} catch {model.error = error.localizedDescription}
                }
            }
            .onChange(of:model.selected) {_,_ in model.render(settings:store.state.settings,lut:store.selectedLUT)}
            .onChange(of:store.state.settings) {_,_ in store.persist(); model.render(settings:store.state.settings,lut:store.selectedLUT)}
            .onChange(of:model.result) {_,_ in store.refresh()}
            .fileImporter(isPresented:$importing,allowedContentTypes:[.data,.image]) {result in switch result {case .success(let url): Task {await model.open(url,root:store.root,settings:store.state.settings,lut:store.selectedLUT)}; case .failure(let error): model.error = error.localizedDescription}}
            .alert("RAW workspace",isPresented:Binding(get:{model.error != nil},set:{if !$0 {model.error = nil}})) {Button("OK") {model.error = nil}} message:{Text(model.error ?? "")}
            .confirmationDialog("Delete this imported source?",isPresented:Binding(get:{deleting != nil},set:{if !$0 {deleting = nil}})) {Button("Delete",role:.destructive) {if let deleting {model.deleteSource(deleting,root:store.root)}; deleting = nil}}
        }
    }
    private func enqueue(_ kind:String) {model.enqueue(kind:kind,root:store.root,settings:store.state.settings,lut:store.selectedLUT,codec:codec,fps:fps,bitrate:Int(bitrate*1e6))}
}
