# Super 16 for iOS

Native Swift/SwiftUI port of the supplied fully local Android Super 16 app, including its recovered film-processing shaders, original film tables, frame assets, presets and local workflows.

Open `FilmCamera.xcodeproj` on a Mac. GitHub Actions also generates the project, builds an unsigned iPhone application, runs iPhone Simulator tests, and compares its shader output with Android-emulator reference pixels. See [building instructions](docs/BUILDING.md) and [processing provenance](docs/PROCESSING-PROVENANCE.md).

Features include photo/video capture, manual camera controls, available lens selection, 4K capture, photo/video editing, audio-preserving trim/export, Photos/Files import, local gallery/share, unlimited CUBE imports, local presets, RGB histograms and full characteristic-curve controls.

The iOS renderer executes the recovered film algorithms with the original 88 color choices, ten presets, animated gates and film burns. Camera capture, codec behavior and GPU floating-point behavior are platform dependent. Exact color-key threshold ties are recorded explicitly in the comparison report; universal physical-device bit identity is not claimed.

CI uses no signing secrets. The unsigned IPA requires your Apple development team/provisioning before installation on a physical iPhone. All application media and presets stay local.

[Expanded verification](docs/VALIDATION.md): the macOS numerical gate passed 1,528 Android/iOS shader cases and all 88 complete color pipelines. The final integrated build/test run is being completed. See the [feature map](docs/FEATURE-PARITY.md) and [delivery inventory](docs/DELIVERY.md).
