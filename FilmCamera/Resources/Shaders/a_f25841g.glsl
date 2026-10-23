#version 300 es
precision highp float;
precision highp int;
precision highp sampler3D;
precision highp isampler2D;
precision highp sampler2D;

in highp vec2 vTextureCoord;
out vec4 fragColor;
uniform isampler2D histSumTexture;
uniform highp int clampedHeight;

void main() {   
    mediump ivec3 amp;
 
    amp.r = texelFetch(histSumTexture, ivec2(vTextureCoord.x * 255.0 + 0.5, 0), 0).r;
    amp.g = texelFetch(histSumTexture, ivec2(vTextureCoord.x * 255.0 + 0.5, 1), 0).r;
    amp.b = texelFetch(histSumTexture, ivec2(vTextureCoord.x * 255.0 + 0.5, 2), 0).r;
    
    
    //highp vec3 color = (vec3(1.0) - step(vec3(amp),  vec3(clampedHeight * vTextureCoord.y))); 
    bvec3 pixelTest = greaterThan(amp, ivec3( float(clampedHeight) * vTextureCoord.y));
    //fragColor =  vec4(clamp(color, 0.129411, 0.43921), 1.0);    
    fragColor =  vec4(mix( vec3(0.129411), vec3(0.43921), vec3(pixelTest)), 1.0);    
}      