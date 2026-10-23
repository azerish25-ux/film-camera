#version 320 es
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;


uniform sampler2D waveformSourceTexture;
uniform highp float waveformPortraitInvWidth;
uniform highp float waveformPortraitInvHeight;
layout(binding = 5, rgba8) writeonly uniform highp image2D waveformOutputImageR;
layout(binding = 6, rgba8) writeonly uniform highp image2D waveformOutputImageG;
layout(binding = 7, rgba8) writeonly uniform highp image2D waveformOutputImageB;
layout(local_size_x = 00000, local_size_y = 00000, local_size_z = 1) in;


void main() {    
    // Read current global position for this thread
    ivec2 storePos = ivec2(gl_GlobalInvocationID.xy);
    int x = storePos.x;
    int y = storePos.y;     
    
    vec2 colorPosition = vec2(2.0 * (float(y)) * waveformPortraitInvWidth, (float(x)) * waveformPortraitInvHeight);
    ivec3 color = ivec3(textureLod(waveformSourceTexture, colorPosition, 0.0 ).rgb * vec3(255.0) + 0.5);
    
    vec2 colorPosition2 = vec2(2.0 * (float(y)) * waveformPortraitInvWidth, (float(x) + 0.5) * waveformPortraitInvHeight);
    ivec3 color2 = ivec3(textureLod(waveformSourceTexture, colorPosition2, 0.0 ).rgb * vec3(255.0) + 0.5);

    int yR = 511 - (color.r + color2.r);
    int yG = 511 - (color.g + color2.g);
    int yB = 511 - (color.b + color2.b);
    imageStore(waveformOutputImageR, ivec2(x, yR), vec4(0.43921));        
    imageStore(waveformOutputImageG, ivec2(x, yG), vec4(0.43921));        
    imageStore(waveformOutputImageB, ivec2(x, yB), vec4(0.43921));        
}      