# Expanded validation work record

Objective: verify the complete iOS port against the original Android film engine on GitHub Actions macOS, fix measured discrepancies, and commit/push the verified result.

## Coverage added

- Every one of the 88 color modes; all 87 LUTs decoded independently from the supplied Android assets and compared byte for byte (`ANDROID-ASSET-AUDIT.json`).
- 1,502 Android GLES shader fixtures: color cube, gradient, neutral ramp, photo scene, saturation 0/0.7/1/2, every film with grain, control endpoints, dirt branches and frame shifts.
- Android pass-chain outputs for every film, checked through the public production FilmRenderer rather than the test probe alone.
- Every film/frame combination in portrait and landscape (2,112 render combinations).
- All 14 animated frame/burn assets decoded around duration/loop boundaries.
- Temporal seeking and all seven burn rolls; 720p/1080p/4K processing paths.
- Existing photo/video export, retained audio/trim, persistence, curve, histogram and simulator UI tests remain in the gate.

## Source audit fixes under regression verification

- Android j4.p.d bypasses grain for amount < 0.01; iOS was using > 0.
- Android j4.p.e fog buffer receives independent nextFloat()-0.5 samples even when film breath is disabled; iOS had tied it to breath.
- Android j4.p.I0 uses a 3-sample shake buffer; iOS was using 5.

## Evidence status

The earlier 17-fixture validation is insufficient evidence for the expanded goal. The new matrix and regression tests must run on macOS before these findings can be marked fixed. No physical iPhone testing is required by the user.

Additional source-audit findings to correct after red-test evidence:

- j4.p.d computes grain's mask displacement after L0 advances by 71; its inverted parity and subtraction cancel. The grain mask must use the same signed shake as the gate/tone passes. Swift currently subtracts it.
- j4.p.e uploads holes.seed before incrementing its 400-frame counter. Swift increments FilmDynamics.frame earlier and currently starts the seed one frame ahead.
- j4.p.d places horizontal scratch X and Y from width-100. Swift currently uses height for Y, changing the fraction of scratches visible in landscape images.
- The Android fast-shake draw precedes the slow-shift draws. Separate dirt randomness from the temporal java.util.Random stream (Android uses Kotlin's random stream for dirt).

Live evidence runs:
- Initial 1,222-case matrix: https://github.com/azerish25-ux/film-camera/actions/runs/40028371153 (main at 1d54803).
- Full chains, native noise decoding and regression tests: https://github.com/azerish25-ux/film-camera/actions/runs/40029498461 (validation/exhaustive-parity at 0ba37b8).


Candidate fixes are prepared for the grain activation threshold, independent fog variation, three-sample shake buffer, shake/shift draw order, grain mask shake sign, leakage seed phase and scratch placement. The grain cell calculation now uses the equivalent exact fragment-pixel coordinates to avoid an interpolated-UV cell-crossing failure observed at size 0.27. Every 0.01 grain-size step is now in the comparison matrix.

Numeric GPU bounds are explicit per operation: 2/255 normally, 3/255 for grain followed by LUT interpolation, and 4/255 for halation with cutoff >= 0.99. Mean absolute RGB error remains below 0.25/255 for every fixture. The controlled Arri chroma-key gradient identifies only input values within 1/65536 of its threshold; all-pixel error and boundary counts remain in the report, with at most eight such pixels permitted per fixture. The expanded evidence showed a single shifted key tie and a single 3/255 steep-LUT sample. These are separate from the 66/255 grain cell error, which requires an implementation correction.

Expected image fixtures have moved to the test target. They are not shipped inside the application bundle. Final verification and updated pinned references are still pending.

Current execution record (2026-10-23):
- 1d54803, run 40028371153: initial 1222-case run failed exactly four pixel bounds (film-64-grain max3 one pixel; grainSize0.27 max66 39 pixels on row62; halationCutoff0.995 max4 178 samples; shifted Arri max14 one near-key pixel). All other earlier tests passed.
- 0ba37b8 on validation/exhaustive-parity, run 40029498461: unfixed regression suite still running. Android native ETC1 matched all 1048576 noise pixels. Expected references downloaded to artifacts/expanded-reference-1401.
- dd25b4a on main, run 40032128615: candidate dynamics/grain fixes with1502 cases; Android stage still running at last observation.
- Local uncommitted work: animated-frame upload cache plus seek test; native ETC1 checks for two static frame scans; actual mask/border probes (matrix now1520); JPEG color assertion; expanded original asset audit.
- Pinned references contain1401 cases, so must be refreshed and hash-verified against the final Android artifact, with updated provenance.
- The committed Xcode project needs replacement from the final CI-generated project after moving fixtures to the test target; final HEAD must be verified.
- Outstanding: inspect regression/core runs, fix failures, run final1520-case/full integration suite including cache/JPEG assertions, inspect film contact sheets, pin final references/project/evidence, update documentation, commit/push, verify clean worktree/remote SHA/final macOS run. Only then complete goal.


Diagnostic46184e5/run40035469293 measured: exposure exact; gate and tone maximum errors1/255; largest whole-image mean0.097141/255; isolated raw output maximum14/255 after steep LUT amplification. Independent CPU trilinear sampling matched Android's lookup within1/255 for all88 films. The new test checks intermediate stages and both GPU lookups against that independent oracle, retaining a tighter full-image mean bound and a per-pixel envelope derived from each original LUT's sensitivity.

All three behavior regressions were confirmed red in40029498461. Its2112 film/frame renders passed in1405.524s; animated-asset loops, temporal seeking/burn rolls and720p/1080p/4K processing passed. Two animation repeat/seek assertions and video color-space normalization remain under targeted investigation.

Temporary artifact staging folder to remove after verified evidence transfer: C:/Users/shahr/film-camera-ci-evidence-20261023-1947. Source remains on D. All1520 references from40034074197 are pinned/hash-verified, and both scanned frame borders passed native Android ETC1 verification.
