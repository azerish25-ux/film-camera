#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;
in highp vec2 vTextureCoord;
out vec4 fragColor;
uniform samplerExternalOES chromaTexId;

//vignette
uniform float chroma_vignetteFalloff;
uniform highp vec2 chroma_iResolution;
uniform float chroma_value;
uniform float chroma_pseudoExposure;
uniform float chroma_contrast;

vec4 applyVignette(vec4 inColor){
    vec2 uv = vTextureCoord.xy;
    vec2 coord = (uv - 0.5) * vec2(chroma_iResolution.x/chroma_iResolution.y, 1.0) * 2.0;
    float rf = sqrt(dot(coord, coord)) * chroma_vignetteFalloff;
    float rf2 = rf * rf + 1.0;
    float vig = 1.0 / (rf2 * rf2);    
    vec4 result = vec4((chroma_contrast * (inColor.rgb - 0.5) + 0.5) * vig , 1.0);
	return clamp(result, 0.0, 1.0);
}

vec4 applyChroma2(vec2 inCoord){   
    vec3 color;    
    vec2 delta = inCoord - vec2(0.5);
    vec3 norm = normalize(vec3(delta.x, delta.y, sqrt(0.5 - delta.x*delta.x - delta.y*delta.y)));
    vec3 refr_r = refract(vec3(0.0, 0.0, -1.0), norm, mix(1.0, (1.156/(1.150)), chroma_value*4.0));
    vec3 refr_y = refract(vec3(0.0, 0.0, -1.0), norm, mix(1.0, (1.156/(1.153)), chroma_value*4.0));    
    vec3 refr_c = refract(vec3(0.0, 0.0, -1.0), norm, mix(1.0, (1.156/(1.159)), chroma_value*4.0));
    vec3 refr_b = refract(vec3(0.0, 0.0, -1.0), norm, mix(1.0, (1.156/(1.162)), chroma_value*4.0));
    vec3 refr_p = refract(vec3(0.0, 0.0, -1.0), norm, mix(1.0, (1.156/(1.165)), chroma_value*4.0));    
    
    vec3 r_color = texture(chromaTexId, refr_r.xy + inCoord).xyz;
    vec3 y_color = texture(chromaTexId, refr_y.xy + inCoord).xyz;
    vec3 g_color = texture(chromaTexId, inCoord).xyz;
    vec3 c_color = texture(chromaTexId, refr_c.xy + inCoord).xyz;
    vec3 b_color = texture(chromaTexId, refr_b.xy + inCoord).xyz;
    vec3 p_color = texture(chromaTexId, refr_p.xy + inCoord).xyz;

    float r = r_color.x * 0.5;    
    float y = (y_color.x * 2.0 + y_color.y * 2.0 - y_color.z)/6.0;
    float g = g_color.y * 0.5;
    float c = (c_color.y * 2.0 + c_color.z * 2.0 - c_color.x)/6.0;
    float b = b_color.z * 0.5;
    float p = (p_color.z * 2.0 + p_color.x * 2.0 - p_color.y)/6.0;

    float R = r + (2.0*p + 2.0*y - c)/3.0;
    float G = g + (2.0*y + 2.0*c - p)/3.0;
    float B = b + (2.0*c + 2.0*p - y)/3.0;
    color = vec3(R,G,B);
    
    return vec4(color,1.0);
}

void main() {  
    vec4 color;    
    color = applyChroma2(vTextureCoord) * (chroma_pseudoExposure);    
    fragColor = applyVignette(color);
}