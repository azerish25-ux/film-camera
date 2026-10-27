import Foundation
import CoreGraphics

enum RawMovieResolution: String, Codable, CaseIterable, Identifiable {
    case p720 = "720p max", p1080 = "1080p max", p1440 = "1440p max", p4k = "4K max", source = "Source size"
    var id: String {rawValue}
    var bounds: CGSize? {
        switch self {
        case .p720: return CGSize(width:1280,height:720)
        case .p1080: return CGSize(width:1920,height:1080)
        case .p1440: return CGSize(width:2560,height:1440)
        case .p4k: return CGSize(width:3840,height:2160)
        case .source: return nil
        }
    }
    var decodeLimit: Double? {bounds.map {Double(max($0.width,$0.height))}}
    func fit(_ input:CGSize) -> CGSize {
        let limit = bounds.map {input.width < input.height ? CGSize(width:$0.height,height:$0.width) : $0} ?? input
        let scale = min(1,min(limit.width/max(1,input.width),limit.height/max(1,input.height)))
        return CGSize(width:max(2,floor(input.width*scale/2)*2),height:max(2,floor(input.height*scale/2)*2))
    }
}
