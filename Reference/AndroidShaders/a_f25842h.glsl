#version 300 es
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;

in highp vec2 vTextureCoord;
out vec4 fragColor;
uniform sampler2D waveformDrawTexture;

void main() {   
    fragColor = textureLod(waveformDrawTexture, vTextureCoord, 0.0);
}      