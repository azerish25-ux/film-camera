import AVFoundation

enum BMCMovieCodec: String, CaseIterable, Identifiable {
    case h264, hevc
    var id: String { rawValue }
    var title: String { self == .h264 ? "H.264" : "HEVC" }
    func exportPreset(fourK: Bool) -> String {
        switch (self, fourK) {
        case (.h264, false): return AVAssetExportPreset1920x1080
        case (.h264, true): return AVAssetExportPreset3840x2160
        case (.hevc, false): return AVAssetExportPresetHEVC1920x1080
        case (.hevc, true): return AVAssetExportPresetHEVC3840x2160
        }
    }
}
