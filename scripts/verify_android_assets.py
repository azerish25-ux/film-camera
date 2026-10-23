"""Verify every shipped film LUT against the supplied original Android assets."""
import argparse, hashlib, io, json
from pathlib import Path
from PIL import Image
parser=argparse.ArgumentParser()
parser.add_argument('android',type=Path)
parser.add_argument('--output',type=Path,default=Path('docs/ANDROID-ASSET-AUDIT.json'))
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
assets=args.android/'editable-apk/assets'
report=[]
for film in json.loads((root/'FilmCamera/Resources/film-catalog.json').read_text()):
    if not film['asset']: continue
    original=assets/film['asset']
    data=original.read_bytes()
    image=Image.open(io.BytesIO(b'\x89PNG\r\n\x1a\n'+data[8:])).convert('RGB')
    assert image.size==(4096,64),film['name']
    raw=image.tobytes()
    packed=b''.join(raw[(g*4096+b*64)*3:(g*4096+b*64)*3+192] for b in range(64) for g in range(64))
    shipped=(root/'FilmCamera/Resources/OriginalAssets'/(film['asset']+'.lut')).read_bytes()
    assert packed==shipped,film['name']
    report.append(dict(film=film['name'],asset=film['asset'],originalSHA256=hashlib.sha256(data).hexdigest(),
                       decodedLUTSHA256=hashlib.sha256(shipped).hexdigest(),byteCount=len(shipped)))
shaders=list((root/'Reference/AndroidShaders').glob('*.glsl'))
for p in shaders:
    assert p.read_bytes()==(root/'FilmCamera/Resources/Shaders'/p.name).read_bytes(),p.name
result=dict(filmTablesVerified=len(report),shaderFilesVerified=len(shaders),tables=report)
args.output.write_text(json.dumps(result,indent=2)+'\n')
print(f'Verified {len(report)} original film tables byte-for-byte and {len(shaders)} preserved shader files')
