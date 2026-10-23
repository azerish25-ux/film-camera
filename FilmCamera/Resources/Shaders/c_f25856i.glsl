#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out lowp vec4 fragColor;
uniform sampler2D blurTempTexture;
uniform highp vec2 blurResInv;
uniform highp float blurOffset;
uniform highp float blurFramePadding;
void main ()
{
  highp vec2 tmpvar_1;
  tmpvar_1 = (float((vTextureCoord.x > blurFramePadding)) * blurResInv);
  highp vec2 tmpvar_2;
  tmpvar_2 = (vTextureCoord + (vec2(blurOffset) * tmpvar_1));
  highp vec2 tmpvar_3;
  tmpvar_3.x = blurOffset;
  highp float tmpvar_4;
  tmpvar_4 = -(blurOffset);
  tmpvar_3.y = tmpvar_4;
  highp vec2 tmpvar_5;
  tmpvar_5 = (vTextureCoord + (tmpvar_3 * tmpvar_1));
  highp vec2 tmpvar_6;
  tmpvar_6.x = tmpvar_4;
  tmpvar_6.y = blurOffset;
  highp vec2 tmpvar_7;
  tmpvar_7 = (vTextureCoord + (tmpvar_6 * tmpvar_1));
  highp vec2 tmpvar_8;
  tmpvar_8 = (vTextureCoord + (vec2(tmpvar_4) * tmpvar_1));
  fragColor = (((
    (textureLod (blurTempTexture, tmpvar_2, 0.0) + textureLod (blurTempTexture, tmpvar_5, 0.0))
   + textureLod (blurTempTexture, tmpvar_7, 0.0)) + textureLod (blurTempTexture, tmpvar_8, 0.0)) * 0.25);
}