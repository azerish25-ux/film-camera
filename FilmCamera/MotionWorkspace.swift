import SwiftUI
import CoreImage

struct MotionExportJob: Codable, Identifiable {
    var id = UUID()
    let source: URL
    let destination: URL
    let first: Int
    let last: Int
    let settings: FilmSettings
    let lut: CubeLUT?
    let kind: String
    let codec: MotionVideoCodec
    let fps: Double
    let bitrate: Int
    var status = "Queued"
}
@MainActor final class MotionWorkspace: ObservableObject {
    @Published var clip: MotionClip?
    @Published var preview: UIImage?
    @Published var selected = 0
    @Published var first = 0
    @Published var last = 0
    @Published var busy = false
    @Published var progress = 0.0
    @Published var jobs: [MotionExportJob] = []
    @Published var error: String?
    @Published var result: URL?
    private var task: Task<Void,Never>?
    private var previewTask: Task<Void,Never>?
    private var queueURL: URL?
    func configure(root:URL) {
        guard queueURL == nil else {return}
        queueURL = root.appendingPathComponent("motion-export-queue.json")
        if let data = try? Data(contentsOf:queueURL!),let saved = try? JSONDecoder().decode([MotionExportJob].self,from:data) {
            jobs = saved.map {job in var j = job; if ["Rendering","Queued"].contains(j.status) {j.status = "Interrupted — retry"}; return j}
        }
        persist()
    }
    private func persist() {
        guard let queueURL else {return}
        do {try JSONEncoder().encode(jobs).write(to:queueURL,options:.atomic)} catch {self.error = error.localizedDescription}
    }
    func open(_ source:URL,root:URL,settings:FilmSettings,lut:CubeLUT?) async {
        let access = source.startAccessingSecurityScopedResource(); defer {if access {source.stopAccessingSecurityScopedResource()}}
        do {
            let directory = root.appendingPathComponent("RAW",isDirectory:true)
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            let local: URL
            if source.deletingLastPathComponent() == directory {local = source}
            else {local = directory.appendingPathComponent(UUID().uuidString+"."+source.pathExtension); try FileManager.default.copyItem(at:source,to:local)}
            let opened = try await Task.detached {try MotionClip(url:local)}.value
            clip = opened; selected = 0; first = 0; last = opened.count-1; result = nil
            render(settings:settings,lut:lut)
        } catch {self.error = error.localizedDescription}
    }
    func render(settings:FilmSettings,lut:CubeLUT?) {
        guard let clip else {return}; previewTask?.cancel()
        let index = selected
        previewTask = Task {
            do {
                let image = try await Task.detached {
                    let renderer = FilmRenderer(),source = try clip.image(index,context:renderer.context)
                    let scale = min(1,1024/max(source.extent.width,source.extent.height))
                    let processed = try renderer.render(source.transformed(by:CGAffineTransform(scaleX:scale,y:scale)),settings:settings,lut:lut,time:Double(index)/clip.fps)
                    guard let cg = renderer.context.createCGImage(processed,from:processed.extent) else {throw PortError.message("Cannot render RAW preview.")}
                    return UIImage(cgImage:cg)
                }.value
                if !Task.isCancelled {preview = image}
            } catch {if !Task.isCancelled {self.error = error.localizedDescription}}
        }
    }
    func enqueue(kind:String,root:URL,settings:FilmSettings,lut:CubeLUT?,codec:MotionVideoCodec,fps:Double,bitrate:Int) {
        guard let clip,first <= last,first >= 0,last < clip.count else {error = "Select a valid frame range."; return}
        let ext = kind == "Movie" ? "mov" : kind == "JPEG" ? "jpg" : kind == "DNG" ? "dng" : "cinemadng"
        jobs.append(MotionExportJob(source:clip.url,destination:root.appendingPathComponent("Motion-\(UUID().uuidString).\(ext)"),first:kind == "JPEG" || kind == "DNG" ? selected : first,last:kind == "JPEG" || kind == "DNG" ? selected : last,settings:settings,lut:lut,kind:kind,codec:codec,fps:fps,bitrate:bitrate))
        persist(); runNext()
    }
    func retry(_ id:UUID) {guard let i = jobs.firstIndex(where:{$0.id == id}),jobs[i].status != "Rendering" else {return}; jobs[i].status = "Queued"; persist(); runNext()}
    func cancel() {task?.cancel()}
    private func runNext() {
        guard !busy,let index = jobs.firstIndex(where:{$0.status == "Queued"}) else {return}
        jobs[index].status = "Rendering"; persist(); busy = true; progress = 0
        let job = jobs[index]
        task = Task {
            do {
                let work = Task.detached {try await MotionJobRunner.run(job) {value in Task {@MainActor in self.progress = value}}}
                try await withTaskCancellationHandler(operation:{try await work.value},onCancel:{work.cancel()})
                jobs[index].status = "Finished"; result = job.destination
            } catch {jobs[index].status = error is CancellationError ? "Cancelled" : "Failed: \(error.localizedDescription)"; if !(error is CancellationError) {self.error = error.localizedDescription}}
            persist(); busy = false; task = nil; runNext()
        }
    }
}
