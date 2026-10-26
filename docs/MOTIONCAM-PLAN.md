# MotionCam integration — design and implementation plan

Source: local MotionCam Pro 1.2.7 reverse-engineering specification, APK SHA-256
55b76c30091bc9e6dda0a27bb3bf5de47ea36b726aba0c6cfc238e1f46b9b468.

## Design

Keep the existing film camera, editor, gallery and presets. Add independently testable
MotionCam domain models and native iOS processing before the recovered Super 16 film
pipeline. Persist grading inside film presets with backward-compatible decoding.
Keep viewfinder aids out of saved pixels. Store captured DNG and recording sidecars
locally. Add a RAW workspace for container import, frame selection, grading and export.

Use AVFoundation/Core Image/Core Motion for platform services. Android JNI libraries,
APK protectors, billing wrappers and ELF binaries cannot execute on iOS and are not
included. Native replacements must be documented separately from exact recovered
equations. Do not claim sensor RAW video from an RGB video output, Halide parity from
Core Image, or device capture validation from a simulator.

## Implementation and verification

- [ ] Recover constants, exposure ramp, frame-merge thresholds, grading equations,
  focus state machine, histogram estimation and orientation hysteresis as Swift models.
- [ ] Add tests for boundary conditions, serialization/migration and corrupt inputs.
  Execute tests on GitHub Actions macOS, including a failing baseline before implementation.
- [ ] Integrate grade-before-film processing across preview, stills and video export.
  Add live clipping/focus peaking and RAW still capture with capability checks.
- [ ] Add bounded burst/night capture and timelapse recording with cancellation,
  storage/memory limits and Core Motion/Gyroflow sidecars.
- [ ] Add checked container reading, RAW unpacking, DNG output, scrub/trim,
  photo-from-video and video export through a RAW workspace.
- [ ] Document exact logic, native adaptations and unsupported operations honestly.
- [ ] Review changes and run device build, simulator unit/UI tests and original film
  parity regression tests in GitHub Actions. Fix failures and record final run evidence.
- [ ] Merge verified integration into the repository default branch.

All source work remains on D:. iOS execution occurs on GitHub Actions, not Windows.
