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
    private func source(_ image: UIImage) throws -> CIImage {
        guard let pixels = image.ciImage ?? image.cgImage.map({CIImage(cgImage:$0)}) else {throw PortError.message("Cannot decode image.")}
        let orientation: Int32
        switch image.imageOrientation {
        case .up: orientation = 1
        case .upMirrored: orientation = 2
        case .down: orientation = 3
        case .downMirrored: orientation = 4
        case .leftMirrored: orientation = 5
        case .right: orientation = 6
        case .rightMirrored: orientation = 7
        case .left: orientation = 8
        @unknown default: orientation = 1
        }
        return pixels.oriented(forExifOrientation:orientation)
    }

    func preview(_ image: UIImage, settings: FilmSettings, lut: CubeLUT?) throws -> UIImage {
        let pixels = try source(image)
        let scale = min(1,1024/max(pixels.extent.width,pixels.extent.height))
        let result = try render(pixels.transformed(by:CGAffineTransform(scaleX:scale,y:scale)),settings:settings,lut:lut)
        guard let cg = context.createCGImage(result,from:result.extent) else {throw PortError.message("Cannot render preview.")}
        return UIImage(cgImage:cg)
    }
    func photo(_ image: UIImage, settings: FilmSettings, lut: CubeLUT?) throws -> UIImage {
        let result = try render(try source(image),settings:settings,lut:lut)
        guard let cg = context.createCGImage(result,from:result.extent) else { throw PortError.message("Cannot render image.") }
        return UIImage(cgImage:cg)
    }
}
