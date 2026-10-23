#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
uniform highp vec2 iTexelResolutionRotate;
out highp vec2 vTexelCoord;

void main() {  
    gl_Position =  aPosition;    
    vTexelCoord = vec2(1.0 - aTextureCoord.y, aTextureCoord.x) * iTexelResolutionRotate + 0.5;
}