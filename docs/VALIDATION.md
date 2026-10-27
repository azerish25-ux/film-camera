# Validation

## MotionCam integration

Verified source: `9d96bebba9db79ad8c7b69c6ea64bb4c4789a6b3`.
[Integration Actions run](https://github.com/azerish25-ux/film-camera/actions/runs/40419151881).

Succeeded: unsigned iPhone build, all **30 focused tests**, independent Python
ZIP64 validation and all **32 original film regressions** (62 simulator tests,
zero failures). The workflow saved its tested Xcode project in commit
`615e75fd7e35bd9c5186831753da73341e30dc07` and uploaded the application/test artifacts.
[Main-branch confirmation](https://github.com/azerish25-ux/film-camera/actions/runs/40424128745)
also succeeded at merged source `ebb60df75d54e9ac3350ae833b740b1b74137dec`:
fresh Android references, unsigned iPhone build, the complete 62-test simulator
suite and packaging. Subsequent documentation-only changes preserve that runtime.

The focused suite covers recovered exposure/slider/focus/orientation/Gyroflow logic,
all codec-6 modes and packed RAW, malformed containers, DNG development, saved jobs,
RAW journals, original DNG identity, sensor-time movies/PCM trim and two workspace UI
flows. The large 4032x3024 RAW/de-squeeze regression exercises 4K movie export.
The selected output bounds are applied before film GPU allocation at both frame paths.

Independent Python validation opens the CinemaDNG ZIP64 fixture and checks its DNG
entries, checksums and PCM sidecar. Simulator screenshots of mcraw frame development
and native sequence export were visually inspected.

Review found geometry-budget and malformed gyro-origin cases; both have fixes and
regressions. The exact final fix was independently reviewed with no actionable issues.
Physical camera capture/cadence, microphones and IMU sensors are outside simulator
coverage. [Implementation fidelity and limits](MOTIONCAM-INTEGRATION.md) distinguish
recovered equations from Apple processing adaptations.

## Original film port baseline

Verified runtime/test/project commit: 869c9534e7a062ec3fd32fe0568be9f7f2b690a5. Later documentation-only commits preserve that tested source.

[Processing gate](https://github.com/azerish25-ux/film-camera/actions/runs/40044846193): succeeded, ten selected tests, no issues. [Android reference generation](https://github.com/azerish25-ux/film-camera/actions/runs/40042781189): succeeded on macOS.

[Final full macOS workflow](https://github.com/azerish25-ux/film-camera/actions/runs/40045800863): succeeded. Android reference generation, unsigned iPhone build, the complete iPhone Simulator suite and packaging passed.

All 32 tests passed with no issues: 30 processing/model/media tests and two UI workflows. This includes all 2,112 film/frame/orientation combinations, every adjustment's visible effect after temporal warm-up, all animation loops, 720p/1080p/4K processing, audio-preserving video trim/export, JPEG color preservation, persistence, curves and histograms. Six contact sheets covering all 88 color modes were visually inspected.

The fresh final-run Android reference files are byte-identical to all 1,528 pinned fixtures. The ready-to-open Xcode project matches the generated/tested project. The IPA was inspected: bundle com.azerish.filmcamera, minimum iOS17, 87 LUTs, 14 overlay movies, one noise table and 56 shaders. No expected RGBA images or preset-test expectations are shipped in the app.

Final local delivery: artifacts/verified-port, 7,742 files (466.0MiB), copied and SHA256-verified. VERIFICATION.json, TRANSFER-MANIFEST.json, C-CLEANUP.json, shader-comparison.json, production-comparison.json, build logs, Tests.xcresult and exported attachments retain the evidence. Both temporary C staging folders were removed after their D backups were hash-verified.

## Measured coverage

- All 88 color modes, including 87 original film tables and Normal Mode.
- 1,528 Android/iOS shader comparisons: color cube, neutral ramp, spatial gradient, photo scene, saturation endpoints, all 101 grain-size steps, grain with every film, effects/dirty-film branches, actual masks and scanned borders.
- Every film's complete production pipeline: exposure bytes identical; gate/tone bytes differ by at most one level; CPU trilinear oracle matches both final GPU lookups within one level. No local LUT-sensitivity envelope violations.
- Largest complete-pipeline mean error: 0.097141/255. Isolated steep-LUT output differences reach 14/255 after a one-level input rounding difference; the original tables and their local sensitivity account for these differences.
- Real-photo grain cases at ambiguous cell sizes: largest mean error 0.181641/255; minimum PSNR 46.19 dB.
- All ten predefined presets are checked against Android's effective loading rule, including V2 halation overrides, film/frame selections and curve points.
- Original assets audited: 87 tables, seven PNG masks, 14 encoded video payloads, all preserved shader files; Android native ETC1 decoding matches all 1,048,576 noise pixels and both static frame scans.
- Photo/JPEG grading and audio-preserving video trim/export are checked. Video and photo colors are normalized to sRGB before comparing their representations.

## Numerical boundaries

Ordinary shader comparisons retain a two-level maximum; grain/LUT interpolation allows three and near-unity halation cutoff allows four. The controlled Arri key identifies input-derived threshold ties within 1/65536, records all-pixel errors and permits at most eight boundary pixels.

At an integer grain-cell seam, one ULP of interpolator rounding can choose a neighboring random sample. Every non-seam pixel retains the strict bounds. For the synthetic seam cases, whole-image mean absolute error is limited to 0.75/255, channel-mean bias to 0.25/255 and channel-standard-deviation difference to 0.5/255. The worst measured synthetic MAE is 0.512045/255; all photo cases retain the stricter 0.25/255 mean bound. All raw maxima, seam counts and statistics are retained in the shader report.

These bounds describe emulator/code conformance and stochastic sampling, not universal bit-for-bit GPU identity.
