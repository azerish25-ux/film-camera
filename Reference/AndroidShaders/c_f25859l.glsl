#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
out lowp vec4 fragColor;
uniform sampler2D textureHalationMergeSource;
uniform sampler2D textureHalationMergeBlur;
uniform float halationMergeIntensity;
uniform float halationMergeHueGreen;
uniform float halationMergeHueBlue;
void main ()
{
    lowp vec4 tmpvar_1;
    tmpvar_1 = textureLod (textureHalationMergeBlur, vTextureCoord, 0.0);
    lowp vec3 tmpvar_2;
    tmpvar_2.x = tmpvar_1.x;
    tmpvar_2.y = (tmpvar_1.y * halationMergeHueGreen);
    tmpvar_2.z = (tmpvar_1.z * halationMergeHueBlue);
    lowp vec4 tmpvar_3;
    tmpvar_3.w = 1.0;
    tmpvar_3.xyz = clamp (pow ((
    pow (textureLod (textureHalationMergeSource, vTextureCoord, 0.0).xyz, vec3(2.2, 2.2, 2.2))
    +
    ((pow (tmpvar_2, vec3(2.2, 2.2, 2.2)) * 15.0) * halationMergeIntensity)
    ), vec3(0.4545454, 0.4545454, 0.4545454)), 0.0, 1.0);
    fragColor = tmpvar_3;
}        