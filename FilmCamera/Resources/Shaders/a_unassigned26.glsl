#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;
precision mediump int;
precision mediump sampler3D;
precision mediump sampler2D;
precision mediump samplerExternalOES;

struct LightLeak{
    float amp;
    float top;
    float topMultiplier;
    float bottom;
    float bottomMultiplier;
};

struct Holes{
    float internalOffset;
    float externalOffset;
    float seed;
    float amp;
    vec2 amountY;
    vec2 amountX;
    vec2 xMultiplier;
};


in highp vec2 vTextureCoord;
uniform sampler2D textureInPass3;
uniform sampler2D textureLuminance;
uniform mediump vec3 curve[66];
uniform highp float srandomX;
uniform highp float srandomY;
uniform float filmBreathR;
uniform float filmBreathG;
uniform float filmBreathB;
uniform samplerExternalOES lightLeakTexture;
uniform int usingLightLeak;

uniform sampler2D framePerforationsTexture;

uniform float luminanceMipmapLevel;

uniform float expiredFoggingAmp;
uniform LightLeak lightLeak;
uniform Holes holes;

const highp vec3 linearAprox = vec3(1.0, 0.693147, 3.258891);
const highp vec3 sRGBGamma = vec3(0.45454545454);
const highp vec3 blueStaticColor = vec3(0.6, 0.5, 1.0);
const highp vec3 redStaticColor = vec3(1.0, 0.0, 0.0);
const vec3 sat_weight3 = vec3(0.2125, 0.7154, 0.0721);
out vec4 fragColor;

vec3 toLinear(vec3 v) {
    return pow(v, vec3(2.2));
}

vec3 toGamma(vec3 v) {
    return pow(v, vec3(1.0 / 2.2));
}

highp vec3 toLinearAprox(highp vec3 x){
    return (exp2(x)-linearAprox.r-x*linearAprox.g)*linearAprox.b;
}

vec3 czm_saturation(vec3 rgb, float satur)
{
    vec3 intensity = vec3(dot(rgb, sat_weight3));
    return mix(intensity, rgb, satur);
}

void main() {
    vec4 colorIn;
    colorIn = textureLod(textureInPass3, vTextureCoord, 0.0);

    //tone curve
    vec3 scaledColor = colorIn.rgb * 63.0;
    ivec3 i = ivec3(scaledColor);
    highp vec3 f = scaledColor - vec3(i);
    ivec3 iclamped = clamp(i + 1, 1, 64);
    highp vec3 fclamped = clamp(f, 0.0, 1.0);

    vec3 point1 = vec3(curve[iclamped.r].r, curve[iclamped.g].g, curve[iclamped.b].b);
    vec3 point2 = vec3(curve[iclamped.r + 1].r, curve[iclamped.g + 1].g, curve[iclamped.b + 1].b);

    vec3 curveProcessedColor = vec3(mix(point1, point2, fclamped) + vec3(filmBreathR, filmBreathG, filmBreathB));

    mediump vec3 filmBurnColor;
    if (usingLightLeak==1){
        vec4 lightleakTextureColor;
        lightleakTextureColor = texture(lightLeakTexture, vec2(vTextureCoord.x + srandomX, 1.0 - vTextureCoord.y - srandomY));
        filmBurnColor.rgb = pow(toLinearAprox(lightleakTextureColor.rgb) + toLinearAprox(curveProcessedColor.rgb), sRGBGamma);
    } else {
        filmBurnColor = curveProcessedColor;
    }

    mediump vec3 lightLeakColor;

    mediump float foggingMask;
    foggingMask = 2.5*pow(vTextureCoord.x + srandomX - 0.375, 2.0);
    mediump float screenLuminance;
    screenLuminance = czm_saturation(textureLod(textureLuminance, vec2(0.8, 0.5), luminanceMipmapLevel).rgb, 0.0).r;

    mediump float llTopMask;
    llTopMask = mix(1.0, lightLeak.topMultiplier * pow(abs(vTextureCoord.x + srandomX - 0.625), clamp(lightLeak.top, 0.03, 1.0) * 40.0), smoothstep(0.0, 0.03, lightLeak.top));
    mediump float llBottomMask;
    llBottomMask = mix(1.0, lightLeak.bottomMultiplier * pow(abs(vTextureCoord.x + srandomX - 0.625), clamp(lightLeak.bottom, 0.03, 1.0)*40.0), smoothstep(0.0, 0.03, lightLeak.top));
    mediump float llVerticalMask;
    llVerticalMask = smoothstep(0.0, 1.0, vTextureCoord.y + srandomY);
    mediump float lightLeakMask;
    lightLeakMask = mix(llBottomMask, llTopMask, llVerticalMask);

    //holes
    mediump vec3 holesLinear = vec3(0.0);

    mediump float holesMaskTop = 0.0;
    mediump float holesMaskBottom = 0.0;
    mediump float holesMask = 0.0;
    mediump float holesStencil = 0.0;
    mediump float holesShiftY = mod(mod(1.0 - vTextureCoord.y - holes.seed, holes.internalOffset), holes.externalOffset);
    holesStencil = textureLod(framePerforationsTexture, vec2(vTextureCoord.x, holesShiftY) + vec2(srandomX, - srandomY), 0.0).a;

    holesMaskTop = holes.xMultiplier.x*pow(abs(vTextureCoord.x + srandomX - 0.625), holes.amountX.x * 40.0)*max(0.0, 1.0 - 7.5957*pow(abs(holesShiftY - holes.amountY.x), 1.5));
    holesMaskBottom = holes.xMultiplier.y*pow(abs(vTextureCoord.x + srandomX - 0.625), holes.amountX.y * 40.0)*max(0.0, 1.0 - 7.5957*pow(abs(holesShiftY - holes.amountY.y), 1.5));
    holesMask = mix(holesMaskBottom, holesMaskTop, llVerticalMask);
    holesLinear = clamp(toLinearAprox(holesStencil * holesMask * blueStaticColor * holes.amp /*+ 0.4*holesMask*/), 0.0, 1.0);


    lightLeakColor = pow(
    toLinearAprox(filmBurnColor.rgb) +
    toLinearAprox(foggingMask * blueStaticColor * expiredFoggingAmp * (1.0 - screenLuminance)) +
    clamp(toLinearAprox(lightLeakMask * redStaticColor * lightLeak.amp), 0.0, 1.0) +
    holesLinear, sRGBGamma);

    fragColor = vec4(lightLeakColor.rgb, 1.0);
} 