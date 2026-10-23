# Super 16 for iOS

Native Swift/SwiftUI port of the supplied fully local Android Super 16 app. Source and film processing assets are kept in this repository; builds and automated simulator verification run in GitHub Actions on macOS.

Open `FilmCamera.xcodeproj` from the CI artifact, or install XcodeGen on a Mac and run `xcodegen generate` using `project.yml`.

The camera uses AVFoundation. Recovered GLES 3 film shaders, original 3D film tables, gate videos, perforation masks and characteristic curves run in the shared preview/photo/video processing pipeline. Gallery, Photos/Files import, video trimming, local presets and CUBE imports are implemented in Swift.

CI builds an unsigned iPhone app and a Simulator app, runs tests, and uploads the generated project, applications, logs and `.xcresult` evidence. The unsigned IPA needs Apple signing before installation on a physical device. The Simulator app is directly usable in Xcode Simulator.

Port validation is ongoing. See `docs/PORT-PLAN.md`; do not interpret a compilation pass as proof of complete emulation parity.
