from pathlib import Path
import subprocess,shutil,time,hashlib
root=Path.cwd();destination=Path(r'D:/IOS APPS/IOS APP 1/IOS Port')
files=subprocess.check_output(['git','ls-files','-z']).decode().split('\0')
count=0
for name in files:
 if not name:continue
 source=root/name;target=destination/name
 for attempt in range(12):
  try:
   target.parent.mkdir(parents=True,exist_ok=True)
   if not target.exists() or hashlib.sha256(source.read_bytes()).digest()!=hashlib.sha256(target.read_bytes()).digest():shutil.copyfile(source,target)
   if hashlib.sha256(source.read_bytes()).digest()!=hashlib.sha256(target.read_bytes()).digest():raise OSError('Hash mismatch')
   count+=1;break
  except OSError:
   if attempt==11:raise
   time.sleep(5)
print('Verified on D:',count,'tracked files')
