vec4 frame(){
    return textureLod(mTextureID, vec2((vTextureCoord.x ) , vTextureCoord.y ) *0.95 + 0.03, 0.0);
}