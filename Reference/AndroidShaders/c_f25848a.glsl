uniform samplerExternalOES frameTexture;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
    mediump vec4 processedColor_1;
    lowp vec4 hawaiiFrameTextureColor_2;
    highp float xcoord_3;
    lowp vec4 colorIn_4;
    xcoord_3 = ((vTextureCoord.x * 1.06) - 0.048);
    if (((vTextureCoord.x > 0.13) && ((vTextureCoord.y > 0.16) && (vTextureCoord.y < 0.794)))) {
        highp vec2 tmpvar_5;
        tmpvar_5.x = (xcoord_3 / 1.06);
        tmpvar_5.y = vTextureCoord.y;
        highp vec2 P_6;
        P_6 = ((tmpvar_5 * 1.06) - 0.03);
        colorIn_4 = textureLod (mTextureID1, P_6, 0.0);
    } else {
        if (((vTextureCoord.x > 0.13) && (vTextureCoord.y < 0.16))) {
            highp vec2 tmpvar_7;
            tmpvar_7.x = xcoord_3;
            tmpvar_7.y = ((vTextureCoord.y * 1.06) + 0.67);
            highp vec2 P_8;
            P_8 = (tmpvar_7 - 0.03);
            colorIn_4 = textureLod (mTextureID2, P_8, 0.0);
        } else {
            if (((vTextureCoord.x > 0.13) && (vTextureCoord.y > 0.794))) {
                highp vec2 tmpvar_9;
                tmpvar_9.x = xcoord_3;
                tmpvar_9.y = ((vTextureCoord.y * 1.06) - 0.67);
                highp vec2 P_10;
                P_10 = (tmpvar_9 - 0.03);
                colorIn_4 = textureLod (mTextureID, P_10, 0.0);
            } else {
                if ((((vTextureCoord.x > 0.04) && (vTextureCoord.x < 0.13)) && (vTextureCoord.y < 0.11))) {
                    highp vec2 tmpvar_11;
                    tmpvar_11.x = (xcoord_3 * 0.6);
                    tmpvar_11.y = 0.595;
                    highp vec2 P_12;
                    P_12 = (tmpvar_11 * 0.6);
                    highp vec2 tmpvar_13;
                    tmpvar_13.x = (xcoord_3 * 0.6);
                    tmpvar_13.y = 0.5844001;
                    highp vec2 P_14;
                    P_14 = (tmpvar_13 * 0.6);
                    highp vec2 tmpvar_15;
                    tmpvar_15.x = (xcoord_3 * 0.6);
                    tmpvar_15.y = 0.5738;
                    highp vec2 P_16;
                    P_16 = (tmpvar_15 * 0.6);
                    colorIn_4 = (((textureLod (mTextureID1, P_12, 0.0) + textureLod (mTextureID1, P_14, 0.0)) + textureLod (mTextureID1, P_16, 0.0)) / 3.0);
                } else {
                    if ((((
                    (vTextureCoord.x > 0.04)
                    &&
                    (vTextureCoord.x < 0.13)
                    ) && (vTextureCoord.y > 0.21)) && (vTextureCoord.y < 0.3))) {
                        highp vec2 tmpvar_17;
                        tmpvar_17.x = (xcoord_3 * 0.6);
                        tmpvar_17.y = (((vTextureCoord.y * 1.06) + 0.307) - 0.03);
                        highp vec2 P_18;
                        P_18 = (tmpvar_17 * 0.6);
                        colorIn_4 = textureLod (mTextureID1, P_18, 0.0);
                    } else {
                        if ((((
                        (vTextureCoord.x > 0.04)
                        &&
                        (vTextureCoord.x < 0.13)
                        ) && (vTextureCoord.y > 0.3)) && (vTextureCoord.y < 0.74))) {
                            highp vec2 tmpvar_19;
                            tmpvar_19.x = (xcoord_3 * 0.6);
                            tmpvar_19.y = 0.595;
                            highp vec2 P_20;
                            P_20 = (tmpvar_19 * 0.6);
                            highp vec2 tmpvar_21;
                            tmpvar_21.x = (xcoord_3 * 0.6);
                            tmpvar_21.y = 0.5844001;
                            highp vec2 P_22;
                            P_22 = (tmpvar_21 * 0.6);
                            highp vec2 tmpvar_23;
                            tmpvar_23.x = (xcoord_3 * 0.6);
                            tmpvar_23.y = 0.5738;
                            highp vec2 P_24;
                            P_24 = (tmpvar_23 * 0.6);
                            colorIn_4 = (((textureLod (mTextureID1, P_20, 0.0) + textureLod (mTextureID1, P_22, 0.0)) + textureLod (mTextureID1, P_24, 0.0)) / 3.0);
                        } else {
                            if ((((
                            (vTextureCoord.x > 0.04)
                            &&
                            (vTextureCoord.x < 0.13)
                            ) && (vTextureCoord.y > 0.84)) && (vTextureCoord.y < 0.93))) {
                                highp vec2 tmpvar_25;
                                tmpvar_25.x = (xcoord_3 * 0.6);
                                tmpvar_25.y = (((vTextureCoord.y * 1.06) - 0.365) - 0.03);
                                highp vec2 P_26;
                                P_26 = (tmpvar_25 * 0.6);
                                colorIn_4 = textureLod (mTextureID, P_26, 0.0);
                            } else {
                                if ((((vTextureCoord.x > 0.04) && (vTextureCoord.x < 0.13)) && (vTextureCoord.y > 0.93))) {
                                    highp vec2 tmpvar_27;
                                    tmpvar_27.x = (xcoord_3 * 0.6);
                                    tmpvar_27.y = 0.5908;
                                    highp vec2 P_28;
                                    P_28 = (tmpvar_27 * 0.6);
                                    highp vec2 tmpvar_29;
                                    tmpvar_29.x = (xcoord_3 * 0.6);
                                    tmpvar_29.y = 0.5802;
                                    highp vec2 P_30;
                                    P_30 = (tmpvar_29 * 0.6);
                                    highp vec2 tmpvar_31;
                                    tmpvar_31.x = (xcoord_3 * 0.6);
                                    tmpvar_31.y = 0.5696;
                                    highp vec2 P_32;
                                    P_32 = (tmpvar_31 * 0.6);
                                    colorIn_4 = (((textureLod (mTextureID, P_28, 0.0) + textureLod (mTextureID, P_30, 0.0)) + textureLod (mTextureID, P_32, 0.0)) / 3.0);
                                };
                            };
                        };
                    };
                };
            };
        };
    };
    lowp vec4 tmpvar_33;
    tmpvar_33 = texture (frameTexture, vTextureCoord);
    hawaiiFrameTextureColor_2 = tmpvar_33;
    if ((((vTextureCoord.x > 0.04) && (vTextureCoord.x < 0.13)) && (tmpvar_33.y > (tmpvar_33.x * 0.7)))) {
        hawaiiFrameTextureColor_2.w = (1.0 - tmpvar_33.y);
        hawaiiFrameTextureColor_2.y = 0.0;
        hawaiiFrameTextureColor_2.x = 0.0;
        hawaiiFrameTextureColor_2.z = 0.0;
    } else {
        if ((((vTextureCoord.x > 0.04) && (vTextureCoord.x < 0.13)) && (hawaiiFrameTextureColor_2.y < (hawaiiFrameTextureColor_2.x * 0.7)))) {
            hawaiiFrameTextureColor_2.w = (1.0 - hawaiiFrameTextureColor_2.y);
            hawaiiFrameTextureColor_2.y = 0.0;
            hawaiiFrameTextureColor_2.z = 0.0;
        } else {
            if (((vTextureCoord.x > 0.13) && (hawaiiFrameTextureColor_2.y > hawaiiFrameTextureColor_2.x))) {
                hawaiiFrameTextureColor_2.w = (1.0 - hawaiiFrameTextureColor_2.y);
                hawaiiFrameTextureColor_2.y = 0.0;
                hawaiiFrameTextureColor_2.x = 0.0;
                hawaiiFrameTextureColor_2.z = 0.0;
            };
        };
    };
    if ((vTextureCoord.x < 1.0)) {
        processedColor_1.xyz = (hawaiiFrameTextureColor_2.xyz + ((colorIn_4.xyz * colorIn_4.w) * (1.0 - hawaiiFrameTextureColor_2.w)));
        processedColor_1.w = (hawaiiFrameTextureColor_2.w + (colorIn_4.w * (1.0 - hawaiiFrameTextureColor_2.w)));
    } else {
        processedColor_1 = vec4(0.0, 0.0, 0.0, 1.0);
    };
    return processedColor_1;
}