import SwiftUI

struct LibraryState: Codable {
    var settings = FilmPreset.originals.first(where:{$0.name.contains("(default preset)")})?.settings ?? FilmSettings()
    var presets: [FilmPreset] = []
    var luts: [CubeLUT] = []
}
@MainActor final class FilmStore: ObservableObject {
    let motionWorkspace = MotionWorkspace()
    @Published var state = LibraryState()
    @Published var media: [URL] = []
    @Published var error: String?
    let root: URL
    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("FilmCamera")
        do {
            try FileManager.default.createDirectory(at:self.root,withIntermediateDirectories:true)
            let file = self.root.appendingPathComponent("library.json")
            if FileManager.default.fileExists(atPath:file.path) { state = try JSONDecoder().decode(LibraryState.self,from:Data(contentsOf:file)) }
            state.settings.validate()
            for index in state.presets.indices {state.presets[index].settings.validate()}
            let lutIDs = Set(state.luts.map(\.id))
            if let id = state.settings.lutID, !lutIDs.contains(id) {state.settings.lutID = nil}
            for index in state.presets.indices {
                if let id = state.presets[index].settings.lutID, !lutIDs.contains(id) {state.presets[index].settings.lutID = nil}
            }
            refresh()
            motionWorkspace.onCompletion = {[weak self] _ in self?.refresh()}
        } catch { self.error = error.localizedDescription }
    }
    func persist() {
        do { try JSONEncoder().encode(state).write(to:root.appendingPathComponent("library.json"),options:.atomic) }
        catch { self.error = error.localizedDescription }
    }
    func savePreset(_ name: String) throws {
        let clean = name.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty else { throw PortError.message("Enter a preset name.") }
        state.presets.append(FilmPreset(name:clean,settings:state.settings)); persist()
    }
    func importLUT(_ url: URL) throws {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard (try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0) < 24_000_000 else { throw PortError.message("LUT file is too large.") }
        let lut = try CubeLUT.parse(String(contentsOf:url,encoding:.utf8),name:url.deletingPathExtension().lastPathComponent)
        state.luts.append(lut); state.settings.lutID = lut.id; persist()
    }
    var selectedLUT: CubeLUT? { state.luts.first { $0.id == state.settings.lutID } }
    func destination(_ ext: String) -> URL { root.appendingPathComponent("Film-\(UUID().uuidString).\(ext)") }
    func refresh() { media = ((try? FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:[.creationDateKey])) ?? []).filter { ["jpg","mov","mp4","dng","gcsv","wav","cinemadng","zip"].contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent > $1.lastPathComponent } }
    func delete(_ url: URL) { do { try FileManager.default.removeItem(at:url); refresh() } catch { self.error = error.localizedDescription } }
}
