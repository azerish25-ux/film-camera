#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision highp float;
precision highp int;
precision highp sampler2D;

in highp vec2 vTexelCoord;
out highp vec4 fragColor;
uniform sampler2D sourceTexture;
void main() { 
  fragColor = texelFetch(sourceTexture, ivec2(vTexelCoord), 0); 
}      