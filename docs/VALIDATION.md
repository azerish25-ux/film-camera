# Final validation

Verified code commit: `a5aced57cadac7b4eab317dadc8d009973d238ec`.

- [Full macOS workflow](https://github.com/azerish25-ux/film-camera/actions/runs/40023375985): succeeded. Android-emulator reference generation, unsigned iPhone build, iPhone Simulator tests and artifact packaging all passed.
- [Fast validation](https://github.com/azerish25-ux/film-camera/actions/runs/40023376045): succeeded against the committed Android reference fixtures.
- 20 tests passed: 18 processing/model/media tests and two UI workflow tests.
- 17 Android/iOS shader fixtures were compared. Maximum error outside mathematically exact color-key ties was one 8-bit color level. Largest mean absolute byte error was 0.04742.
- The Arri gradient fixture contains six exact `green = 1.3 * red` key ties; three selected different branches because of GPU floating-point rounding. All-pixel errors and tie counts remain in the report. The original keying predicate is unchanged.

Coverage includes original looks/presets/assets, noise lookup, halation/blur, film gates, tone curves, histogram channels, validated persistence/CUBE domains, source colors, vertical image order, video trim/audio/container aspect, photo export, and UI navigation/preset persistence/editor-to-gallery export.

The final IPA was inspected: bundle `com.azerish.filmcamera`, minimum iOS 17, 87 original LUT files, 14 original overlay movies. The generated project, icon and fresh reference files were compared with the delivered source. Final artifacts on D: were copied and SHA-256 verified (202 files, 164.6 MiB).

Local evidence: `artifacts/final/VERIFICATION.json`, `artifacts/final/shader-comparison.json`, build logs, `.xcresult`, and exported attachments. Device-camera ranges/quality require physical hardware; CI does not supply Apple signing credentials. This is not a claim of universal bit-for-bit physical-sensor/codec identity.
