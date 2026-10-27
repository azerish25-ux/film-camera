# Blackmagic Camera APK investigation

This is a working inventory, not a claim of complete parity. The source is the
user-supplied `Bmc.apk`, package `com.blackmagicdesign.android.blackmagiccam`,
version `3.2.1.0001`, SHA-256
`fc27ba8fe3537b277f11341c9ea22e5ca79f0fd101b6c192d2d1e2241676c12d`.

The local D: workspace contains Apktool 3.0.3 output, the REA checkout and
REA's JADX package evidence. The independently generated JADX source has 261
decompilation errors; absent or malformed output cannot establish that a
feature is absent. Android resources, shader sources, smali and native binaries
remain available for corroboration.

## Feature families found in resources

* Camera controls: lens, focus and exposure, ISO, shutter, white balance,
  frame rate, stabilization, time lapse and anamorphic monitoring.
* Monitoring: exposure and focus aids, zebra, false color, guides, grids,
  histogram, audio meters and LUT display.
* Recording and media: codecs, quality, resolution, audio source and gain,
  clip metadata, timecode, local and external storage, media review and LUTs.
* Connections: remote camera control and monitoring, clip synchronization,
  streaming, Blackmagic Cloud and accessory integration.

Resource labels show that these features exist; they do not by themselves
establish the behavior, supported configurations, protocols or compatibility.
These families require method-level tracing, native analysis and, where
appropriate, physical-device and service tests.

## Initial monitoring port

`assets/glsl/false_color_effect.glsl` specifies Rec. 709 gamma decoding, CIE
lightness and the color bands implemented by `BMCMonitor`. The APK also contains
HLG and P3 paths and precomputed luminance LUTs. `zebra_effect.glsl` specifies
the two middle-gray intervals, threshold comparison and diagonal stripes.
The current preview uses a Rec. 709 equation instead of the APK's selected
luminance LUT; color management, stripe geometry, animation, other color
spaces and interaction with other aids need reference validation. Neither
overlay is applied to recorded media. The initial Swift implementation and
simulator tests are a starting point, not proof of visual parity.

The APK's `EftGuideState` lists eleven frame ratios from 2.76:1 through
9:16. Its secondary settings also list thirds, crosshairs, center dot, level,
safe area and separate colors and opacity. The initial Swift preview includes
the ratios, thirds, crosshairs and dot. Its geometry and appearance still need
comparison against an Android device; level, safe area and color remain open.

## Open work

Trace each family above to its settings, state transitions, media pipeline and
platform dependencies. Record feature-by-feature implementation and test
evidence, including unsupported Apple hardware capabilities and any service or
protocol requirements, before declaring parity.

## Clip metadata evidence

`BmdMetadata` in the decompiled APK defines QuickTime metadata keys including
`com.blackmagic-design.camera.reelNumber`, `.scene`, `.take`, `.dayNight`,
`.environment`, `.goodTake`, `.projectName`, `.cameraNumber`, `.director`,
`.cameraOp` and `.look.LUTName`. It also names exposure, lens, audio and video
properties, and Apple ProApps keys for reel, scene, shot and log notes.
`media/manager/C5911f` writes these as keyed metadata, and the APK contains a
separate MOV timecode editor. A future AVFoundation port must preserve existing
metadata and timecode, handle non-MOV inputs deliberately, and verify exported
files by reading their actual metadata; matching labels alone is insufficient.
The initial Swift slate writes a subset of those keys using AVFoundation during
movie export; its round-trip simulator test is pending.
