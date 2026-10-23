import CoreImage
import UIKit
import AVFoundation

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
        let size = s.frame.outputSize(for:landscape.extent.size)
        let rect = CGRect(x:(landscape.extent.width-size.width)/2,y:(landscape.extent.height-size.height)/2,width:size.width,height:size.height)
        let cropped = landscape.cropped(to:rect).transformed(by:CGAffineTransform(translationX:-rect.minX,y:-rect.minY))
        let pipeline = try originalPipeline()
        let processed = try pipeline.render(cropped,settings:s,lut:lut,time:time)
        return portrait ? processed.oriented(.left) : processed
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
    func videoComposition(asset: AVAsset, settings: FilmSettings, lut: CubeLUT?, preview: Bool = false, histogram: (([Float]) -> Void)? = nil) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition(asset:asset) {[self] request in
            do {
                let raw = request.sourceImage
                let scale = preview ? min(1,1280/max(raw.extent.width,raw.extent.height)) : 1
                let input = raw.transformed(by:CGAffineTransform(scaleX:scale,y:scale))
                let image = try render(input,settings:settings,lut:lut,time:request.compositionTime.seconds)
                if let histogram {histogram(FilmHistogram.values(image))}
                let target = CGRect(origin:.zero,size:request.renderSize)
                let fitScale = min(target.width/image.extent.width,target.height/image.extent.height)
                let fitted = image.transformed(by:CGAffineTransform(scaleX:fitScale,y:fitScale))
                let centered = fitted.transformed(by:CGAffineTransform(translationX:(target.width-fitted.extent.width)/2,y:(target.height-fitted.extent.height)/2))
                request.finish(with:centered.composited(over:CIImage(color:.black).cropped(to:target)).cropped(to:target),context:context)
            } catch {request.finish(with:error)}
        }
        composition.renderSize = settings.frame.outputSize(for:composition.renderSize)
        return composition
    }

}
