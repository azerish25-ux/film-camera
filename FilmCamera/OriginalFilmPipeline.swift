import Foundation
import CoreImage
import OpenGLES

/// Executes the recovered Android GLES 3 shaders. Only external-camera samplers
/// are changed to ordinary 2D textures; the fragment calculations are preserved.
final class OriginalFilmPipeline {
    private let lock = NSLock()
    private let gl: EAGLContext
    private let ci = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
    private var programs: [String: GLuint] = [:]
    private var frameBuffer: GLuint = 0
    private var vao: GLuint = 0
    private var vbo: GLuint = 0
    private var textures: [GLuint] = []
    private var width = 0, height = 0
    private var lutTexture: GLuint = 0
    private var lutKey = ""
    init() throws {
        guard let context = EAGLContext(api:.openGLES3) else {throw PortError.message("OpenGL ES 3 is unavailable.")}
        gl = context
        EAGLContext.setCurrent(gl)
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
        let vertex = try compile(shaderText("a_f25836b"),type:GLenum(GL_VERTEX_SHADER))
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
        width = w; height = h; textures = [GLuint](repeating:0,count:8); glGenTextures(8,&textures)
        for t in textures {
            glBindTexture(GLenum(GL_TEXTURE_2D),t)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MIN_FILTER),GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_MAG_FILTER),GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_S),GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D),GLenum(GL_TEXTURE_WRAP_T),GL_CLAMP_TO_EDGE)
            glTexImage2D(GLenum(GL_TEXTURE_2D),0,GL_RGBA8,GLsizei(w),GLsizei(h),0,GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),nil)
        }
    }
    private func draw(_ name: String, to: GLuint, setup: (GLuint) -> Void) throws {
        let p = try program(name); glUseProgram(p)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER),frameBuffer)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER),GLenum(GL_COLOR_ATTACHMENT0),GLenum(GL_TEXTURE_2D),to,0)
        guard glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) == GL_FRAMEBUFFER_COMPLETE else {throw PortError.message("Film framebuffer is incomplete.")}
        glViewport(0,0,GLsizei(width),GLsizei(height)); glBindVertexArray(vao)
        setup(p); glDrawArrays(GLenum(GL_TRIANGLE_STRIP),0,4)
        let error = glGetError(); guard error == GL_NO_ERROR else {throw PortError.message("Film GPU error \(error)")}
    }
    private func uploadLUT(_ lut: CubeLUT?, look: String) throws {
        let key = lut?.id.uuidString ?? look
        guard lutKey != key else {return}
        lutKey = key
        let dimension = lut?.dimension ?? 64
        var colors: [UInt8] = []
        if let lut {colors = lut.rgba.enumerated().filter {$0.offset%4 != 3}.map {UInt8(min(255,max(0,Int(($0.element*255).rounded()))))}}
        else if let film = OriginalFilm.all.first(where:{$0.name == look}), !film.asset.isEmpty {
            guard let url = Bundle.main.url(forResource:film.asset,withExtension:"lut") else {throw PortError.message("Missing original film table.")}
            colors = Array(try Data(contentsOf:url))
            guard colors.count == 64*64*64*3 else {throw PortError.message("Invalid original film table.")}
        } else {
            colors.reserveCapacity(dimension*dimension*dimension*3)
            for b in 0..<dimension {for g in 0..<dimension {for r in 0..<dimension {colors += [UInt8(r*255/(dimension-1)),UInt8(g*255/(dimension-1)),UInt8(b*255/(dimension-1))]}}}
        }
        glActiveTexture(GLenum(GL_TEXTURE1)); glBindTexture(GLenum(GL_TEXTURE_3D),lutTexture)
        for axis in [GL_TEXTURE_WRAP_S,GL_TEXTURE_WRAP_T,GL_TEXTURE_WRAP_R] {glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(axis),GL_CLAMP_TO_EDGE)}
        glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(GL_TEXTURE_MIN_FILTER),GL_LINEAR); glTexParameteri(GLenum(GL_TEXTURE_3D),GLenum(GL_TEXTURE_MAG_FILTER),GL_LINEAR)
        colors.withUnsafeBytes {glTexImage3D(GLenum(GL_TEXTURE_3D),0,GL_RGB8,GLsizei(dimension),GLsizei(dimension),GLsizei(dimension),0,GLenum(GL_RGB),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
    }
    func render(_ source: CIImage, settings s: FilmSettings, lut: CubeLUT?, time: Double) throws -> CIImage {
        lock.lock(); defer {EAGLContext.setCurrent(nil); lock.unlock()}
        EAGLContext.setCurrent(gl)
        while glGetError() != GL_NO_ERROR {}
        let w = Int(source.extent.width), h = Int(source.extent.height)
        guard w > 0, h > 0 else {throw PortError.message("Empty film input.")}
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
        var current = textures[1]
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
                let target = current == textures[2] ? textures[3] : textures[2]
                try draw("c_f25856i",to:target) {p in bind(p,"blurTempTexture",current); v(p,"blurResInv",1/Double(w),1/Double(h)); f(p,"blurOffset",Double(offset)+0.5); f(p,"blurFramePadding",0)}; current = target
            }
        }
        try draw("c_f25861n",to:textures[5]) {p in
            bind(p,"textureInPass3",current); bind(p,"textureLuminance",current,2); bind(p,"framePerforationsTexture",textures[7],3); bind(p,"lightLeakTexture",textures[7],4)
            var curve = Self.curve(temperature:s["temperature"],tint:s["tint"])
            curve.withUnsafeMutableBufferPointer {glUniform3fv(glGetUniformLocation(p,"curve"),66,$0.baseAddress)}
            for channel in ["R","G","B"] {f(p,"filmBreath"+channel,sin(time*8)*s["flicker"]*0.05)}
            f(p,"expiredFoggingAmp",s["leakBlue"]); f(p,"lightLeak.amp",s["leakRed"])
            f(p,"lightLeak.top",0.1); f(p,"lightLeak.bottom",0.1); f(p,"lightLeak.topMultiplier",1); f(p,"lightLeak.bottomMultiplier",1)
            f(p,"holes.internalOffset",0.125); f(p,"holes.externalOffset",1); f(p,"holes.amp",s["leakHoles"])
            v(p,"holes.amountY",0.1,0.1); v(p,"holes.amountX",0.1,0.1); v(p,"holes.xMultiplier",1,1)
        }
        try uploadLUT(lut,look:s.look)
        try draw(s["grain"] > 0 ? "c_f25865r" : "c_f25866s",to:textures[6]) {p in
            bind(p,"grainInputTexture",textures[5]); bind(p,"mLutID",lutTexture,1,GLenum(GL_TEXTURE_3D)); bind(p,"framePerforationsTexture",textures[7],2)
            f(p,"saturation",s["saturation"]); f(p,"perfColor",s["perfColor"]); v(p,"noiseRes",Double(w),Double(h))
            f(p,"grainSize",s["grainSize"]); f(p,"grainStrength",s["grain"]); f(p,"grainSmoohtness",s["grainSmoothness"]); f(p,"grainChroma",s["grainChroma"]); f(p,"grainDarkLevel",s["grainShadows"])
            i(p,"seed",(Int(time*24)*71)%500)
            // Scratch event state is supplied separately; disabled events must never divide black by zero.
            i(p,"stain.time",0); i(p,"scratch.time",0); i(p,"scratch_v.time",0)
        }
        var output = [UInt8](repeating:0,count:w*h*4)
        output.withUnsafeMutableBytes {glReadPixels(0,0,GLsizei(w),GLsizei(h),GLenum(GL_RGBA),GLenum(GL_UNSIGNED_BYTE),$0.baseAddress)}
        return CIImage(bitmapData:Data(output),bytesPerRow:w*4,size:CGSize(width:w,height:h),format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
    }
    static let blurSchedule: [[Int]] = [[],[0],[0,0],[0,1],[0,1,1],[0,1,2],[0,1,1,2],[0,1,2,3],[0,1,2,2,3],[0,1,2,3,4],[0,1,2,3,3,4],[0,1,2,3,4,5],[0,1,2,3,4,4,5],[0,1,2,3,4,5,6],[0,1,2,3,4,5,5,6],[0,1,2,3,4,5,6,7],[0,1,2,3,4,5,7,8],[0,1,2,3,4,5,7,8,9],[0,1,2,3,4,5,7,8,8,9],[0,1,2,3,4,5,7,8,9,10]]
    static func curve(temperature: Double,tint: Double) -> [Float] {
        let t = floor(temperature/100), halfTint = floor(tint/2)
        let r = t <= 66 ? 255-halfTint : 329.698727446*pow(t-60,-0.1332047592)-halfTint
        let g = t <= 66 ? 99.4708025861*log(t)-161.1195681661+tint : 288.1221695283*pow(t-60,-0.0755148492)+tint
        let b = t >= 66 ? 255-halfTint : t <= 19 ? 0 : 138.5177312231*log(t-10)-305.0447927307-halfTint
        let white = [r,g,b].map {min(1,max(0,$0/255))}
        return (0..<66).flatMap {index -> [Float] in
            let sample = index == 0 ? 0 : index == 65 ? 255 : (index-1)*4
            return white.map {Float($0*Double(sample)/255)}
        }
    }
}
