#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME}}
sdkmanager 'platforms;android-29' 'build-tools;35.0.0'
TOOLS="$SDK/build-tools/35.0.0"
JAR="$SDK/platforms/android-29/android.jar"
WORK="$ROOT/scripts/android-reference/out"
REMOTE=/data/local/tmp/film-reference
mkdir -p "$WORK/classes" "$WORK/dex" "$WORK/assets" "$ROOT/android-reference"
cp FilmCamera/Resources/Shaders/*.glsl "$WORK/assets/"
cp FilmCamera/Resources/reference-cases.json "$WORK/assets/"
cp FilmCamera/Resources/OriginalAssets/e4e45cae0068917f80a90a1a8380ee5ac1176e88.noise "$WORK/assets/noise.rgba"
javac -source 8 -target 8 -classpath "$JAR" -d "$WORK/classes" scripts/android-reference/src/com/azerish/reference/ReferenceMain.java
"$TOOLS/d8" --lib "$JAR" --output "$WORK/dex" "$WORK/classes/com/azerish/reference/ReferenceMain.class"
(cd "$WORK/dex" && zip -q -j "$WORK/reference.jar" classes.dex)
(cd "$WORK" && zip -qr reference.jar assets)
python3 -c 'import subprocess,sys; subprocess.run(sys.argv[1:],check=True,timeout=60)' adb shell "mkdir -p $REMOTE"
python3 -c 'import subprocess,sys; subprocess.run(sys.argv[1:],check=True,timeout=120)' adb push "$WORK/reference.jar" "$REMOTE/reference.jar"
# app_process initializes Android's Java/native API runtime, including EGL/GLES.
# No APK installation or package-manager state is needed for this offscreen test.
python3 -c 'import subprocess,sys; subprocess.run(sys.argv[1:],check=True,timeout=240)' adb shell "CLASSPATH=$REMOTE/reference.jar app_process /system/bin com.azerish.reference.ReferenceMain $REMOTE"
for name in $(python3 -c 'import json; print(" ".join(x["name"] for x in json.load(open("FilmCamera/Resources/reference-cases.json"))))'); do
  adb exec-out cat "$REMOTE/$name.rgba" > "android-reference/$name.rgba"
done
adb exec-out cat "$REMOTE/renderer.txt" > android-reference/renderer.txt
cp FilmCamera/Resources/reference-cases.json android-reference/
