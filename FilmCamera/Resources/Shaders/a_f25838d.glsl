#version 300 es
precision highp float;
precision highp int;
layout (location = 0)  in vec4 aPosition;
layout (location = 1)  in vec4 aTextureCoord;
uniform highp vec2 iTexelResolution;
out highp vec2 vTexelCoord;

void main() {  
    gl_Position =  aPosition;    
    vTexelCoord = vec2(aTextureCoord.x, aTextureCoord.y) * iTexelResolution + 0.5;
}