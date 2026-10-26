import CoreImage

enum MotionViewfinder {
    /// APK HSV shadow tone map and sigmoid contrast, ported to Core Image's kernel dialect.
    private static let kernel = CIColorKernel(source:"""
    kernel vec4 motionViewfinder(__sample c, float shadows, float contrast, float saturation) {
        vec4 K = vec4(0.0,-1.0/3.0,2.0/3.0,-1.0);
        vec4 p = mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));
        vec4 q = mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
        float d = q.x-min(q.w,q.y);
        vec3 hsv = vec3(abs(q.z+(q.w-q.y)/(6.0*d+1e-10)),d/(q.x+1e-10),q.x);
        float inputValue = hsv.z*shadows;
        float tonemap = inputValue/(1.0+inputValue);
        float gamma = pow(max(0.0,tonemap),1.0/2.2);
        float a = clamp(contrast,0.0,1.0)+1.0;
        float b = gamma/max(1e-5,1.0-gamma);
        float v = 1.0/(1.0+pow(max(1e-5,b),-a));
        hsv.y = clamp(hsv.y*saturation,0.0,1.0);
        hsv.z = pow(max(v,0.0),2.2);
        vec3 rgbP = abs(fract(hsv.xxx+vec3(1.0,2.0/3.0,1.0/3.0))*6.0-vec3(3.0));
        vec3 rgb = hsv.z*mix(vec3(1.0),clamp(rgbP-vec3(1.0),0.0,1.0),hsv.y);
        return vec4(pow(max(rgb,vec3(0.0)),vec3(1.0/2.2)),c.a);
    }
    """)
    static func render(_ source:CIImage,shadows:Double,contrast:Double,saturation:Double) throws -> CIImage {
        guard let kernel,let result = kernel.apply(extent:source.extent,arguments:[source,max(1,shadows),contrast,saturation]) else {throw PortError.message("Cannot compile MotionCam viewfinder tone map.")}
        return result
    }
}
