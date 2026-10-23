from pathlib import Path
import xml.etree.ElementTree as E,json
ns='{http://schemas.android.com/apk/res/android}'
source=E.parse('Reference/launcher_vector_foreground.xml').getroot()
root=E.Element('svg',xmlns='http://www.w3.org/2000/svg',width='1024',height='1024',viewBox='0 0 108 108')
E.SubElement(root,'rect',width='108',height='108',fill='#e93949')
count=0
def convert(element,parent):
 global count
 for child in element:
  if child.tag=='group':
   sx=child.get(ns+'scaleX','1');sy=child.get(ns+'scaleY','1');tx=child.get(ns+'translateX','0');ty=child.get(ns+'translateY','0')
   group=E.SubElement(parent,'g',transform=f'matrix({sx} 0 0 {sy} {tx} {ty})');convert(child,group)
  elif child.tag=='path':
   color=child.get(ns+'fillColor','#ff000000');attrs={'d':child.get(ns+'pathData'),'fill':'#'+color[-6:]}
   if len(color)==9:attrs['fill-opacity']=str(int(color[1:3],16)/255)
   E.SubElement(parent,'path',attrs)
  elif child.tag=='clip-path':
   count+=1;ident=f'clip{count}';clip=E.SubElement(parent,'clipPath',id=ident);E.SubElement(clip,'path',d=child.get(ns+'pathData'));parent.set('clip-path',f'url(#{ident})')
convert(source,root)
Path('FilmCamera/Resources/app-icon.svg').write_bytes(E.tostring(root))
folder=Path('FilmCamera/Assets.xcassets/AppIcon.appiconset');folder.mkdir(parents=True,exist_ok=True)
(folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
Path('FilmCamera/Assets.xcassets/Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
# An iOS icon is rasterized from the original Android vector by macOS CI.
p=Path('project.yml');t=p.read_text().replace('        PRODUCT_BUNDLE_IDENTIFIER:','        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon\n        PRODUCT_BUNDLE_IDENTIFIER:');p.write_text(t)
for file in ['.github/workflows/ios.yml','.github/workflows/swift-check.yml']:
 p=Path(file);t=p.read_text()
 t=t.replace('brew install xcodegen && xcodegen generate','brew install xcodegen librsvg && rsvg-convert -o FilmCamera/Assets.xcassets/AppIcon.appiconset/AppIcon.png FilmCamera/Resources/app-icon.svg && xcodegen generate')
 t=t.replace('          brew install xcodegen\n','          brew install xcodegen librsvg\n          rsvg-convert -o FilmCamera/Assets.xcassets/AppIcon.appiconset/AppIcon.png FilmCamera/Resources/app-icon.svg\n')
 p.write_text(t)
