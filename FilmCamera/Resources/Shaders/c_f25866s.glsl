#version 300 es
precision mediump sampler2D;
precision mediump sampler3D;
precision highp int;
precision highp float;
struct Stain {
  lowp int x;
  lowp int y;
  lowp int w;
  lowp int h;
  lowp int time;
  lowp float mask[576];
};
struct Scratch {
  lowp float x;
  lowp float y;
  lowp float vx;
  lowp float vy;
  lowp float len;
  lowp int time;
  lowp float D[100];
};
struct Scratch_v {
  lowp float x[8];
  lowp float t[8];
  lowp int time;
};
in highp vec2 vTextureCoord;
uniform sampler2D grainInputTexture;
uniform mediump sampler3D mLutID;
uniform highp float srandomX;
uniform highp float srandomY;
uniform sampler2D framePerforationsTexture;
uniform mediump float saturation;
uniform highp float perfColor;
uniform Stain stain;
uniform Scratch scratch;
uniform Scratch_v scratch_v;
uniform mediump float gScratchesColor;
uniform mediump float gVerticalScratchIntensity;
uniform highp vec2 noiseRes;
out mediump vec4 fragColor;
void main ()
{
  mediump vec4 hawaiiFramePerforations_1;
  mediump vec3 resultColor_2;
  mediump vec3 source_3;
  lowp vec3 tmpvar_4;
  tmpvar_4 = textureLod (grainInputTexture, vTextureCoord, 0.0).xyz;
  source_3 = tmpvar_4;
  mediump vec4 tmpvar_5;
  tmpvar_5 = textureLod (mLutID, source_3, 0.0);
  mediump vec3 tmpvar_6;
  tmpvar_6 = mix (vec3(dot (tmpvar_5.xyz, vec3(0.2125, 0.7154, 0.0721))), tmpvar_5.xyz, saturation);
  mediump vec3 colorIn_7;
  colorIn_7 = tmpvar_6;
  mediump float WV_8;
  lowp float W_9;
  mediump ivec2 uv_10;
  mediump float fY_11;
  mediump float tmpvar_12;
  tmpvar_12 = (((tmpvar_6.x + tmpvar_6.y) + tmpvar_6.z) / 3.0);
  fY_11 = tmpvar_12;
  highp ivec2 tmpvar_13;
  tmpvar_13 = ivec2((vTextureCoord * noiseRes));
  uv_10 = tmpvar_13;
  lowp ivec2 tmpvar_14;
  tmpvar_14.x = stain.x;
  tmpvar_14.y = stain.y;
  mediump ivec2 tmpvar_15;
  tmpvar_15 = (uv_10 - tmpvar_14);
  mediump ivec4 tmpvar_16;
  tmpvar_16.x = stain.w;
  tmpvar_16.y = stain.h;
  tmpvar_16.zw = tmpvar_15;
  mediump ivec4 tmpvar_17;
  tmpvar_17.zw = ivec2(-1, -1);
  tmpvar_17.xy = tmpvar_15;
  bvec4 tmpvar_18;
  tmpvar_18 = greaterThan (tmpvar_16, tmpvar_17);
  mediump int tmpvar_19;
  tmpvar_19 = clamp (((tmpvar_15.y * 24) + tmpvar_15.x), 0, 576);
  lowp float tmpvar_20;
  tmpvar_20 = stain.mask[tmpvar_19];
  bool tmpvar_21;
  if ((stain.time > 0)) {
    tmpvar_21 = ((tmpvar_18.x && tmpvar_18.y) && (tmpvar_18.z && tmpvar_18.w));
  } else {
    tmpvar_21 = bool(0);
  };
  mediump float tmpvar_22;
  lowp float a_23;
  a_23 = float(tmpvar_21);
  tmpvar_22 = mix (tmpvar_12, ((tmpvar_12 * tmpvar_20) + (gScratchesColor * 
    (1.0 - tmpvar_20)
  )), a_23);
  fY_11 = tmpvar_22;
  lowp vec2 tmpvar_24;
  tmpvar_24.x = scratch.x;
  tmpvar_24.y = scratch.y;
  mediump vec2 tmpvar_25;
  tmpvar_25 = (vec2(uv_10) - tmpvar_24);
  mediump vec2 tmpvar_26;
  tmpvar_26.x = ((tmpvar_25.x * scratch.vx) + (tmpvar_25.y * scratch.vy));
  tmpvar_26.y = ((tmpvar_25.x * scratch.vy) - (tmpvar_25.y * scratch.vx));
  mediump vec2 tmpvar_27;
  tmpvar_27.x = tmpvar_26.x;
  tmpvar_27.y = scratch.len;
  mediump vec2 tmpvar_28;
  tmpvar_28.x = 0.0;
  tmpvar_28.y = tmpvar_26.x;
  bvec2 tmpvar_29;
  tmpvar_29 = greaterThan (tmpvar_27, tmpvar_28);
  mediump int tmpvar_30;
  tmpvar_30 = clamp (int(tmpvar_26.x), 0, 100);
  mediump float tmpvar_31;
  tmpvar_31 = clamp ((abs(
    (tmpvar_26.y - scratch.D[tmpvar_30])
  ) * 0.5), 0.4, 1.0);
  W_9 = tmpvar_31;
  bool tmpvar_32;
  if ((scratch.time > 0)) {
    tmpvar_32 = (tmpvar_29.x && tmpvar_29.y);
  } else {
    tmpvar_32 = bool(0);
  };
  mediump float tmpvar_33;
  lowp float a_34;
  a_34 = float(tmpvar_32);
  tmpvar_33 = mix (tmpvar_22, ((tmpvar_22 * W_9) + (gScratchesColor * 
    (1.0 - W_9)
  )), a_34);
  fY_11 = tmpvar_33;
  lowp float tmpvar_35;
  tmpvar_35 = scratch_v.x[1];
  mediump vec2 tmpvar_36;
  tmpvar_36.x = float(uv_10.x);
  tmpvar_36.y = (tmpvar_35 + 2.0);
  mediump vec2 tmpvar_37;
  tmpvar_37.x = (tmpvar_35 - 2.0);
  tmpvar_37.y = float(uv_10.x);
  bvec2 tmpvar_38;
  tmpvar_38 = greaterThan (tmpvar_36, tmpvar_37);
  highp float tmpvar_39;
  tmpvar_39 = ((7.0 * float(uv_10.y)) / noiseRes.y);
  highp int tmpvar_40;
  tmpvar_40 = int(tmpvar_39);
  highp float tmpvar_41;
  tmpvar_41 = fract(tmpvar_39);
  highp float tmpvar_42;
  tmpvar_42 = ((scratch_v.t[tmpvar_40] * (1.0 - tmpvar_41)) + (scratch_v.t[(tmpvar_40 + 1)] * tmpvar_41));
  highp float tmpvar_43;
  tmpvar_43 = clamp (abs((
    float(uv_10.x)
   - 
    ((scratch_v.x[tmpvar_40] * (1.0 - tmpvar_41)) + (scratch_v.x[(tmpvar_40 + 1)] * tmpvar_41))
  )), gVerticalScratchIntensity, 1.0);
  WV_8 = tmpvar_43;
  bool tmpvar_44;
  if ((scratch_v.time > 0)) {
    tmpvar_44 = (tmpvar_38.x && tmpvar_38.y);
  } else {
    tmpvar_44 = bool(0);
  };
  highp float tmpvar_45;
  lowp float a_46;
  a_46 = float(tmpvar_44);
  tmpvar_45 = mix (tmpvar_33, ((
    ((gScratchesColor * tmpvar_42) + (tmpvar_33 * (1.0 - tmpvar_42)))
   * 
    (1.0 - WV_8)
  ) + (tmpvar_33 * WV_8)), a_46);
  fY_11 = tmpvar_45;
  colorIn_7 = (tmpvar_6 * (fY_11 / tmpvar_12));
  highp vec2 tmpvar_47;
  tmpvar_47.x = vTextureCoord.x;
  tmpvar_47.y = (1.0 - vTextureCoord.y);
  highp vec2 tmpvar_48;
  tmpvar_48.x = srandomX;
  tmpvar_48.y = -(srandomY);
  lowp vec4 tmpvar_49;
  highp vec2 P_50;
  P_50 = (tmpvar_47 + tmpvar_48);
  tmpvar_49 = textureLod (framePerforationsTexture, P_50, 0.0);
  hawaiiFramePerforations_1 = tmpvar_49;
  highp vec3 tmpvar_51;
  tmpvar_51 = mix (colorIn_7, (hawaiiFramePerforations_1.xyz + perfColor), hawaiiFramePerforations_1.w);
  resultColor_2 = tmpvar_51;
  mediump vec4 tmpvar_52;
  tmpvar_52.w = 1.0;
  tmpvar_52.xyz = resultColor_2;
  fragColor = tmpvar_52;
}       