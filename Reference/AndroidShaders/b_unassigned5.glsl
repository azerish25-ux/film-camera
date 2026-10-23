#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;
in highp vec2 vTextureCoord;
out vec4 fragColor;
uniform samplerExternalOES simpleTexId;

//vignette
uniform float vignetteFalloff;
uniform float pseudoExposure;
uniform float contrast;
uniform highp vec2 iResolution;



vec4 applyVignette(vec4 inColor){
    vec2 uv = vTextureCoord.xy;// / iResolution.xy;
    vec2 coord = (uv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    float rf = sqrt(dot(coord, coord)) * vignetteFalloff;
    float rf2 = rf * rf + 1.0;
    float vig = 1.0 / (rf2 * rf2);    
    vec4 result = vec4((contrast * (inColor.rgb - 0.5) + 0.5) * vig * (pseudoExposure), 1.0);
	return clamp(result, 0.0, 1.0);
}

void main() {  
    vec4 color;
    color = texture( simpleTexId, vTextureCoord);    
    fragColor = applyVignette(color);
}