#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump sampler2D;
precision mediump sampler3D;
precision mediump int;
precision mediump float;
precision mediump samplerExternalOES;
in highp vec2 vTextureCoord;
out lowp vec4 fragColor;
uniform sampler2D halationHighSourceTexture;
uniform float halationIntensity;
uniform float halationCuttoff;
void main ()
{
    lowp vec3 tmpvar_1;
    tmpvar_1 = clamp (((
    pow (textureLod (halationHighSourceTexture, vTextureCoord, 0.0).xyz, vec3(2.2, 2.2, 2.2))
    - halationCuttoff) / (1.0 - halationCuttoff)), 0.0, 1.0);
    lowp vec4 tmpvar_2;
    tmpvar_2.w = 1.0;
    tmpvar_2.xyz = pow (((tmpvar_1 *
    (tmpvar_1 * (3.0 - (2.0 * tmpvar_1)))
    ) * halationIntensity), vec3(0.4545454, 0.4545454, 0.4545454));
    fragColor = tmpvar_2;
}