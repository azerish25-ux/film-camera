uniform samplerExternalOES frameTexture;
vec4 frame(){
    mediump vec4 processedColor_1;
    lowp vec4 frameTextureColor_2;
    highp float xcoord_3;
    lowp vec4 colorIn_4;
    xcoord_3 = (vTextureCoord.x - 0.07);
    if ((vTextureCoord.x > 0.16)) {
        highp vec2 tmpvar_5;
        tmpvar_5.x = xcoord_3;
        tmpvar_5.y = vTextureCoord.y;
        colorIn_4 = textureLod (mTextureID, tmpvar_5, 0.0);
    } else {
        highp vec2 tmpvar_6;
        tmpvar_6.x = 0.0;
        tmpvar_6.y = vTextureCoord.y;
        colorIn_4 = textureLod (mTextureID, tmpvar_6, 0.0);
    };
    lowp vec4 tmpvar_7;
    tmpvar_7 = texture (frameTexture, vTextureCoord);
    frameTextureColor_2 = tmpvar_7;
    if (((vTextureCoord.x > 0.16) && (tmpvar_7.y > (tmpvar_7.x * 1.3)))) {
        frameTextureColor_2.w = (1.0 - clamp(tmpvar_7.y * 1.3, 0.0, 1.0));
        frameTextureColor_2.y = 0.0;
        frameTextureColor_2.x = 0.0;
        frameTextureColor_2.z = 0.0;
    } else {
        if (((vTextureCoord.x < 0.16) && (frameTextureColor_2.y > (frameTextureColor_2.x * 1.3)))) {
            frameTextureColor_2.w = 1.0;
            frameTextureColor_2.y = frameTextureColor_2.x;
        } else {
            if ((((
            ((vTextureCoord.x > 0.15) && (vTextureCoord.x < 0.18))
            &&
            (vTextureCoord.y > 0.4)
            ) && (vTextureCoord.y < 0.6)) && (frameTextureColor_2.x > (frameTextureColor_2.z * 1.3)))) {
                frameTextureColor_2.w = 1.0;
                frameTextureColor_2.x = frameTextureColor_2.y;
            };
        };
    };
    if ((vTextureCoord.x < 0.97)) {
        processedColor_1.xyz = (frameTextureColor_2.xyz + ((colorIn_4.xyz * colorIn_4.w) * (1.0 - frameTextureColor_2.w)));
        processedColor_1.w = (frameTextureColor_2.w + (colorIn_4.w * (1.0 - frameTextureColor_2.w)));
    } else {
        processedColor_1 = vec4(0.0, 0.0, 0.0, 1.0);
    };
    return processedColor_1;
}  