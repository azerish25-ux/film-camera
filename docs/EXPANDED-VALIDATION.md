# Expanded validation work record

Objective: verify the complete iOS port against the original Android film engine on GitHub Actions macOS, fix measured discrepancies, and commit/push the verified result.

## Coverage added

- Every one of the 88 color modes; all 87 LUTs decoded independently from the supplied Android assets and compared byte for byte (`ANDROID-ASSET-AUDIT.json`).
- 1,401 Android GLES shader fixtures: color cube, gradient, neutral ramp, photo scene, saturation 0/0.7/1/2, every film with grain, control endpoints, dirt branches and frame shifts.
- Android pass-chain outputs for every film, checked through the public production FilmRenderer rather than the test probe alone.
- Every film/frame combination in portrait and landscape (2,112 render combinations).
- All 14 animated frame/burn assets decoded around duration/loop boundaries.
- Temporal seeking and all seven burn rolls; 720p/1080p/4K processing paths.
- Existing photo/video export, retained audio/trim, persistence, curve, histogram and simulator UI tests remain in the gate.

## Source audit findings awaiting regression verification

- Android j4.p.d bypasses grain for amount < 0.01; iOS currently uses > 0.
- Android j4.p.e fog buffer receives independent nextFloat()-0.5 samples even when film breath is disabled; iOS incorrectly ties it to breath.
- Android j4.p.I0 uses a 3-sample shake buffer; iOS currently uses 5.

## Evidence status

The earlier 17-fixture validation is insufficient evidence for the expanded goal. The new matrix and regression tests must run on macOS before these findings can be marked fixed. No physical iPhone testing is required by the user.
