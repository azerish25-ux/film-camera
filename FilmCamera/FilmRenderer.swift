import CoreImage
import UIKit

final class FilmRenderer {
    let context = CIContext(options: [.cacheIntermediates: false])
    func render(_ source: CIImage, settings s: FilmSettings, lut: CubeLUT? = nil, time: Double = 0) -> CIImage {
        let bounds = source.extent
        var image = source
        func apply(_ name: String, _ parameters: [String: Any] = [:]) { image = image.applyingFilter(name, parameters: parameters) }
        let movement = sin(time*1.7)*s["jitter"]*4 + sin(time*37)*s["shake"]*3
        if movement != 0 { image = image.clampedToExtent().transformed(by: CGAffineTransform(translationX:movement,y:movement*0.7)).cropped(to:bounds) }
        apply("CIExposureAdjust", [kCIInputEVKey:s["exposure"] + sin(time*8)*s["flicker"]*0.25])
        apply("CIColorControls", [kCIInputContrastKey:s["contrast"],kCIInputSaturationKey:s["saturation"]])
        apply("CITemperatureAndTint", ["inputNeutral":CIVector(x:6500,y:0),"inputTargetNeutral":CIVector(x:s["temperature"],y:s["tint"])])
        switch s.look {
        case "Warm negative": apply("CIPhotoEffectInstant")
        case "Cool negative": apply("CIPhotoEffectProcess")
        case "Faded print": apply("CIPhotoEffectFade")
        case "Chrome": apply("CIPhotoEffectChrome")
        case "Black & white": apply("CIPhotoEffectNoir")
        case "Sepia": apply("CISepiaTone",[kCIInputIntensityKey:0.85])
        default: break
        }
        if let lut = lut {
            let scales = zip(lut.domainMin,lut.domainMax).map { 1 / ($1 - $0) }
            let offset = zip(lut.domainMin,scales).map { -$0*$1 }
            apply("CIColorMatrix",["inputRVector":CIVector(x:CGFloat(scales[0]),y:0,z:0,w:0),"inputGVector":CIVector(x:0,y:CGFloat(scales[1]),z:0,w:0),"inputBVector":CIVector(x:0,y:0,z:CGFloat(scales[2]),w:0),"inputBiasVector":CIVector(x:CGFloat(offset[0]),y:CGFloat(offset[1]),z:CGFloat(offset[2]),w:0)])
            let data = lut.rgba.withUnsafeBufferPointer { Data(buffer:$0) }
            apply("CIColorCube",["inputCubeDimension":lut.dimension,"inputCubeData":data])
        }
        if s["chroma"] > 0 {
            let red = image.transformed(by:CGAffineTransform(translationX:s["chroma"],y:0)).applyingFilter("CIColorMatrix",parameters:["inputGVector":CIVector(x:0,y:0,z:0,w:0),"inputBVector":CIVector(x:0,y:0,z:0,w:0)])
            let cyan = image.applyingFilter("CIColorMatrix",parameters:["inputRVector":CIVector(x:0,y:0,z:0,w:0)])
            image = red.applyingFilter("CIAdditionCompositing",parameters:[kCIInputBackgroundImageKey:cyan]).cropped(to:bounds)
        }
        if s["halation"] > 0 {
            let glow = image.applyingFilter("CIColorClamp",parameters:["inputMinComponents":CIVector(x:s["halationCutoff"],y:s["halationCutoff"],z:s["halationCutoff"],w:0)])
                .applyingFilter("CIColorMatrix",parameters:["inputRVector":CIVector(x:s["halation"],y:0,z:0,w:0),"inputGVector":CIVector(x:0,y:s["halation"]*s["halationGreen"],z:0,w:0),"inputBVector":CIVector(x:0,y:0,z:s["halation"]*s["halationBlue"],w:0)])
                .clampedToExtent().applyingFilter("CIGaussianBlur",parameters:[kCIInputRadiusKey:s["halationRadius"]]).cropped(to:bounds)
            image = glow.applyingFilter("CIScreenBlendMode",parameters:[kCIInputBackgroundImageKey:image])
        }
        if s["blur"] > 0 { image = image.clampedToExtent().applyingFilter("CIGaussianBlur",parameters:[kCIInputRadiusKey:s["blur"]]).cropped(to:bounds) }
        if s["grain"] > 0, var noise = CIFilter(name:"CIRandomGenerator")?.outputImage {
            noise = noise.transformed(by:CGAffineTransform(translationX:Double(Int(time*24)%173),y:Double(Int(time*24)%137))).transformed(by:CGAffineTransform(scaleX:s["grainSize"],y:s["grainSize"]))
            noise = noise.applyingFilter("CIColorControls",parameters:[kCIInputSaturationKey:s["grainChroma"],kCIInputContrastKey:1-s["grainSmoothness"]*0.8])
            noise = noise.applyingFilter("CIColorMatrix",parameters:["inputAVector":CIVector(x:0,y:0,z:0,w:s["grain"]*0.4)]).cropped(to:bounds)
            let mask = image.applyingFilter("CIColorControls",parameters:[kCIInputSaturationKey:0]).applyingFilter("CIColorInvert")
            let shadow = noise.applyingFilter("CIBlendWithMask",parameters:[kCIInputBackgroundImageKey:CIImage(color:.clear).cropped(to:bounds),kCIInputMaskImageKey:mask])
            noise = shadow.applyingFilter("CIDissolveTransition",parameters:[kCIInputTargetImageKey:noise,kCIInputTimeKey:1-s["grainShadows"]])
            image = noise.applyingFilter("CISoftLightBlendMode",parameters:[kCIInputBackgroundImageKey:image])
        }
        apply("CIVignette",[kCIInputIntensityKey:s["vignette"],kCIInputRadiusKey:min(bounds.width,bounds.height)*0.5])
        if s["leakRed"]+s["leakBlue"]+s["leakHoles"] > 0 {
            let color = CIColor(red:s["leakRed"],green:s["leakHoles"]*0.3,blue:s["leakBlue"],alpha:0.7)
            if let leak = CIFilter(name:"CILinearGradient",parameters:["inputPoint0":CIVector(x:bounds.minX,y:0),"inputPoint1":CIVector(x:bounds.midX,y:0),"inputColor0":color,"inputColor1":CIColor.clear])?.outputImage {
                image = leak.cropped(to:bounds).applyingFilter("CIScreenBlendMode",parameters:[kCIInputBackgroundImageKey:image])
            }
        }
        let scratchAmount = s["scratches"]+s["verticalScratch"]
        if scratchAmount > 0 {
            let x = bounds.width*(0.1 + abs(sin(floor(time*12)+2))*0.8)
            let scratch = CIImage(color:CIColor(red:s["scratchColor"],green:s["scratchColor"],blue:s["scratchColor"],alpha:min(1,scratchAmount)*0.5)).cropped(to:CGRect(x:x,y:bounds.minY,width:max(1,bounds.width/600),height:bounds.height))
            image = scratch.composited(over:image)
        }
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
        let result = render(source,settings:settings,lut:lut)
        guard let cg = context.createCGImage(result,from:result.extent) else { throw PortError.message("Cannot render image.") }
        return UIImage(cgImage:cg)
    }
}
