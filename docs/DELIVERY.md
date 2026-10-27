# Delivery inventory

The repository contains the native iOS application, original film assets, MotionCam
integration, generated Xcode project, test fixtures, workflows and provenance.

- `FilmCamera/`: original film processing plus RAW development/capture/workspace.
- `FilmCameraTests/` and `FilmCameraUITests/`: original film and added MotionCam tests.
- `FilmCameraTests/Resources/`: pinned Android references, excluded from the app.
- `docs/MOTIONCAM-INTEGRATION.md`: workflows, source map and platform/format limits.
- `docs/motioncam/REVERSE-ENGINEERING-SPEC.md`: supplied APK logic specification.
- `docs/motioncam/METADATA-AUDIT.md`: additional Ghidra checks and metadata provenance.
- `.github/workflows/motioncam.yml`: unsigned iPhone build, focused simulator tests,
  independent Python ZIP64 validation, original film regressions and packaging.
- `.github/workflows/ios.yml`: fresh Android references and complete iOS validation.
- `Reference/`: original film shader/Java provenance and compressed texture data.

## Applications and evidence

[Successful MotionCam validation](https://github.com/azerish25-ux/film-camera/actions/runs/40419151881)
built the iPhone target and passed all 62 simulator tests plus independent ZIP64
validation. The tested generated project was committed as
`615e75fd7e35bd9c5186831753da73341e30dc07`.
[Main-branch validation](https://github.com/azerish25-ux/film-camera/actions/runs/40424128745)
also passed after regenerating Android references. Its `ios-validation` artifact
contains the merged application's builds and complete test evidence.

Artifacts contain the simulator application, unsigned IPA, generated Xcode project,
xcresult bundles, logs, summaries and exported screenshots. GitHub retains artifacts
for 14 days; source and workflows remain committed for reproducible builds.

An unsigned IPA requires your Apple development team/provisioning before installation.
See [building instructions](BUILDING.md), [validation](VALIDATION.md) and
[MotionCam limits](MOTIONCAM-INTEGRATION.md). Simulator tests do not verify physical
camera capture, RAW cadence, microphones or IMU sensors.

The original pre-MotionCam delivery remains historical evidence in
`artifacts/verified-port` and [its successful workflow](https://github.com/azerish25-ux/film-camera/actions/runs/40045800863).
New local work and downloaded evidence stay on D: inside this workspace.
