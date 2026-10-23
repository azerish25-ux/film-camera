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
Path('FilmCamera/Resources/reference-cases.json').write_text(json.dumps(cases,indent=2))
