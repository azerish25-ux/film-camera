#version 320 es
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;

layout(binding = 5, rgba8) writeonly uniform highp image2D waveFormImageToClearR;
layout(binding = 6, rgba8) writeonly uniform highp image2D waveFormImageToClearG;
layout(binding = 7, rgba8) writeonly uniform highp image2D waveFormImageToClearB;
layout(local_size_x = 00000, local_size_y = 00000, local_size_z = 1) in;

const highp vec4 waveformClearColor = vec4(0.129411, 0.129411, 0.129411, 1.0);

void main() {    
    ivec2 storePos = ivec2(gl_GlobalInvocationID.xy);
    imageStore(waveFormImageToClearR, storePos, waveformClearColor);        
    imageStore(waveFormImageToClearG, storePos, waveformClearColor);        
    imageStore(waveFormImageToClearB, storePos, waveformClearColor);        
}      