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
  sampler2D mask;
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
  mediump int y_8;
  mediump int x_9;
  mediump float fY_10;
  mediump float tmpvar_11;
  tmpvar_11 = (((tmpvar_6.x + tmpvar_6.y) + tmpvar_6.z) / 3.0);
  fY_10 = tmpvar_11;
  highp int tmpvar_12;
  tmpvar_12 = int((vTextureCoord.x * noiseRes.x));
  x_9 = tmpvar_12;
  highp int tmpvar_13;
  tmpvar_13 = int((vTextureCoord.y * noiseRes.y));
  y_8 = tmpvar_13;
  if ((stain.time > 0)) {
    mediump int tmpvar_14;
    tmpvar_14 = (x_9 - stain.x);
    mediump int tmpvar_15;
    tmpvar_15 = (y_8 - stain.y);
    if ((((
      (tmpvar_14 < stain.w)
     && 
      (tmpvar_15 < stain.h)
    ) && (tmpvar_14 >= 0)) && (tmpvar_15 >= 0))) {
      mediump ivec2 tmpvar_16;
      tmpvar_16.y = 0;
      tmpvar_16.x = ((tmpvar_15 * 24) + tmpvar_14);
      mediump vec4 tmpvar_17;
      tmpvar_17 = texelFetch (stain.mask, tmpvar_16, 0);
      fY_10 = ((tmpvar_11 * tmpvar_17.x) + (gScratchesColor * (1.0 - tmpvar_17.x)));
    };
  };
  if ((scratch.time > 0)) {
    mediump float tmpvar_18;
    tmpvar_18 = (float(x_9) - scratch.x);
    mediump float tmpvar_19;
    tmpvar_19 = (float(y_8) - scratch.y);
    mediump float tmpvar_20;
    tmpvar_20 = ((tmpvar_18 * scratch.vx) + (tmpvar_19 * scratch.vy));
    mediump float tmpvar_21;
    tmpvar_21 = ((tmpvar_18 * scratch.vy) - (tmpvar_19 * scratch.vx));
    if (((tmpvar_20 > 0.0) && (tmpvar_20 < scratch.len))) {
      mediump float tmpvar_22;
      tmpvar_22 = clamp ((abs(
        (tmpvar_21 - scratch.D[int(tmpvar_20)])
      ) * 0.5), 0.4, 1.0);
      fY_10 = ((fY_10 * tmpvar_22) + (gScratchesColor * (1.0 - tmpvar_22)));
    };
  };
  mediump float tmpvar_23;
  tmpvar_23 = float(x_9);
  mediump float tmpvar_24;
  tmpvar_24 = float(y_8);
  if (((scratch_v.time > 0) && ((tmpvar_23 > 
    (scratch_v.x[1] - 2.0)
  ) && (tmpvar_23 < 
    (scratch_v.x[1] + 2.0)
  )))) {
    highp float tmpvar_25;
    tmpvar_25 = ((7.0 * tmpvar_24) / noiseRes.y);
    highp int tmpvar_26;
    tmpvar_26 = int(tmpvar_25);
    highp float tmpvar_27;
    tmpvar_27 = fract(tmpvar_25);
    highp float tmpvar_28;
    tmpvar_28 = ((scratch_v.t[tmpvar_26] * (1.0 - tmpvar_27)) + (scratch_v.t[(tmpvar_26 + 1)] * tmpvar_27));
    highp float tmpvar_29;
    tmpvar_29 = clamp (abs((tmpvar_23 - 
      ((scratch_v.x[tmpvar_26] * (1.0 - tmpvar_27)) + (scratch_v.x[(tmpvar_26 + 1)] * tmpvar_27))
    )), gVerticalScratchIntensity, 1.0);
    fY_10 = (((
      (gScratchesColor * tmpvar_28)
     + 
      (fY_10 * (1.0 - tmpvar_28))
    ) * (1.0 - tmpvar_29)) + (fY_10 * tmpvar_29));
  };
  colorIn_7 = (tmpvar_6 * (fY_10 / tmpvar_11));
  highp vec2 tmpvar_30;
  tmpvar_30.x = vTextureCoord.x;
  tmpvar_30.y = (1.0 - vTextureCoord.y);
  highp vec2 tmpvar_31;
  tmpvar_31.x = srandomX;
  tmpvar_31.y = -(srandomY);
  lowp vec4 tmpvar_32;
  highp vec2 P_33;
  P_33 = (tmpvar_30 + tmpvar_31);
  tmpvar_32 = textureLod (framePerforationsTexture, P_33, 0.0);
  hawaiiFramePerforations_1 = tmpvar_32;
  highp vec3 tmpvar_34;
  tmpvar_34 = mix (colorIn_7, (hawaiiFramePerforations_1.xyz + perfColor), hawaiiFramePerforations_1.w);
  resultColor_2 = tmpvar_34;
  mediump vec4 tmpvar_35;
  tmpvar_35.w = 1.0;
  tmpvar_35.xyz = resultColor_2;
  fragColor = tmpvar_35;
}       