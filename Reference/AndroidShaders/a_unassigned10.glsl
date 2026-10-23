#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out vec4 fragColor;

uniform sampler2D halationBlurTempTexture;
uniform highp vec2 halationBlurResInv;

uniform highp float redHalationOffset;
uniform float halationBlurHueGreen;
uniform float halationBlurHueBlue;

float toLinear(float v) {
  return pow(v, float(2.2));
}
vec3 toLinear(vec3 v) {
  return pow(v, vec3(2.2));
}

vec3 toGamma(vec3 v) {
  return pow(v, vec3(1.0 / 2.2));
}

void main() {
    highp vec2 point0 = vTextureCoord + (vec2(redHalationOffset, redHalationOffset) * halationBlurResInv);
    highp vec2 point1 = vTextureCoord + (vec2(redHalationOffset, -redHalationOffset) * halationBlurResInv);
    highp vec2 point2 = vTextureCoord + (vec2(-redHalationOffset, redHalationOffset) * halationBlurResInv);
    highp vec2 point3 = vTextureCoord + (vec2(-redHalationOffset, -redHalationOffset) * halationBlurResInv);


    vec3 colorCenter = textureLod(halationBlurTempTexture, vTextureCoord, 0.0).rgb;
    
    vec3 color0 = toLinear(textureLod(halationBlurTempTexture, point0, 0.0).rgb);
    vec3 color1 = toLinear(textureLod(halationBlurTempTexture, point1, 0.0).rgb);
    vec3 color2 = toLinear(textureLod(halationBlurTempTexture, point2, 0.0).rgb);
    vec3 color3 = toLinear(textureLod(halationBlurTempTexture, point3, 0.0).rgb);

    vec3 resultColor = toGamma((color0 + color1 + color2 + color3) * 0.25);

    fragColor = vec4(vec3(resultColor.r, mix(colorCenter.g, resultColor.g , halationBlurHueGreen) , mix(colorCenter.b, resultColor.b , halationBlurHueBlue) ), 1.0);
}      