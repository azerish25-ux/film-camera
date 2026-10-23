import AVFoundation
import Photos
import UIKit

final class MediaExporter: ObservableObject {
    @Published var progress: Float = 0
    @Published var busy = false
    private var session: AVAssetExportSession?
    private let renderer = FilmRenderer()
    @MainActor func exportVideo(source: URL, destination: URL, settings: FilmSettings, lut: CubeLUT?, start: Double = 0, end: Double? = nil, resolution: String = AVAssetExportPreset1920x1080) async throws {
        guard !busy else { throw PortError.message("An export is already running.") }
        busy = true; progress = 0
        defer { busy = false; session = nil }
        let asset = AVURLAsset(url:source)
        let duration = try await asset.load(.duration)
        guard duration.seconds.isFinite, duration.seconds > 0 else { throw PortError.message("Invalid video duration.") }
        guard let export = AVAssetExportSession(asset:asset,presetName:resolution) else { throw PortError.message("Unsupported export resolution.") }
        session = export
        export.outputURL = destination
        export.outputFileType = .mov
        export.shouldOptimizeForNetworkUse = false
        let begin = max(0,min(start,duration.seconds-0.01)), finish = max(begin+0.01,min(end ?? duration.seconds,duration.seconds))
        export.timeRange = CMTimeRange(start:CMTime(seconds:begin,preferredTimescale:600),end:CMTime(seconds:finish,preferredTimescale:600))
        let renderer = self.renderer
        export.videoComposition = AVVideoComposition(asset:asset) { request in
            let result = renderer.render(request.sourceImage,settings:settings,lut:lut,time:request.compositionTime.seconds)
            // AVVideoComposition requires a constant render extent. Fit the film crop into that extent.
            let target = request.sourceImage.extent
            let scale = min(target.width/result.extent.width,target.height/result.extent.height)
            let fitted = result.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
            let centered = fitted.transformed(by:CGAffineTransform(translationX:(target.width-fitted.extent.width)/2,y:(target.height-fitted.extent.height)/2))
            request.finish(with:centered.composited(over:CIImage(color:.black).cropped(to:target)).cropped(to:target),context:renderer.context)
        }
        let monitor = Task { @MainActor in
            while !Task.isCancelled { progress = export.progress; try? await Task.sleep(nanoseconds:150_000_000) }
        }
        defer { monitor.cancel() }
        await export.export()
        guard export.status == .completed else {
            try? FileManager.default.removeItem(at:destination)
            throw export.error ?? PortError.message(export.status == .cancelled ? "Export cancelled." : "Video export failed.")
        }
        progress = 1
    }
    @MainActor func cancel() { session?.cancelExport() }
    static func saveToPhotos(_ url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for:.addOnly)
        guard status == .authorized || status == .limited else { throw PortError.message("Allow Photos access in Settings to save to your library.") }
        try await PHPhotoLibrary.shared().performChanges {
            if ["mov","mp4"].contains(url.pathExtension.lowercased()) { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:url) }
            else { PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL:url) }
        }
    }
}
