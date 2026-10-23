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
        let bounds = source.extent
        let pipeline = try originalPipeline()
        var image = try pipeline.render(source,settings:s,lut:lut,time:time)
        var crop = bounds
        if let ratio = s.frame.ratio {
            let r = bounds.width < bounds.height ? 1/ratio : ratio
            if bounds.width/bounds.height > r { crop.size.width = bounds.height*r; crop.origin.x += (bounds.width-crop.width)/2 }
            else { crop.size.height = bounds.width/r; crop.origin.y += (bounds.height-crop.height)/2 }
        }
        image = image.cropped(to:crop).transformed(by:CGAffineTransform(translationX:-crop.minX,y:-crop.minY))
        if s.frame.perforations || s.frame == .framed {
            let e = image.extent, rail = max(3,e.width*0.055)
            let black = CIImage(color:.black)
            image = black.cropped(to:CGRect(x:0,y:0,width:rail,height:e.height)).composited(over:image)
            if s.frame == .framed { image = black.cropped(to:CGRect(x:e.width-rail,y:0,width:rail,height:e.height)).composited(over:image) }
            if s.frame.perforations {
                let color = CIImage(color:CIColor(red:s["perfColor"],green:s["perfColor"],blue:s["perfColor"]))
                for n in 0..<8 {
                    let hole = CGRect(x:rail*0.2,y:CGFloat(n)*e.height/8 + e.height/40,width:rail*0.6,height:e.height/18)
                    image = color.cropped(to:hole).composited(over:image)
                }
            }
        }
        return image
    }
    func photo(_ image: UIImage, settings: FilmSettings, lut: CubeLUT?) throws -> UIImage {
        guard let data = image.jpegData(compressionQuality:1), let source = CIImage(data:data,options:[.applyOrientationProperty:true]) else { throw PortError.message("Cannot decode image.") }
        let result = try render(source,settings:settings,lut:lut)
        guard let cg = context.createCGImage(result,from:result.extent) else { throw PortError.message("Cannot render image.") }
        return UIImage(cgImage:cg)
    }
}
