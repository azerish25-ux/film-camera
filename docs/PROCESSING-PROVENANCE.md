# Processing provenance

The supplied Android source is the active fully local build described in its README and developer handoff. Reference Java is decompiler output; the original app is built from recovered bytecode and resources.

- `l4/a.java`, `l4/b.java`, `l4/c.java`: recovered GLSL. Shader strings were decoded from Java literals and retained in `Reference/AndroidShaders`. Runtime loading replaces external-camera sampler declarations with ordinary 2D samplers for iOS-owned pixel textures.
- `j4/d.java`, `j4/p.java`, `j4/e.java`: pass order, uniforms, temporal state, framebuffer sizes and blur schedules.
- `v3/d0.java`: original 88-entry film list. 87 image LUTs plus Normal Mode.
- `h4/e.java`: ten original presets.
- `ba/j.k`: natural cubic spline for the characteristic curve. Input samples are quantized to integer bytes as in the Android path.
- `v3/m1.java`: PNG headers are restored to their standard signature; video headers XOR the first eight bytes with the recovered header key. ETC1 assets are decoded to uncompressed pixels for iOS.
- Native `Java_a_a_c` / `FUN_0019501c`: original LUT packing order is blue plane, green row, red column. The original LUT PNG stores a pixel at `(blue*64+red,green)`.
- Normal Mode follows Android's integer `channel*255/64` table generation rather than substituting a mathematically ideal identity table.

The Swift application implements local camera, editor, gallery and preset workflows with Apple APIs. Rendering uses the recovered shader calculations, film tables and frame assets. OS camera capture, codec behavior and GPU floating-point behavior differ by platform. Tests report pixel error for deterministic shader fixtures and a separate bound for procedural grain; a test pass must not be described as universal bit-for-bit device equivalence.
