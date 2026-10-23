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
uniform highp float grainStrength;
uniform highp float grainSize;
uniform highp float grainSmoohtness;
uniform highp float grainChroma;
uniform highp float grainDarkLevel;
uniform mediump int seed;
uniform highp vec2 noiseRes;
uniform sampler2D noiseTexture;
out mediump vec4 fragColor;
void main ()
{
  mediump vec4 hawaiiFramePerforations_1;
  mediump vec3 resultColor_2;
  highp float tmpvar_3;
  tmpvar_3 = ((0.5 - (0.4 * grainSize)) * 2.0);
  highp vec2 tmpvar_4;
  tmpvar_4 = ((vTextureCoord * noiseRes) * tmpvar_3);
  highp vec3 tmpvar_5;
  highp vec4 result_6;
  highp float tmpvar_7;
  tmpvar_7 = (1.0 + (63.0 * pow (
    (1.0 - grainSmoohtness)
  , 6.0)));
  highp vec2 tmpvar_8;
  tmpvar_8 = floor(tmpvar_4);
  highp vec2 tmpvar_9;
  tmpvar_9 = fract(tmpvar_4);
  highp vec2 tmpvar_10;
  tmpvar_10 = (tmpvar_8 + vec2(0.5, 0.5));
  highp vec3 tmpvar_11;
  tmpvar_11.xy = tmpvar_10;
  mediump float tmpvar_12;
  tmpvar_12 = float(seed);
  tmpvar_11.z = tmpvar_12;
  highp vec3 tmpvar_13;
  tmpvar_13 = floor(tmpvar_11);
  highp vec3 tmpvar_14;
  tmpvar_14 = fract(tmpvar_11);
  highp vec3 tmpvar_15;
  tmpvar_15 = (tmpvar_14 * tmpvar_14);
  highp vec3 tmpvar_16;
  tmpvar_16 = ((tmpvar_14 * tmpvar_15) * ((10.0 - 
    (15.0 * tmpvar_14)
  ) + (6.0 * tmpvar_15)));
  lowp vec4 tmpvar_17;
  highp vec2 P_18;
  P_18 = (((
    (tmpvar_13.xy + (vec2(37.0, -17.0) * tmpvar_13.z))
   + tmpvar_16.xy) + 0.5) / 1024.0);
  tmpvar_17 = textureLod (noiseTexture, P_18, 0.0);
  lowp vec3 tmpvar_19;
  tmpvar_19 = mix (tmpvar_17.yxz, tmpvar_17.xzy, tmpvar_16.z);
  highp vec3 tmpvar_20;
  tmpvar_20 = tmpvar_19;
  highp vec2 tmpvar_21;
  tmpvar_21 = fract((tmpvar_20.xy * 10.0));
  lowp vec4 tmpvar_22;
  highp vec2 P_23;
  P_23 = (((tmpvar_10 + tmpvar_21) / noiseRes) / tmpvar_3);
  tmpvar_22 = textureLod (grainInputTexture, P_23, 0.0);
  highp vec2 x_24;
  x_24 = ((vec2(0.5, 0.5) - tmpvar_9) + tmpvar_21);
  highp float tmpvar_25;
  tmpvar_25 = clamp ((sqrt(
    dot (x_24, x_24)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_26;
  tmpvar_26 = pow ((1.0 - (tmpvar_25 * 
    (tmpvar_25 * (3.0 - (2.0 * tmpvar_25)))
  )), tmpvar_7);
  highp vec3 tmpvar_27;
  tmpvar_27 = (mix (tmpvar_20.zzz, tmpvar_20, grainChroma) * 2.0);
  highp vec3 tmpvar_28;
  tmpvar_28 = (tmpvar_27 * grainStrength);
  lowp vec3 tmpvar_29;
  tmpvar_29 = max ((1.0 - (2.0 * tmpvar_22.xyz)), 0.0);
  highp vec4 tmpvar_30;
  highp float tmpvar_31;
  tmpvar_31 = (1.4 - grainStrength);
  highp float tmpvar_32;
  tmpvar_32 = (0.5 * grainStrength);
  tmpvar_30.xyz = (((
    (tmpvar_22.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_27, grainStrength))
   + 
    (0.05 * tmpvar_28)
  ) + (
    ((grainDarkLevel * tmpvar_31) * (tmpvar_28 - tmpvar_32))
   * tmpvar_29)) * vec3(tmpvar_26));
  tmpvar_30.w = tmpvar_26;
  highp vec2 tmpvar_33;
  tmpvar_33 = (tmpvar_8 + vec2(-0.5, -0.5));
  highp vec3 tmpvar_34;
  tmpvar_34.xy = tmpvar_33;
  tmpvar_34.z = tmpvar_12;
  highp vec3 tmpvar_35;
  tmpvar_35 = floor(tmpvar_34);
  highp vec3 tmpvar_36;
  tmpvar_36 = fract(tmpvar_34);
  highp vec3 tmpvar_37;
  tmpvar_37 = (tmpvar_36 * tmpvar_36);
  highp vec3 tmpvar_38;
  tmpvar_38 = ((tmpvar_36 * tmpvar_37) * ((10.0 - 
    (15.0 * tmpvar_36)
  ) + (6.0 * tmpvar_37)));
  lowp vec4 tmpvar_39;
  highp vec2 P_40;
  P_40 = (((
    (tmpvar_35.xy + (vec2(37.0, -17.0) * tmpvar_35.z))
   + tmpvar_38.xy) + 0.5) / 1024.0);
  tmpvar_39 = textureLod (noiseTexture, P_40, 0.0);
  lowp vec3 tmpvar_41;
  tmpvar_41 = mix (tmpvar_39.yxz, tmpvar_39.xzy, tmpvar_38.z);
  highp vec3 tmpvar_42;
  tmpvar_42 = tmpvar_41;
  highp vec2 tmpvar_43;
  tmpvar_43 = fract((tmpvar_42.xy * 10.0));
  lowp vec4 tmpvar_44;
  highp vec2 P_45;
  P_45 = (((tmpvar_33 + tmpvar_43) / noiseRes) / tmpvar_3);
  tmpvar_44 = textureLod (grainInputTexture, P_45, 0.0);
  highp vec2 x_46;
  x_46 = ((vec2(-0.5, -0.5) - tmpvar_9) + tmpvar_43);
  highp float tmpvar_47;
  tmpvar_47 = clamp ((sqrt(
    dot (x_46, x_46)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_48;
  tmpvar_48 = pow ((1.0 - (tmpvar_47 * 
    (tmpvar_47 * (3.0 - (2.0 * tmpvar_47)))
  )), tmpvar_7);
  highp vec3 tmpvar_49;
  tmpvar_49 = (mix (tmpvar_42.zzz, tmpvar_42, grainChroma) * 2.0);
  highp vec3 tmpvar_50;
  tmpvar_50 = (tmpvar_49 * grainStrength);
  lowp vec3 tmpvar_51;
  tmpvar_51 = max ((1.0 - (2.0 * tmpvar_44.xyz)), 0.0);
  highp vec4 tmpvar_52;
  tmpvar_52.xyz = (((
    (tmpvar_44.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_49, grainStrength))
   + 
    (0.05 * tmpvar_50)
  ) + (
    ((grainDarkLevel * tmpvar_31) * (tmpvar_50 - tmpvar_32))
   * tmpvar_51)) * vec3(tmpvar_48));
  tmpvar_52.w = tmpvar_48;
  highp vec2 tmpvar_53;
  tmpvar_53 = (tmpvar_8 + vec2(0.5, -0.5));
  highp vec3 tmpvar_54;
  tmpvar_54.xy = tmpvar_53;
  tmpvar_54.z = tmpvar_12;
  highp vec3 tmpvar_55;
  tmpvar_55 = floor(tmpvar_54);
  highp vec3 tmpvar_56;
  tmpvar_56 = fract(tmpvar_54);
  highp vec3 tmpvar_57;
  tmpvar_57 = (tmpvar_56 * tmpvar_56);
  highp vec3 tmpvar_58;
  tmpvar_58 = ((tmpvar_56 * tmpvar_57) * ((10.0 - 
    (15.0 * tmpvar_56)
  ) + (6.0 * tmpvar_57)));
  lowp vec4 tmpvar_59;
  highp vec2 P_60;
  P_60 = (((
    (tmpvar_55.xy + (vec2(37.0, -17.0) * tmpvar_55.z))
   + tmpvar_58.xy) + 0.5) / 1024.0);
  tmpvar_59 = textureLod (noiseTexture, P_60, 0.0);
  lowp vec3 tmpvar_61;
  tmpvar_61 = mix (tmpvar_59.yxz, tmpvar_59.xzy, tmpvar_58.z);
  highp vec3 tmpvar_62;
  tmpvar_62 = tmpvar_61;
  highp vec2 tmpvar_63;
  tmpvar_63 = fract((tmpvar_62.xy * 10.0));
  lowp vec4 tmpvar_64;
  highp vec2 P_65;
  P_65 = (((tmpvar_53 + tmpvar_63) / noiseRes) / tmpvar_3);
  tmpvar_64 = textureLod (grainInputTexture, P_65, 0.0);
  highp vec2 x_66;
  x_66 = ((vec2(0.5, -0.5) - tmpvar_9) + tmpvar_63);
  highp float tmpvar_67;
  tmpvar_67 = clamp ((sqrt(
    dot (x_66, x_66)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_68;
  tmpvar_68 = pow ((1.0 - (tmpvar_67 * 
    (tmpvar_67 * (3.0 - (2.0 * tmpvar_67)))
  )), tmpvar_7);
  highp vec3 tmpvar_69;
  tmpvar_69 = (mix (tmpvar_62.zzz, tmpvar_62, grainChroma) * 2.0);
  highp vec3 tmpvar_70;
  tmpvar_70 = (tmpvar_69 * grainStrength);
  lowp vec3 tmpvar_71;
  tmpvar_71 = max ((1.0 - (2.0 * tmpvar_64.xyz)), 0.0);
  highp vec4 tmpvar_72;
  tmpvar_72.xyz = (((
    (tmpvar_64.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_69, grainStrength))
   + 
    (0.05 * tmpvar_70)
  ) + (
    ((grainDarkLevel * tmpvar_31) * (tmpvar_70 - tmpvar_32))
   * tmpvar_71)) * vec3(tmpvar_68));
  tmpvar_72.w = tmpvar_68;
  highp vec2 tmpvar_73;
  tmpvar_73 = (tmpvar_8 + vec2(-0.5, 0.5));
  highp vec3 tmpvar_74;
  tmpvar_74.xy = tmpvar_73;
  tmpvar_74.z = tmpvar_12;
  highp vec3 tmpvar_75;
  tmpvar_75 = floor(tmpvar_74);
  highp vec3 tmpvar_76;
  tmpvar_76 = fract(tmpvar_74);
  highp vec3 tmpvar_77;
  tmpvar_77 = (tmpvar_76 * tmpvar_76);
  highp vec3 tmpvar_78;
  tmpvar_78 = ((tmpvar_76 * tmpvar_77) * ((10.0 - 
    (15.0 * tmpvar_76)
  ) + (6.0 * tmpvar_77)));
  lowp vec4 tmpvar_79;
  highp vec2 P_80;
  P_80 = (((
    (tmpvar_75.xy + (vec2(37.0, -17.0) * tmpvar_75.z))
   + tmpvar_78.xy) + 0.5) / 1024.0);
  tmpvar_79 = textureLod (noiseTexture, P_80, 0.0);
  lowp vec3 tmpvar_81;
  tmpvar_81 = mix (tmpvar_79.yxz, tmpvar_79.xzy, tmpvar_78.z);
  highp vec3 tmpvar_82;
  tmpvar_82 = tmpvar_81;
  highp vec2 tmpvar_83;
  tmpvar_83 = fract((tmpvar_82.xy * 10.0));
  lowp vec4 tmpvar_84;
  highp vec2 P_85;
  P_85 = (((tmpvar_73 + tmpvar_83) / noiseRes) / tmpvar_3);
  tmpvar_84 = textureLod (grainInputTexture, P_85, 0.0);
  highp vec2 x_86;
  x_86 = ((vec2(-0.5, 0.5) - tmpvar_9) + tmpvar_83);
  highp float tmpvar_87;
  tmpvar_87 = clamp ((sqrt(
    dot (x_86, x_86)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_88;
  tmpvar_88 = pow ((1.0 - (tmpvar_87 * 
    (tmpvar_87 * (3.0 - (2.0 * tmpvar_87)))
  )), tmpvar_7);
  highp vec3 tmpvar_89;
  tmpvar_89 = (mix (tmpvar_82.zzz, tmpvar_82, grainChroma) * 2.0);
  highp vec3 tmpvar_90;
  tmpvar_90 = (tmpvar_89 * grainStrength);
  lowp vec3 tmpvar_91;
  tmpvar_91 = max ((1.0 - (2.0 * tmpvar_84.xyz)), 0.0);
  highp vec4 tmpvar_92;
  tmpvar_92.xyz = (((
    (tmpvar_84.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_89, grainStrength))
   + 
    (0.05 * tmpvar_90)
  ) + (
    ((grainDarkLevel * tmpvar_31) * (tmpvar_90 - tmpvar_32))
   * tmpvar_91)) * vec3(tmpvar_88));
  tmpvar_92.w = tmpvar_88;
  result_6 = ((tmpvar_30 + tmpvar_52) + (tmpvar_72 + tmpvar_92));
  tmpvar_5 = (result_6.xyz / result_6.w);
  mediump vec3 tmpvar_93;
  tmpvar_93 = tmpvar_5;
  mediump vec4 tmpvar_94;
  tmpvar_94 = textureLod (mLutID, tmpvar_93, 0.0);
  mediump vec3 tmpvar_95;
  tmpvar_95 = mix (vec3(dot (tmpvar_94.xyz, vec3(0.2125, 0.7154, 0.0721))), tmpvar_94.xyz, saturation);
  mediump vec3 colorIn_96;
  colorIn_96 = tmpvar_95;
  mediump int y_97;
  mediump int x_98;
  mediump float fY_99;
  mediump float tmpvar_100;
  tmpvar_100 = (((tmpvar_95.x + tmpvar_95.y) + tmpvar_95.z) / 3.0);
  fY_99 = tmpvar_100;
  highp int tmpvar_101;
  tmpvar_101 = int((vTextureCoord.x * noiseRes.x));
  x_98 = tmpvar_101;
  highp int tmpvar_102;
  tmpvar_102 = int((vTextureCoord.y * noiseRes.y));
  y_97 = tmpvar_102;
  if ((stain.time > 0)) {
    mediump int tmpvar_103;
    tmpvar_103 = (x_98 - stain.x);
    mediump int tmpvar_104;
    tmpvar_104 = (y_97 - stain.y);
    if ((((
      (tmpvar_103 < stain.w)
     && 
      (tmpvar_104 < stain.h)
    ) && (tmpvar_103 >= 0)) && (tmpvar_104 >= 0))) {
      mediump ivec2 tmpvar_105;
      tmpvar_105.y = 0;
      tmpvar_105.x = ((tmpvar_104 * 24) + tmpvar_103);
      mediump vec4 tmpvar_106;
      tmpvar_106 = texelFetch (stain.mask, tmpvar_105, 0);
      fY_99 = ((tmpvar_100 * tmpvar_106.x) + (gScratchesColor * (1.0 - tmpvar_106.x)));
    };
  };
  if ((scratch.time > 0)) {
    mediump float tmpvar_107;
    tmpvar_107 = (float(x_98) - scratch.x);
    mediump float tmpvar_108;
    tmpvar_108 = (float(y_97) - scratch.y);
    mediump float tmpvar_109;
    tmpvar_109 = ((tmpvar_107 * scratch.vx) + (tmpvar_108 * scratch.vy));
    mediump float tmpvar_110;
    tmpvar_110 = ((tmpvar_107 * scratch.vy) - (tmpvar_108 * scratch.vx));
    if (((tmpvar_109 > 0.0) && (tmpvar_109 < scratch.len))) {
      mediump float tmpvar_111;
      tmpvar_111 = clamp ((abs(
        (tmpvar_110 - scratch.D[int(tmpvar_109)])
      ) * 0.5), 0.4, 1.0);
      fY_99 = ((fY_99 * tmpvar_111) + (gScratchesColor * (1.0 - tmpvar_111)));
    };
  };
  mediump float tmpvar_112;
  tmpvar_112 = float(x_98);
  mediump float tmpvar_113;
  tmpvar_113 = float(y_97);
  if (((scratch_v.time > 0) && ((tmpvar_112 > 
    (scratch_v.x[1] - 2.0)
  ) && (tmpvar_112 < 
    (scratch_v.x[1] + 2.0)
  )))) {
    highp float tmpvar_114;
    tmpvar_114 = ((7.0 * tmpvar_113) / noiseRes.y);
    highp int tmpvar_115;
    tmpvar_115 = int(tmpvar_114);
    highp float tmpvar_116;
    tmpvar_116 = fract(tmpvar_114);
    highp float tmpvar_117;
    tmpvar_117 = ((scratch_v.t[tmpvar_115] * (1.0 - tmpvar_116)) + (scratch_v.t[(tmpvar_115 + 1)] * tmpvar_116));
    highp float tmpvar_118;
    tmpvar_118 = clamp (abs((tmpvar_112 - 
      ((scratch_v.x[tmpvar_115] * (1.0 - tmpvar_116)) + (scratch_v.x[(tmpvar_115 + 1)] * tmpvar_116))
    )), gVerticalScratchIntensity, 1.0);
    fY_99 = (((
      (gScratchesColor * tmpvar_117)
     + 
      (fY_99 * (1.0 - tmpvar_117))
    ) * (1.0 - tmpvar_118)) + (fY_99 * tmpvar_118));
  };
  colorIn_96 = (tmpvar_95 * (fY_99 / tmpvar_100));
  highp vec2 tmpvar_119;
  tmpvar_119.x = vTextureCoord.x;
  tmpvar_119.y = (1.0 - vTextureCoord.y);
  highp vec2 tmpvar_120;
  tmpvar_120.x = srandomX;
  tmpvar_120.y = -(srandomY);
  lowp vec4 tmpvar_121;
  highp vec2 P_122;
  P_122 = (tmpvar_119 + tmpvar_120);
  tmpvar_121 = textureLod (framePerforationsTexture, P_122, 0.0);
  hawaiiFramePerforations_1 = tmpvar_121;
  highp vec3 tmpvar_123;
  tmpvar_123 = mix (colorIn_96, (hawaiiFramePerforations_1.xyz + perfColor), hawaiiFramePerforations_1.w);
  resultColor_2 = tmpvar_123;
  mediump vec4 tmpvar_124;
  tmpvar_124.w = 1.0;
  tmpvar_124.xyz = resultColor_2;
  fragColor = tmpvar_124;
}