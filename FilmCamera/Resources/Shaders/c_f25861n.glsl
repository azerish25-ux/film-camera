#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;

struct LightLeak {
  float amp;
  float top;
  float topMultiplier;
  float bottom;
  float bottomMultiplier;
};
struct Holes {
  float internalOffset;
  float externalOffset;
  float seed;
  float amp;
  vec2 amountY;
  vec2 amountX;
  vec2 xMultiplier;
};
in highp vec2 vTextureCoord;
uniform sampler2D textureInPass3;
uniform sampler2D textureLuminance;
uniform mediump vec3 curve[66];
uniform highp float srandomX;
uniform highp float srandomY;
uniform float filmBreathR;
uniform float filmBreathG;
uniform float filmBreathB;
uniform samplerExternalOES lightLeakTexture;
uniform highp int usingLightLeak;
uniform sampler2D framePerforationsTexture;
uniform float luminanceMipmapLevel;
uniform float expiredFoggingAmp;
uniform LightLeak lightLeak;
uniform Holes holes;
out mediump vec4 fragColor;


void main ()
{
  mediump float holesShiftY_1;
  mediump float holesStencil_2;
  mediump float holesMaskBottom_3;
  mediump float holesMaskTop_4;
  mediump vec3 holesLinear_5;
  mediump float llVerticalMask_6;
  mediump float llBottomMask_7;
  mediump float llTopMask_8;
  mediump float screenLuminance_9;
  mediump float foggingMask_10;
  mediump vec3 lightLeakColor_11;
  mediump vec3 filmBurnColor_12;
  highp vec3 f_13;
  lowp vec3 tmpvar_14;
  tmpvar_14 = (textureLod (textureInPass3, vTextureCoord, 0.0).xyz * 63.0);
  lowp ivec3 tmpvar_15;
  tmpvar_15 = ivec3(tmpvar_14);
  lowp vec3 tmpvar_16;
  tmpvar_16 = (tmpvar_14 - vec3(tmpvar_15));
  f_13 = tmpvar_16;
  lowp ivec3 tmpvar_17;
  tmpvar_17 = clamp ((tmpvar_15 + 1), 1, 64);
  mediump vec3 tmpvar_18;
  tmpvar_18.x = curve[tmpvar_17.x].x;
  tmpvar_18.y = curve[tmpvar_17.y].y;
  tmpvar_18.z = curve[tmpvar_17.z].z;
  mediump vec3 tmpvar_19;
  tmpvar_19.x = curve[(tmpvar_17.x + 1)].x;
  tmpvar_19.y = curve[(tmpvar_17.y + 1)].y;
  tmpvar_19.z = curve[(tmpvar_17.z + 1)].z;
  vec3 tmpvar_20;
  tmpvar_20.x = filmBreathR;
  tmpvar_20.y = filmBreathG;
  tmpvar_20.z = filmBreathB;
  highp vec3 tmpvar_21;
  tmpvar_21 = (mix (tmpvar_18, tmpvar_19, clamp (f_13, 0.0, 1.0)) + tmpvar_20);
  if ((usingLightLeak == 1)) {
    highp vec2 tmpvar_22;
    tmpvar_22.x = (vTextureCoord.x + srandomX);
    tmpvar_22.y = ((1.0 - vTextureCoord.y) - srandomY);
    lowp vec4 tmpvar_23;
    tmpvar_23 = texture (lightLeakTexture, tmpvar_22);
    highp vec3 x_24;
    x_24 = tmpvar_23.xyz;
    highp vec3 tmpvar_25;
    tmpvar_25 = pow (((
      ((exp2(x_24) - 1.0) - (x_24 * 0.693147))
     * 3.258891) + (
      ((exp2(tmpvar_21) - 1.0) - (tmpvar_21 * 0.693147))
     * 3.258891)), vec3(0.4545455, 0.4545455, 0.4545455));
    filmBurnColor_12 = tmpvar_25;
  } else {
    filmBurnColor_12 = tmpvar_21;
  };
  highp float tmpvar_26;
  highp float tmpvar_27;
  tmpvar_27 = (vTextureCoord.x + srandomX);
  highp float tmpvar_28;
  tmpvar_28 = (tmpvar_27 - 0.375);
  tmpvar_26 = (tmpvar_28 * tmpvar_28);
  foggingMask_10 = (2.5 * tmpvar_26);
  lowp vec3 tmpvar_29;
  tmpvar_29 = vec3(dot (textureLod (textureLuminance, vec2(0.8, 0.5), luminanceMipmapLevel).xyz, vec3(0.2125, 0.7154, 0.0721)));
  screenLuminance_9 = tmpvar_29.x;
  float tmpvar_30;
  tmpvar_30 = clamp ((lightLeak.top / 0.03), 0.0, 1.0);
  highp float tmpvar_31;
  tmpvar_31 = mix (1.0, (lightLeak.topMultiplier * pow (
    abs((tmpvar_27 - 0.625))
  , 
    (clamp (lightLeak.top, 0.03, 1.0) * 40.0)
  )), (tmpvar_30 * (tmpvar_30 * 
    (3.0 - (2.0 * tmpvar_30))
  )));
  llTopMask_8 = tmpvar_31;
  float tmpvar_32;
  tmpvar_32 = clamp ((lightLeak.top / 0.03), 0.0, 1.0);
  highp float tmpvar_33;
  tmpvar_33 = mix (1.0, (lightLeak.bottomMultiplier * pow (
    abs((tmpvar_27 - 0.625))
  , 
    (clamp (lightLeak.bottom, 0.03, 1.0) * 40.0)
  )), (tmpvar_32 * (tmpvar_32 * 
    (3.0 - (2.0 * tmpvar_32))
  )));
  llBottomMask_7 = tmpvar_33;
  highp float tmpvar_34;
  highp float tmpvar_35;
  tmpvar_35 = clamp ((vTextureCoord.y + srandomY), 0.0, 1.0);
  tmpvar_34 = (tmpvar_35 * (tmpvar_35 * (3.0 - 
    (2.0 * tmpvar_35)
  )));
  llVerticalMask_6 = tmpvar_34;
  mediump float tmpvar_36;
  tmpvar_36 = mix (llBottomMask_7, llTopMask_8, llVerticalMask_6);
  highp float tmpvar_37;
  tmpvar_37 = (float(mod ((float(mod ((
    (1.0 - vTextureCoord.y)
   - holes.seed), holes.internalOffset))), holes.externalOffset)));
  holesShiftY_1 = tmpvar_37;
  highp vec2 tmpvar_38;
  tmpvar_38.x = vTextureCoord.x;
  tmpvar_38.y = holesShiftY_1;
  highp vec2 tmpvar_39;
  tmpvar_39.x = srandomX;
  tmpvar_39.y = -(srandomY);
  lowp vec4 tmpvar_40;
  highp vec2 P_41;
  P_41 = (tmpvar_38 + tmpvar_39);
  tmpvar_40 = textureLod (framePerforationsTexture, P_41, 0.0);
  holesStencil_2 = tmpvar_40.w;
  highp float tmpvar_42;
  tmpvar_42 = pow (abs((tmpvar_27 - 0.625)), (holes.amountX.x * 40.0));
  holesMaskTop_4 = ((holes.xMultiplier.x * tmpvar_42) * max (0.0, (1.0 - 
    (7.5957 * pow (abs((holesShiftY_1 - holes.amountY.x)), 1.5))
  )));
  highp float tmpvar_43;
  tmpvar_43 = pow (abs((tmpvar_27 - 0.625)), (holes.amountX.y * 40.0));
  holesMaskBottom_3 = ((holes.xMultiplier.y * tmpvar_43) * max (0.0, (1.0 - 
    (7.5957 * pow (abs((holesShiftY_1 - holes.amountY.y)), 1.5))
  )));
  mediump float tmpvar_44;
  tmpvar_44 = mix (holesMaskBottom_3, holesMaskTop_4, llVerticalMask_6);
  highp vec3 x_45;
  x_45 = (((holesStencil_2 * tmpvar_44) * vec3(0.6, 0.5, 1.0)) * holes.amp);
  highp vec3 tmpvar_46;
  tmpvar_46 = clamp (((
    (exp2(x_45) - 1.0)
   - 
    (x_45 * 0.693147)
  ) * 3.258891), 0.0, 1.0);
  holesLinear_5 = tmpvar_46;
  highp vec3 x_47;
  x_47 = filmBurnColor_12;
  highp vec3 x_48;
  x_48 = (((foggingMask_10 * vec3(0.6, 0.5, 1.0)) * expiredFoggingAmp) * (1.0 - screenLuminance_9));
  highp vec3 x_49;
  x_49 = ((tmpvar_36 * vec3(1.0, 0.0, 0.0)) * lightLeak.amp);
  highp vec3 tmpvar_50;
  tmpvar_50 = pow (((
    ((((
      exp2(x_47)
     - 1.0) - (x_47 * 0.693147)) * 3.258891) + (((
      exp2(x_48)
     - 1.0) - (x_48 * 0.693147)) * 3.258891))
   + 
    clamp ((((
      exp2(x_49)
     - 1.0) - (x_49 * 0.693147)) * 3.258891), 0.0, 1.0)
  ) + holesLinear_5), vec3(0.4545455, 0.4545455, 0.4545455));
  lightLeakColor_11 = tmpvar_50;
  mediump vec4 tmpvar_51;
  tmpvar_51.w = 1.0;
  tmpvar_51.xyz = lightLeakColor_11;
  fragColor = tmpvar_51;
}                