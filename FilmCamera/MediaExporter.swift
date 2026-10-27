import AVFoundation
import Photos
import UIKit

final class MediaExporter: ObservableObject {
    @Published var progress: Float = 0
    @Published var busy = false
    private var session: AVAssetExportSession?
    private let renderer = FilmRenderer()
    @MainActor func exportVideo(source: URL, destination: URL, settings: FilmSettings, lut: CubeLUT?, slate: BMCSlate? = nil, start: Double = 0, end: Double? = nil, resolution: String = AVAssetExportPreset1920x1080) async throws {
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
        if let slate, !slate.fields.isEmpty { export.metadata = slate.merging(with: try await asset.load(.metadata)) }
        export.shouldOptimizeForNetworkUse = false
        let begin = max(0,min(start,duration.seconds-0.01)), finish = max(begin+0.01,min(end ?? duration.seconds,duration.seconds))
        export.timeRange = CMTimeRange(start:CMTime(seconds:begin,preferredTimescale:600),end:CMTime(seconds:finish,preferredTimescale:600))
        export.videoComposition = renderer.videoComposition(asset:asset,settings:settings,lut:lut)
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
