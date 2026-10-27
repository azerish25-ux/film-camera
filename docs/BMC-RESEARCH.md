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

The D: workspace's `inventory-smali.cjs` recorded 17,199 class declarations
and 123,886 method declarations across the three decoded DEX files. Of these,
5,216 classes and 28,622 methods use the `com.blackmagicdesign.android`
namespace. The JSONL ledger identifies each method and its smali file; it is an
inventory, not proof of behavioral analysis. Namespace counts omit obfuscated
application code and include generated code. Native functions are separate.

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

The APK's `AppSettings` adds concrete configuration evidence for recording
codec, bit rate, open gate, color space and tags, proxy recording, recording
LUTs, audio format/routing/rate/metering, storage destination, location,
orientation, desqueeze, lens correction, sharpening, noise reduction, HDMI
output, remote camera synchronization, cloud uploads, streaming, Bluetooth and
accessories. `SecondaryControlsData` adds exposure/focus modes and values,
zoom, stabilization, false color, zebra, focus assist and multiple guides.
These declarations are a discovery checklist, not confirmation that Swift
implements each setting or that an iPhone supports the same hardware modes.

For native analysis, the D: workspace includes dynamic-symbol inventories for
all arm64 libraries, including cloud authentication/storage/chat/router,
streaming, USB, timecode accessories and audio. Exported symbols identify API
boundaries but are not a decompilation of their implementations.
Ghidra additionally produced a D:-local decompilation of 52 JNI entries from
`libbmddavcloudclient.so`; one entry was unavailable. These wrappers call into
the larger native cloud library, which still requires analysis and service-level
validation.
The same process recovered 5 audio, 1 LUT parser, 49 remote-streaming and
160 timecode-accessory JNI entry points; two accessory entries were unavailable.
The results still need call-chain analysis and cannot be counted as a completed
port simply because a decompiler produced C-like output.
The remote-streaming JNI interface explicitly includes SDP offer/answer, ICE
candidates, data-channel messages, video/audio buffers and stream lifecycle;
its names indicate a WebRTC-style transport. Session signaling, protocol
messages, authentication, negotiation and interoperation still need tracing.
AVFoundation can supply camera and audio buffers but does not by itself provide
the whole transport or establish interoperability with the Android app.

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

`C8955i` and its callers specify black stripes with width 8 and a shift that
advances on each draw and resets after twice that width. The Swift preview now
models these values; pixel-level Android comparison remains outstanding.

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
movie export. GitHub Actions run 40432765227 passed a simulator round-trip test
for reel, scene and take. This does not establish parity for the remaining
metadata fields, timecode tracks, editing existing clips or physical devices.

## Focus assist evidence

`focus_assist_effect.glsl` applies a 5×5 Laplacian to the red camera channel,
with separate colored-line and peaking branches. `C8949c` scales the configured
focus-assist value by 0.04 before passing it to the shader; `FocusAssist`
selects colored lines or peaking, and `FocusAssistColor` lists white, black,
red, green and blue. The existing MotionCam focus peaking is a different
algorithm. An initial Core Image implementation uses the recovered kernel and
the rendered preview as its edge source; its simulator test and the APK's exact
input range, camera-texture sampling, transform order and Android pixel output
remain to be validated.

## Manual white balance

The APK's `CameraManager$setManualWhiteBalance` clamps temperature and tint to
the Android camera's reported ranges before applying them. The initial iOS
control converts temperature and tint to device-specific gains with
AVFoundation, verifies custom-gain support and clamps every channel to the
device's legal range. The UI's ranges and the resulting camera color require
physical-device comparison; matching Android's camera calibration is not yet
established. The simulator can validate the bounds calculation but has no camera
hardware for this test.
