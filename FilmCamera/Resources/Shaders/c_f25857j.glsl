#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out lowp vec4 fragColor;
uniform sampler2D halationBlurTempTexture;
uniform highp vec2 halationBlurResInv;
uniform highp float redHalationOffset;
uniform float halationBlurHueGreen;
uniform float halationBlurHueBlue;
void main ()
{
    highp vec2 tmpvar_1;
    tmpvar_1 = (vTextureCoord + (vec2(redHalationOffset) * halationBlurResInv));
    highp vec2 tmpvar_2;
    tmpvar_2.x = redHalationOffset;
    highp float tmpvar_3;
    tmpvar_3 = -(redHalationOffset);
    tmpvar_2.y = tmpvar_3;
    highp vec2 tmpvar_4;
    tmpvar_4 = (vTextureCoord + (tmpvar_2 * halationBlurResInv));
    highp vec2 tmpvar_5;
    tmpvar_5.x = tmpvar_3;
    tmpvar_5.y = redHalationOffset;
    highp vec2 tmpvar_6;
    tmpvar_6 = (vTextureCoord + (tmpvar_5 * halationBlurResInv));
    highp vec2 tmpvar_7;
    tmpvar_7 = (vTextureCoord + (vec2(tmpvar_3) * halationBlurResInv));
    lowp vec3 tmpvar_8;
    tmpvar_8 = textureLod (halationBlurTempTexture, vTextureCoord, 0.0).xyz;
    lowp vec3 tmpvar_9;
    tmpvar_9 = pow (((
    ((pow (textureLod (halationBlurTempTexture, tmpvar_1, 0.0).xyz, vec3(2.2, 2.2, 2.2)) + pow (textureLod (halationBlurTempTexture, tmpvar_4, 0.0).xyz, vec3(2.2, 2.2, 2.2))) + pow (textureLod (halationBlurTempTexture, tmpvar_6, 0.0).xyz, vec3(2.2, 2.2, 2.2)))
    +
    pow (textureLod (halationBlurTempTexture, tmpvar_7, 0.0).xyz, vec3(2.2, 2.2, 2.2))
    ) * 0.25), vec3(0.4545454, 0.4545454, 0.4545454));
    lowp vec3 tmpvar_10;
    tmpvar_10.x = tmpvar_9.x;
    tmpvar_10.y = mix (tmpvar_8.y, tmpvar_9.y, halationBlurHueGreen);
    tmpvar_10.z = mix (tmpvar_8.z, tmpvar_9.z, halationBlurHueBlue);
    lowp vec4 tmpvar_11;
    tmpvar_11.w = 1.0;
    tmpvar_11.xyz = tmpvar_10;
    fragColor = tmpvar_11;
}