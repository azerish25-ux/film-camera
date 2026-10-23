import numpy as np
from pathlib import Path
import os
os.chdir(Path(__file__).resolve().parents[1])
w,h=128,96
noise=np.frombuffer(Path('FilmCamera/Resources/OriginalAssets/e4e45cae0068917f80a90a1a8380ee5ac1176e88.noise').read_bytes(),np.uint8).reshape(1024,1024,4)[:,:,:3].astype(np.float32)/255
expected=np.frombuffer(Path('FilmCamera/Resources/AndroidReference/grain.rgba').read_bytes(),np.uint8).reshape(h,w,4)[:,:,:3]
x,y=np.meshgrid(np.arange(w),np.arange(h));uv=np.stack([x+.5,y+.5],axis=-1).astype(np.float32)
source=np.stack([1+x*253//127,1+y*253//95,1+(x+y)*253//222],axis=-1).astype(np.float32)/255
scale=np.float32((.5-.4*.4)*2);p=uv*scale;cell=np.floor(p);f=p-cell
power=np.float32(1+63*(1-.3)**6)
def sample(positions):
 q=positions/scale-.5;lo=np.floor(q).astype(int);frac=q-lo
 out=np.zeros((h,w,3),np.float32)
 for a in [0,1]:
  for b in [0,1]:
   weight=(frac[:,:,0] if a else 1-frac[:,:,0])*(frac[:,:,1] if b else 1-frac[:,:,1])
   out+=source[np.clip(lo[:,:,1]+b,0,h-1),np.clip(lo[:,:,0]+a,0,w-1)]*weight[:,:,None]
 return out
for sx,sy in [(0,0),(-1,0),(0,-1),(-1,-1),(1,0),(0,1),(1,1)]:
 total=np.zeros((h,w,3),np.float32);weights=np.zeros((h,w),np.float32)
 for corner in [( .5,.5),(-.5,-.5),(.5,-.5),(-.5,.5)]:
  center=cell+corner;lookup=np.floor(center).astype(int)+np.array([37*71+1+sx,-17*71+1+sy])
  n=noise[lookup[:,:,1]%1024,lookup[:,:,0]%1024][:,:,[1,0,2]]
  jitter=np.mod(n[:,:,:2]*10,1)
  c=sample(center+jitter)
  d=np.clip(np.sqrt(np.sum((np.array(corner)-f+jitter)**2,axis=-1))/2.828,0,1)
  weight=(1-d*d*(3-2*d))**power
  v=(n[:,:,2:3]*(1-.7)+n*.7)*2
  result=c*(1+(v-1)*.15)+.05*v*.15+.2*(1.4-.15)*(v*.15-.5*.15)*np.maximum(1-2*c,0)
  total+=result*weight[:,:,None];weights+=weight
 rgb=total/weights[:,:,None]
 # Original 64-cubed integer Normal Mode lookup.
 q=np.clip(rgb*64-.5,0,63);lo=np.floor(q).astype(int);frac=q-lo
 val=(lo*255//64)*(1-frac)+(np.minimum(lo+1,63)*255//64)*frac
 actual=np.clip(np.round(val),0,255).astype(np.uint8)
 delta=np.abs(actual.astype(int)-expected.astype(int))
 print(sx,sy,'mean',delta.mean(),'max',delta.max())
