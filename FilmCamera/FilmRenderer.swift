import CoreImage
import UIKit

final class FilmRenderer {
    private let pipelineLock = NSLock()
    private var pipeline: OriginalFilmPipeline?
    private func originalPipeline() throws -> OriginalFilmPipeline {
        pipelineLock.lock(); defer {pipelineLock.unlock()}
        if let pipeline {return pipeline}
        let created = try OriginalFilmPipeline(); pipeline = created; return created
    }
    let context = CIContext(options: [.cacheIntermediates: false])
    func render(_ source: CIImage, settings s: FilmSettings, lut: CubeLUT? = nil, time: Double = 0) throws -> CIImage {
        let normalized = source.transformed(by:CGAffineTransform(translationX:-source.extent.minX,y:-source.extent.minY))
        let bounds = normalized.extent
        let portrait = bounds.width < bounds.height
        let landscape = portrait ? normalized.oriented(.right) : normalized
        let pipeline = try originalPipeline()
        let processed = try pipeline.render(landscape,settings:s,lut:lut,time:time)
        var image = portrait ? processed.oriented(.left) : processed
        var crop = image.extent
        if let ratio = s.frame.ratio {
            let r = bounds.width < bounds.height ? 1/ratio : ratio
            if bounds.width/bounds.height > r { crop.size.width = bounds.height*r; crop.origin.x += (bounds.width-crop.width)/2 }
            else { crop.size.height = bounds.width/r; crop.origin.y += (bounds.height-crop.height)/2 }
        }
        image = image.cropped(to:crop).transformed(by:CGAffineTransform(translationX:-crop.minX,y:-crop.minY))
        return image
    }
    func photo(_ image: UIImage, settings: FilmSettings, lut: CubeLUT?) throws -> UIImage {
        guard let source = CIImage(image:image,options:[.applyOrientationProperty:true]) else { throw PortError.message("Cannot decode image.") }
        let result = try render(source,settings:settings,lut:lut)
        guard let cg = context.createCGImage(result,from:result.extent) else { throw PortError.message("Cannot render image.") }
        return UIImage(cgImage:cg)
    }
}
