# Processing provenance

The supplied Android source is the active fully local build described in its README and developer handoff. Reference Java is decompiler output; the original app is built from recovered bytecode and resources.

- `l4/a.java`, `l4/b.java`, `l4/c.java`: recovered GLSL. Shader strings were decoded from Java literals and retained in `Reference/AndroidShaders`. Runtime loading replaces external-camera sampler declarations with ordinary 2D samplers for iOS-owned pixel textures. iOS requests 32-bit float precision and spells the original nearest/repeat noise lookup as integer texel access to avoid driver-dependent half-precision and boundary tie handling; the reference shader files are unchanged.
- `o4/h5.java`: original 4:3 and 16:9 full-scan container mappings; the visible gate ratio is not substituted for the scan container.
- `j4/d.java`, `j4/p.java`, `j4/e.java`: pass order, uniforms, temporal state, framebuffer sizes and blur schedules.
- `v3/d0.java`: original 88-entry film list. 87 image LUTs plus Normal Mode.
- `h4/e.java`: ten original presets.
- `ba/j.k`: natural cubic spline for the characteristic curve. Input samples are quantized to integer bytes as in the Android path.
- `v3/m1.java`: PNG headers are restored to their standard signature; video headers XOR the first eight bytes with the recovered header key. ETC1 assets are decoded to uncompressed pixels for iOS.
- Native `Java_a_a_c` / `FUN_0019501c`: original LUT packing order is blue plane, green row, red column. The original LUT PNG stores a pixel at `(blue*64+red,green)`.
- Normal Mode follows Android's integer `channel*255/64` table generation rather than substituting a mathematically ideal identity table.

The Swift application implements local camera, editor, gallery and preset workflows with Apple APIs. Rendering uses the recovered shader calculations, film tables and frame assets. OS camera capture, codec behavior and GPU floating-point behavior differ by platform. Tests report pixel error for every shader fixture, including grain with the original noise table; a test pass must not be described as universal bit-for-bit physical-device equivalence.

The cross-GPU gradient fixture for the Arri gate includes exact `green = 1.3 * red` values. Vulkan and Metal can normalize the underlying UNORM8 values and round the comparison differently; three fixture pixels selected opposite branches. The conformance test identifies only mathematically exact key ties from the input, records all-pixel error and those tie decisions, and applies a tighter two-byte maximum to every other pixel. The recovered keying formula is not changed to fit one GPU's rounding.


Expanded verification adapters:
- Recovered vec4 colorIn locals in frame compositors are initialized to transparent black in the iOS loader and Android offscreen harness. Their original declarations leave masked regions unassigned, which can expose undefined registers under shifted sampling. Original GLSL files remain unchanged.
- Grain uses integer-reconstructed fragment centers and an explicitly rounded Float32 scale. Integer cell seams remain sensitive to allowed interpolator rounding across GPUs; conformance records these input-derived seams and checks both stable pixels and full-image signal statistics.
- Original preset loading uses halationIntensityV2 when present, otherwise legacy intensity multiplied by 0.6. Three copied preset values were corrected to their effective zero V2 intensity. scripts/verify_original_presets.py and the source-derived test expectations verify all ten presets.
- Auxiliary animated textures are reused when the decoder returns the same cached frame. Seek and animation tests verify their output within one GPU rounding level.
