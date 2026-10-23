package com.azerish.reference;
import android.opengl.*;
import java.nio.*;
import java.io.*;
import java.util.*;
import org.json.*;

public final class ReferenceMain {
  static final int W=128,H=96;
  final File root;
  ReferenceMain(File root){this.root=root;}
  public static void main(String[] args){
    try {ReferenceMain runner=new ReferenceMain(new File(args[0]));runner.run();runner.write("done",new byte[]{1});System.exit(0);}
    catch(Throwable error){error.printStackTrace();System.exit(1);}
  }
  void write(String name,byte[] bytes) throws Exception {try(FileOutputStream s=new FileOutputStream(new File(root,name))){s.write(bytes);}}
  String read(String name) throws Exception {try(java.util.zip.ZipFile zip=new java.util.zip.ZipFile(new File(root,"reference.jar"));InputStream s=zip.getInputStream(zip.getEntry("assets/"+name));ByteArrayOutputStream o=new ByteArrayOutputStream()){byte[] b=new byte[8192];int n;while((n=s.read(b))>0)o.write(b,0,n);return new String(o.toByteArray(),"UTF-8");}}
  byte[] asset(String name) throws Exception {try(java.util.zip.ZipFile zip=new java.util.zip.ZipFile(new File(root,"reference.jar"));InputStream input=zip.getInputStream(zip.getEntry("assets/"+name));ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] chunk=new byte[8192];int n;while((n=input.read(chunk))>0)out.write(chunk,0,n);return out.toByteArray();}}
  String shader(String name) throws Exception {if(name.startsWith("frame_")) return shader("c_f25860m").replace("//{frame_func}",shader(name.substring(6)));return read(name+".glsl").replaceAll("(?m)^#extension GL_OES_EGL_image_external.*$","").replace("samplerExternalOES","sampler2D");}
  int compile(String text,int type) {int s=GLES30.glCreateShader(type);GLES30.glShaderSource(s,text);GLES30.glCompileShader(s);int[] ok={0};GLES30.glGetShaderiv(s,GLES30.GL_COMPILE_STATUS,ok,0);if(ok[0]==0)throw new RuntimeException(GLES30.glGetShaderInfoLog(s));return s;}
  int program(String fragment) throws Exception {int v=compile(shader(fragment.startsWith("frame_")?"b_f25843a":"a_f25836b"),GLES30.GL_VERTEX_SHADER),f=compile(shader(fragment),GLES30.GL_FRAGMENT_SHADER);int p=GLES30.glCreateProgram();GLES30.glAttachShader(p,v);GLES30.glAttachShader(p,f);GLES30.glLinkProgram(p);int[] ok={0};GLES30.glGetProgramiv(p,GLES30.GL_LINK_STATUS,ok,0);if(ok[0]==0)throw new RuntimeException(GLES30.glGetProgramInfoLog(p));GLES30.glDeleteShader(v);GLES30.glDeleteShader(f);return p;}
  ByteBuffer buffer(byte[] b){ByteBuffer v=ByteBuffer.allocateDirect(b.length).order(ByteOrder.nativeOrder());v.put(b).position(0);return v;}
  byte[] pixels(int kind){byte[] b=new byte[W*H*4];for(int y=0;y<H;y++)for(int x=0;x<W;x++){int n=(y*W+x)*4;b[n]=(byte)(kind==0?1+x*253/(W-1):kind==1?60:0);b[n+1]=(byte)(kind==0?1+y*253/(H-1):kind==1?90:0);b[n+2]=(byte)(kind==0?1+(x+y)*253/(W+H-2):kind==1?120:0);b[n+3]=(byte)(kind==2?0:255);}return b;}
  void run() throws Exception {
    EGLDisplay display=EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);int[] version=new int[2];if(!EGL14.eglInitialize(display,version,0,version,1))throw new RuntimeException("EGL initialize");
    EGLConfig[] configs=new EGLConfig[1];int[] count={0};int[] attributes={EGL14.EGL_RENDERABLE_TYPE,0x40,EGL14.EGL_SURFACE_TYPE,EGL14.EGL_PBUFFER_BIT,EGL14.EGL_RED_SIZE,8,EGL14.EGL_GREEN_SIZE,8,EGL14.EGL_BLUE_SIZE,8,EGL14.EGL_ALPHA_SIZE,8,EGL14.EGL_NONE};
    EGL14.eglChooseConfig(display,attributes,0,configs,0,1,count,0);
    EGLContext context=EGL14.eglCreateContext(display,configs[0],EGL14.EGL_NO_CONTEXT,new int[]{EGL14.EGL_CONTEXT_CLIENT_VERSION,3,EGL14.EGL_NONE},0);
    EGLSurface surface=EGL14.eglCreatePbufferSurface(display,configs[0],new int[]{EGL14.EGL_WIDTH,W,EGL14.EGL_HEIGHT,H,EGL14.EGL_NONE},0);
    if(!EGL14.eglMakeCurrent(display,surface,surface,context))throw new RuntimeException("EGL make current");
    int[] ids=new int[6];GLES30.glGenTextures(6,ids,0);
    Map<String,Integer> textures=new HashMap<>();
    for(int i=0;i<3;i++){GLES30.glBindTexture(GLES30.GL_TEXTURE_2D,ids[i]);params(GLES30.GL_TEXTURE_2D);GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D,0,GLES30.GL_RGBA8,W,H,0,GLES30.GL_RGBA,GLES30.GL_UNSIGNED_BYTE,buffer(pixels(i)));textures.put(i==0?"source":i==1?"background":"clear",ids[i]);}
    byte[] lut=new byte[64*64*64*3];int at=0;for(int b=0;b<64;b++)for(int g=0;g<64;g++)for(int r=0;r<64;r++){lut[at++]=(byte)(r*255/64);lut[at++]=(byte)(g*255/64);lut[at++]=(byte)(b*255/64);}
    GLES30.glBindTexture(GLES30.GL_TEXTURE_3D,ids[3]);params(GLES30.GL_TEXTURE_3D);GLES30.glTexParameteri(GLES30.GL_TEXTURE_3D,GLES30.GL_TEXTURE_WRAP_R,GLES30.GL_CLAMP_TO_EDGE);GLES30.glTexImage3D(GLES30.GL_TEXTURE_3D,0,GLES30.GL_RGB8,64,64,64,0,GLES30.GL_RGB,GLES30.GL_UNSIGNED_BYTE,buffer(lut));textures.put("lut",ids[3]);
    byte[] noise;try(java.util.zip.ZipFile zip=new java.util.zip.ZipFile(new File(root,"reference.jar"));InputStream s=zip.getInputStream(zip.getEntry("assets/noise.rgba"));ByteArrayOutputStream out=new ByteArrayOutputStream()){byte[] chunk=new byte[8192];int n;while((n=s.read(chunk))>0)out.write(chunk,0,n);noise=out.toByteArray();}
    ByteBuffer decoded=ByteBuffer.allocateDirect(1024*1024*3);
    ETC1.decodeImage(buffer(asset("AndroidNoise.etc1")),decoded,1024,1024,3,1024*3);
    for(int pixel=0;pixel<1024*1024;pixel++)for(int channel=0;channel<3;channel++)if(decoded.get(pixel*3+channel)!=noise[pixel*4+channel])throw new RuntimeException("Original ETC1 noise mismatch at "+pixel+":"+channel);
    write("noise-decoding.txt","Android ETC1 decoded all 1048576 noise pixels identically to the iOS table\n".getBytes("UTF-8"));
    GLES30.glBindTexture(GLES30.GL_TEXTURE_2D,ids[5]);GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,GLES30.GL_TEXTURE_MIN_FILTER,GLES30.GL_NEAREST);GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,GLES30.GL_TEXTURE_MAG_FILTER,GLES30.GL_NEAREST);GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,GLES30.GL_TEXTURE_WRAP_S,GLES30.GL_REPEAT);GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D,GLES30.GL_TEXTURE_WRAP_T,GLES30.GL_REPEAT);GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D,0,GLES30.GL_RGBA8,1024,1024,0,GLES30.GL_RGBA,GLES30.GL_UNSIGNED_BYTE,buffer(noise));textures.put("noise",ids[5]);
    GLES30.glBindTexture(GLES30.GL_TEXTURE_2D,ids[4]);params(GLES30.GL_TEXTURE_2D);GLES30.glTexImage2D(GLES30.GL_TEXTURE_2D,0,GLES30.GL_RGBA8,W,H,0,GLES30.GL_RGBA,GLES30.GL_UNSIGNED_BYTE,null);
    int[] fb={0},vao={0},vbo={0};GLES30.glGenFramebuffers(1,fb,0);GLES30.glBindFramebuffer(GLES30.GL_FRAMEBUFFER,fb[0]);GLES30.glFramebufferTexture2D(GLES30.GL_FRAMEBUFFER,GLES30.GL_COLOR_ATTACHMENT0,GLES30.GL_TEXTURE_2D,ids[4],0);
    GLES30.glGenVertexArrays(1,vao,0);GLES30.glBindVertexArray(vao[0]);GLES30.glGenBuffers(1,vbo,0);GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER,vbo[0]);
    float[] verts={-1,-1,0,0,1,-1,1,0,-1,1,0,1,1,1,1,1};FloatBuffer vb=ByteBuffer.allocateDirect(64).order(ByteOrder.nativeOrder()).asFloatBuffer();vb.put(verts).position(0);GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER,64,vb,GLES30.GL_STATIC_DRAW);GLES30.glEnableVertexAttribArray(0);GLES30.glVertexAttribPointer(0,2,GLES30.GL_FLOAT,false,16,0);GLES30.glEnableVertexAttribArray(1);GLES30.glVertexAttribPointer(1,2,GLES30.GL_FLOAT,false,16,8);
    JSONArray cases=new JSONArray(read("reference-cases.json"));
    Map<String,Integer> programs=new HashMap<>();
    String currentLook="";
    for(int index=0;index<cases.length();index++){
      JSONObject c=cases.getJSONObject(index);
      String look=c.optString("lookAsset","");
      if(index==0 || !look.equals(currentLook)) {
        GLES30.glActiveTexture(GLES30.GL_TEXTURE0);GLES30.glBindTexture(GLES30.GL_TEXTURE_3D,ids[3]);
        GLES30.glTexImage3D(GLES30.GL_TEXTURE_3D,0,GLES30.GL_RGB8,64,64,64,0,GLES30.GL_RGB,GLES30.GL_UNSIGNED_BYTE,buffer(look.isEmpty()?lut:asset(look+".lut")));currentLook=look;
      }
      byte[] source=pixels(0);int pattern=c.optInt("pattern",0);
      for(int y=0;y<H;y++)for(int x=0;x<W;x++){int n=(y*W+x)*4,k=y*W+x;if(pattern==1){source[n]=(byte)((k%23)*255/22);source[n+1]=(byte)(((k/23)%23)*255/22);source[n+2]=(byte)(((k/529)%23)*255/22);}else if(pattern==2){source[n]=source[n+1]=source[n+2]=(byte)(x*255/127);}}
      if(pattern==3)source=asset("ReferenceScene.rgba");
      if(c.has("inputCase")){try(FileInputStream in=new FileInputStream(new File(root,c.getString("inputCase")+".rgba"))){int offset=0,n;while(offset<source.length && (n=in.read(source,offset,source.length-offset))>0)offset+=n;if(offset!=source.length)throw new IOException("Short chain fixture");}}
      GLES30.glActiveTexture(GLES30.GL_TEXTURE0);GLES30.glBindTexture(GLES30.GL_TEXTURE_2D,ids[0]);GLES30.glTexSubImage2D(GLES30.GL_TEXTURE_2D,0,0,0,W,H,GLES30.GL_RGBA,GLES30.GL_UNSIGNED_BYTE,buffer(source));
      String shaderName=c.getString("shader");if(!programs.containsKey(shaderName))programs.put(shaderName,program(shaderName));int p=programs.get(shaderName);GLES30.glUseProgram(p);GLES30.glViewport(0,0,W,H);
      JSONObject fs=c.getJSONObject("floats");for(Iterator<String> keys=fs.keys();keys.hasNext();){String key=keys.next();GLES30.glUniform1f(GLES30.glGetUniformLocation(p,key),(float)fs.getDouble(key));}
      JSONObject vs=c.getJSONObject("vectors");for(Iterator<String> keys=vs.keys();keys.hasNext();){String key=keys.next();JSONArray v=vs.getJSONArray(key);GLES30.glUniform2f(GLES30.glGetUniformLocation(p,key),(float)v.getDouble(0),(float)v.getDouble(1));}
      JSONObject is=c.getJSONObject("ints");for(Iterator<String> keys=is.keys();keys.hasNext();){String key=keys.next();GLES30.glUniform1i(GLES30.glGetUniformLocation(p,key),is.getInt(key));}
      JSONObject arrays=c.getJSONObject("arrays");for(Iterator<String> keys=arrays.keys();keys.hasNext();){String key=keys.next();JSONArray a=arrays.getJSONArray(key);float[] values=new float[a.length()];for(int n=0;n<values.length;n++)values[n]=(float)a.getDouble(n);if(key.equals("curve"))GLES30.glUniform3fv(GLES30.glGetUniformLocation(p,key),values.length/3,values,0);else GLES30.glUniform1fv(GLES30.glGetUniformLocation(p,key),values.length,values,0);}
      JSONObject samplers=c.getJSONObject("samplers");int unit=0;for(Iterator<String> keys=samplers.keys();keys.hasNext();){String key=keys.next(),name=samplers.getString(key);GLES30.glActiveTexture(GLES30.GL_TEXTURE0+unit);GLES30.glBindTexture(name.equals("lut")?GLES30.GL_TEXTURE_3D:GLES30.GL_TEXTURE_2D,textures.get(name));GLES30.glUniform1i(GLES30.glGetUniformLocation(p,key),unit++);}
      GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP,0,4);int error=GLES30.glGetError();if(error!=0)throw new RuntimeException(c.getString("name")+": GLES "+error);
      ByteBuffer output=ByteBuffer.allocateDirect(W*H*4);GLES30.glReadPixels(0,0,W,H,GLES30.GL_RGBA,GLES30.GL_UNSIGNED_BYTE,output);byte[] data=new byte[W*H*4];output.get(data);write(c.getString("name")+".rgba",data);
    }
    write("renderer.txt",(GLES30.glGetString(GLES30.GL_RENDERER)+"\n"+GLES30.glGetString(GLES30.GL_VERSION)).getBytes("UTF-8"));
  }
  void params(int target){GLES30.glTexParameteri(target,GLES30.GL_TEXTURE_MIN_FILTER,GLES30.GL_LINEAR);GLES30.glTexParameteri(target,GLES30.GL_TEXTURE_MAG_FILTER,GLES30.GL_LINEAR);GLES30.glTexParameteri(target,GLES30.GL_TEXTURE_WRAP_S,GLES30.GL_CLAMP_TO_EDGE);GLES30.glTexParameteri(target,GLES30.GL_TEXTURE_WRAP_T,GLES30.GL_CLAMP_TO_EDGE);}
}
