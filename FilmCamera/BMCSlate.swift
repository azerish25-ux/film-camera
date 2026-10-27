import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

enum BMCSlateDayNight: String, Codable, CaseIterable, Identifiable {
    case day = "Day", night = "Night"
    var id: String { rawValue }
}

enum BMCSlateEnvironment: String, Codable, CaseIterable, Identifiable {
    case interior = "Interior", exterior = "Exterior"
    var id: String { rawValue }
}

/// User-entered slate values stored in the movie's QuickTime metadata.
struct BMCSlate: Codable, Equatable {
    var project = ""
    var reel = ""
    var scene = ""
    var take = ""
    var camera = ""
    var director = ""
    var cameraOperator = ""
    var notes = ""
    // Optional properties also allow slates saved by older app versions to decode.
    var dayNight: BMCSlateDayNight?
    var environment: BMCSlateEnvironment?
    var goodTake: Bool?

    var fields: [String: String] {
        var values = [
            "com.blackmagic-design.camera.projectName": project,
            "com.blackmagic-design.camera.reelNumber": reel,
            "com.blackmagic-design.camera.scene": scene,
            "com.blackmagic-design.camera.take": take,
            "com.blackmagic-design.camera.cameraNumber": camera,
            "com.blackmagic-design.camera.director": director,
            "com.blackmagic-design.camera.cameraOp": cameraOperator,
            "com.apple.proapps.logNote": notes
        ]
        values["com.blackmagic-design.camera.dayNight"] = dayNight?.rawValue
        values["com.blackmagic-design.camera.environment"] = environment?.rawValue
        values["com.blackmagic-design.camera.goodTake"] = goodTake.map { $0 ? "1" : "0" }
        return values.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    #if canImport(AVFoundation)
    func merging(with existing: [AVMetadataItem]) -> [AVMetadataItem] {
        let fields = fields
        let preserved = existing.filter { item in
            guard item.keySpace == .quickTimeMetadata, let key = item.key as? String else { return true }
            return fields[key] == nil
        }
        let additions: [AVMetadataItem] = fields.sorted { $0.key < $1.key }.map { key, value in
            let item = AVMutableMetadataItem()
            item.keySpace = .quickTimeMetadata
            item.key = key as NSString
            item.value = value as NSString
            item.dataType = "com.apple.metadata.datatype.UTF-8"
            return item
        }
        return preserved + additions
    }
    #endif
}
