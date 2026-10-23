#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
out highp vec2 vTextureCoord;

uniform highp vec2 iResolution;
uniform float scaleX;
uniform float scaleY;
uniform float centerX;
uniform float centerY;
uniform int orientation;

void main() {
    gl_Position =  aPosition;

    highp float minX = centerX - 0.5 / scaleX;

    //isSelfie
    #if 0
    highp float xCoord = (1.0 - aTextureCoord.x) / scaleX + minX;
    #else
    highp float xCoord = aTextureCoord.x / scaleX + minX;
    #endif

    highp float minY = centerY - 0.5 / scaleY;
    highp float yCoord = aTextureCoord.y / scaleY + minY;


    if (orientation == 0){
        vTextureCoord = vec2(xCoord, yCoord);
    } else if (orientation == 1)  {
        vTextureCoord = vec2(1.0 - yCoord, xCoord);
    }
    else if (orientation == 2)  {
        vTextureCoord = vec2(1.0 - xCoord, 1.0 - yCoord);
    }
    else if (orientation == 3)  {
        vTextureCoord = vec2(yCoord, 1.0 - xCoord);
    }
}