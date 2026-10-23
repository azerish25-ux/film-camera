#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME}}
sdkmanager 'platforms;android-29' 'build-tools;35.0.0'
TOOLS="$SDK/build-tools/35.0.0"
JAR="$SDK/platforms/android-29/android.jar"
WORK="$ROOT/scripts/android-reference/out"
mkdir -p "$WORK/classes" "$WORK/dex" "$WORK/assets" "$ROOT/android-reference"
cp FilmCamera/Resources/Shaders/*.glsl "$WORK/assets/"
cp FilmCamera/Resources/reference-cases.json "$WORK/assets/"
javac -source 8 -target 8 -classpath "$JAR" -d "$WORK/classes" scripts/android-reference/src/com/azerish/reference/ReferenceActivity.java
"$TOOLS/d8" --lib "$JAR" --output "$WORK/dex" "$WORK/classes/com/azerish/reference/ReferenceActivity.class"
"$TOOLS/aapt" package -f -M scripts/android-reference/AndroidManifest.xml -I "$JAR" -A "$WORK/assets" -F "$WORK/reference.apk"
(cd "$WORK/dex" && zip -q -j "$WORK/reference.apk" classes.dex)
keytool -genkeypair -keystore "$WORK/debug.jks" -storepass android -keypass android -alias androiddebugkey -dname 'CN=CI Reference' -keyalg RSA -validity 30
"$TOOLS/apksigner" sign --ks "$WORK/debug.jks" --ks-pass pass:android "$WORK/reference.apk"
adb install -r "$WORK/reference.apk"
adb shell am start -n com.azerish.reference/.ReferenceActivity
for i in $(seq 1 90); do
  if adb shell run-as com.azerish.reference test -f files/done; then break; fi
  if adb shell run-as com.azerish.reference test -f files/error; then adb shell run-as com.azerish.reference cat files/error; exit 1; fi
  sleep 2
done
adb shell run-as com.azerish.reference test -f files/done
for name in exposure-vignette chromatic halation-high halation-blur halation-merge film-blur film-lut-saturation grain; do
  adb exec-out run-as com.azerish.reference cat "files/$name.rgba" > "android-reference/$name.rgba"
done
adb exec-out run-as com.azerish.reference cat files/renderer.txt > android-reference/renderer.txt
cp FilmCamera/Resources/reference-cases.json android-reference/
