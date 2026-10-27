import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct GalleryScreen: View {
    @EnvironmentObject var store: FilmStore
    @State private var selected: URL?
    @State private var deleting: URL?
    var body: some View {
        NavigationStack {
            List {
                if store.media.isEmpty {ContentUnavailableView("Your film roll is empty",systemImage:"photo.stack",description:Text("Capture or export media to add it here."))}
                ForEach(store.media,id:\.self) {url in
                    Button {selected = url} label: {Label(url.lastPathComponent,systemImage:url.pathExtension == "jpg" ? "photo" : "film").lineLimit(1)}
                        .swipeActions {Button("Delete",role:.destructive) {deleting = url}}
                }
            }.navigationTitle("Gallery").onAppear {store.refresh()}
            .sheet(item:Binding(get:{selected.map(MediaSelection.init)},set:{selected = $0?.url})) {item in
                NavigationStack {
                    VStack {
                        if item.url.pathExtension == "jpg", let image = UIImage(contentsOfFile:item.url.path) {Image(uiImage:image).resizable().scaledToFit()}
                        else if ["mov","mp4"].contains(item.url.pathExtension) {MovieViewer(url:item.url)}
                        else if ["dng","rawseq"].contains(item.url.pathExtension) {MotionWorkspaceScreen(initialURL:item.url).environmentObject(store)}
                        else {Label(item.url.lastPathComponent,systemImage:"doc")}
                        HStack {ShareLink(item:item.url); if ["jpg","mov","mp4"].contains(item.url.pathExtension) {Button("Save to Photos") {Task {do {try await MediaExporter.saveToPhotos(item.url)} catch {store.error = error.localizedDescription}}}}}
                    }.padding().toolbar {Button("Done") {selected = nil}}
                }
            }
            .confirmationDialog("Delete this media permanently?",isPresented:Binding(get:{deleting != nil},set:{if !$0 {deleting = nil}})) {Button("Delete",role:.destructive) {if let deleting {store.delete(deleting)}; deleting = nil}}
        }
    }
}
struct MediaSelection: Identifiable {let url: URL; var id: URL {url}}
struct MovieViewer: View {
    let url: URL
    @State private var player: AVPlayer?
    var body: some View {VideoPlayer(player:player).onAppear {player = AVPlayer(url:url)}.onDisappear {player?.pause(); player = nil}}
}
struct PresetsScreen: View {
    @EnvironmentObject var store: FilmStore
    @State private var name = ""
    @State private var importing = false
    @FocusState private var editingName: Bool
    var body: some View {
        NavigationStack {
            List {
                Section("Save current film settings") {
                    TextField("Preset name",text:$name).focused($editingName).submitLabel(.done).onSubmit {editingName = false}.accessibilityIdentifier("presetName")
                    Button("Save preset") {do {try store.savePreset(name); name = ""; editingName = false} catch {store.error = error.localizedDescription}}.accessibilityIdentifier("savePreset")
                }
                Section("My presets") {
                    ForEach(store.state.presets) {preset in
                        Button(preset.name) {store.state.settings = preset.settings; store.persist()}
                    }.onDelete {offsets in store.state.presets.remove(atOffsets:offsets); store.persist()}
                }
                Section("Original camera presets") {
                    ForEach(FilmPreset.originals) {preset in Button(preset.name) {store.state.settings = preset.settings; store.persist()}}
                }
                Section("Film looks") {ForEach(FilmSettings.looks,id:\.self) {look in Button(look) {store.state.settings.look = look; store.persist()}}}
                Section("CUBE lookup tables") {
                    Button("Import CUBE LUT") {importing = true}
                    ForEach(store.state.luts) {lut in Button(lut.name) {store.state.settings.lutID = lut.id; store.persist()}}
                        .onDelete {offsets in
                            let ids = offsets.map {store.state.luts[$0].id}
                            if let id = store.state.settings.lutID, ids.contains(id) {store.state.settings.lutID = nil}
                            store.state.luts.remove(atOffsets:offsets); store.persist()
                        }
                }
            }.navigationTitle("Presets")
            .fileImporter(isPresented:$importing,allowedContentTypes:[.data,.plainText]) {result in do {try store.importLUT(result.get())} catch {store.error = error.localizedDescription}}
        }
    }
}
struct SettingsScreen: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Super 16 for iOS") {
                    Text("A local film camera and editor.")
                    Text("Photos, films, presets and imported LUTs stay on this device. No account or subscription is required.")
                }
                Section("Permissions") {Button("Open system settings") {if let url = URL(string:UIApplication.openSettingsURLString) {UIApplication.shared.open(url)}}}
                Section("Using the camera") {Text("Choose Photo or Video, adjust your film settings, then capture. Video is processed after recording. Keep the app open until export finishes. Find finished media in Gallery, where you can share or save to Photos.")}
                Section("Editing") {Text("Import a photo or video from Photos or Files. Adjust the film settings, trim videos and select an export resolution. Export creates a new file in Gallery and preserves your source.")}
                Section("LUTs and presets") {Text("Import a 3D .cube table in Presets. Supported dimensions are 2–64. Save the current adjustments under a name to reuse them.")}
            }.navigationTitle("Settings")
        }
    }
}
