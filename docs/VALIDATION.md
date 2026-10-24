# Expanded validation

Numerical code commit: 2b16306 (the ready Xcode project is copied from this run).

[Processing gate](https://github.com/azerish25-ux/film-camera/actions/runs/40044846193): succeeded, ten selected tests, no issues. [Android reference generation](https://github.com/azerish25-ux/film-camera/actions/runs/40042781189): succeeded on macOS.

The final integrated iPhone build and complete simulator suite are pending for the delivery commit. This document will record their actual result before completion.

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
