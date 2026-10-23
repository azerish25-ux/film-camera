#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

in highp vec2 vTextureCoord;
uniform sampler2D mTextureID;
uniform highp float randomX;
uniform highp float randomY;
out vec4 fragColor;

//{frame_func}

void main() {
    fragColor = frame();
} 