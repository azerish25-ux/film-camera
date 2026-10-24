from pathlib import Path
import json,re,math
source=Path('Reference/AndroidJava/OriginalPresets.java').read_text()
ported=json.loads(Path('FilmCamera/Resources/original-presets.json').read_text())
films=json.loads(Path('FilmCamera/Resources/film-catalog.json').read_text())
def split_args(text):
 result=[];start=0;depth=0;quoted=False;escaped=False
 for i,c in enumerate(text):
  if quoted:
   if escaped:escaped=False
   elif c=='\\':escaped=True
   elif c=='"':quoted=False
  elif c=='"':quoted=True
  elif c in '({[':depth+=1
  elif c in ')}]':depth-=1
  elif c==',' and depth==0:result.append(text[start:i].strip());start=i+1
 result.append(text[start:].strip());return result
calls=[]
for match in re.finditer(r'new PredefinedPreset\(',source):
 start=match.end();depth=1;quoted=False;escaped=False
 for i in range(start,len(source)):
  c=source[i]
  if quoted:
   if escaped:escaped=False
   elif c=='\\':escaped=True
   elif c=='"':quoted=False
  elif c=='"':quoted=True
  elif c=='(':depth+=1
  elif c==')':
   depth-=1
   if depth==0:calls.append(split_args(source[start:i]));break
keys=['jitter','shake','flicker','chroma','temperature','tint','saturation','contrast','blur','grain','grainSize','grainSmoothness','grainChroma','grainShadows','vignette','verticalScratch','scratches','scratchColor','perfColor']
def number(text):
 if text=='fValueOf':return 0.0
 return float(text.rstrip('fd'))
frames={'frameMode':'16:9','frameMode2':'Bolex','FrameMode.FILM_SUPER8_BEAULIEU':'Beaulieu','FrameMode.FILM_SUPER16MM_RAW2':'Super 16 raw 2','FrameMode.FILM_SUPER16MM_FRAME':'Super 16 frame','FrameMode.FILM_8MM_RAW':'Super 8mm Canon','FrameMode.FILM_16MM_RAW':'16mm','FrameMode.FILM_SUPER16MM_RAW':'Super 16mm'}
report=[];mismatches=[]
assert len(calls)==len(ported)==10
for args,preset in zip(calls,ported):
 assert len(args)==35
 assert json.loads(args[0])==preset['name']
 expected={key:number(value) for key,value in zip(keys,args[2:21])}
 expected['halation']=number(args[22]) if args[22]!='null' else number(args[21])*0.6
 for key,index in [('halationCutoff',23),('halationRadius',24),('halationGreen',25),('halationBlue',26),('leakBlue',27),('leakRed',28),('leakHoles',29)]:expected[key]=number(args[index])
 expected['exposure']=math.log2(number(args[30]))
 for key,value in expected.items():
  actual=preset['settings']['values'][key]
  if abs(actual-value)>1e-6:mismatches.append({'preset':preset['name'],'field':key,'originalEffective':value,'ported':actual})
 assert preset['settings']['look']==films[int(args[31])]['name']
 assert preset['settings']['frame']==frames[args[34]],(preset['name'],args[34])
 for key,index in [('curveX',32),('curveY',33)]:
  values=[number(v.strip()) for v in args[index].split('{')[1].split('}')[0].split(',')]
  assert values==preset['settings'][key]
 report.append({'preset':preset['name'],'effectiveValues':expected,'film':preset['settings']['look'],'frame':preset['settings']['frame']})
print('Audited all 10 preset names, 28 effective parameters, LUT selections, frame modes and curve coordinates')
print('Mismatches:',mismatches)
Path('docs/PRESET-SOURCE-AUDIT.json').write_text(json.dumps({'presets':report,'mismatches':mismatches},indent=2))
assert not mismatches, 'Original preset settings diverged from Android effective values'
import sys
if '--write-expectations' in sys.argv:
    snapshots=[]
    for args,entry in zip(calls,report):
        curves={}
        for key,index in [('curveX',32),('curveY',33)]:
            curves[key]=[number(v.strip()) for v in args[index].split('{')[1].split('}')[0].split(',')]
        snapshots.append(dict(name=entry['preset'],values=entry['effectiveValues'],look=entry['film'],frame=entry['frame'],**curves))
    Path('FilmCameraTests/Resources/OriginalPresetExpectations.json').write_text(json.dumps(snapshots,indent=2)+'\n')

