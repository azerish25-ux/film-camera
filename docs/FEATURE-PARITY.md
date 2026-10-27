# Local-feature port map

| Android local feature | Native iOS implementation |
| --- | --- |
| 88 original color choices | Original RGB lookup tables, including Android Normal Mode packing |
| Twelve frame modes | Original gate shaders, masks/video overlays and source-derived scan container ratios |
| Film grain | Original grain shader and original ETC1-decoded 1024-square noise table; explicit nearest/repeat texel sampling |
| Halation and blur | Original highlight extraction, blur schedules, buffer scaling and merge calculations |
| Gate weave, breath, dirt and scratches | Swift temporal state with recovered shader uniforms and calculations |
| Light leaks, fogging and burns | Original light-leak processing and all seven original burn clips |
| Color and characteristic curve | Original temperature/tint math and natural cubic curve interpolation; editable X/Y control points |
| Camera | AVFoundation photo/video capture, front/back camera, available lenses, zoom, ISO/shutter, focus, bias, torch, frame-rate and 4K controls |
| Editor | Photos/Files import, non-destructive film processing, comparison, video trim and resolution selection |
| Export | JPEG photos, QuickTime video, retained audio, progress/cancellation and local outputs |
| Presets and custom LUTs | Ten original presets, local saved presets, unlimited validated CUBE imports and persistence |
| Gallery | Local output review, deletion confirmation, sharing and save-to-Photos; native Photos picker for device-library albums |
| Analysis tools | RGB histogram and characteristic-curve visualization |
| Fully local access | No sign-in, billing, analytics, community publishing or cloud service dependency |

The working Android build's disabled account/cloud features stay disabled. Android ELF/JNI libraries are replaced with Apple capture/media APIs and native Swift state; the recovered film algorithms and data are retained. The app is a native port, not an embedded Android runtime.

Verification covers the iPhone build, iPhone Simulator processing, original assets, local persistence, photo/video export, audio/trim/container dimensions, UI navigation/export, and Android/iOS shader comparisons. Physical camera ranges and lens availability are queried from the device; simulator checks cannot validate a real sensor or Apple provisioning. The image processor bounds individual frames to 16 megapixels and supported texture dimensions to avoid unbounded allocations.

See PROCESSING-PROVENANCE.md for the narrowly documented GPU color-key tie behavior and VALIDATION.md for the final run evidence.


## MotionCam extension

The original film pipeline remains available with MotionCam development disabled.
The integrated RAW workspace adds mcraw v2/v3 codec-6 decoding, original DNG
sequences, sensor-time audio/video, grading, frame trim, sharpness scans,
CinemaDNG/ZIP64/JPEG/MOV exports and a persistent serial queue. Capture adds
native RAW still/sequence/burst/timelapse, processed ZSL/night/burst, focus aids,
manual exposure and Gyroflow sidecars.

See [the implementation map and exact platform limits](MOTIONCAM-INTEGRATION.md).
RAW photo cadence depends on the device; high-frame-rate sensor RAW and Android
native ISP pixel parity are not claimed.
