uniform samplerExternalOES frameTexture;
uniform sampler2D frameSuper16mm;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
const float topUpKiev = 0.13;
const float topDownKiev = 0.20;
const float bottomUpKiev = 0.85;
const float bottomDowmKiev = 0.95;
const float centerShiftKiev = 0.1;
const float shiftKiev = 0.71;


vec3 toLinearAproxKiev16U(vec3 x){
    return (exp2(x)-1.0-x*0.693147)*3.258891;
}

vec4 frame(){
    vec4 colorIn1 = vec4(0.0);
    vec4 colorIn2 = vec4(0.0);
    vec4 colorIn3 = vec4(0.0);

    highp float xcoord;
    xcoord = vTextureCoord.x;

    highp float yCenterShift;
    yCenterShift = vTextureCoord.y - centerShiftKiev;

    if (vTextureCoord.y < topDownKiev) {
        colorIn1 = textureGrad(mTextureID2, vec2(xcoord, yCenterShift + shiftKiev) - 0.02, vec2(0.0), vec2(0.0));
    }
    if (vTextureCoord.y > topUpKiev && vTextureCoord.y < bottomDowmKiev) {
        colorIn2 = textureGrad(mTextureID1, vec2(xcoord, yCenterShift          ) - 0.02, vec2(0.0), vec2(0.0));
    }
    if (vTextureCoord.y > bottomUpKiev) {
        colorIn3 = textureGrad(mTextureID, vec2(xcoord, yCenterShift - shiftKiev)- 0.02, vec2(0.0), vec2(0.0));
    }


    mediump vec3 processedColorLinear;

    vec4 frameTex;
    frameTex = textureLod(frameSuper16mm, vTextureCoord, 0.0);
    vec3 keykodeColor;
    keykodeColor = texture(frameTexture, vTextureCoord).rgb;
    processedColorLinear = (frameTex.g + frameTex.b > frameTex.r*1.6 ) ? toLinearAproxKiev16U(colorIn2.rgb * colorIn2.a * frameTex.g) +
        (1.0-step(0.5, vTextureCoord.y)) * toLinearAproxKiev16U(colorIn1.rgb * colorIn1.a*frameTex.b) +
        step(0.5, vTextureCoord.y) * toLinearAproxKiev16U(colorIn3.rgb * colorIn3.a*frameTex.b) : toLinearAproxKiev16U(frameTex.rgb * 0.5);
    
//    if (frameTex.g + frameTex.b > frameTex.r*1.6 ){
//        processedColorLinear = toLinearAproxKiev16U(colorIn2.rgb * colorIn2.a * frameTex.g) +
//        (1.0-step(0.5, vTextureCoord.y)) * toLinearAproxKiev16U(colorIn1.rgb * colorIn1.a*frameTex.b) +
//        step(0.5, vTextureCoord.y) * toLinearAproxKiev16U(colorIn3.rgb * colorIn3.a*frameTex.b);
//    }
    vec3 mergeColor = pow(clamp(processedColorLinear,0.0,1.0) + toLinearAproxKiev16U(keykodeColor)*0.5, vec3(0.45454545454));
    
    return vec4(clamp(mergeColor,0.0,1.0), 1.0);
}