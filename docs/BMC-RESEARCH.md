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
The checked-out REA 6.8.0 source was compiled on D: with a verified portable
Node runtime and successfully inspected the APK; its package evidence is saved
as `rea-source-package.json` in the D: analysis workspace.
The D:-local Apktool checkout at `fd9d5d4` was built with Gradle and decoded the
APK's resources separately as `3.1.0-dirty`; the original full smali decode
used Apktool 3.0.3. The `dirty` version label comes from the shallow checkout
without a reachable release tag, not a claim that the APK was modified.
An additional text scan found 444 `Method not decompiled` markers and 278
`Code decompiled incorrectly` markers across the generated sources. These may
overlap and are not equivalent to JADX's 261 reported errors. The file list is
saved on D: for smali fallback and method-by-method follow-up.
An additional JADX `simple` pass reduced its reported errors to 52 and left
16 `Method not decompiled` markers. It produced a less-structured rendering of
the audio-meter lambda that corroborates the smali extraction; reduced errors
do not establish semantic correctness or replace bytecode review.
REA retrieved bodies for all 16 remaining marked methods: 15 smali fallbacks
and one Java result. The D:-local evidence records include exact class and
method signatures; none is considered semantically complete merely because
its body was retrieved.

The D: workspace's `inventory-smali.cjs` recorded 17,199 class declarations
and 123,886 method declarations across the three decoded DEX files. Of these,
5,216 classes and 28,622 methods use the `com.blackmagicdesign.android`
namespace. The JSONL ledger identifies each method and its smali file; it is an
inventory, not proof of behavioral analysis. Namespace counts omit obfuscated
application code and include generated code. Native functions are separate.
The largest named-package method counts are camera 8,088, settings 4,214,
cloud 4,087, remote 3,427, metadata editor 2,327, protobuf 2,322 and media
1,672. These are declaration counts, not feature counts or completed ports.
REA's APK artifact graph and obligation-ledger output are also saved on D:.
For the supplied static graph the generated ledger reports unknown, partial
coverage and zero automatically generated obligations; that result is not a
claim that the APK has no remaining work. The separate smali inventory keeps
unreviewed methods visible.

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
The recorder's `VideoCodecFormat` enum names H.264, HEVC, AV1 and APV. Actual
availability is device-dependent. The current iOS pipeline records a movie and
then exports a graded movie; it does not yet expose or prove equivalent codec,
profile, bitrate, bit-depth or color-space selection. Selecting an Apple codec
with similar characteristics does not establish APV bitstream compatibility.
An initial H.264/HEVC capture and export selection is being added locally. It
checks the camera output's advertised codecs and supported settings before
selecting a capture codec, then re-encodes the film output using the same codec.
This does not yet implement BMC bitrate, profile, APV or AV1 choices. Simulator
tests can check the export when supported, but cannot prove camera hardware
capture behavior.

The native CUBE parser recognizes per-channel `LUT_3D_INPUT_RANGE_R`, `_G`
and `_B` directives as well as `DOMAIN_MIN` and `DOMAIN_MAX`. The current
Swift parser rejects the former. Its normalization and interpolation must be
traced and tested against actual APK output before claiming LUT import parity.

The APK bundles 41 named 33³ RGBA lookup tables: 10 each for Rec. 709, P3 D65
and Rec. 2020, plus 11 for Samsung Log HDR. Their serialized records declare no
1D table and no input/output video-range flag. A local Swift catalog now exposes
the extracted tables with stable IDs and SHA-256 checks, without serializing
the cube data into user settings. The existing film renderer resamples custom
tables to 64³ and does not automatically convert the selected profile, so
this integration is not yet a pixel-identical BMC LUT pipeline. Catalog and
restoration tests are awaiting simulator validation.
Local display-versus-record switches are being integrated: the selected LUT can
be shown in the viewfinder independently from applying it to exported movies
or timelapse frames. The app's underlying film look remains active in either
case; the routing and full BMC color management still require verification.
Portable Swift run 40442261643 verified that all 41 manifest IDs decode and
that the referenced tables have the expected byte lengths; it does not replace
the app-bundle loading, checksum or persistence tests.

For native analysis, the D: workspace includes dynamic-symbol inventories for
all arm64 libraries, including cloud authentication/storage/chat/router,
streaming, USB, timecode accessories and audio. Exported symbols identify API
boundaries but are not a decompilation of their implementations.
The passes described below target the APK's arm64 libraries. A separate
`armeabi-v7a` decompilation pass has started; ABI comparison remains open.
Ghidra additionally produced a D:-local decompilation of 52 JNI entries from
`libbmddavcloudclient.so`; one entry was unavailable. These wrappers call into
the larger native cloud library, which still requires analysis and service-level
validation.
The same process recovered 5 audio, 1 LUT parser, 49 remote-streaming and
160 timecode-accessory JNI entry points; two accessory entries were unavailable.
The results still need call-chain analysis and cannot be counted as a completed
port simply because a decompiler produced C-like output.
An additional Ghidra pass generated C-like output for 509 non-thunk functions
in the cloud JNI library, with zero reported decompiler failures. This is a
static decompilation count, not a guarantee that behavior is understood or
that indirect calls, other libraries or external services are covered.
The larger `libdavcloudclient.so` pass produced 22,236 function outputs; two
initial timeouts produced output on a longer retry. The GCC exception-handler
analyzer was disabled after it stalled; exception metadata and any affected
control flow require separate review. Decompilation is not behavioral proof.
The D: workspace also contains `readelf` section and frame-information output
for the cloud library. Its `.gcc_except_table` and `.eh_frame` sections are
present; their existence or a frame dump does not resolve the skipped
exception-handler control flow.
Static cross-references found the cloud API URL format at `0039f2d3` with a
reference from `00656e10`, which Ghidra did not associate with a function.
The `wss://` literal is referenced from `sio::client_impl::connect_impl`.
These observations do not identify the complete authentication or service
contract.
Separate media-core passes produced 1,973 function outputs for
`libdavstream.so` and 14,166 for `libdavstreamd.so`, with no reported
decompiler failures. A pass over `libnativeplayer.so` produced 6,218 outputs
with no reported failures. GCC exception analysis was disabled for these passes as
well; call paths, exception handling and runtime behavior remain open. The
all-function script excludes external functions and thunks, so its totals are
not a complete native function inventory.
The remote-streaming JNI interface explicitly includes SDP offer/answer, ICE
candidates, data-channel messages, video/audio buffers and stream lifecycle;
its names indicate a WebRTC-style transport. Session signaling, protocol
messages, authentication, negotiation and interoperation still need tracing.
AVFoundation can supply camera and audio buffers but does not by itself provide
the whole transport or establish interoperability with the Android app.
The native wrapper also exposes a distinct `NativeSRTGstreamer` pipeline. Its
transport configuration, latency, reconnect behavior and relationship to the
live-stream UI still need method-level tracing.
The decoded dependency provider registers Bonjour discovery for
`_bmd-cam-control-android._tcp` and `_bmd-cam-control._tcp`, and the APK has
WebSocket and TCP signaling components. These are discovery observations only;
do not advertise or connect using guessed message formats or credentials.
The Android NSD registration writes TXT keys `name`, `slate_name`,
`model_name`, and `proto` (major and minor separated by a dot). Its legacy
resolve callback interprets the service name as a UUID and requires the first
three values, and it accepts optional controller information in `ctrl_uuid`,
`ctrl_name`, `ctrl_slate_name`, `ctrl_model_name`, and `ctrl_proto`. The Swift
record parser and portable tests cover these fields; no discovery transport or
peer interoperability is established. The Android TCP signaling socket writes
UTF-8 messages terminated by a newline and reads them with `readLine`; this
does not establish framing for WebSocket or data-channel traffic.
The v5 signaling code uses a 32-byte nonce from each peer and a 15-second
authentication timeout. The recovered two-stage SHA-256 challenge calculation
has a standalone CryptoKit implementation and a deterministic test vector;
pairing, state transitions, secure nonce generation, transport, control messages
and live interoperation are not implemented by that primitive alone.
The decoded wire serializer uses a JSON envelope with `type` and `data`; its
message types include hello request/response, connection request/response,
bye, ICE candidate and SDP offer/answer. Participant fields include UUID,
model, device and slate names, and major/minor protocol versions. The decoder
accepts some fields that the shown encoder does not emit, so both sides and
failure paths must be tested before implementing the state machine. An initial
Swift JSON codec and tests are present locally; they are not a connection or an
interoperability test.
The client expects a hello response after its hello request, derives the
challenge response, sends a connection request and transitions to authorized
only after an authorized response. A Swift client handshake building block and
ordered-message tests are present locally, without transport, timeout or
hardware interoperability. The server's decompiled state checks have
an asymmetry around connection requests and the initial password state; the
same branch is present in smali. The surrounding runtime path and its security
impact remain unverified. A port needs an explicit, tested handshake state
machine rather than assuming the decompiler output proves end-to-end behavior.

## Initial monitoring port

`assets/glsl/false_color_effect.glsl` specifies Rec. 709 gamma decoding, CIE
lightness and the color bands implemented by `BMCMonitor`. The APK also contains
HLG and P3 paths and precomputed luminance LUTs. `zebra_effect.glsl` specifies
the two middle-gray intervals, threshold comparison and diagonal stripes.
The current preview now uses the recovered Rec. 709 luminance LUT; color
management, stripe geometry, animation, other color spaces and interaction
with other aids need reference validation. Neither
overlay is applied to recorded media. The initial Swift implementation and
simulator tests are a starting point, not proof of visual parity.
For the synthetic 128×96 gradient, a local CPU model found that analytic
luminance and trilinear sampling of the 8-bit APK table chose different
false-color bands at 43 pixels and different zebra thresholds at 9 pixels. The
model is not a GPU measurement; the Android/iOS workflow will test the actual
renderers.

`Reference/BMC` holds the APK's four monitoring shader snippets and its
33-cubed Rec. 709 luminance byte table extracted from Java serialization. The
table SHA-256 is `3736d238eab34b8458f55ad294803576b9df4ddd6bb6c98eb224cb7719386c05`.
The APK expands each luminance byte to RGBA, uploads a 3D texture and uses
linear filtering with edge clamping; it does not reorder the array in that
upload path. The harness uses an equivalent single-channel 3D texture.
`BMCReferenceMain` runs those snippets with synthetic images in Android GLES;
a dedicated workflow generates reference frames and compares them to iOS.
This is a shader harness, not execution of the BMC APK or evidence of hardware
camera behavior. The first comparison is pending and may expose differences.

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

`TimeCode` exposes record-run, time-of-day and Tentacle sources. The APK's MOV
timecode editor creates a `tmcd` track and, when adding a new track, writes a
four-byte starting frame count calculated as `secondsOfDay * fps + startingFrame`.
It uses a nanosecond timescale and integer fps in the shown method. This does
not establish drop-frame or external-device synchronization behavior; those
paths still require tracing and a round-trip timecode-track test.
`BMCTimecode` implements the integer starting-frame calculation and big-endian
sample bytes as a standalone building block.
Portable Swift workflow 40441277432 passed its calculation, audio-meter and
signaling-codec checks on Linux. This does not validate the iOS media writer or
Android interoperability.
The recorder's `C1170b.m2182a` returns local time-of-day in milliseconds and
frame zero for both `RECORD_RUN` and `TIME_OF_DAY` in this track-generation
path; the Tentacle branch instead queries the synchronized device and may
return an unavailable sentinel. This does not by itself establish how the
display counter behaves or how recording transitions are synchronized.
The native Tentacle library exposes conversions between timecode, elapsed
seconds and a received timestamp, with a separate drop-frame branch. Ghidra's
current C-like output has uncertain ARM floating-point argument recovery, so
those conversions have not yet been ported or verified.
Apple's AVAssetWriter supports a QuickTime timecode input, format description,
sample and video-track association. The current exporter uses
AVAssetExportSession and does not create such a track. An isolated AVAssetWriter
remux path and reader-based round-trip test are present. Simulator run
40452303237 passed the isolated round-trip after the reader skipped its initial
zero-sample marker; the writer is not connected to capture.
The Swift writer uses the recovered integer-fps nanosecond frame duration, but
currently makes its single timecode sample span the movie as in Apple's writer
guidance. The APK editor's shown sample table uses a one-frame duration; that
difference needs playback and interoperability investigation.

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

The Android GLES reference run 40447045282 and its iOS simulator comparison
executed recovered shaders on a synthetic 128×96 image. Focus matched in the
tested interior; false color differed in 39 channel values at band boundaries
and zebra differed in 4,584 channel values. Saved outputs showed Android's
stripe phase follows bitmap-row `x + y + 1`, while the original Swift kernel
followed `x - y` because Core Image destination coordinates are vertically
reversed relative to bitmap rows. The Swift stripe calculation was changed to
account for the image extent. Diagnostic run 40449059896 reduced zebra
differences to six channel values, while false color still differed in 39.
Its float fixtures showed a maximum interior luminance difference of about
0.0004 between the iOS simulator and Android SwiftShader. Those measurements
come from emulators, not physical camera GPUs. Luminance-table interpolation
and the remaining threshold differences remain open.

## Manual white balance

The APK's `CameraManager$setManualWhiteBalance` clamps temperature and tint to
the Android camera's reported ranges before applying them. The initial iOS
control converts temperature and tint to device-specific gains with
AVFoundation, verifies custom-gain support and clamps every channel to the
device's legal range. The UI's ranges and the resulting camera color require
physical-device comparison; matching Android's camera calibration is not yet
established. The simulator can validate the bounds calculation but has no camera
hardware for this test.
The enum's static initializer in smali resolves the presets that JADX failed to
reconstruct: Sunny 5600 K / tint 10, Tungsten 3200 / 0, Fluorescent 4000 / 15,
Shady 4500 / 15 and Cloudy 6500 / 10. The Swift UI exposes these values; device
gain conversion can still produce different results from Android calibration.

## Exposure modes

`AutoExposurePriority` distinguishes combined shutter/ISO, ISO-only and
shutter-only automation. The current iOS camera UI exposes automatic exposure
and a combined manual ISO/shutter setting; it does not yet reproduce these
priority modes. Trace the Android control loop and determine how to implement
the corresponding behavior with iOS capture-device exposure APIs and real
hardware feedback before marking this capability complete.
The flicker-free option delegates to Android Camera2's
`CONTROL_AE_ANTIBANDING_MODE` for off, 50 Hz, 60 Hz or auto after checking
camera support. An iOS shutter-duration approximation would require device
testing and should not be presented as the same OEM auto-exposure behavior.

## Time lapse

The APK's `TimelapseInterval` enumerates intervals of 2–10 source frames,
1–10 seconds, 20/30/40/50 seconds and 1–10 minutes. The existing MotionCam
implementation has a 0.25-second minimum, a 60-second UI maximum, and fixed
24 fps playback. It therefore does not cover all recovered BMC intervals or
necessarily match BMC's output timing. Trace frame selection and output rate
before replacing that implementation; a simulator-only test cannot prove
camera frame pacing or dropped-frame behavior.

## Audio metering

The APK exposes VU and PPM modes with -18 dBFS and -20 dBFS references.
`AbstractC1048b` maps the meter's integer level and peak state to displayed
values using a `20 * log10(32767)` reference. `C0728a` contains per-channel
state, peak/hold timing and update constants; its processing lambda was not
decompiled by the initial JADX pass. REA recovered a complete smali fallback
for `C2.a.invoke`; its meter branch accumulates absolute 16-bit samples and
per-window maxima, maintains a rolling sum and applies separate decay and
peak-hold behavior. An initial Swift state translation, synthetic-sample tests
and microphone callback integration are local. The callback currently handles
only signed, interleaved 16-bit PCM and reports other formats as unavailable.
The tests have not yet run in the simulator; Android sample-by-sample and real
microphone comparisons are still needed.
