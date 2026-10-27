# Additional APK metadata audit

The supplied specification was supplemented with targeted inspection of
`lib/arm64-v8a/libnative-camera-host.so` from the same verified Raw.apk.
Ghidra 12.1.4, using the supplied ARM64 ELF symbols, confirmed:

| Ghidra address (ELF + 0x100000) | Function | Finding |
| --- | --- | --- |
| 0x00652174 | RawCameraMetadata::parse | Camera calibration illuminants are parsed through IlluminantFromString |
| 0x00653000 | RawCameraMetadata::toJson | Color illuminants are serialized through IlluminantToString |
| 0x0062b0a8 | color::IlluminantToString | Exact labels: standarda, standardb, standardc, d50, d55, d65, d75 |
| 0x00652fe0 / 0x00652fe8 | getBlackLevel overloads | Both return the stored camera black-level vector at +0x288 |
| 0x00652ff0 / 0x00652ff8 | getWhiteLevel overloads | Both return the stored camera white level at +0x280 |

MotionDNG preserves these labels as standard DNG illuminant codes (17,18,19,
23,20,21,22 respectively). Missing illuminants retain the published decoder's
D65/Standard A fallback; unknown supplied illuminants are rejected.

This prevents replacing actual camera calibration with hardcoded light sources.
The binary also confirms both sensorArrangment (historical spelling) and
sensorArrangement strings; the reader accepts both. Dynamic black/white strings
exist, but the inspected 1.2.7 camera accessors return stored camera levels.

Local extraction, Ghidra scripts, project, decompilation, logs, settings and caches
remain under IOS Port/.tools/motioncam-analysis and artifacts/motioncam-analysis.
They are ignored by Git. No Android binary or full decompilation is bundled in the
iOS application. The old launcher initially used its existing C settings path;
its newly created cache directories were relocated into the D analysis directory.
Subsequent analysis directly sets application.settingsdir, application.cachedir,
application.tempdir and user.home to D paths.
