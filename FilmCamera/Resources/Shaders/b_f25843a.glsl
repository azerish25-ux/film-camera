#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
out highp vec2 vTextureCoord;
uniform highp float randomX;
uniform highp float randomY;

void main() {  
    gl_Position =  aPosition;
    
    highp float xcoord;
////isSelfie
//#if 0
//      xcoord = 1.0 - aTextureCoord.x;
//#else
      xcoord = aTextureCoord.x;
//#endif

    vTextureCoord = vec2(xcoord, 1.0 - aTextureCoord.y) + vec2(randomX, - randomY);
}