#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
out highp vec2 vTextureCoord;

void main() {  
    gl_Position =  aPosition;    
    vTextureCoord = aTextureCoord.xy;
}