from pathlib import Path
import json
cases=[]
def add(name,shader,floats={},vectors={},samplers={},ints={},arrays={}):cases.append(dict(name=name,shader=shader,floats=floats,vectors=vectors,samplers=samplers,ints=ints,arrays=arrays))
add('exposure-vignette','b_f25847e',{'vignetteFalloff':.25,'pseudoExposure':1.2,'contrast':1.15},{'iResolution':[128,96]},{'simpleTexId':'source'})
add('chromatic','b_f25846d',{'chroma_value':.17,'chroma_vignetteFalloff':.1,'chroma_pseudoExposure':1.1,'chroma_contrast':.95},{'chroma_iResolution':[128,96]},{'chromaTexId':'source'})
add('halation-high','c_f25858k',{'halationIntensity':.4,'halationCuttoff':.35},{},{'halationHighSourceTexture':'source'})
add('halation-blur','c_f25857j',{'redHalationOffset':3.5,'halationBlurHueGreen':.3,'halationBlurHueBlue':.04},{'halationBlurResInv':[1/128,1/96]},{'halationBlurTempTexture':'source'})
add('halation-merge','c_f25859l',{'halationMergeIntensity':.3,'halationMergeHueGreen':.3,'halationMergeHueBlue':.04},{},{'textureHalationMergeSource':'source','textureHalationMergeBlur':'background'})
add('film-blur','c_f25856i',{'blurOffset':2.5,'blurFramePadding':.11},{'blurResInv':[1/128,1/96]},{'blurTempTexture':'source'})
add('film-lut-saturation','c_f25866s',{'saturation':.7,'perfColor':0},{'noiseRes':[128,96]},{'grainInputTexture':'source','framePerforationsTexture':'clear','mLutID':'lut'},{'stain.time':0,'scratch.time':0,'scratch_v.time':0})
add('grain','c_f25865r',{'saturation':1,'perfColor':0,'grainStrength':.15,'grainSize':.4,'grainSmoohtness':.3,'grainChroma':.7,'grainDarkLevel':.2},{'noiseRes':[128,96]},{'grainInputTexture':'source','framePerforationsTexture':'clear','mLutID':'lut'},{'seed':71,'stain.time':0,'scratch.time':0,'scratch_v.time':0})
# Exercise every recovered gate compositor with controlled current/adjacent frames.
for label,shader in [('super16','c_f25850c'),('sixteen','c_f25849b'),('super8','c_f25851d'),('raw2','c_f25848a'),('bolex','c_f25853f'),('beaulieu','c_f25854g'),('kiev','c_f25864q'),('arri-frame','c_f25852e')]:
 add('gate-'+label,'frame_'+shader,{}, {},{'mTextureID':'source','mTextureID1':'background','mTextureID2':'source','frameTexture':'background','frameSuper16mm':'source'})
curve=[]
for index in range(66):
 sample=0 if index==0 else 255 if index==65 else (index-1)*4
 curve.extend([sample/255,(sample/255)**.9,(sample/255)**1.1])
add('tone-curve','c_f25861n',{'filmBreathR':.01,'filmBreathG':-.01,'filmBreathB':0,'expiredFoggingAmp':0,'lightLeak.amp':0,'lightLeak.top':1,'lightLeak.bottom':1,'lightLeak.topMultiplier':1/(.625**40),'lightLeak.bottomMultiplier':1/(.625**40),'holes.internalOffset':1,'holes.externalOffset':1,'holes.amp':0,'luminanceMipmapLevel':0},{'holes.amountX':[1,1],'holes.amountY':[0,0],'holes.xMultiplier':[1,1]},{'textureInPass3':'source','textureLuminance':'source','framePerforationsTexture':'clear','lightLeakTexture':'clear'},{'usingLightLeak':0},{'curve':curve})
Path('FilmCamera/Resources/reference-cases.json').write_text(json.dumps(cases,indent=2))
