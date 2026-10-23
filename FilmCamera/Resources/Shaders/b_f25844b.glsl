#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
out highp vec2 vTextureCoord;

uniform highp vec2 iResolution;
uniform float chroma_scaleX;
uniform float chroma_scaleY;
uniform float chroma_centerX;
uniform float chroma_centerY;
uniform int chroma_orientation;

void main() {
    gl_Position =  aPosition;

    highp float minX = chroma_centerX - 0.5  / chroma_scaleX;

    //isSelfie
    #if 0
    highp float xCoord = (1.0 - aTextureCoord.x) / chroma_scaleX + minX;
    #else
    highp float xCoord = aTextureCoord.x / chroma_scaleX + minX;
    #endif

    highp float minY = chroma_centerY - 0.5 / chroma_scaleY;
    highp float yCoord = aTextureCoord.y / chroma_scaleY + minY;

    if (chroma_orientation == 0){
        vTextureCoord = vec2(xCoord, yCoord);
    } else if (chroma_orientation == 1)  {
        vTextureCoord = vec2(1.0 - yCoord, xCoord);
    }
    else if (chroma_orientation == 2)  {
        vTextureCoord = vec2(1.0 - xCoord, 1.0 - yCoord );
    }
    else if (chroma_orientation == 3)  {
        vTextureCoord = vec2(yCoord, 1.0 - xCoord);
    }
}