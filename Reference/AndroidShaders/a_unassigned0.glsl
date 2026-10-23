uniform samplerExternalOES frameTexture;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
        
vec4 frame(){
    vec4 colorIn;

    highp float xcoord;
    xcoord = (vTextureCoord.x)*1.06 - 0.048;

    highp float parallax = 0.670;
    highp float topBorder = 0.16;
    highp float bottomBorder = 0.794;
    highp float startMargin = 0.13;

    float scale = 0.6;
    highp float dot1left = 0.04;
    highp float dot1right = 0.13;
    highp float dot1top = 0.21;
    highp float dot1bottom = 0.3;

    highp float dot2left = 0.04;
    highp float dot2right = 0.13;
    highp float dot2top = 0.84;
    highp float dot2bottom = 0.93;

    highp float blackdot1top = 0.11;
    highp float blackdot2top = 0.74;
    highp float dot1parallax = 0.307;
    highp float dot2parallax = 0.365;

    if (vTextureCoord.x > startMargin && (vTextureCoord.y > topBorder && vTextureCoord.y < bottomBorder)){
        colorIn = textureLod(mTextureID1, vec2(xcoord / 1.06, (vTextureCoord.y))*1.06 - 0.03, 0.0);
    } else if (vTextureCoord.x > startMargin &&  vTextureCoord.y < topBorder){
        colorIn = textureLod(mTextureID2, vec2(xcoord, ((vTextureCoord.y))*1.06 + parallax)- 0.03, 0.0);
    } else if (vTextureCoord.x  > startMargin &&  vTextureCoord.y  > bottomBorder){
        colorIn = textureLod(mTextureID, vec2(xcoord, (vTextureCoord.y)*1.06 - parallax)- 0.03, 0.0);
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    vTextureCoord.y < blackdot1top){
        //смазанная часть1
        colorIn = (textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom)*1.06 +0.307)- 0.03)*scale, 0.0) +
        textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom - 0.01)*1.06 +0.307)- 0.03)*scale, 0.0) +
        textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom- 0.02)*1.06 +0.307)- 0.03)*scale, 0.0)) / 3.0;
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    vTextureCoord.y > dot1top &&
    vTextureCoord.y < dot1bottom){
        //верхняя дырка  
        colorIn = textureLod(mTextureID1, vec2(xcoord*scale, ((vTextureCoord.y)*1.06 + dot1parallax)- 0.03)*scale, 0.0);
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    vTextureCoord.y  > dot1bottom &&
    vTextureCoord.y  < blackdot2top){
        //смазанная часть2
        colorIn = (textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom)*1.06 + dot1parallax)- 0.03)*scale, 0.0) +
        textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom - 0.01)*1.06 + dot1parallax)- 0.03)*scale, 0.0) +
        textureLod(mTextureID1, vec2(xcoord*scale, ((dot1bottom- 0.02)*1.06 + dot1parallax)- 0.03)*scale, 0.0)) / 3.0;
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    vTextureCoord.y  > dot2top &&
    vTextureCoord.y  < dot2bottom){
        //нижняя дырка
        colorIn = textureLod(mTextureID, vec2(xcoord*scale, ((vTextureCoord.y)*1.06 - dot2parallax)- 0.03)*scale, 0.0);
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    vTextureCoord.y > dot2bottom){
        //смазанная часть3
        colorIn = (textureLod(mTextureID, vec2(xcoord*scale, ((dot2bottom)*1.06 - dot2parallax)- 0.03)*scale, 0.0) +
        textureLod(mTextureID, vec2(xcoord*scale, ((dot2bottom - 0.01)*1.06 - dot2parallax)- 0.03)*scale, 0.0) +
        textureLod(mTextureID, vec2(xcoord*scale, ((dot2bottom- 0.02)*1.06 - dot2parallax)- 0.03)*scale, 0.0)) / 3.0;
    }


    vec4 hawaiiFrameTextureColor;
    hawaiiFrameTextureColor = texture(frameTexture, vTextureCoord);


    //боковая штука
    if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    hawaiiFrameTextureColor.g > hawaiiFrameTextureColor.r*0.7){
        hawaiiFrameTextureColor.a = 1.0 - hawaiiFrameTextureColor.g;
        hawaiiFrameTextureColor.g = 0.0;
        hawaiiFrameTextureColor.r = 0.0;
        hawaiiFrameTextureColor.b = 0.0;
    } else if (vTextureCoord.x  > dot1left &&
    vTextureCoord.x  < dot1right &&
    hawaiiFrameTextureColor.g < hawaiiFrameTextureColor.r*0.7){
        hawaiiFrameTextureColor.a = 1.0 - hawaiiFrameTextureColor.g;
        hawaiiFrameTextureColor.g = 0.0;
        //hawaiiFrameTextureColor.r = 0.0;
        hawaiiFrameTextureColor.b = 0.0;
    } else if (vTextureCoord.x  > startMargin &&
    hawaiiFrameTextureColor.g >hawaiiFrameTextureColor.r*1.0){
        //основной фрейм
        hawaiiFrameTextureColor.a = 1.0 - hawaiiFrameTextureColor.g;
        hawaiiFrameTextureColor.g = 0.0;
        hawaiiFrameTextureColor.r = 0.0;
        hawaiiFrameTextureColor.b = 0.0;
    }
    mediump vec4 processedColor;
    if (vTextureCoord.x < 1.0){
        processedColor.rgb = hawaiiFrameTextureColor.rgb + colorIn.rgb * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        //processedColor.g = hawaiiFrameTextureColor.g + colorIn.g * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        //processedColor.b = hawaiiFrameTextureColor.b + colorIn.b * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        processedColor.a = hawaiiFrameTextureColor.a + colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
    } else {
        processedColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    return processedColor;
}