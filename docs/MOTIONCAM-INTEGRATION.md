# MotionCam integration

Source: [supplied reverse-engineering specification](motioncam/REVERSE-ENGINEERING-SPEC.md).
The APK SHA-256 was verified as
`55b76c30091bc9e6dda0a27bb3bf5de47ea36b726aba0c6cfc238e1f46b9b468`.
Android executables, protectors, billing wrappers and advertising SDKs are excluded.

## Capture workflows

The original Photo/Video switch remains available. Processed video retains its
microphone through the existing film exporter. MotionCam capture adds ZSL, Night,
Burst, native RAW sequences, timelapse, visual aids, exposure/white-balance locks,
shutter angle, frame statistics, focus tracking and Gyroflow recording.

ZSL/Night/Burst without Save DNG use a memory-limited 1280-pixel RGB pre-roll.
Night selects 4–12 frames from the recovered exposure/shadow rules, registers
translations with Vision, then averages them. Burst saves up to 30 available frames.
This replaces Android's Bayer ring and DIS/wavelet fusion with a native adaptation.

RAW sequence uses AVCapturePhotoOutput to capture original Bayer DNG or Apple
ProRAW files. It prefers Bayer when available, temporarily selects the photo
configuration, and restores processed-video configuration on stop. The requested
interval defaults to one second; actual speed is limited by photo readiness,
processing and disk I/O. It does not claim a 30/60-fps Bayer video stream.
Save DNG + Burst captures 30 native RAW frames; Save DNG + Timelapse records
RAW frames at the chosen interval. Other Save DNG still modes request a native
RAW still with an optional film-developed JPEG.

A RAW capture is a local .rawseq folder containing original DNG files, an atomic
sequence.json journal, optional PCM audio.wav and motion.gcsv. Completed frames
remain readable after interruption. Stop waits for an in-flight photo and disk
write. Recording checks for at least 512 MB free storage; each frame is bounded
to 128 MB. No RAW-capable lens results in an explicit error.

Processed timelapse writes a silent H.264 MOV at 24 fps. RAW timelapse preserves
DNGs and uses 24-fps playback by default. Timelapse stops at the configured
duration, manually, or when the camera leaves the foreground.
Core Motion logs radians/second and acceleration converted from g to m/s²,
with recovered Gyroflow interpolation/scaling, bounded to 180,000 samples/stream.
The simulator cannot validate physical cameras, microphones or IMU sensors.

## Development and exports

Open RAW workspace from Camera to import .mcraw v2/v3, a .rawseq folder, DNG or
another iOS-supported RAW still. Sources can be reopened/deleted. Scrub/trim,
scan sharpness over up to 300 frames, and export JPEG, DNG, CinemaDNG folders,
ZIP64 archives or H.264/HEVC/ProRes MOV. Camera capture settings are retained in
the sequence journal and can be restored with Use capture look.

JPEG/movie development runs before the existing Super 16 film renderer.
DNG/CinemaDNG preserve source samples and color calibration, without baking film.
Developed JPEGs are bounded to the recovered film GPU's 16-megapixel budget;
Movie development also fits the selected output bounds before film GPU allocation.
Full-resolution RAW archival files are unchanged.
Native iOS sequence frames are copied as their original DNG bytes, including
their native metadata. Imported mcraw DNGs preserve Bayer samples, color/forward
matrices, illuminants, neutral and black/white levels; lens-shading opcode maps,
GPS and other unlisted metadata are not reconstructed by the mcraw DNG writer.

Movie export defaults to source speed and a 1080p maximum, preserving aspect.
720p, 1440p, 4K and source-size choices are available. Preview work is serialized
and cancelled when superseded; RAW decoding scales to preview/export needs.
Movie export defaults to source speed. Native sequences and source-timed RAW
video retain actual frame timestamps, including still-capture gaps. PCM audio is
trimmed/aligned to the selected sensor timeline. An explicit frame-rate override
creates a silent speed-adjusted movie. All recovered frame-rate choices through
480 fps are offered; encoder/device capabilities still apply.

CinemaDNG includes the selected audio sidecar. Native sequence exports retain
capture-timing.json and the original IMU log. The log is not automatically trimmed
or retimed; its origin and video offset are recorded for synchronization.

A single app-wide queue saves jobs atomically. Interrupted jobs require explicit
retry rather than automatic crash loops. Cancel removes incomplete movie/sequence
outputs. Captures, finished media, archives and sidecars are shared from Gallery.

## Source-to-code map

| Specification | Implementation | Fidelity |
| --- | --- | --- |
| §5.3 exposure/ISO/shutter tables, merge counts | MotionLogic | Recovered constants/equations |
| §8.2 EV/histogram estimates | MotionExposure | Recovered formulas on native input |
| §9.1 sliders | MotionGrade.value | Recovered forward equations |
| §5.4/5.5 focus/orientation | MotionFocusState / MotionOrientation | Tested models; capture orientation follows iOS |
| §6 clipping, peaking, HSV preview | MotionProcessing / MotionViewfinder | Recovered equations and asymmetric blur weights |
| §7 container/codec 6 | MotionContainer / MotionRaw | Checked Swift reader and MSB-first unpacker |
| §5.6 Gyroflow | MotionLogger / MotionGyroflow | Native acquisition and recovered resampling |
| RAW sensor capture | CameraRawSequence / RawSequenceWriter | Public RAW still API at device-dependent cadence |
| RAW audio/timing | CameraRawAudio / RawPCMWriter / RawSequenceAudio | Streaming PCM and sensor timestamps |
| §8/10 ISP | CIRAWFilter / MotionProcessing | Apple demosaic and native grading adaptation |
| §9 workers | MotionWorkspace / MotionJobRunner | Serial saved queue, progress, cancellation, recovery |
| DNG/photo from video | MotionDNG / MotionClip | Source samples and color calibration |
| H.264/HEVC/ProRes | MotionVideoExport | Native encoder, source timing and optional retiming |

## Platform and format limits

AVCaptureVideoDataOutput is processed RGB. Genuine RAW sequences therefore use
the slower RAW photo API and a documented folder format, not fake mcraw data.
High-frame-rate sensor RAW, Android's 95 Halide kernels, DIS/BEBLID, custom
wavelet fusion, CineForm, VP8/VP9 encoding, 10/12-bit rendered output and
log/HLG/ACES transforms are not reproduced by Core Image.
No MotionCam native-ISP pixel parity is claimed. Existing Super 16 parity is
independently checked with MotionCam development disabled.

Legacy v1/ZIP and newer compressed codecs are rejected. Missing Bayer calibration
is rejected rather than synthesized. mcraw PCM extraction is limited to 256 MB
per export. Native capture WAV is streamed up to the RIFF size limit.
Split-write storage and automatic application exit are not implemented.
Capture/export require foreground execution and sufficient local storage.

## Validation

motioncam.yml builds the unsigned iPhone target, runs model/RAW/export/UI tests,
independently validates ZIP64 fixtures with Python, then runs the original film
regression suite on GitHub Actions macOS. A passing run saves its generated
Xcode project back to the integration branch. Results, logs, screenshots, the
simulator app and unsigned IPA are uploaded.

Tests cover all codec-6 modes, packed RAW10/12, Bayer interleaving, corrupt
containers, DNG development, settings migration, exposure thresholds,
focus/orientation, Gyroflow, PCM, ZIP64, interrupted jobs, native RAW journals,
source-timed movie export, audio trim and UI workflows.
Render fixtures use 320×240 DNGs; the original 64×48 fixture was rejected by
native RAW/encoder processing. Small codec vectors remain independently tested.

The [published decoder](https://github.com/mirsadm/motioncam-decoder) was consulted
for packing and metadata; its C++ is not bundled or linked.
The [additional Ghidra audit](motioncam/METADATA-AUDIT.md) verifies actual APK
illuminant labels and RAW level accessors.


[Verified integration run](https://github.com/azerish25-ux/film-camera/actions/runs/40419151881):
unsigned iPhone build, 30 focused simulator tests, independent Python ZIP64 validation
and 32 original film regressions passed with zero failures. The generated tested
project is committed. Workspace/export simulator screenshots were visually inspected.
See [validation evidence](VALIDATION.md) and [delivery inventory](DELIVERY.md).

The integration is merged in [PR #1](https://github.com/azerish25-ux/film-camera/pull/1).
[Full main-branch validation](https://github.com/azerish25-ux/film-camera/actions/runs/40424128745)
also passed fresh Android reference generation, the iPhone build and all 62 tests.
