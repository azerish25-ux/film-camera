uniform samplerExternalOES frameTexture;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
    mediump vec4 processedColor_1;
    lowp vec4 hawaiiFrameTextureColor_2;
    highp float xcoord_3;
    lowp vec4 colorIn_4;
    xcoord_3 = (vTextureCoord.x * 1.01);
    highp float tmpvar_5;
    tmpvar_5 = (-0.005 * vTextureCoord.x);
    if (((vTextureCoord.y > (0.0805 + tmpvar_5)) && (vTextureCoord.y < (0.9475 + tmpvar_5)))) {
        highp vec2 tmpvar_6;
        tmpvar_6.x = (xcoord_3 / 1.01);
        tmpvar_6.y = vTextureCoord.y;
        highp vec2 P_7;
        P_7 = (tmpvar_6 * 1.01);
        colorIn_4 = textureLod (mTextureID1, P_7, 0.0);
    } else {
        if ((vTextureCoord.y < (0.0805 + tmpvar_5))) {
            highp vec2 tmpvar_8;
            tmpvar_8.x = xcoord_3;
            tmpvar_8.y = ((vTextureCoord.y * 1.01) + 0.878);
            colorIn_4 = textureLod (mTextureID2, tmpvar_8, 0.0);
        } else {
            if ((vTextureCoord.y > (0.9475 + tmpvar_5))) {
                highp vec2 tmpvar_9;
                tmpvar_9.x = xcoord_3;
                tmpvar_9.y = ((vTextureCoord.y * 1.01) - 0.878);
                colorIn_4 = textureLod (mTextureID, tmpvar_9, 0.0);
            };
        };
    };
    lowp vec4 tmpvar_10;
    tmpvar_10 = texture (frameTexture, vTextureCoord);
    hawaiiFrameTextureColor_2 = tmpvar_10;
    if ((tmpvar_10.y > (tmpvar_10.x * 1.3))) {
        hawaiiFrameTextureColor_2.w = (1.0 - tmpvar_10.y);
        hawaiiFrameTextureColor_2.y = 0.0;
        hawaiiFrameTextureColor_2.x = 0.0;
        hawaiiFrameTextureColor_2.z = 0.0;
    };
    processedColor_1.xyz = (hawaiiFrameTextureColor_2.xyz + ((colorIn_4.xyz * colorIn_4.w) * (1.0 - hawaiiFrameTextureColor_2.w)));
    processedColor_1.w = (hawaiiFrameTextureColor_2.w + (colorIn_4.w * (1.0 - hawaiiFrameTextureColor_2.w)));
    return processedColor_1;
}