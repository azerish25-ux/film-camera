#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out vec4 fragColor;

uniform sampler2D textureHalationMergeSource;
uniform sampler2D textureHalationMergeBlur;
uniform float halationMergeIntensity;
uniform float halationMergeHueGreen;
uniform float halationMergeHueBlue;

vec3 toLinear(vec3 v) {
  return pow(v, vec3(2.2));
}

vec3 toGamma(vec3 v) {
  return pow(v, vec3(1.0 / 2.2));
}


void main() { 
    vec4 colorIn;
    colorIn = textureLod(textureHalationMergeSource, vTextureCoord, 0.0);
    vec4 halColorIn;
    halColorIn = textureLod(textureHalationMergeBlur, vTextureCoord, 0.0);
    
    vec3 mergedColor = toGamma(toLinear(colorIn.rgb) + toLinear(vec3(halColorIn.r, halColorIn.g * halationMergeHueGreen, halColorIn.b * halationMergeHueBlue)) * 15.0 * halationMergeIntensity );
    fragColor =  vec4(clamp(mergedColor, 0.0, 1.0), 1.0);
}      