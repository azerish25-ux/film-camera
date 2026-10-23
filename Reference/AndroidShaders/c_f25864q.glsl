uniform samplerExternalOES frameTexture;
uniform sampler2D frameSuper16mm;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;

vec4 frame(){
  mediump vec3 processedColorLinear_1;
  highp float yCenterShift_2;
  highp float xcoord_3;
  lowp vec4 colorIn3_4;
  lowp vec4 colorIn2_5;
  lowp vec4 colorIn1_6;
  colorIn1_6 = vec4(0.0, 0.0, 0.0, 0.0);
  colorIn2_5 = vec4(0.0, 0.0, 0.0, 0.0);
  colorIn3_4 = vec4(0.0, 0.0, 0.0, 0.0);
  xcoord_3 = vTextureCoord.x;
  yCenterShift_2 = (vTextureCoord.y - 0.1);
  if ((vTextureCoord.y < 0.2)) {
    highp vec2 tmpvar_7;
    tmpvar_7.x = xcoord_3;
    tmpvar_7.y = (yCenterShift_2 + 0.71);
    highp vec2 P_8;
    P_8 = (tmpvar_7 - 0.02);
    colorIn1_6 = textureGrad (mTextureID2, P_8, vec2(0.0, 0.0), vec2(0.0, 0.0));
  };
  if (((vTextureCoord.y > 0.13) && (vTextureCoord.y < 0.95))) {
    highp vec2 tmpvar_9;
    tmpvar_9.x = xcoord_3;
    tmpvar_9.y = yCenterShift_2;
    highp vec2 P_10;
    P_10 = (tmpvar_9 - 0.02);
    colorIn2_5 = textureGrad (mTextureID1, P_10, vec2(0.0, 0.0), vec2(0.0, 0.0));
  };
  if ((vTextureCoord.y > 0.85)) {
    highp vec2 tmpvar_11;
    tmpvar_11.x = xcoord_3;
    tmpvar_11.y = (yCenterShift_2 - 0.71);
    highp vec2 P_12;
    P_12 = (tmpvar_11 - 0.02);
    colorIn3_4 = textureGrad (mTextureID, P_12, vec2(0.0, 0.0), vec2(0.0, 0.0));
  };
  lowp vec4 tmpvar_13;
  tmpvar_13 = textureLod (frameSuper16mm, vTextureCoord, 0.0);
  lowp vec4 tmpvar_14;
  tmpvar_14 = texture (frameTexture, vTextureCoord);
  highp vec3 tmpvar_15;
  if (((tmpvar_13.y + tmpvar_13.z) > (tmpvar_13.x * 1.6))) {
    lowp vec3 tmpvar_16;
    lowp vec3 x_17;
    x_17 = ((colorIn2_5.xyz * colorIn2_5.w) * tmpvar_13.y);
    tmpvar_16 = (((
      exp2(x_17)
     - 1.0) - (x_17 * 0.693147)) * 3.258891);
    lowp vec3 tmpvar_18;
    lowp vec3 x_19;
    x_19 = ((colorIn1_6.xyz * colorIn1_6.w) * tmpvar_13.z);
    tmpvar_18 = (((
      exp2(x_19)
     - 1.0) - (x_19 * 0.693147)) * 3.258891);
    lowp vec3 tmpvar_20;
    lowp vec3 x_21;
    x_21 = ((colorIn3_4.xyz * colorIn3_4.w) * tmpvar_13.z);
    tmpvar_20 = (((
      exp2(x_21)
     - 1.0) - (x_21 * 0.693147)) * 3.258891);
    bool tmpvar_22;
    tmpvar_22 = (vTextureCoord.y >= 0.5);
    tmpvar_15 = ((tmpvar_16 + (
      (1.0 - float(tmpvar_22))
     * tmpvar_18)) + (float(tmpvar_22) * tmpvar_20));
  } else {
    highp vec3 tmpvar_23;
    lowp vec3 x_24;
    x_24 = (tmpvar_13.xyz * 0.5);
    lowp vec3 tmpvar_25;
    tmpvar_25 = exp2(x_24);
    tmpvar_23 = (((tmpvar_25 - 1.0) - (x_24 * 0.693147)) * 3.258891);
    tmpvar_15 = tmpvar_23;
  };
  processedColorLinear_1 = tmpvar_15;
  lowp vec3 tmpvar_26;
  tmpvar_26 = (((
    exp2(tmpvar_14.xyz)
   - 1.0) - (tmpvar_14.xyz * 0.693147)) * 3.258891);
  mediump vec4 tmpvar_27;
  tmpvar_27.w = 1.0;
  tmpvar_27.xyz = clamp (pow ((
    clamp (processedColorLinear_1, 0.0, 1.0)
   + 
    (tmpvar_26 * 0.5)
  ), vec3(0.4545455, 0.4545455, 0.4545455)), 0.0, 1.0);
  return tmpvar_27;    
}
