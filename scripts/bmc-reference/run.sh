#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
SDK=${ANDROID_SDK_ROOT:-${ANDROID_HOME}}
sdkmanager 'platforms;android-29' 'build-tools;35.0.0'
WORK="$ROOT/scripts/bmc-reference/out"
REMOTE=/data/local/tmp/bmc-reference
mkdir -p "$WORK/classes" "$WORK/dex" "$WORK/assets" "$ROOT/bmc-reference"
cp Reference/BMC/* "$WORK/assets/"
javac -source 8 -target 8 -classpath "$SDK/platforms/android-29/android.jar" -d "$WORK/classes" scripts/bmc-reference/BMCReferenceMain.java
"$SDK/build-tools/35.0.0/d8" --lib "$SDK/platforms/android-29/android.jar" --output "$WORK/dex" "$WORK/classes/com/azerish/bmc/BMCReferenceMain.class"
(cd "$WORK/dex" && zip -q -j "$WORK/bmc-reference.jar" classes.dex)
(cd "$WORK" && zip -qr bmc-reference.jar assets)
adb shell "mkdir -p $REMOTE"
adb push "$WORK/bmc-reference.jar" "$REMOTE/bmc-reference.jar"
adb shell "CLASSPATH=$REMOTE/bmc-reference.jar app_process /system/bin com.azerish.bmc.BMCReferenceMain $REMOTE"
for name in false-color-input false-color-android zebra-input zebra-android focus-input focus-android; do
  adb exec-out cat "$REMOTE/$name.rgba" > "bmc-reference/$name.rgba"
  test "$(wc -c < "bmc-reference/$name.rgba")" -eq 49152
done
adb exec-out cat "$REMOTE/renderer.txt" > bmc-reference/renderer.txt
