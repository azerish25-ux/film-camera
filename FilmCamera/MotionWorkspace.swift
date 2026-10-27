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
    var resolution: RawMovieResolution? = nil
    var sourceTiming: Bool? = nil
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
    @Published var selecting = false
    @Published var sources: [URL] = []
    var onCompletion: ((URL) -> Void)?
    private var task: Task<Void,Never>?
    private var previewTask: Task<Void,Never>?
    private let previewWorker = MotionPreviewWorker()
    private var queueURL: URL?
    func configure(root:URL) {
        guard queueURL == nil else {return}
        queueURL = root.appendingPathComponent("motion-export-queue.json")
        if let data = try? Data(contentsOf:queueURL!),let saved = try? JSONDecoder().decode([MotionExportJob].self,from:data) {
            jobs = saved.map {job in var j = job; if ["Rendering","Queued"].contains(j.status) {j.status = "Interrupted — retry"}; return j}
        }
        persist()
        refreshSources(root:root)
    }
    func refreshSources(root:URL) {sources = ((try? FileManager.default.contentsOfDirectory(at:root.appendingPathComponent("RAW"),includingPropertiesForKeys:nil)) ?? []).filter {!["json"].contains($0.pathExtension.lowercased())}.sorted {$0.lastPathComponent < $1.lastPathComponent}}
    func deleteSource(_ url:URL,root:URL) {
        guard !busy,!selecting,url.deletingLastPathComponent().standardizedFileURL == root.appendingPathComponent("RAW").standardizedFileURL else {return}
        do {try FileManager.default.removeItem(at:url); if clip?.url == url {previewTask?.cancel(); clip = nil; preview = nil}; refreshSources(root:root)} catch {self.error = error.localizedDescription}
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
            if source.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path+"/") {local = source}
            else {local = directory.appendingPathComponent(source.deletingPathExtension().lastPathComponent+"-"+UUID().uuidString+"."+source.pathExtension)}
            let opened = try await Task.detached {
                var success = false
                defer {if !success && local != source {try? FileManager.default.removeItem(at:local)}}
                if local != source {try FileManager.default.copyItem(at:source,to:local)}
                let clip = try MotionClip(url:local); success = true; return clip
            }.value
            clip = opened; selected = 0; first = 0; last = opened.count-1; result = nil
            refreshSources(root:root)
            render(settings:settings,lut:lut)
        } catch {self.error = error.localizedDescription}
    }
    func render(settings:FilmSettings,lut:CubeLUT?) {
        guard let clip else {return}; previewTask?.cancel()
        let index = selected
        previewTask = Task {
            do {
                let image = try await previewWorker.render(clip:clip,index:index,settings:settings,lut:lut)
                if !Task.isCancelled {preview = image}
            } catch {if !Task.isCancelled {self.error = error.localizedDescription}}
        }
    }
    func selectSharpest(settings:FilmSettings,lut:CubeLUT?) {
        guard let clip,!selecting else {return}
        let range = first...min(last,first+299); selecting = true
        Task {
            defer {selecting = false}
            do {
                let best = try await Task.detached {
                    let context = CIContext(options:[.cacheIntermediates:false])
                    var best = range.lowerBound,score = -Double.greatestFiniteMagnitude
                    for index in range {
                        try Task.checkCancellation()
                        let value: Double = try autoreleasepool {
                            let image = try clip.image(index,context:context,maxDimension:160)
                            let scale = min(1,160/max(image.extent.width,image.extent.height))
                            let small = image.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
                            guard let cg = context.createCGImage(small,from:small.extent) else {throw PortError.message("Cannot rank frame sharpness.")}
                            return MotionSharpness.score(cg)
                        }
                        if value > score {best = index; score = value}
                    }
                    return best
                }.value
                selected = best; render(settings:settings,lut:lut)
            } catch {self.error = error.localizedDescription}
        }
    }
    func enqueue(kind:String,root:URL,settings:FilmSettings,lut:CubeLUT?,codec:MotionVideoCodec,fps:Double,bitrate:Int,resolution:RawMovieResolution = .p1080) {
        guard let clip,first <= last,first >= 0,last < clip.count else {error = "Select a valid frame range."; return}
        let ext = kind == "Movie" ? "mov" : kind == "JPEG" ? "jpg" : kind == "DNG" ? "dng" : kind == "CinemaDNG ZIP" ? "zip" : "cinemadng"
        jobs.append(MotionExportJob(source:clip.url,destination:root.appendingPathComponent("Motion-\(UUID().uuidString).\(ext)"),first:kind == "JPEG" || kind == "DNG" ? selected : first,last:kind == "JPEG" || kind == "DNG" ? selected : last,settings:settings,lut:lut,kind:kind,codec:codec,fps:fps > 0 ? fps : MotionVideoExport.sourceFPS(clip.fps),bitrate:bitrate,resolution:resolution,sourceTiming:kind == "Movie" && fps <= 0 && !clip.isTimelapse))
        persist(); runNext()
    }
    func retry(_ id:UUID) {
        guard let i = jobs.firstIndex(where:{$0.id == id}),!["Rendering","Queued","Finished"].contains(jobs[i].status),let root = queueURL?.deletingLastPathComponent() else {return}
        let target = jobs[i].destination.standardizedFileURL
        guard target.deletingLastPathComponent() == root.standardizedFileURL,target.lastPathComponent.hasPrefix("Motion-") else {error = "Invalid export retry destination."; return}
        do {if FileManager.default.fileExists(atPath:target.path) {try FileManager.default.removeItem(at:target)}} catch {self.error = error.localizedDescription; return}
        jobs[i].status = "Queued"; persist(); runNext()
    }
    func cancel() {task?.cancel()}
    private func runNext() {
        guard !busy,let index = jobs.firstIndex(where:{$0.status == "Queued"}) else {return}
        jobs[index].status = "Rendering"; persist(); busy = true; progress = 0
        let job = jobs[index]
        task = Task {
            do {
                let work = Task.detached {try await MotionJobRunner.run(job) {value in Task {@MainActor in self.progress = value}}}
                try await withTaskCancellationHandler(operation:{try await work.value},onCancel:{work.cancel()})
                jobs[index].status = "Finished"; result = job.destination; onCompletion?(job.destination)
            } catch {jobs[index].status = error is CancellationError ? "Cancelled" : "Failed: \(error.localizedDescription)"; if !(error is CancellationError) {self.error = error.localizedDescription}}
            persist(); busy = false; task = nil; runNext()
        }
    }
}
