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
  highp vec2 tmpvar_5;
  tmpvar_5 = (vTextureCoord * noiseRes);
  tmpvar_4 = (tmpvar_5 * tmpvar_3);
  highp vec3 tmpvar_6;
  highp vec4 result_7;
  highp float tmpvar_8;
  tmpvar_8 = (1.0 + (63.0 * pow (
    (1.0 - grainSmoohtness)
  , 6.0)));
  highp vec2 tmpvar_9;
  tmpvar_9 = floor(tmpvar_4);
  highp vec2 tmpvar_10;
  tmpvar_10 = fract(tmpvar_4);
  highp vec2 tmpvar_11;
  tmpvar_11 = (tmpvar_9 + vec2(0.5, 0.5));
  highp vec3 tmpvar_12;
  tmpvar_12.xy = tmpvar_11;
  mediump float tmpvar_13;
  tmpvar_13 = float(seed);
  tmpvar_12.z = tmpvar_13;
  highp vec3 tmpvar_14;
  tmpvar_14 = floor(tmpvar_12);
  highp vec3 tmpvar_15;
  tmpvar_15 = fract(tmpvar_12);
  highp vec3 tmpvar_16;
  tmpvar_16 = (tmpvar_15 * tmpvar_15);
  highp vec3 tmpvar_17;
  tmpvar_17 = ((tmpvar_15 * tmpvar_16) * ((10.0 - 
    (15.0 * tmpvar_15)
  ) + (6.0 * tmpvar_16)));
  lowp vec4 tmpvar_18;
  highp vec2 P_19;
  P_19 = (((
    (tmpvar_14.xy + (vec2(37.0, -17.0) * tmpvar_14.z))
   + tmpvar_17.xy) + 0.5) / 1024.0);
  tmpvar_18 = textureLod (noiseTexture, P_19, 0.0);
  lowp vec3 tmpvar_20;
  tmpvar_20 = mix (tmpvar_18.yxz, tmpvar_18.xzy, tmpvar_17.z);
  highp vec3 tmpvar_21;
  tmpvar_21 = tmpvar_20;
  highp vec2 tmpvar_22;
  tmpvar_22 = fract((tmpvar_21.xy * 10.0));
  lowp vec4 tmpvar_23;
  highp vec2 P_24;
  P_24 = (((tmpvar_11 + tmpvar_22) / noiseRes) / tmpvar_3);
  tmpvar_23 = textureLod (grainInputTexture, P_24, 0.0);
  highp vec2 x_25;
  x_25 = ((vec2(0.5, 0.5) - tmpvar_10) + tmpvar_22);
  highp float tmpvar_26;
  tmpvar_26 = clamp ((sqrt(
    dot (x_25, x_25)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_27;
  tmpvar_27 = pow ((1.0 - (tmpvar_26 * 
    (tmpvar_26 * (3.0 - (2.0 * tmpvar_26)))
  )), tmpvar_8);
  highp vec3 tmpvar_28;
  tmpvar_28 = (mix (tmpvar_21.zzz, tmpvar_21, grainChroma) * 2.0);
  highp vec3 tmpvar_29;
  tmpvar_29 = (tmpvar_28 * grainStrength);
  lowp vec3 tmpvar_30;
  tmpvar_30 = max ((1.0 - (2.0 * tmpvar_23.xyz)), 0.0);
  highp vec4 tmpvar_31;
  highp float tmpvar_32;
  tmpvar_32 = (1.4 - grainStrength);
  highp float tmpvar_33;
  tmpvar_33 = (0.5 * grainStrength);
  tmpvar_31.xyz = (((
    (tmpvar_23.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_28, grainStrength))
   + 
    (0.05 * tmpvar_29)
  ) + (
    ((grainDarkLevel * tmpvar_32) * (tmpvar_29 - tmpvar_33))
   * tmpvar_30)) * vec3(tmpvar_27));
  tmpvar_31.w = tmpvar_27;
  highp vec2 tmpvar_34;
  tmpvar_34 = (tmpvar_9 + vec2(-0.5, -0.5));
  highp vec3 tmpvar_35;
  tmpvar_35.xy = tmpvar_34;
  tmpvar_35.z = tmpvar_13;
  highp vec3 tmpvar_36;
  tmpvar_36 = floor(tmpvar_35);
  highp vec3 tmpvar_37;
  tmpvar_37 = fract(tmpvar_35);
  highp vec3 tmpvar_38;
  tmpvar_38 = (tmpvar_37 * tmpvar_37);
  highp vec3 tmpvar_39;
  tmpvar_39 = ((tmpvar_37 * tmpvar_38) * ((10.0 - 
    (15.0 * tmpvar_37)
  ) + (6.0 * tmpvar_38)));
  lowp vec4 tmpvar_40;
  highp vec2 P_41;
  P_41 = (((
    (tmpvar_36.xy + (vec2(37.0, -17.0) * tmpvar_36.z))
   + tmpvar_39.xy) + 0.5) / 1024.0);
  tmpvar_40 = textureLod (noiseTexture, P_41, 0.0);
  lowp vec3 tmpvar_42;
  tmpvar_42 = mix (tmpvar_40.yxz, tmpvar_40.xzy, tmpvar_39.z);
  highp vec3 tmpvar_43;
  tmpvar_43 = tmpvar_42;
  highp vec2 tmpvar_44;
  tmpvar_44 = fract((tmpvar_43.xy * 10.0));
  lowp vec4 tmpvar_45;
  highp vec2 P_46;
  P_46 = (((tmpvar_34 + tmpvar_44) / noiseRes) / tmpvar_3);
  tmpvar_45 = textureLod (grainInputTexture, P_46, 0.0);
  highp vec2 x_47;
  x_47 = ((vec2(-0.5, -0.5) - tmpvar_10) + tmpvar_44);
  highp float tmpvar_48;
  tmpvar_48 = clamp ((sqrt(
    dot (x_47, x_47)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_49;
  tmpvar_49 = pow ((1.0 - (tmpvar_48 * 
    (tmpvar_48 * (3.0 - (2.0 * tmpvar_48)))
  )), tmpvar_8);
  highp vec3 tmpvar_50;
  tmpvar_50 = (mix (tmpvar_43.zzz, tmpvar_43, grainChroma) * 2.0);
  highp vec3 tmpvar_51;
  tmpvar_51 = (tmpvar_50 * grainStrength);
  lowp vec3 tmpvar_52;
  tmpvar_52 = max ((1.0 - (2.0 * tmpvar_45.xyz)), 0.0);
  highp vec4 tmpvar_53;
  tmpvar_53.xyz = (((
    (tmpvar_45.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_50, grainStrength))
   + 
    (0.05 * tmpvar_51)
  ) + (
    ((grainDarkLevel * tmpvar_32) * (tmpvar_51 - tmpvar_33))
   * tmpvar_52)) * vec3(tmpvar_49));
  tmpvar_53.w = tmpvar_49;
  highp vec2 tmpvar_54;
  tmpvar_54 = (tmpvar_9 + vec2(0.5, -0.5));
  highp vec3 tmpvar_55;
  tmpvar_55.xy = tmpvar_54;
  tmpvar_55.z = tmpvar_13;
  highp vec3 tmpvar_56;
  tmpvar_56 = floor(tmpvar_55);
  highp vec3 tmpvar_57;
  tmpvar_57 = fract(tmpvar_55);
  highp vec3 tmpvar_58;
  tmpvar_58 = (tmpvar_57 * tmpvar_57);
  highp vec3 tmpvar_59;
  tmpvar_59 = ((tmpvar_57 * tmpvar_58) * ((10.0 - 
    (15.0 * tmpvar_57)
  ) + (6.0 * tmpvar_58)));
  lowp vec4 tmpvar_60;
  highp vec2 P_61;
  P_61 = (((
    (tmpvar_56.xy + (vec2(37.0, -17.0) * tmpvar_56.z))
   + tmpvar_59.xy) + 0.5) / 1024.0);
  tmpvar_60 = textureLod (noiseTexture, P_61, 0.0);
  lowp vec3 tmpvar_62;
  tmpvar_62 = mix (tmpvar_60.yxz, tmpvar_60.xzy, tmpvar_59.z);
  highp vec3 tmpvar_63;
  tmpvar_63 = tmpvar_62;
  highp vec2 tmpvar_64;
  tmpvar_64 = fract((tmpvar_63.xy * 10.0));
  lowp vec4 tmpvar_65;
  highp vec2 P_66;
  P_66 = (((tmpvar_54 + tmpvar_64) / noiseRes) / tmpvar_3);
  tmpvar_65 = textureLod (grainInputTexture, P_66, 0.0);
  highp vec2 x_67;
  x_67 = ((vec2(0.5, -0.5) - tmpvar_10) + tmpvar_64);
  highp float tmpvar_68;
  tmpvar_68 = clamp ((sqrt(
    dot (x_67, x_67)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_69;
  tmpvar_69 = pow ((1.0 - (tmpvar_68 * 
    (tmpvar_68 * (3.0 - (2.0 * tmpvar_68)))
  )), tmpvar_8);
  highp vec3 tmpvar_70;
  tmpvar_70 = (mix (tmpvar_63.zzz, tmpvar_63, grainChroma) * 2.0);
  highp vec3 tmpvar_71;
  tmpvar_71 = (tmpvar_70 * grainStrength);
  lowp vec3 tmpvar_72;
  tmpvar_72 = max ((1.0 - (2.0 * tmpvar_65.xyz)), 0.0);
  highp vec4 tmpvar_73;
  tmpvar_73.xyz = (((
    (tmpvar_65.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_70, grainStrength))
   + 
    (0.05 * tmpvar_71)
  ) + (
    ((grainDarkLevel * tmpvar_32) * (tmpvar_71 - tmpvar_33))
   * tmpvar_72)) * vec3(tmpvar_69));
  tmpvar_73.w = tmpvar_69;
  highp vec2 tmpvar_74;
  tmpvar_74 = (tmpvar_9 + vec2(-0.5, 0.5));
  highp vec3 tmpvar_75;
  tmpvar_75.xy = tmpvar_74;
  tmpvar_75.z = tmpvar_13;
  highp vec3 tmpvar_76;
  tmpvar_76 = floor(tmpvar_75);
  highp vec3 tmpvar_77;
  tmpvar_77 = fract(tmpvar_75);
  highp vec3 tmpvar_78;
  tmpvar_78 = (tmpvar_77 * tmpvar_77);
  highp vec3 tmpvar_79;
  tmpvar_79 = ((tmpvar_77 * tmpvar_78) * ((10.0 - 
    (15.0 * tmpvar_77)
  ) + (6.0 * tmpvar_78)));
  lowp vec4 tmpvar_80;
  highp vec2 P_81;
  P_81 = (((
    (tmpvar_76.xy + (vec2(37.0, -17.0) * tmpvar_76.z))
   + tmpvar_79.xy) + 0.5) / 1024.0);
  tmpvar_80 = textureLod (noiseTexture, P_81, 0.0);
  lowp vec3 tmpvar_82;
  tmpvar_82 = mix (tmpvar_80.yxz, tmpvar_80.xzy, tmpvar_79.z);
  highp vec3 tmpvar_83;
  tmpvar_83 = tmpvar_82;
  highp vec2 tmpvar_84;
  tmpvar_84 = fract((tmpvar_83.xy * 10.0));
  lowp vec4 tmpvar_85;
  highp vec2 P_86;
  P_86 = (((tmpvar_74 + tmpvar_84) / noiseRes) / tmpvar_3);
  tmpvar_85 = textureLod (grainInputTexture, P_86, 0.0);
  highp vec2 x_87;
  x_87 = ((vec2(-0.5, 0.5) - tmpvar_10) + tmpvar_84);
  highp float tmpvar_88;
  tmpvar_88 = clamp ((sqrt(
    dot (x_87, x_87)
  ) / 2.828), 0.0, 1.0);
  highp float tmpvar_89;
  tmpvar_89 = pow ((1.0 - (tmpvar_88 * 
    (tmpvar_88 * (3.0 - (2.0 * tmpvar_88)))
  )), tmpvar_8);
  highp vec3 tmpvar_90;
  tmpvar_90 = (mix (tmpvar_83.zzz, tmpvar_83, grainChroma) * 2.0);
  highp vec3 tmpvar_91;
  tmpvar_91 = (tmpvar_90 * grainStrength);
  lowp vec3 tmpvar_92;
  tmpvar_92 = max ((1.0 - (2.0 * tmpvar_85.xyz)), 0.0);
  highp vec4 tmpvar_93;
  tmpvar_93.xyz = (((
    (tmpvar_85.xyz * mix (vec3(1.0, 1.0, 1.0), tmpvar_90, grainStrength))
   + 
    (0.05 * tmpvar_91)
  ) + (
    ((grainDarkLevel * tmpvar_32) * (tmpvar_91 - tmpvar_33))
   * tmpvar_92)) * vec3(tmpvar_89));
  tmpvar_93.w = tmpvar_89;
  result_7 = ((tmpvar_31 + tmpvar_53) + (tmpvar_73 + tmpvar_93));
  tmpvar_6 = (result_7.xyz / result_7.w);
  mediump vec3 tmpvar_94;
  tmpvar_94 = tmpvar_6;
  mediump vec4 tmpvar_95;
  tmpvar_95 = textureLod (mLutID, tmpvar_94, 0.0);
  mediump vec3 tmpvar_96;
  tmpvar_96 = mix (vec3(dot (tmpvar_95.xyz, vec3(0.2125, 0.7154, 0.0721))), tmpvar_95.xyz, saturation);
  mediump vec3 colorIn_97;
  colorIn_97 = tmpvar_96;
  mediump float WV_98;
  lowp float W_99;
  mediump ivec2 uv_100;
  mediump float fY_101;
  mediump float tmpvar_102;
  tmpvar_102 = (((tmpvar_96.x + tmpvar_96.y) + tmpvar_96.z) / 3.0);
  fY_101 = tmpvar_102;
  highp ivec2 tmpvar_103;
  tmpvar_103 = ivec2(tmpvar_5);
  uv_100 = tmpvar_103;
  lowp ivec2 tmpvar_104;
  tmpvar_104.x = stain.x;
  tmpvar_104.y = stain.y;
  mediump ivec2 tmpvar_105;
  tmpvar_105 = (uv_100 - tmpvar_104);
  mediump ivec4 tmpvar_106;
  tmpvar_106.x = stain.w;
  tmpvar_106.y = stain.h;
  tmpvar_106.zw = tmpvar_105;
  mediump ivec4 tmpvar_107;
  tmpvar_107.zw = ivec2(-1, -1);
  tmpvar_107.xy = tmpvar_105;
  bvec4 tmpvar_108;
  tmpvar_108 = greaterThan (tmpvar_106, tmpvar_107);
  mediump int tmpvar_109;
  tmpvar_109 = clamp (((tmpvar_105.y * 24) + tmpvar_105.x), 0, 576);
  lowp float tmpvar_110;
  tmpvar_110 = stain.mask[tmpvar_109];
  bool tmpvar_111;
  if ((stain.time > 0)) {
    tmpvar_111 = ((tmpvar_108.x && tmpvar_108.y) && (tmpvar_108.z && tmpvar_108.w));
  } else {
    tmpvar_111 = bool(0);
  };
  mediump float tmpvar_112;
  lowp float a_113;
  a_113 = float(tmpvar_111);
  tmpvar_112 = mix (tmpvar_102, ((tmpvar_102 * tmpvar_110) + (gScratchesColor * 
    (1.0 - tmpvar_110)
  )), a_113);
  fY_101 = tmpvar_112;
  lowp vec2 tmpvar_114;
  tmpvar_114.x = scratch.x;
  tmpvar_114.y = scratch.y;
  mediump vec2 tmpvar_115;
  tmpvar_115 = (vec2(uv_100) - tmpvar_114);
  mediump vec2 tmpvar_116;
  tmpvar_116.x = ((tmpvar_115.x * scratch.vx) + (tmpvar_115.y * scratch.vy));
  tmpvar_116.y = ((tmpvar_115.x * scratch.vy) - (tmpvar_115.y * scratch.vx));
  mediump vec2 tmpvar_117;
  tmpvar_117.x = tmpvar_116.x;
  tmpvar_117.y = scratch.len;
  mediump vec2 tmpvar_118;
  tmpvar_118.x = 0.0;
  tmpvar_118.y = tmpvar_116.x;
  bvec2 tmpvar_119;
  tmpvar_119 = greaterThan (tmpvar_117, tmpvar_118);
  mediump int tmpvar_120;
  tmpvar_120 = clamp (int(tmpvar_116.x), 0, 100);
  mediump float tmpvar_121;
  tmpvar_121 = clamp ((abs(
    (tmpvar_116.y - scratch.D[tmpvar_120])
  ) * 0.5), 0.4, 1.0);
  W_99 = tmpvar_121;
  bool tmpvar_122;
  if ((scratch.time > 0)) {
    tmpvar_122 = (tmpvar_119.x && tmpvar_119.y);
  } else {
    tmpvar_122 = bool(0);
  };
  mediump float tmpvar_123;
  lowp float a_124;
  a_124 = float(tmpvar_122);
  tmpvar_123 = mix (tmpvar_112, ((tmpvar_112 * W_99) + (gScratchesColor * 
    (1.0 - W_99)
  )), a_124);
  fY_101 = tmpvar_123;
  lowp float tmpvar_125;
  tmpvar_125 = scratch_v.x[1];
  mediump vec2 tmpvar_126;
  tmpvar_126.x = float(uv_100.x);
  tmpvar_126.y = (tmpvar_125 + 2.0);
  mediump vec2 tmpvar_127;
  tmpvar_127.x = (tmpvar_125 - 2.0);
  tmpvar_127.y = float(uv_100.x);
  bvec2 tmpvar_128;
  tmpvar_128 = greaterThan (tmpvar_126, tmpvar_127);
  highp float tmpvar_129;
  tmpvar_129 = ((7.0 * float(uv_100.y)) / noiseRes.y);
  highp int tmpvar_130;
  tmpvar_130 = int(tmpvar_129);
  highp float tmpvar_131;
  tmpvar_131 = fract(tmpvar_129);
  highp float tmpvar_132;
  tmpvar_132 = ((scratch_v.t[tmpvar_130] * (1.0 - tmpvar_131)) + (scratch_v.t[(tmpvar_130 + 1)] * tmpvar_131));
  highp float tmpvar_133;
  tmpvar_133 = clamp (abs((
    float(uv_100.x)
   - 
    ((scratch_v.x[tmpvar_130] * (1.0 - tmpvar_131)) + (scratch_v.x[(tmpvar_130 + 1)] * tmpvar_131))
  )), gVerticalScratchIntensity, 1.0);
  WV_98 = tmpvar_133;
  bool tmpvar_134;
  if ((scratch_v.time > 0)) {
    tmpvar_134 = (tmpvar_128.x && tmpvar_128.y);
  } else {
    tmpvar_134 = bool(0);
  };
  highp float tmpvar_135;
  lowp float a_136;
  a_136 = float(tmpvar_134);
  tmpvar_135 = mix (tmpvar_123, ((
    ((gScratchesColor * tmpvar_132) + (tmpvar_123 * (1.0 - tmpvar_132)))
   * 
    (1.0 - WV_98)
  ) + (tmpvar_123 * WV_98)), a_136);
  fY_101 = tmpvar_135;
  colorIn_97 = (tmpvar_96 * (fY_101 / tmpvar_102));
  highp vec2 tmpvar_137;
  tmpvar_137.x = vTextureCoord.x;
  tmpvar_137.y = (1.0 - vTextureCoord.y);
  highp vec2 tmpvar_138;
  tmpvar_138.x = srandomX;
  tmpvar_138.y = -(srandomY);
  lowp vec4 tmpvar_139;
  highp vec2 P_140;
  P_140 = (tmpvar_137 + tmpvar_138);
  tmpvar_139 = textureLod (framePerforationsTexture, P_140, 0.0);
  hawaiiFramePerforations_1 = tmpvar_139;
  highp vec3 tmpvar_141;
  tmpvar_141 = mix (colorIn_97, (hawaiiFramePerforations_1.xyz + perfColor), hawaiiFramePerforations_1.w);
  resultColor_2 = tmpvar_141;
  mediump vec4 tmpvar_142;
  tmpvar_142.w = 1.0;
  tmpvar_142.xyz = resultColor_2;
  fragColor = tmpvar_142;
}