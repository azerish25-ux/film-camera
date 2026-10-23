#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out vec4 fragColor;

uniform sampler2D blurTempTexture;
uniform highp vec2 blurResInv;
uniform highp float blurOffset;
uniform highp float blurFramePadding;


void main() {


      highp vec2 pixelTest = float(vTextureCoord.x > blurFramePadding) * blurResInv;      
      highp vec2 p1 = vTextureCoord + vec2(blurOffset, blurOffset) * pixelTest;
      highp vec2 p2 = vTextureCoord + vec2(blurOffset, -blurOffset) * pixelTest;
      highp vec2 p3 = vTextureCoord + vec2(-blurOffset, blurOffset) * pixelTest;
      highp vec2 p4 = vTextureCoord + vec2(-blurOffset, -blurOffset) * pixelTest;
      vec4 color1 = textureLod(blurTempTexture, p1, 0.0);
      vec4 color2 = textureLod(blurTempTexture, p2, 0.0);
      vec4 color3 = textureLod(blurTempTexture, p3, 0.0);
      vec4 color4 = textureLod(blurTempTexture, p4, 0.0);      
      fragColor = (color1 + color2 + color3 + color4) * 0.25; 
  
}    