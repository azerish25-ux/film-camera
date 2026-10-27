# Super 16 for iOS

Native Swift/SwiftUI port of the supplied fully local Android Super 16 app, including its recovered film-processing shaders, original film tables, frame assets, presets and local workflows.

MotionCam development is integrated with the existing film renderer: RAW/DNG and
MotionCam container import, frame scrubbing, CinemaDNG/JPEG/MOV export, persisted
render jobs, native RAW still/sequence capture, bounded ZSL/night/burst, timelapse and Gyroflow
logging. See [MotionCam integration and platform limits](docs/MOTIONCAM-INTEGRATION.md)
and the [supplied reverse-engineering specification](docs/motioncam/REVERSE-ENGINEERING-SPEC.md).

Open `FilmCamera.xcodeproj` on a Mac. GitHub Actions also generates the project, builds an unsigned iPhone application, runs iPhone Simulator tests, and compares its shader output with Android-emulator reference pixels. See [building instructions](docs/BUILDING.md) and [processing provenance](docs/PROCESSING-PROVENANCE.md).

Features include photo/video capture, manual camera controls, available lens selection, 4K capture, photo/video editing, audio-preserving trim/export, Photos/Files import, local gallery/share, unlimited CUBE imports, local presets, RGB histograms and full characteristic-curve controls.

The iOS renderer executes the recovered film algorithms with the original 88 color choices, ten presets, animated gates and film burns. Camera capture, codec behavior and GPU floating-point behavior are platform dependent. Exact color-key threshold ties are recorded explicitly in the comparison report; universal physical-device bit identity is not claimed.

CI uses no signing secrets. The unsigned IPA requires your Apple development team/provisioning before installation on a physical iPhone. All application media and presets stay local.

[Verification](docs/VALIDATION.md): the MotionCam integration workflow built the iPhone app and passed all 62 simulator tests plus independent ZIP64 validation. This includes the original 1,528 Android/iOS shader cases, all 88 complete color pipelines and 2,112 film/frame/orientation combinations. See the [feature map](docs/FEATURE-PARITY.md) and [delivery inventory](docs/DELIVERY.md).
