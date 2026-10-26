# MotionCam integration

Source: [supplied reverse-engineering specification](motioncam/REVERSE-ENGINEERING-SPEC.md).
The local APK SHA-256 was verified as
`55b76c30091bc9e6dda0a27bb3bf5de47ea36b726aba0c6cfc238e1f46b9b468`.
Android executables, protectors, billing wrappers and advertising SDKs are excluded.

## Workflows

Camera retains full-resolution Photo and processed Video capture. Expand MotionCam
capture for ZSL, Night, Burst, Timelapse, DNG stills, clipping, focus peaking,
shutter angle, exposure/white-balance locks and Gyroflow logging.
ZSL/Night/Burst use a memory-limited 1280-pixel RGB pre-roll. Night averages up to
12 recent frames; Burst saves up to 30 available frames. These are native iOS
fallbacks, not Android Bayer capture or DIS optical-flow fusion. Save DNG requests
a full-resolution native RAW still with an optional film-developed JPEG, regardless
of pre-roll mode. It requires a compatible physical iPhone lens.

Timelapse writes silent H.264 MOV at 24 fps from sampled film-developed frames.
It stops at the selected duration or when stopped/backgrounded. Capture/export
require the foreground. Core Motion logs radians/second and acceleration converted
from g to m/s², using recovered Gyroflow interpolation/scaling. Motion acquisition
is bounded to 180,000 samples/stream (30 minutes at 100 Hz).

Open RAW workspace from Camera to import `.mcraw` v2/v3 or an iOS-supported RAW
still. Scrub frames, set trim endpoints, develop through MotionCam controls and
the existing Super 16 film look, and queue JPEG, DNG, CinemaDNG or MOV exports.
Sources are copied into the local RAW directory. The queue is saved atomically;
interrupted jobs require explicit retry rather than automatic crash loops.
Cancel removes incomplete movie/sequence output. Gallery shares finished media.

## Source-to-code map

| Specification | Implementation | Fidelity |
| --- | --- | --- |
| §5.3 exposure/ISO/shutter tables, merge counts | MotionLogic | Recovered constants/equations |
| §8.2 EV and histogram estimates | MotionExposure | Recovered formulas |
| §9.1 sliders | MotionGrade.value | Recovered forward equations |
| §5.4/5.5 focus and orientation | MotionFocusState / MotionOrientation | Tested state models; capture orientation follows iOS |
| §6 clipping and peaking | MotionProcessing.aids | Original asymmetric blur weights and overlay thresholds |
| §7 container/codec 6 | MotionContainer / MotionRaw | Checked Swift reader, MSB-first unpacking |
| §5.6 Gyroflow | MotionLogger / MotionGyroflow | Native acquisition and recovered resampling |
| §8/10 ISP | MotionProcessing / CIRAWFilter | Apple demosaic and native grade-before-film adaptation |
| §9 workers | MotionWorkspace / MotionJobRunner | Serial queue, progress, cancellation, recovery |
| CinemaDNG / photo-from-video | MotionDNG / MotionClip | Source Bayer samples and calibration |
| H.264 / HEVC / ProRes | MotionVideoExport | Native encoder, dependent on device support |

## Limits requiring further implementation

iOS video data output supplies processed RGB; newly recorded iPhone video is not
sensor RAW and is not written into fake `.mcraw` files. Imported RAW video can be
developed. Core Image does not reproduce the 95 Halide kernels, OpenCV BEBLID/DIS,
wavelet fusion, CineForm, VP8/VP9, 10/12-bit exports or log/HLG/ACES transforms.
No pixel parity with MotionCam's native ISP is claimed. Original Super 16 film
parity remains independently tested with MotionCam development disabled.

Legacy v1/ZIP and newer compressed codecs are rejected explicitly. Missing Bayer
calibration is rejected. RAW movie export is currently silent: embedded BW64/PCM
extraction/synchronization remains unimplemented. Native camera MOV capture keeps
its microphone through the existing exporter. Split-write, GPS and automatic app
exit are not implemented. Simulator CI cannot validate physical camera/sensors.

## Validation

`motioncam.yml` builds the unsigned iPhone target and runs simulator unit/UI tests
on GitHub Actions macOS, uploading results, logs, screenshots, simulator app and IPA.
Tests cover every codec-6 mode, RAW10/12, Bayer interleaving, corrupt containers,
DNG development, settings migration, exposure thresholds, focus/orientation,
Gyroflow and renderer integration.

The [published decoder](https://github.com/mirsadm/motioncam-decoder) was consulted
to verify packing and metadata keys; its C++ code is not bundled or linked.
