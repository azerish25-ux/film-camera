# Verified delivery

- FilmCamera.xcodeproj: complete ready-to-open Xcode project, identical to the final generated/tested project.
- FilmCamera/: native Swift application and all original runtime film assets.
- FilmCameraTests/Resources/: 1,528 pinned Android reference images and source-derived original preset expectations; these resources are excluded from the application target.
- FilmCameraTests/ and FilmCameraUITests/: 32 passing automated tests.
- .github/workflows/ios.yml and swift-check.yml: macOS full verification and focused diagnostics.
- Reference/: preserved Android shader/Java provenance and original compressed texture data.
- scripts/verify_android_assets.py and verify_original_presets.py: original-source audits.

Latest local applications:
- artifacts/verified-port/build/deliverables/FilmCamera-unsigned.ipa
- artifacts/verified-port/build/deliverables/FilmCamera-simulator.zip

The same applications and test evidence are available in the successful final workflow:
https://github.com/azerish25-ux/film-camera/actions/runs/40045800863

artifacts/verified-port contains the full test result bundle, logs, screenshots, raw reference/comparison data and SHA256 verification manifests. Generated artifacts are excluded from Git. All source, runtime assets, test fixtures, project files and workflows are committed. The older artifacts/final directory is the initial delivery, preserved as history; verified-port is the current delivery.

Temporary C staging was deleted only after per-file D backup verification. The supplied original Android directory was not changed. See BUILDING.md for Xcode and signing instructions.
