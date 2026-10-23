# Delivered files

- `FilmCamera.xcodeproj`: ready-to-open Xcode project.
- `FilmCamera/`: native Swift application, original processing assets and reference fixtures.
- `FilmCameraTests/`, `FilmCameraUITests/`: automated processing/media and UI verification.
- `.github/workflows/ios.yml`: full macOS Android-reference/iPhone build/test workflow.
- `.github/workflows/swift-check.yml`: macOS validation using committed reference fixtures.
- `artifacts/final/build/deliverables/FilmCamera-unsigned.ipa`: unsigned iPhone application.
- `artifacts/final/build/deliverables/FilmCamera-simulator.zip`: Simulator application.
- `artifacts/final/`: logs, `.xcresult`, visual/raw attachments, comparison report and verification hashes.

Artifacts are deliberately excluded from Git; their verified copies are saved locally on D:. The original Android directory is unchanged. See BUILDING.md for signing and local build instructions.
