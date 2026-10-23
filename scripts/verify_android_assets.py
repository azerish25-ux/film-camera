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
noiseOriginal=(assets/'e4e45cae0068917f80a90a1a8380ee5ac1176e88').read_bytes()
noiseCompressed=(root/'Reference/AndroidNoise.etc1').read_bytes()
assert noiseOriginal[16:]==noiseCompressed
noiseDecoded=(root/'FilmCamera/Resources/OriginalAssets/e4e45cae0068917f80a90a1a8380ee5ac1176e88.noise').read_bytes()
assert len(noiseDecoded)==1024*1024*4
masks=[]
for shipped in (root/'FilmCamera/Resources/OriginalAssets').glob('*.png'):
    original=(assets/shipped.stem).read_bytes()
    if original[8:16]==b'\0\0\0\rIHDR':
        decoded=Image.open(io.BytesIO(b'\x89PNG\r\n\x1a\n'+original[8:])).convert('RGBA')
        restored=Image.open(shipped).convert('RGBA')
        assert decoded.size==restored.size and decoded.tobytes()==restored.tobytes(),shipped.name
        masks.append(shipped.stem)
for compressed in (root/'Reference/ETC1').glob('*.etc1'):
    assert compressed.read_bytes()==(assets/compressed.stem).read_bytes()[16:]
clips=[]
for shipped in (root/'FilmCamera/Resources/OriginalAssets').glob('*.mp4'):
    # Only the recovered eight-byte file header is transformed. Preserve all
    # encoded samples and container metadata exactly; simulator tests decode them.
    original=next(assets.rglob(shipped.stem)).read_bytes()
    restored=shipped.read_bytes()
    assert original[8:]==restored[8:],shipped.name
    clips.append(dict(asset=shipped.stem,SHA256=hashlib.sha256(restored).hexdigest()))
result=dict(pngMasksVerified=masks,encodedVideoPayloadsVerified=clips,
            noiseOriginalSHA256=hashlib.sha256(noiseOriginal).hexdigest(),
            noiseCompressedSHA256=hashlib.sha256(noiseCompressed).hexdigest(),
            noiseDecodedSHA256=hashlib.sha256(noiseDecoded).hexdigest(),
            filmTablesVerified=len(report),shaderFilesVerified=len(shaders),tables=report)
args.output.write_text(json.dumps(result,indent=2)+'\n')
print(f'Verified {len(report)} original film tables byte-for-byte and {len(shaders)} preserved shader files')
