import CoreImage
import UIKit

actor MotionPreviewWorker {
    private let renderer = FilmRenderer()
    func render(clip:MotionClip,index:Int,settings:FilmSettings,lut:CubeLUT?) throws -> UIImage {
        try Task.checkCancellation()
        let source = try clip.image(index,context:renderer.context,maxDimension:1024)
        try Task.checkCancellation()
        let scale = min(1,1024/max(source.extent.width,source.extent.height))
        let image = try renderer.render(source.transformed(by:CGAffineTransform(scaleX:scale,y:scale)),settings:settings,lut:lut,time:clip.relativeTime(index,from:0))
        try Task.checkCancellation()
        guard let cg = renderer.context.createCGImage(image,from:image.extent) else {throw PortError.message("Cannot render RAW preview.")}
        return UIImage(cgImage:cg)
    }
}
