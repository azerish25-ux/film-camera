import CoreImage
import UIKit

/// Native iOS ISP adaptation; recovered slider equations live in MotionLogic.
enum MotionProcessing {
    static func grade(_ source: CIImage, _ raw: MotionGrade) -> CIImage {
        guard raw.enabled else {return source}
        var s = raw; s.validate()
        var image = source
        let extent = image.extent
        let crop = extent.insetBy(dx:extent.width*s.cropWidth/200,dy:extent.height*s.cropHeight/200)
        image = image.cropped(to:crop).transformed(by:CGAffineTransform(translationX:-crop.minX,y:-crop.minY))
        image = image.transformed(by:CGAffineTransform(scaleX:s.squeezeX,y:s.squeezeY))
        if s.flip180 {image = image.oriented(.down)}
        image = image.applyingFilter("CIExposureAdjust",parameters:["inputEV":s.exposure])
        image = image.applyingFilter("CITemperatureAndTint",parameters:["inputNeutral":CIVector(x:s.temperature,y:s.tint),"inputTargetNeutral":CIVector(x:6500,y:0)])
        image = image.applyingFilter("CIHighlightShadowAdjust",parameters:["inputShadowAmount":min(1,log2(s.shadows)/6),"inputHighlightAmount":max(0,1-s.highlights/8)])
        image = image.applyingFilter("CIColorControls",parameters:["inputSaturation":s.saturation,"inputContrast":0.5+s.contrast])
        let scale = 1/max(0.01,s.whitePoint-s.blacks), bias = -s.blacks*scale
        image = image.applyingFilter("CIColorMatrix",parameters:["inputRVector":CIVector(x:scale,y:0,z:0,w:0),"inputGVector":CIVector(x:0,y:scale*(1+s.greens/100),z:0,w:0),"inputBVector":CIVector(x:0,y:0,z:scale*(1+s.blues/100),w:0),"inputBiasVector":CIVector(x:bias,y:bias,z:bias,w:0)])
        if s.denoise > 0 {image = image.applyingFilter("CINoiseReduction",parameters:["inputNoiseLevel":0.01*s.denoise,"inputSharpness":0.4])}
        if s.sharpen0 > 1 {image = image.applyingFilter("CISharpenLuminance",parameters:["inputSharpness":(s.sharpen0-1)*0.4])}
        if s.sharpen1 > 1 {image = image.applyingFilter("CIUnsharpMask",parameters:["inputRadius":1.0,"inputIntensity":(s.sharpen1-1)*0.25])}
        if s.pop > 1 {image = image.applyingFilter("CIUnsharpMask",parameters:["inputRadius":12.0,"inputIntensity":(s.pop-1)*0.3])}
        return image.cropped(to:image.extent)
    }

    // This kernel reproduces the APK's unusual x0 + 2*x1 + x2 blur weighting.
    private static let aidKernel = CIKernel(source:"""
    kernel vec4 motionAids(sampler image, float clipping, float peaking, float sensitivity) {
        vec2 p = samplerCoord(image);
        vec2 dx = samplerTransform(image, destCoord()+vec2(1.0,0.0))-p;
        vec2 dy = samplerTransform(image, destCoord()+vec2(0.0,1.0))-p;
        vec4 c = sample(image,p);
        vec4 x0 = 0.25*(sample(image,p+dx)+2.0*c+sample(image,p-dx));
        vec4 x1 = 0.25*(sample(image,p+dx-dy)+2.0*sample(image,p-dy)+sample(image,p-dx-dy));
        vec4 x2 = 0.25*(sample(image,p+dx+dy)+2.0*sample(image,p+dy)+sample(image,p-dx+dy));
        vec3 blur = 0.25*(x0.rgb+2.0*x1.rgb+x2.rgb);
        float avg = (c.r+c.g+c.b)/3.0;
        float edge = abs(avg-(blur.r+blur.g+blur.b)/3.0);
        float h = smoothstep(0.97,1.0,avg)*clipping;
        float l = (1.0-smoothstep(0.0,0.01,avg))*clipping;
        float f = step(sensitivity,edge)*peaking;
        vec3 overlay = min(vec3(1.0),vec3(h+l,l+f,0.0));
        return vec4(overlay.r+overlay.g+overlay.b > 0.5 ? overlay : c.rgb,1.0);
    }
    """)
    static func aids(_ image: CIImage, clipping: Bool, peaking: Bool, sensitivity: Double) throws -> CIImage {
        guard clipping || peaking else {return image}
        guard let kernel = aidKernel, let output = kernel.apply(extent:image.extent,roiCallback:{_,r in r.insetBy(dx:-1,dy:-1)},arguments:[image,clipping ? 1.0 : 0.0,peaking ? 1.0 : 0.0,sensitivity]) else {throw PortError.message("Viewfinder aids could not be compiled.")}
        return output
    }
    static func decode(_ url: URL,maxDimension:Double? = nil) throws -> CIImage {
        if ["dng","nef","arw","cr2","cr3","raf","rw2"].contains(url.pathExtension.lowercased()) {
            guard let filter = CIRAWFilter(imageURL:url) else {throw PortError.message("This RAW camera format is not supported by iOS.")}
            if let maxDimension {filter.scaleFactor = Float(min(1,maxDimension/Double(max(filter.nativeSize.width,filter.nativeSize.height))))}
            guard let image = filter.outputImage else {throw PortError.message("This RAW camera format is not supported by iOS.")}
            return image
        }
        guard let image = CIImage(contentsOf:url,options:[.applyOrientationProperty:true]) else {throw PortError.message("Cannot decode this image.")}
        return image
    }
}
