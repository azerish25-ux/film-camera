#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;
in highp vec2 vTextureCoord;
out highp vec4 fragColor;
uniform samplerExternalOES chromaTexId;
uniform float chroma_vignetteFalloff;
uniform highp vec2 chroma_iResolution;
uniform float chroma_value;
uniform float chroma_pseudoExposure;
uniform float chroma_contrast;
void main ()
{
  lowp vec4 color_1;
  highp vec2 tmpvar_2;
  tmpvar_2 = (vTextureCoord - vec2(0.5, 0.5));
  highp vec3 tmpvar_3;
  tmpvar_3.xy = tmpvar_2;
  tmpvar_3.z = sqrt(((0.5 - 
    (tmpvar_2.x * tmpvar_2.x)
  ) - (tmpvar_2.y * tmpvar_2.y)));
  highp vec3 tmpvar_4;
  tmpvar_4 = normalize(tmpvar_3);
  float eta_5;
  eta_5 = mix (1.0, 1.005217, (chroma_value * 4.0));
  highp vec3 tmpvar_6;
  highp float tmpvar_7;
  tmpvar_7 = dot (tmpvar_4, vec3(0.0, 0.0, -1.0));
  highp float tmpvar_8;
  tmpvar_8 = (1.0 - (eta_5 * (eta_5 * 
    (1.0 - (tmpvar_7 * tmpvar_7))
  )));
  if ((tmpvar_8 < 0.0)) {
    tmpvar_6 = vec3(0.0, 0.0, 0.0);
  } else {
    tmpvar_6 = ((eta_5 * vec3(0.0, 0.0, -1.0)) - ((
      (eta_5 * tmpvar_7)
     + 
      sqrt(tmpvar_8)
    ) * tmpvar_4));
  };
  float eta_9;
  eta_9 = mix (1.0, 1.002602, (chroma_value * 4.0));
  highp vec3 tmpvar_10;
  highp float tmpvar_11;
  tmpvar_11 = dot (tmpvar_4, vec3(0.0, 0.0, -1.0));
  highp float tmpvar_12;
  tmpvar_12 = (1.0 - (eta_9 * (eta_9 * 
    (1.0 - (tmpvar_11 * tmpvar_11))
  )));
  if ((tmpvar_12 < 0.0)) {
    tmpvar_10 = vec3(0.0, 0.0, 0.0);
  } else {
    tmpvar_10 = ((eta_9 * vec3(0.0, 0.0, -1.0)) - ((
      (eta_9 * tmpvar_11)
     + 
      sqrt(tmpvar_12)
    ) * tmpvar_4));
  };
  float eta_13;
  eta_13 = mix (1.0, 0.9974115, (chroma_value * 4.0));
  highp vec3 tmpvar_14;
  highp float tmpvar_15;
  tmpvar_15 = dot (tmpvar_4, vec3(0.0, 0.0, -1.0));
  highp float tmpvar_16;
  tmpvar_16 = (1.0 - (eta_13 * (eta_13 * 
    (1.0 - (tmpvar_15 * tmpvar_15))
  )));
  if ((tmpvar_16 < 0.0)) {
    tmpvar_14 = vec3(0.0, 0.0, 0.0);
  } else {
    tmpvar_14 = ((eta_13 * vec3(0.0, 0.0, -1.0)) - ((
      (eta_13 * tmpvar_15)
     + 
      sqrt(tmpvar_16)
    ) * tmpvar_4));
  };
  float eta_17;
  eta_17 = mix (1.0, 0.9948366, (chroma_value * 4.0));
  highp vec3 tmpvar_18;
  highp float tmpvar_19;
  tmpvar_19 = dot (tmpvar_4, vec3(0.0, 0.0, -1.0));
  highp float tmpvar_20;
  tmpvar_20 = (1.0 - (eta_17 * (eta_17 * 
    (1.0 - (tmpvar_19 * tmpvar_19))
  )));
  if ((tmpvar_20 < 0.0)) {
    tmpvar_18 = vec3(0.0, 0.0, 0.0);
  } else {
    tmpvar_18 = ((eta_17 * vec3(0.0, 0.0, -1.0)) - ((
      (eta_17 * tmpvar_19)
     + 
      sqrt(tmpvar_20)
    ) * tmpvar_4));
  };
  float eta_21;
  eta_21 = mix (1.0, 0.9922747, (chroma_value * 4.0));
  highp vec3 tmpvar_22;
  highp float tmpvar_23;
  tmpvar_23 = dot (tmpvar_4, vec3(0.0, 0.0, -1.0));
  highp float tmpvar_24;
  tmpvar_24 = (1.0 - (eta_21 * (eta_21 * 
    (1.0 - (tmpvar_23 * tmpvar_23))
  )));
  if ((tmpvar_24 < 0.0)) {
    tmpvar_22 = vec3(0.0, 0.0, 0.0);
  } else {
    tmpvar_22 = ((eta_21 * vec3(0.0, 0.0, -1.0)) - ((
      (eta_21 * tmpvar_23)
     + 
      sqrt(tmpvar_24)
    ) * tmpvar_4));
  };
  highp vec2 P_25;
  P_25 = (tmpvar_6.xy + vTextureCoord);
  lowp vec4 tmpvar_26;
  highp vec2 P_27;
  P_27 = (tmpvar_10.xy + vTextureCoord);
  tmpvar_26 = texture (chromaTexId, P_27);
  lowp vec4 tmpvar_28;
  highp vec2 P_29;
  P_29 = (tmpvar_14.xy + vTextureCoord);
  tmpvar_28 = texture (chromaTexId, P_29);
  highp vec2 P_30;
  P_30 = (tmpvar_18.xy + vTextureCoord);
  lowp vec4 tmpvar_31;
  highp vec2 P_32;
  P_32 = (tmpvar_22.xy + vTextureCoord);
  tmpvar_31 = texture (chromaTexId, P_32);
  lowp float tmpvar_33;
  tmpvar_33 = (((
    (tmpvar_26.x * 2.0)
   + 
    (tmpvar_26.y * 2.0)
  ) - tmpvar_26.z) / 6.0);
  lowp float tmpvar_34;
  tmpvar_34 = (((
    (tmpvar_28.y * 2.0)
   + 
    (tmpvar_28.z * 2.0)
  ) - tmpvar_28.x) / 6.0);
  lowp float tmpvar_35;
  tmpvar_35 = (((
    (tmpvar_31.z * 2.0)
   + 
    (tmpvar_31.x * 2.0)
  ) - tmpvar_31.y) / 6.0);
  lowp vec3 tmpvar_36;
  tmpvar_36.x = ((texture (chromaTexId, P_25).x * 0.5) + ((
    ((2.0 * tmpvar_35) + (2.0 * tmpvar_33))
   - tmpvar_34) / 3.0));
  tmpvar_36.y = ((texture (chromaTexId, vTextureCoord).y * 0.5) + ((
    ((2.0 * tmpvar_33) + (2.0 * tmpvar_34))
   - tmpvar_35) / 3.0));
  tmpvar_36.z = ((texture (chromaTexId, P_30).z * 0.5) + ((
    ((2.0 * tmpvar_34) + (2.0 * tmpvar_35))
   - tmpvar_33) / 3.0));
  lowp vec4 tmpvar_37;
  tmpvar_37.w = 1.0;
  tmpvar_37.xyz = tmpvar_36;
  color_1 = (tmpvar_37 * chroma_pseudoExposure);
  highp vec2 tmpvar_38;
  tmpvar_38.y = 1.0;
  tmpvar_38.x = (chroma_iResolution.x / chroma_iResolution.y);
  highp vec2 tmpvar_39;
  tmpvar_39 = (((vTextureCoord - 0.5) * tmpvar_38) * 2.0);
  highp float tmpvar_40;
  tmpvar_40 = (sqrt(dot (tmpvar_39, tmpvar_39)) * chroma_vignetteFalloff);
  highp float tmpvar_41;
  tmpvar_41 = ((tmpvar_40 * tmpvar_40) + 1.0);
  highp vec4 tmpvar_42;
  tmpvar_42.w = 1.0;
  tmpvar_42.xyz = (((chroma_contrast * 
    (color_1.xyz - 0.5)
  ) + 0.5) * (1.0/((tmpvar_41 * tmpvar_41))));
  fragColor = clamp (tmpvar_42, 0.0, 1.0);
}    