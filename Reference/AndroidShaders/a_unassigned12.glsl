#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out vec4 fragColor;

uniform sampler2D halationHighSourceTexture;
uniform float halationIntensity;
uniform float halationCuttoff;

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 toLinear(vec3 v) {
  return pow(v, vec3(2.2));
}

vec3 applyIntensity(vec3 v) {
  return  (smoothstep(halationCuttoff/*0.35*/, 1.0, v)) * halationIntensity;
}

vec3 toGamma(vec3 v) {
  return pow(v, vec3(1.0 / 2.2));
}


void main() { 
  vec4 src = textureLod(halationHighSourceTexture, vTextureCoord, 0.0);   
  vec3 srcLinear =  toGamma(applyIntensity(toLinear(src.rgb)));  
  fragColor = vec4(srcLinear, 1.0);
}      