#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;
in highp vec2 vTextureCoord;
out highp vec4 fragColor;
uniform samplerExternalOES simpleTexId;
uniform float vignetteFalloff;
uniform float pseudoExposure;
uniform float contrast;
uniform highp vec2 iResolution;
void main ()
{
  lowp vec4 tmpvar_1;
  tmpvar_1 = texture (simpleTexId, vTextureCoord);
  highp vec2 tmpvar_2;
  tmpvar_2.y = 1.0;
  tmpvar_2.x = (iResolution.x / iResolution.y);
  highp vec2 tmpvar_3;
  tmpvar_3 = (((vTextureCoord - 0.5) * tmpvar_2) * 2.0);
  highp float tmpvar_4;
  tmpvar_4 = (sqrt(dot (tmpvar_3, tmpvar_3)) * vignetteFalloff);
  highp float tmpvar_5;
  tmpvar_5 = ((tmpvar_4 * tmpvar_4) + 1.0);
  highp vec4 tmpvar_6;
  tmpvar_6.w = 1.0;
  tmpvar_6.xyz = (((
    (contrast * (tmpvar_1.xyz - 0.5))
   + 0.5) * (1.0/(
    (tmpvar_5 * tmpvar_5)
  ))) * pseudoExposure);
  fragColor = clamp (tmpvar_6, 0.0, 1.0);
}       