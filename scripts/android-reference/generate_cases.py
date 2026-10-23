"""Generate a deterministic Android/iOS shader comparison matrix from shipped assets.
No expected pixels are produced here: those are rendered by Android GLES in CI.
"""
from pathlib import Path
from copy import deepcopy
import json
ROOT = Path(__file__).resolve().parents[2]
base = json.loads((Path(__file__).with_name('base-cases.json')).read_text())
cases = deepcopy(base)
by_name = {c['name']:c for c in base}
def variant(template, name, **changes):
    c = deepcopy(by_name[template]); c['name'] = name
    for key,value in changes.items():
        if isinstance(value,dict): c[key].update(value)
        else: c[key] = value
    cases.append(c)
# Exercise every original film, including Normal Mode, over the complete color cube,
# a spatial gradient, and the black-to-white neutral axis; saturation extremes too.
films = json.loads((ROOT/'FilmCamera/Resources/film-catalog.json').read_text())
for index,film in enumerate(films):
    for pattern in range(3):
        for saturation in (0,0.7,1,2):
            variant('film-lut-saturation',f'film-{index:02d}-p{pattern}-s{saturation}',
                    look=film['name'],lookAsset=film['asset'],pattern=pattern,
                    floats={'saturation':saturation})
    # Actual colored LUT + grain, not just the neutral lookup table.
    variant('grain',f'film-{index:02d}-grain',look=film['name'],lookAsset=film['asset'],pattern=1)
# Branches and control endpoints, plus intermediate values where sampling matters.
for key,values in {'grainStrength':[0.001,0.5,1], 'grainSize':[0,0.27,0.5,1],
                   'grainSmoohtness':[0,0.5,1], 'grainChroma':[0,0.5,1],
                   'grainDarkLevel':[0,0.5,1]}.items():
    for v in values:
        variant('grain',f'grain-{key}-{v}',floats={key:v},pattern=1)
for seed in (0,1,142,499): variant('grain',f'grain-seed-{seed}',ints={'seed':seed},pattern=1)
for v in (0.125,1,8):
    variant('exposure-vignette',f'exposure-{v}',floats={'pseudoExposure':v},pattern=1)
for key in ('contrast','vignetteFalloff'):
    for v in (0,1,2 if key=='contrast' else 0.99):
        variant('exposure-vignette',f'{key}-{v}',floats={key:v},pattern=1)
for v in (0,0.02,0.5,1): variant('chromatic',f'chroma-{v}',floats={'chroma_value':v},pattern=1)
for v in (0,0.002,0.5,1): variant('halation-high',f'halation-intensity-{v}',floats={'halationIntensity':v},pattern=1)
for v in (0,0.35,0.995): variant('halation-high',f'halation-cutoff-{v}',floats={'halationCuttoff':v},pattern=1)
for offset in (0.5,1.5,5.5,10.5):
    variant('halation-blur',f'halation-radius-{offset}',floats={'redHalationOffset':offset},pattern=1)
    variant('film-blur',f'blur-radius-{offset}',floats={'blurOffset':offset},pattern=1)
for template in [c['name'] for c in base if c['name'].startswith('gate-')]:
    variant(template,template+'-shift',floats={'randomX':0.023,'randomY':-0.037})
# Explicit dirt branches that the old fixtures disabled.
for template in ('grain','film-lut-saturation'):
    variant(template,template+'-dirt',ints={'stain.time':1,'stain.x':10,'stain.y':12,'stain.w':20,'stain.h':20,
        'scratch.time':1,'scratch_v.time':30},floats={'scratch.x':40,'scratch.y':40,'scratch.vx':0.6,'scratch.vy':0.8,
        'scratch.len':60,'gScratchesColor':0.5,'gVerticalScratchIntensity':0.5},
        arrays={'stain.mask':[0.4]*576,'scratch.D':[i/100 for i in range(100)],
                'scratch_v.x':[20+i for i in range(8)],'scratch_v.t':[0.5]*8})
for v in (0,0.5,1):
    variant('tone-curve',f'tone-leaks-{v}',floats={'expiredFoggingAmp':v,'lightLeak.amp':v,'holes.amp':v})
assert len({c['name'] for c in cases}) == len(cases)
(ROOT/'FilmCamera/Resources/reference-cases.json').write_text(json.dumps(cases,indent=2)+'\n')
print(f'Generated {len(cases)} shader cases covering all {len(films)} films')
