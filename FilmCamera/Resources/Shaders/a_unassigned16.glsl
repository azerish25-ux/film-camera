#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out vec4 fragColor;
uniform sampler2D sourceTexture;
void main() { 
  fragColor = textureLod(sourceTexture, vTextureCoord, 0.0); 
}      