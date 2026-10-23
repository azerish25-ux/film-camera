# Building and installing

The project targets iOS 17 and later and uses SwiftUI, AVFoundation, Core Image and the recovered GLES 3 film shaders. There are no third-party runtime packages.

On macOS with Xcode installed:

```sh
brew install xcodegen librsvg
rsvg-convert -o FilmCamera/Assets.xcassets/AppIcon.appiconset/AppIcon.png FilmCamera/Resources/app-icon.svg
xcodegen generate
xcodebuild -project FilmCamera.xcodeproj -scheme FilmCamera -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

The full GitHub Actions workflow generates Android reference renders on a macOS Intel runner, builds the iPhone target on a macOS Apple Silicon runner, and tests in iPhone Simulator. Its artifacts contain the generated Xcode project, unsigned IPA, Simulator application, test results and exported attachments.

For a physical iPhone, supply your own Apple development team and provisioning. The repository defaults to `CODE_SIGNING_ALLOWED=NO` for CI. Set it to `YES` and select your team to sign a device build. An unsigned IPA cannot be installed directly on an iPhone.

The fast Swift validation workflow exercises the Swift application, media export, original assets, UI workflows and committed Android reference fixtures. The full workflow regenerates the fixtures on Android before comparing them with iOS.

Camera, microphone and Photos permissions are requested when needed. Photos/Files imports preserve source files; finished media and presets live in the application's Documents directory. Gallery can share exports or save them to Photos.
