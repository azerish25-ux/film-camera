package com.azerish.bmc;

import android.opengl.*;
import java.io.*;
import java.nio.*;
import java.util.zip.ZipFile;

/** Offscreen execution of the APK's monitoring shaders, not the APK itself. */
public final class BMCReferenceMain {
    static final int W = 128, H = 96;
    final File root;
    BMCReferenceMain(File root) { this.root = root; }
    public static void main(String[] args) {
        try { new BMCReferenceMain(new File(args[0])).run(); System.exit(0); }
        catch (Throwable error) { error.printStackTrace(); System.exit(1); }
    }
    byte[] asset(String name) throws Exception {
        try (ZipFile zip = new ZipFile(new File(root, "bmc-reference.jar")); InputStream in = zip.getInputStream(zip.getEntry("assets/" + name)); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192]; int count;
            while ((count = in.read(buffer)) > 0) out.write(buffer, 0, count);
            return out.toByteArray();
        }
    }
    String text(String name) throws Exception { return new String(asset(name), "UTF-8"); }
    void write(String name, byte[] bytes) throws Exception { try (FileOutputStream out = new FileOutputStream(new File(root, name))) { out.write(bytes); } }
    static ByteBuffer buffer(byte[] bytes) { ByteBuffer out = ByteBuffer.allocateDirect(bytes.length).order(ByteOrder.nativeOrder()); out.put(bytes).position(0); return out; }
    static int compile(String source, int type) {
        int shader = GLES30.glCreateShader(type); GLES30.glShaderSource(shader, source); GLES30.glCompileShader(shader);
        int[] ok = {0}; GLES30.glGetShaderiv(shader, GLES30.GL_COMPILE_STATUS, ok, 0);
        if (ok[0] == 0) throw new IllegalStateException(GLES30.glGetShaderInfoLog(shader));
        return shader;
    }
    static void params(int target) {
        GLES30.glTexParameteri(target, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(target, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_LINEAR);
        GLES30.glTexParameteri(target, GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE);
        GLES30.glTexParameteri(target, GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE);
    }
    void run() throws Exception {
        EGLDisplay display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY); int[] version = new int[2];
        if (!EGL14.eglInitialize(display, version, 0, version, 1)) throw new IllegalStateException("EGL initialize");
        EGLConfig[] configs = new EGLConfig[1]; int[] count = {0};
        int[] attributes = {EGL14.EGL_RENDERABLE_TYPE, 0x40, EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT, EGL14.EGL_RED_SIZE, 8, EGL14.EGL_GREEN_SIZE, 8, EGL14.EGL_BLUE_SIZE, 8, EGL14.EGL_ALPHA_SIZE, 8, EGL14.EGL_NONE};
        if (!EGL14.eglChooseConfig(display, attributes, 0, configs, 0, 1, count, 0) || count[0] == 0) throw new IllegalStateException("EGL config");
        EGLContext context = EGL14.eglCreateContext(display, configs[0], EGL14.EGL_NO_CONTEXT, new int[]{EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE}, 0);
        EGLSurface surface = EGL14.eglCreatePbufferSurface(display, configs[0], new int[]{EGL14.EGL_WIDTH, W, EGL14.EGL_HEIGHT, H, EGL14.EGL_NONE}, 0);
        if (!EGL14.eglMakeCurrent(display, surface, surface, context)) throw new IllegalStateException("EGL make current");
        String vertex = "#version 300 es\nlayout(location=0) in vec2 pos; layout(location=1) in vec2 uv; out vec2 cameraTexCoordinates; void main(){gl_Position=vec4(pos,0.,1.);cameraTexCoordinates=uv;}";
        String fragment = "#version 300 es\nprecision highp float; in vec2 cameraTexCoordinates; uniform sampler2D cameraTexture; uniform int mode; out vec4 result;\n"
            + text("luminance_function.glsl") + text("false_color_effect_fast.glsl") + text("zebra_effect.glsl") + text("focus_assist_effect.glsl")
            + "\nvoid main(){vec4 c=texture(cameraTexture,cameraTexCoordinates);float l=getLuminance(c);if(mode==1)c=falseColor(l);else if(mode==2)c=zebras(c,l);else if(mode==3)c=focusAssist(c);else if(mode==4){uint b=floatBitsToUint(l);c=vec4(float(b&255u),float((b>>8u)&255u),float((b>>16u)&255u),float((b>>24u)&255u))/255.0;}result=c;}";
        int vs = compile(vertex, GLES30.GL_VERTEX_SHADER), fs = compile(fragment, GLES30.GL_FRAGMENT_SHADER);
        int program = GLES30.glCreateProgram(); GLES30.glAttachShader(program, vs); GLES30.glAttachShader(program, fs); GLES30.glLinkProgram(program);
        int[] ok = {0}; GLES30.glGetProgramiv(program, GLES30.GL_LINK_STATUS, ok, 0); if (ok[0] == 0) throw new IllegalStateException(GLES30.glGetProgramInfoLog(program));
        int[] texture = new int[3], framebuffer = new int[1], vao = new int[1], vbo = new int[1]; GLES30.glGenTextures(3, texture, 0);
        GLES30.glPixelStorei(GLES30.GL_UNPACK_ALIGNMENT, 1);
        GLES30.glActiveTexture(GLES30.GL_TEXTURE1); GLES30.glBindTexture(GLES30.GL_TEXTURE_3D, texture[1]); params(GLES30.GL_TEXTURE_3D); GLES30.glTexParameteri(GLES30.GL_TEXTURE_3D, GLES30.GL_TEXTURE_WRAP_R, GLES30.GL_CLAMP_TO_EDGE);
        byte[] lut = asset("rec709-luminance.bin"); if (lut.length != 33*33*33) throw new IllegalStateException("Luminance LUT size");
        GLES30.glTexImage3D(GLES30.GL_TEXTURE_3D, 0, GLES30.GL_R8, 33, 33, 33, 0, GLES30.GL_RED, GLES30.GL_UNSIGNED_BYTE, buffer(lut));
        GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture[2]); params(GLES30.GL_TEXTURE_2D); GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8, W, H, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, null);
        GLES30.glGenFramebuffers(1, framebuffer, 0); GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER, framebuffer[0]); GLES30.glFramebufferTexture2D(GLES30.GL_FRAMEBUFFER, GLES30.GL_COLOR_ATTACHMENT0, GLES30.GL_TEXTURE_2D, texture[2], 0);
        if (GLES30.glCheckFramebufferStatus(GLES30.GL_FRAMEBUFFER) != GLES30.GL_FRAMEBUFFER_COMPLETE) throw new IllegalStateException("Framebuffer");
        float[] vertices = {-1,-1,0,0, 1,-1,1,0, -1,1,0,1, 1,1,1,1}; FloatBuffer vb = ByteBuffer.allocateDirect(64).order(ByteOrder.nativeOrder()).asFloatBuffer(); vb.put(vertices).position(0);
        GLES30.glGenVertexArrays(1, vao, 0); GLES30.glBindVertexArray(vao[0]); GLES30.glGenBuffers(1, vbo, 0); GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vbo[0]); GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, 64, vb, GLES30.GL_STATIC_DRAW);
        GLES30.glEnableVertexAttribArray(0); GLES30.glVertexAttribPointer(0, 2, GLES30.GL_FLOAT, false, 16, 0); GLES30.glEnableVertexAttribArray(1); GLES30.glVertexAttribPointer(1, 2, GLES30.GL_FLOAT, false, 16, 8);
        GLES30.glUseProgram(program); GLES30.glViewport(0, 0, W, H);
        GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "cameraTexture"), 0); GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "luminanceTexture"), 1);
        GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "luminanceScale"), 32f/33f); GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "luminanceOffset"), .5f/33f);
        GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "outWidth"), W); GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "outHeight"), H);
        GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "zebraThreshold"), .75f); GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "zebraShift"), 0); GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "zebraWidth"), 8);
        GLES30.glUniform4f(GLES30.glGetUniformLocation(program, "zebraColor"), 0,0,0,1); GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "midGreyMode"), 0);
        GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "enableColoredLines"), 1); GLES30.glUniform4f(GLES30.glGetUniformLocation(program, "lineColor"), 1,0,0,1); GLES30.glUniform1f(GLES30.glGetUniformLocation(program, "peakingThreshold"), 3f);
        for (int mode = 1; mode <= 4; mode++) {
            byte[] source = new byte[W*H*4];
            for (int y=0; y<H; y++) for (int x=0; x<W; x++) {
                int i=(y*W+x)*4; source[i]=(byte)(mode==3 ? (x < W/2 ? 0 : 255) : x*255/(W-1));
                source[i+1]=(byte)(mode==3 ? (x < W/2 ? 0 : 255) : y*255/(H-1)); source[i+2]=(byte)(mode==3 ? (x < W/2 ? 0 : 255) : (x+y)*255/(W+H-2)); source[i+3]=(byte)255;
            }
            String name = mode == 1 ? "false-color" : mode == 2 ? "zebra" : mode == 3 ? "focus" : "luminance-f32";
            write(name+"-input.rgba", source);
            GLES30.glActiveTexture(GLES30.GL_TEXTURE0); GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture[0]); params(GLES30.GL_TEXTURE_2D); GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D, 0, GLES30.GL_RGBA8, W, H, 0, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, buffer(source));
            if (mode == 4) GLES30.glDisable(GLES30.GL_DITHER); // Preserve the float's packed bits in RGBA8.
            GLES30.glUniform1i(GLES30.glGetUniformLocation(program, "mode"), mode); GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4);
            int error = GLES30.glGetError(); if (error != GLES30.GL_NO_ERROR) throw new IllegalStateException(name+" GLES "+error);
            ByteBuffer output = ByteBuffer.allocateDirect(W*H*4); GLES30.glReadPixels(0, 0, W, H, GLES30.GL_RGBA, GLES30.GL_UNSIGNED_BYTE, output); byte[] result = new byte[W*H*4]; output.get(result); write(name+"-android.rgba", result);
        }
        write("bmc-renderer.txt", (GLES30.glGetString(GLES30.GL_RENDERER)+"\n"+GLES30.glGetString(GLES30.GL_VERSION)+"\n").getBytes("UTF-8"));
    }
}
