uniform sampler2D frameSuper16mm;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
    mediump vec4 processedColor_1;
    lowp vec4 hawaiiFrameTextureColor_2;
    highp float xcoord_3;
    lowp vec4 colorIn_4;
    xcoord_3 = ((vTextureCoord.x * 1.03) - 0.02);
    if (((vTextureCoord.y > 0.03) && (vTextureCoord.y < 0.985))) {
        highp vec2 tmpvar_5;
        tmpvar_5.x = (xcoord_3 / 1.03);
        tmpvar_5.y = vTextureCoord.y;
        highp vec2 P_6;
        P_6 = ((tmpvar_5 * 1.03) - 0.02);
        colorIn_4 = textureLod (mTextureID1, P_6, 0.0);
    } else {
        if ((vTextureCoord.y < 0.03)) {
            highp vec2 tmpvar_7;
            tmpvar_7.x = xcoord_3;
            tmpvar_7.y = ((vTextureCoord.y * 1.03) + 0.98);
            highp vec2 P_8;
            P_8 = (tmpvar_7 - 0.02);
            colorIn_4 = textureLod (mTextureID2, P_8, 0.0);
        } else {
            if ((vTextureCoord.y > 0.985)) {
                highp vec2 tmpvar_9;
                tmpvar_9.x = xcoord_3;
                tmpvar_9.y = ((vTextureCoord.y * 1.03) - 0.98);
                highp vec2 P_10;
                P_10 = (tmpvar_9 - 0.02);
                colorIn_4 = textureLod (mTextureID, P_10, 0.0);
            };
        };
    };
    lowp vec4 tmpvar_11;
    tmpvar_11 = textureLod (frameSuper16mm, vTextureCoord, 0.0);
    hawaiiFrameTextureColor_2 = tmpvar_11;
    if ((tmpvar_11.y > (tmpvar_11.x * 1.3))) {
        hawaiiFrameTextureColor_2.w = (1.0 - tmpvar_11.y);
        hawaiiFrameTextureColor_2.y = 0.0;
        hawaiiFrameTextureColor_2.x = 0.0;
        hawaiiFrameTextureColor_2.z = 0.0;
    };
    processedColor_1.xyz = (hawaiiFrameTextureColor_2.xyz + ((colorIn_4.xyz * colorIn_4.w) * (1.0 - hawaiiFrameTextureColor_2.w)));
    processedColor_1.w = (hawaiiFrameTextureColor_2.w + (colorIn_4.w * (1.0 - hawaiiFrameTextureColor_2.w)));
    return processedColor_1;
}  