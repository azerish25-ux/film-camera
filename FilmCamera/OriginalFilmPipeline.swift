import Foundation
import CoreImage
import OpenGLES
import UIKit

/// Executes the recovered Android GLES 3 shaders. Only external-camera samplers
/// are changed to ordinary 2D textures; the fragment calculations are preserved.
final class OriginalFilmPipeline {
    private let lock = NSLock()
    private let assets = OriginalAssetSampler()
    private var dynamics = FilmDynamics()
    private var auxiliary: [String: GLuint] = [:]
    private var lastTime: Double = -1
    private let gl: EAGLContext
    private let ci = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
    private var programs: [String: GLuint] = [:]
    private var frameBuffer: GLuint = 0
    private var vao: GLuint = 0
    private var vbo: GLuint = 0
    private var textures: [GLuint] = []
    private var textureSizes: [GLuint:(Int,Int)] = [:]
    private var width = 0, height = 0
    private var lutTexture: GLuint = 0
    private var lutKey = ""
    init() throws {
        guard let context = EAGLContext(api:.openGLES3) else {throw PortError.message("OpenGL ES 3 is unavailable.")}
        gl = context
        guard EAGLContext.setCurrent(gl) else {throw PortError.message("Cannot activate the film GPU context.")}
        glGenFramebuffers(1,&frameBuffer)
        glGenVertexArrays(1,&vao); glBindVertexArray(vao)
        glGenBuffers(1,&vbo); glBindBuffer(GLenum(GL_ARRAY_BUFFER),vbo)
        let vertices: [Float] = [-1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,1,1,1]
        vertices.withUnsafeBytes {glBufferData(GLenum(GL_ARRAY_BUFFER),$0.count,$0.baseAddress,GLenum(GL_STATIC_DRAW))}
        glEnableVertexAttribArray(0); glVertexAttribPointer(0,2,GLenum(GL_FLOAT),GLboolean(GL_FALSE),16,nil)
        glEnableVertexAttribArray(1); glVertexAttribPointer(1,2,GLenum(GL_FLOAT),GLboolean(GL_FALSE),16,UnsafeRawPointer(bitPattern:8))
        glGenTextures(1,&lutTexture)
        EAGLContext.setCurrent(nil)
    }
    private func shaderText(_ name: String) throws -> String {
        if name.hasPrefix("frame_") {
            let function = String(name.dropFirst(6))
            return try shaderText("c_f25860m").replacingOccurrences(of:"//{frame_func}",with:shaderText(function))
        }
        guard let url = Bundle.main.url(forResource:name,withExtension:"glsl") else {throw PortError.message("Missing original shader \(name)")}
        return try String(contentsOf:url,encoding:.utf8).components(separatedBy:.newlines).filter {!$0.contains("#extension GL_OES_EGL_image_external")}.joined(separator:"\n").replacingOccurrences(of:"samplerExternalOES",with:"sampler2D")
    }
    private func compile(_ source: String, type: GLenum) throws -> GLuint {
        let shader = glCreateShader(type)
        source.withCString {string in var pointer: UnsafePointer<GLchar>? = string; glShaderSource(shader,1,&pointer,nil)}
        glCompileShader(shader)
        var ok: GLint = 0; glGetShaderiv(shader,GLenum(GL_COMPILE_STATUS),&ok)
        if ok == 0 {
            var log = [GLchar](repeating:0,count:8192); glGetShaderInfoLog(shader,8192,nil,&log); glDeleteShader(shader)
            throw PortError.message("Original shader: "+String(cString:log))
        }
        return shader
    }
    private func program(_ fragment: String) throws -> GLuint {
        if let p = programs[fragment] {return p}
        let vertex = try compile(shaderText(fragment.hasPrefix("frame_") ? "b_f25843a" : "a_f25836b"),type:GLenum(GL_VERTEX_SHADER))
        let pixel = try compile(shaderText(fragment),type:GLenum(GL_FRAGMENT_SHADER))
        defer {glDeleteShader(vertex); glDeleteShader(pixel)}
        let p = glCreateProgram(); glAttachShader(p,vertex); glAttachShader(p,pixel); glLinkProgram(p)
        var ok: GLint = 0; glGetProgramiv(p,GLenum(GL_LINK_STATUS),&ok)
        if ok == 0 {var log = [GLchar](repeating:0,count:8192); glGetProgramInfoLog(p,8192,nil,&log); glDeleteProgram(p); throw PortError.message("Original pipeline: "+String(cString:log))}
        programs[fragment] = p; return p
    }
    private func f(_ p: GLuint,_ name: String,_ value: Double) {glUniform1f(glGetUniformLocation(p,name),GLfloat(value))}
    private func i(_ p: GLuint,_ name: String,_ value: Int) {glUniform1i(glGetUniformLocation(p,name),GLint(value))}
    private func v(_ p: GLuint,_ name: String,_ x: Double,_ y: Double) {glUniform2f(glGetUniformLocation(p,name),GLfloat(x),GLfloat(y))}
    private func bind(_ p: GLuint,_ name: String,_ texture: GLuint,_ unit: Int = 0,_ target: GLenum = GLenum(GL_TEXTURE_2D)) {glActiveTexture(GLenum(GL_TEXTURE0)+GLenum(unit)); glBindTexture(target,texture); i(p,name,unit)}
    private func allocate(_ w: Int,_ h: Int) {
        guard width != w || height != h else {return}
        if !textures.isEmpty {glDeleteTextures(GLsizei(textures.count),&textures)}
        width = w; height = h; lastTime = -1; textures = [GLuint](repeating:0,count:13); glGenTextures(13,&textures)
        textureSizes = [:]
        for (index,t) in textures.enumerated() {
            let halationDivisor = h == 1080 ? 2 : h == 2160 ? 3 : h == 4320 ? 4 : 1
            let divisor = [2,3].contains(index) ? halationDivisor : [11,12].contains(index) ? 2 : 1
            let tw = max(1,w/divisor), th = max(1,h/divisor)
            textureSizes[t] = (tw,th)
            glBindTexture(GLenum(GL_TEXTURE_2D),t)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MIN_FILTER),GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MAG_FILTER),GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_S),GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_T),GL_CLAMP_TO_EDGE)
            glTexImage2D(GLenum(GL_TEXTURE_2D),0,GL_RGBA8,GLsizei(tw),GLsizei(th),0,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),nil)
        }
    }
    private func draw(_ name: String, to: GLuint, setup: (GLuint) -> Void) throws {
        let p = try program(name); glUseProgram(p)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER),frameBuffer)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER),GLenum(GL_COLOR_ATTACHMENT0),GLenum(GL_TEXTURE_2D),to,0)
        guard glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) == GL_FRAMEBUFFER_COMPLETE else {throw PortError.message("Film framebuffer is incomplete.")}
        let size = textureSizes[to] ?? (width,height)
        glViewport(0,0,GLsizei(size.0),GLsizei(size.1)); glBindVertexArray(vao)
        setup(p); glDrawArrays(GLenum(GL_TRIANGLE_STRIP),0,4)
        let error = glGetError(); guard error == GL_NO_ERROR else {throw PortError.message("Film GPU error \(error)")}
    }
    private func array(_ p: GLuint,_ name: String,_ values: [Float]) {
        values.withUnsafeBufferPointer {glUniform1fv(glGetUniformLocation(p,name),GLsizei(values.count),$0.baseAddress)}
    }
    deinit {
        EAGLContext.setCurrent(gl)
        if !textures.isEmpty {glDeleteTextures(GLsizei(textures.count),&textures)}
        var extra = Array(auxiliary.values); if !extra.isEmpty {glDeleteTextures(GLsizei(extra.count),&extra)}
        glDeleteTextures(1,&lutTexture); glDeleteFramebuffers(1,&frameBuffer); glDeleteBuffers(1,&vbo); glDeleteVertexArrays(1,&vao)
        for p in programs.values {glDeleteProgram(p)}
        EAGLContext.setCurrent(nil)
    }
    private func imageTexture(_ name: String, time: Double? = nil) throws -> GLuint {
        if time == nil, let cached = auxiliary[name] {return cached}
        if name == "e4e45cae0068917f80a90a1a8380ee5ac1176e88" {
            guard let url = Bundle.main.url(forResource:name,withExtension:"noise") else {throw PortError.message("Missing original film-grain noise table.")}
            let bytes = try Data(contentsOf:url)
            guard bytes.count == 1024*1024*4 else {throw PortError.message("Invalid film-grain noise table.")}
            var texture: GLuint = 0; glGenTextures(1,&texture); auxiliary[name] = texture
            glActiveTexture(GLenum(GL_TEXTURE10)); glBindTexture(GLenum(GL_TEXTURE_2D),texture)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MIN_FILTER),GL_NEAREST); glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MAG_FILTER),GL_NEAREST)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_S),GL_REPEAT); glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_T),GL_REPEAT)
            bytes.withUnsafeBytes {glTexImage2D(GLenum(GL_TEXTURE_2D),0,GL_RGBA8,1024,1024,0,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
            return texture
        }
        let image: CGImage
        if let time {image = try assets.frame(name,time:time)}
        else {
            guard let url = Bundle.main.url(forResource:name,withExtension:"png"), let cg = UIImage(contentsOfFile:url.path)?.cgImage else {throw PortError.message("Missing original mask \(name)")}
            image = cg
        }
        var texture = auxiliary[name] ?? 0
        if texture == 0 {glGenTextures(1,&texture); auxiliary[name] = texture}
        glActiveTexture(GLenum(GL_TEXTURE12)); glBindTexture(GLenum(GL_TEXTURE_2D),texture)
        glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MIN_FILTER),GL_LINEAR); glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MAG_FILTER),GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_S),GL_CLAMP_TO_EDGE); glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_T),GL_CLAMP_TO_EDGE)
        var bytes = [UInt8](repeating:0,count:image.width*image.height*4)
        bytes.withUnsafeMutableBytes {ci.render(CIImage(cgImage:image),toBitmap:$0.baseAddress!,rowBytes:image.width*4,bounds:CGRect(x:0,y:0,width:image.width,height:image.height),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())}
        bytes.withUnsafeBytes {glTexImage2D(GLenum(GL_TEXTURE_2D),0,GL_RGBA8,GLsizei(image.width),GLsizei(image.height),0,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        return texture
    }
    private func uploadLUT(_ lut: CubeLUT?, look: String) throws {
        let key = lut?.id.uuidString ?? look
        guard lutKey != key else {return}
        if let lut {
            guard (2...64).contains(lut.dimension), lut.rgba.count == lut.dimension*lut.dimension*lut.dimension*4,
                  lut.rgba.allSatisfy({$0.isFinite}), lut.domainMin.count == 3, lut.domainMax.count == 3,
                  zip(lut.domainMin,lut.domainMax).allSatisfy({$0.isFinite && $1.isFinite && $0 < $1}) else {throw PortError.message("Invalid lookup table data.")}
        }
        let dimension = 64
        var colors: [UInt8] = []
        if let lut {colors = lut.textureRGB()}
        else if let film = OriginalFilm.all.first(where:{$0.name == look}), !film.asset.isEmpty {
            guard let url = Bundle.main.url(forResource:film.asset,withExtension:"lut") else {throw PortError.message("Missing original film table.")}
            colors = Array(try Data(contentsOf:url))
            guard colors.count == 64*64*64*3 else {throw PortError.message("Invalid original film table.")}
        } else {
            colors.reserveCapacity(dimension*dimension*dimension*3)
            for b in 0..<dimension {for g in 0..<dimension {for r in 0..<dimension {colors += [UInt8(r*255/dimension),UInt8(g*255/dimension),UInt8(b*255/dimension)]}}}
        }
        glActiveTexture(GLenum(GL_TEXTURE1)); glBindTexture(GLenum(GL_TEXTURE_3D),lutTexture)
        for axis in [GL_TEXTURE_WRAP_S,GL_TEXTURE_WRAP_T,GL_TEXTURE_WRAP_R] {glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(axis),GL_CLAMP_TO_EDGE)}
        glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(GL_TEXTURE_MIN_FILTER),GL_LINEAR); glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(GL_TEXTURE_MAG_FILTER),GL_LINEAR)
        glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT),1)
        colors.withUnsafeBytes {glTexImage3D(GLenum(GL_TEXTURE_3D),0,GL_RGB8,GLsizei(dimension),GLsizei(dimension),GLsizei(dimension),0,GLenum(GL_RGB),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        lutKey = key
    }
    func render(_ source: CIImage, settings s: FilmSettings, lut: CubeLUT?, time: Double) throws -> CIImage {
        lock.lock(); defer {EAGLContext.setCurrent(nil); lock.unlock()}
        guard EAGLContext.setCurrent(gl) else {throw PortError.message("Cannot activate the film GPU context.")}
        for _ in 0..<16 {if glGetError() == GL_NO_ERROR {break}}
        let w = Int(source.extent.width), h = Int(source.extent.height)
        guard w > 0, h > 0, w <= 8192, h <= 8192, w*h <= 16_777_216 else {throw PortError.message("Image dimensions exceed the supported 16-megapixel processing limit, or the image is empty.")}
        allocate(w,h)
        var bytes = [UInt8](repeating:0,count:w*h*4)
        bytes.withUnsafeMutableBytes {ci.render(source,toBitmap:$0.baseAddress!,rowBytes:w*4,bounds:source.extent,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())}
        glActiveTexture(GLenum(GL_TEXTURE0)); glBindTexture(GLenum(GL_TEXTURE_2D),textures[0])
        bytes.withUnsafeBytes {glTexSubImage2D(GLenum(GL_TEXTURE_2D),0,0,0,GLsizei(w),GLsizei(h),GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        glBindTexture(GLenum(GL_TEXTURE_2D),textures[7])
        let clear = [UInt8](repeating:0,count:w*h*4)
        clear.withUnsafeBytes {glTexSubImage2D(GLenum(GL_TEXTURE_2D),0,0,0,GLsizei(w),GLsizei(h),GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        let chroma = s["chroma"] >= 0.02
        try draw(chroma ? "b_f25846d" : "b_f25847e",to:textures[1]) {p in
            let prefix = chroma ? "chroma_" : ""
            bind(p,chroma ? "chromaTexId" : "simpleTexId",textures[0])
            f(p,prefix+"vignetteFalloff",s["vignette"]); f(p,prefix+"pseudoExposure",pow(2,s["exposure"])); f(p,prefix+"contrast",s["contrast"])
            f(p,"chroma_value",s["chroma"]); v(p,prefix+"iResolution",Double(w),Double(h))
        }
        if lastTime < 0 || time < lastTime {dynamics = FilmDynamics()}
        dynamics.advance(settings:s,width:w,height:h,time:time)
        let mask = try s.frame.originalMask.map {try imageTexture($0)} ?? textures[7]
        let film = try s.frame.originalVideo.map {try imageTexture($0,time:time)} ?? textures[7]
        let staticFrame: GLuint
        if s.frame == .kiev || s.frame == .framed {
            staticFrame = try imageTexture(s.frame == .kiev ? "b8650c3c26a4b77d6b9899dffb91e5e5876edbd8" : "bab945a9d56dcb9e116bd018c81fecc093e5b5b2")
        } else {staticFrame = textures[7]}
        if lastTime < 0 || time <= lastTime {
            for history in [textures[9],textures[10]] {
                try draw("c_f25862o",to:history) {p in bind(p,"sourceTexture",textures[1])}
            }
        }
        try draw("frame_"+s.frame.originalShader,to:textures[8]) {p in
            bind(p,"mTextureID",textures[1]); bind(p,"mTextureID1",textures[9],1); bind(p,"mTextureID2",textures[10],2)
            bind(p,"frameTexture",film,3); bind(p,"frameSuper16mm",staticFrame,4)
            f(p,"randomX",dynamics.shiftX); f(p,"randomY",dynamics.shiftY+dynamics.fastShake)
        }
        try draw("c_f25862o",to:textures[10]) {p in bind(p,"sourceTexture",textures[9])}
        try draw("c_f25862o",to:textures[9]) {p in bind(p,"sourceTexture",textures[1])}
        lastTime = time
        var current = textures[8]
        if s["halation"] >= 0.002 {
            try draw("c_f25858k",to:textures[2]) {p in bind(p,"halationHighSourceTexture",current); f(p,"halationIntensity",s["halation"]); f(p,"halationCuttoff",min(0.995,s["halationCutoff"]))}
            var blurred = textures[2]
            let schedule = Self.blurSchedule[min(19,max(0,Int(s["halationRadius"])))]
            for (index,offset) in schedule.enumerated() {
                let target = blurred == textures[2] ? textures[3] : textures[2]
                try draw("c_f25857j",to:target) {p in
                    bind(p,"halationBlurTempTexture",blurred); v(p,"halationBlurResInv",1/Double(w),1/Double(h)); f(p,"redHalationOffset",Double(offset)+0.5)
                    f(p,"halationBlurHueGreen",index <= Int(Double(schedule.count)*s["halationGreen"]) ? 1 : 0.3)
                    f(p,"halationBlurHueBlue",index <= Int(Double(schedule.count)*s["halationBlue"]) ? 1 : 0.3)
                }; blurred = target
            }
            try draw("c_f25859l",to:textures[4]) {p in
                bind(p,"textureHalationMergeSource",current); bind(p,"textureHalationMergeBlur",blurred,1)
                f(p,"halationMergeIntensity",s["halation"]); f(p,"halationMergeHueGreen",s["halationGreen"]); f(p,"halationMergeHueBlue",s["halationBlue"])
            }; current = textures[4]
        }
        if s["blur"] > 0 {
            for offset in Self.blurSchedule[min(19,max(0,Int(s["blur"])))] {
                let target = current == textures[11] ? textures[12] : textures[11]
                try draw("c_f25856i",to:target) {p in bind(p,"blurTempTexture",current); v(p,"blurResInv",1/Double(w),1/Double(h)); f(p,"blurOffset",Double(offset)+0.5); f(p,"blurFramePadding",s.frame.blurPadding-dynamics.shiftX)}; current = target
            }
        }
        let burn = s["burn"] > 0.5 ? try imageTexture(FilmBurn.clips[min(6,max(0,Int(s["burnClip"])))],time:time) : textures[7]
        glActiveTexture(GLenum(GL_TEXTURE15)); glBindTexture(GLenum(GL_TEXTURE_2D),textures[1]); glGenerateMipmap(GLenum(GL_TEXTURE_2D))
        try draw("c_f25861n",to:textures[5]) {p in
            bind(p,"textureInPass3",current); bind(p,"textureLuminance",textures[1],2); f(p,"luminanceMipmapLevel",min(8,floor(log2(Double(max(w,h))))+1)); bind(p,"framePerforationsTexture",mask,3); bind(p,"lightLeakTexture",burn,4); i(p,"usingLightLeak",s["burn"] > 0.5 ? 1 : 0)
            var curve = Self.curve(temperature:s["temperature"],tint:s["tint"],samples:FilmCurve.samples(x:s.curveX,y:s.curveY))
            curve.withUnsafeMutableBufferPointer {glUniform3fv(glGetUniformLocation(p,"curve"),66,$0.baseAddress)}
            for (index,channel) in ["R","G","B"].enumerated() {f(p,"filmBreath"+channel,dynamics.breathRGB[index])}
            f(p,"srandomX",dynamics.shiftX); f(p,"srandomY",dynamics.shiftY+dynamics.fastShake)
            f(p,"expiredFoggingAmp",dynamics.fogAmplitude)
            let redAmp = min(1,max(0,(1-dynamics.redBottom)/0.2))
            f(p,"lightLeak.amp",redAmp*redAmp*(3-2*redAmp))
            f(p,"lightLeak.top",dynamics.redTop); f(p,"lightLeak.bottom",dynamics.redBottom)
            f(p,"lightLeak.topMultiplier",1/pow(0.625,dynamics.redTop*40)); f(p,"lightLeak.bottomMultiplier",1/pow(0.625,dynamics.redBottom*40))
            let holes = s.frame.holeGeometry
            f(p,"holes.internalOffset",holes.0); f(p,"holes.externalOffset",holes.1); f(p,"holes.seed",Double((dynamics.frame%400)*2)*holes.0/400)
            let holeAmp = min(1,max(0,1-dynamics.holeTopX)); f(p,"holes.amp",holeAmp*holeAmp*(3-2*holeAmp))
            v(p,"holes.amountY",dynamics.holeTopY+holes.2,dynamics.holeBottomY+holes.2)
            v(p,"holes.amountX",dynamics.holeTopX,dynamics.holeBottomX)
            v(p,"holes.xMultiplier",1/pow(0.625,dynamics.holeTopX*40),1/pow(0.625,dynamics.holeBottomX*40))
        }
        try uploadLUT(lut,look:s.look)
        let noise = try imageTexture("e4e45cae0068917f80a90a1a8380ee5ac1176e88")
        try draw(s["grain"] > 0 ? "c_f25865r" : "c_f25866s",to:textures[6]) {p in
            bind(p,"grainInputTexture",textures[5]); bind(p,"mLutID",lutTexture,1,GLenum(GL_TEXTURE_3D)); bind(p,"framePerforationsTexture",mask,2); bind(p,"noiseTexture",noise,10)
            f(p,"saturation",s["saturation"]); f(p,"perfColor",s["perfColor"]); v(p,"noiseRes",Double(w),Double(h))
            f(p,"grainSize",s["grainSize"]); f(p,"grainStrength",s["grain"]); f(p,"grainSmoohtness",s["grainSmoothness"]); f(p,"grainChroma",s["grainChroma"]); f(p,"grainDarkLevel",s["grainShadows"])
            i(p,"seed",(dynamics.frame*71)%500)
            f(p,"srandomX",dynamics.shiftX); f(p,"srandomY",dynamics.shiftY-dynamics.fastShake)
            i(p,"stain.x",dynamics.stainX); i(p,"stain.y",dynamics.stainY); i(p,"stain.w",dynamics.stainW); i(p,"stain.h",dynamics.stainH); i(p,"stain.time",dynamics.stainTime); array(p,"stain.mask",dynamics.stainMask)
            f(p,"scratch.x",dynamics.scratchX); f(p,"scratch.y",dynamics.scratchY); f(p,"scratch.vx",dynamics.scratchVX); f(p,"scratch.vy",dynamics.scratchVY); f(p,"scratch.len",dynamics.scratchLength); i(p,"scratch.time",dynamics.scratchTime); array(p,"scratch.D",dynamics.scratchD)
            array(p,"scratch_v.x",dynamics.verticalX); array(p,"scratch_v.t",dynamics.verticalT); i(p,"scratch_v.time",dynamics.verticalTime)
            f(p,"gScratchesColor",s["scratchColor"]); f(p,"gVerticalScratchIntensity",s["verticalScratch"])
        }
        var output = [UInt8](repeating:0,count:w*h*4)
        output.withUnsafeMutableBytes {glReadPixels(0,0,GLsizei(w),GLsizei(h),GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        return CIImage(bitmapData:Data(output),bytesPerRow:w*4,size:CGSize(width:w,height:h),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB()).oriented(.downMirrored)
    }
    /// Isolated shader probe used to compare the same recovered pass on Android and iOS.
    func probe(_ config: ReferenceCase) throws -> Data {
        lock.lock(); defer {EAGLContext.setCurrent(nil); lock.unlock()}
        guard EAGLContext.setCurrent(gl) else {throw PortError.message("Cannot activate the film GPU context.")}
        for _ in 0..<16 {if glGetError() == GL_NO_ERROR {break}}
        allocate(128,96)
        for kind in 0..<3 {
            var bytes = [UInt8](repeating:0,count:128*96*4)
            for y in 0..<96 {for x in 0..<128 {
                let n = (y*128+x)*4
                bytes[n] = UInt8(kind == 0 ? 1+x*253/127 : kind == 1 ? 60 : 0)
                bytes[n+1] = UInt8(kind == 0 ? 1+y*253/95 : kind == 1 ? 90 : 0)
                bytes[n+2] = UInt8(kind == 0 ? 1+(x+y)*253/222 : kind == 1 ? 120 : 0)
                bytes[n+3] = kind == 2 ? 0 : 255
            }}
            let texture = kind == 2 ? textures[7] : textures[kind]
            glActiveTexture(GLenum(GL_TEXTURE0)); glBindTexture(GLenum(GL_TEXTURE_2D),texture)
            bytes.withUnsafeBytes {glTexSubImage2D(GLenum(GL_TEXTURE_2D),0,0,0,128,96,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        }
        try uploadLUT(nil,look:"Normal Mode")
        let lookup: [String:GLuint] = ["source":textures[0],"background":textures[1],"clear":textures[7],"lut":lutTexture,"noise":try imageTexture("e4e45cae0068917f80a90a1a8380ee5ac1176e88")]
        try draw(config.shader,to:textures[6]) {p in
            for (key,value) in config.floats {f(p,key,value)}
            for (key,value) in config.vectors {v(p,key,value[0],value[1])}
            for (key,value) in config.ints {i(p,key,value)}
            for (key,value) in config.arrays {
                if key == "curve" {value.withUnsafeBufferPointer {glUniform3fv(glGetUniformLocation(p,key),GLsizei(value.count/3),$0.baseAddress)}}
                else {array(p,key,value)}
            }
            for (unit,key) in config.samplers.keys.sorted().enumerated() {
                let name = config.samplers[key]!
                bind(p,key,lookup[name]!,unit,name == "lut" ? GLenum(GL_TEXTURE_3D) : GLenum(GL_TEXTURE_2D))
            }
        }
        var output = [UInt8](repeating:0,count:128*96*4)
        output.withUnsafeMutableBytes {glReadPixels(0,0,128,96,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        return Data(output)
    }
    static let blurSchedule: [[Int]] = [[],[0],[0,0],[0,1],[0,1,1],[0,1,2],[0,1,1,2],[0,1,2,3],[0,1,2,2,3],[0,1,2,3,4],[0,1,2,3,3,4],[0,1,2,3,4,5],[0,1,2,3,4,4,5],[0,1,2,3,4,5,6],[0,1,2,3,4,5,5,6],[0,1,2,3,4,5,6,7],[0,1,2,3,4,5,7,8],[0,1,2,3,4,5,7,8,9],[0,1,2,3,4,5,7,8,8,9],[0,1,2,3,4,5,7,8,9,10]]
    static func curve(temperature: Double,tint: Double,samples: [Double] = (0...255).map(Double.init)) -> [Float] {
        let t = floor(temperature/100), halfTint = floor(tint/2)
        let r = t <= 66 ? 255-halfTint : 329.698727446*pow(t-60,-0.1332047592)-halfTint
        let g = t <= 66 ? 99.4708025861*log(t)-161.1195681661+tint : 288.1221695283*pow(t-60,-0.0755148492)+tint
        let b = t >= 66 ? 255-halfTint : t <= 19 ? 0 : 138.5177312231*log(t-10)-305.0447927307-halfTint
        let white = [r,g,b].map {min(1,max(0,$0/255))}
        return (0..<66).flatMap {index -> [Float] in
            let sample = index == 0 ? 0 : index == 65 ? 255 : (index-1)*4
            return white.map {Float($0*samples[sample]/255)}
        }
    }
}

