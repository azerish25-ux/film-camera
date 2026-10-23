vec4 frame(){
    highp vec2 P_1;
    P_1 = ((vTextureCoord * 0.95) + 0.03);
    return textureLod (mTextureID, P_1, 0.0);
}