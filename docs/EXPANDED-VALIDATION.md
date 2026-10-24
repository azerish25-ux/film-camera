# Expanded validation completed

Final source commit:869c9534e7a062ec3fd32fe0568be9f7f2b690a5.
Final macOS run:https://github.com/azerish25-ux/film-camera/actions/runs/40045800863.
Result:all32 tests passed, no issues.

## Corrections found by this investigation

- Match Android's grain bypass below0.01.
- Use an independent25-sample fog stream and the original three-sample fast-shake buffer.
- Match temporal draw order, grain-mask shake direction, perforation seed phase and original scratch placement.
- Define transparent-black input in recovered frame-shader masked regions that previously read uninitialized registers.
- Reuse identical decoded animated textures, with repeat/seek and loop-boundary checks.
- Normalize fractional previews to integral raster storage.
- Correct three predefined presets that used legacy halation instead of their effective zero V2 value.
- Stabilize UI export testing by waiting for the edited preview, and exercise perforation leakage after its original temporal warm-up.

## Evidence

All88 production color pipelines passed independent stage and CPU original-table checks. All1,528 shader cases passed documented stable-pixel and stochastic-boundary bounds. Eight photo grain cases stayed below0.182/255 mean error; all101 selectable grain sizes were exercised. All2,112 film/frame/orientation combinations rendered, every adjustment changed an image when enabled, all14 animated clips decoded around loop boundaries, and720p/1080p/4K processing passed. JPEG and video grading, audio/trim, persistence, curves, histogram and both UI workflows passed. All ten presets match28 original effective parameters plus their LUT/frame/curve choices.

Original asset audits verified87 tables, seven masks,14 video payloads and all preserved shaders. Android native ETC1 decoding matched every noise pixel and both scanned frame borders.

See VALIDATION.md for exact error bounds, including grain-cell and chroma-key precision ties. Raw maxima and whole-image statistics remain in the reports; this record does not claim universal pixel identity across GPU implementations.

## Delivery and cleanup

The generated Xcode project matches the committed ready project. The IPA contains all runtime assets and no expected test images. The latest7,742-file delivery is under artifacts/verified-port and was SHA256-verified.

Historical C staging:34,390 files,1,969,491,094bytes, backed up under artifacts/expanded-validation/staging and removed. Final C staging:7,742files,488,681,897bytes, backed up under artifacts/verified-port and removed. Per-file verification and cleanup manifests retain the audit trail.

No source work remains pending. The original Android folder was not modified.
