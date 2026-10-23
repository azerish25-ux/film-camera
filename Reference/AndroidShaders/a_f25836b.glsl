#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in highp vec4 aPosition;
layout (location = 1)  in highp vec4 aTextureCoord;
out highp vec2 vTextureCoord;

void main() {  
    gl_Position =  aPosition;    
    vTextureCoord = aTextureCoord.xy;
}