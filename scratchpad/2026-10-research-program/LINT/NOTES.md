# The middle-out kernels under the WGSL lint; `/status`; macOS clippy (2026-11-27)

Branch **`dev/mo-lint`** on the fork, cut from `dev/mo-mode` `0b6e22e1`; head **`c16d48e9`** (6 commits):

| commit | what |
|---|---|
| `8ccc49a0` | `scripts/wgsl-lint.py`: a shader's base from its header's first `base:` or else first `b:` (the middle-out kernels say `b`); `--require KERNEL[@BASE][:FIELD=VALUE]...` matches comptime values of the kernel info (`:w=64`, `:oh64=false`); new `--require-present` (found in the dump, no division count asked) |
| `79aa2753` | `midout::gpu::tests::wgsl_dump_for_lint` and `midout::gpu_wide::tests::wgsl_dump_for_lint` (ignored; do nothing without `CUBECL_DEBUG_LOG`) |
| `af19eb41` | `gpu-parity.yml` lint step: runs the three dump tests (`--exact`, `--test-threads 1`), 21 new `--require` and 17 `--require-present` specs |
| `5220ea18` | `/status` gets `disagreed`; end-to-end test |
| `0508b0b9` | the dump tests' device as let-else (clippy `manual_let_else`, found by CI's "Format and clippy" on `5220ea18`) |
| `c16d48e9` | the base-65 dump's survivor and parent caps cut (runtime sizes only) so every binding fits lavapipe's 128 MiB at W 8 (estimated: `out` was 148 MB at W 8 with the route's caps) |

No kernel source changed on the branch. `scripts/spirv-atomic-check.py` (upstream #278) is not on this branch.

## 1. What the dump covers now

Each dump test runs one slice's first batch only (`gj.batches.truncate(1)`), so the slice's accounts fail by
design and nothing is checked; the run exists to make CubeCL compile and log every kernel. Widths: the device's own
plane width (8 on lavapipe, 32 on the M4) and 32 and 64 through the existing compile-only path (`with_width`,
`force_w`) where the device's differs.

**Narrow, base 64** (`GpuJoin`, `Caps::b64(4)`): for each width × prefilter form (`Limbs24` = wgpu's, `Limbs32` =
CUDA's): `build_anc` (anc8), `run_slice_dev_with` unshared and shared (device tops: tops5, tops1, tscan, tops2,
tdigz2, toprec2; parents: hist2, scan16, scatter3, hsort; g2, expand, production's `check_kernel` in hits mode,
done), `run_slice` (host tops: tdigz, toprec). 16 middle-out kernels + the check.

**Wide, base 65** (`WideJoin`, the route's `WideCaps::for_base(65)` with 4 classes per batch and cut runtime caps,
`Coord::for_base(65)` and its shape (4, 10); slice 717171717): wtops5, wtops1, wscan (both instances: `seg=true`
n 4160 and `seg=false` n 16384), wtops2, wtdigz, whist, wscatter, wsort, wide, wexpand, wcheck, wdone. 12 kernels.
(The `(4, 9, 6)` coordinate also known at 65 has the same shape, so the same comptime values.)

Comptime variants in the M4 dump (lavapipe adds the W 8 ones, `fill` 512):

| kernel | variants dumped | constant divisions seen (M4 WGSL) |
|---|---|---|
| G2Kernel | w 32, 64 (+8 on lavapipe) | 8 |
| Hist2Kernel, Anc8Kernel | w 32, 64 (+8) | 4, 0 |
| ExpandKernel | oh64 true, false | 0 |
| CheckKernel b64 | ballot true, false (hits mode) | 0 |
| HsortKernel, Scan16Kernel, Tops1Kernel, Tops2Kernel | one | 2, 2, 1, 1 |
| Scatter3, Done, Tdigz, Toprec, Tops5, Tscan, Tdigz2, Toprec2 | one | 0 |
| WideKernel b65 | w 32, 64 (+8); nroot 1, maxpop 18 | 12 |
| WhistKernel, Wtops5Kernel b65 | w 32, 64 (+8) | 34, 163 |
| Wtops1, Wcheck (probe false), Wexpand (pf2 true), Wtops2, Wscatter b65; Wsort | one | 164, 107, 33, 1, 2, 2 |
| WscanKernel | seg false / seg true | 32 / 0 |
| WtdigzKernel b65, WdoneKernel | one | 0 |

CI's `--require` list asks for every kernel with divisions (by width where it has one: `G2Kernel:w=32`,
`G2Kernel:w=64`, `WideKernel@65:w=32`, ...), and `--require-present` for the ones with none, so a kernel or a
forced width that drops out of the dump fails the step. The device-width (W 8) variants are not required by name:
a runner with another lavapipe width would fail CI for no defect.

**Not covered, and why**
- Plane width 16: no width forced to it (no target device reported as max-16 here); it compiles only on such a device.
- `check_kernel` probe mode, `wcheck` `probe=true`: tests only, never launched by the drivers.
- `wexpand` with `pf2=false` (`set_prefilter_b2(false)`): bench A/B only.
- The wide path at base 64 (bench forcing) and bases 66–70 (the route refuses them).
- What naga makes of the WGSL (its MSL) and CubeCL's own MSL compiler (`cubecl-metal`): the log holds WGSL only, as
  before; the lint's header lists what it cannot see.

## 2. What the lint said

**0 flagged sites** in every middle-out shader, on the M4's dump (`5220ea18`, and again at `0508b0b9`+the caps
patch: the same 52 shaders, identical lint output) and in CI on lavapipe (see §4). Nothing to fix.

To show the lint does see into these kernels, a scratch build (never committed) put the old miscompiled form back
into hist2's `parent` (`u32::cast_from(pip >> 32u64) % 63u32`, value-neutral since `pip` < 2^30): the lint flagged
`Hist2Kernel` at both widths, `divides a HI32 dividend by 63: let l_142 = l_141 % u32(63);`, exit 1.

The lint was not weakened: the changes only add matching (base from `b:`, comptime filters, presence-only
requirements); the existing require list and self-test are unchanged and pass.

## 3. Device runs (mayalaran, Apple M4, macOS 27.2, Metal via wgpu<wgsl>, Rust 1.100.0)

Scripts in `~/claude/scripts/` there: `lint_dump.sh TAG COMMIT [PATCH]` (build, the three dumps, tier b),
`head_checks.sh TAG COMMIT [PATCH]` (plus nice_client's midout_route tests and clippy), `clippy_main.sh`.
- `5220ea18`: tier (b) `cubecl_midout` **8 passed** (W 32, 24-bit prefilter); dumps 3 passed.
- `5220ea18` + let-else patch (= `0508b0b9`): `nice_client --bin nice_client midout_route` **22 passed** (incl. the
  new `/status` assertions); clippy `nice_common --all-targets --features cubecl -D warnings`: only the two upstream
  `cpu_join.rs` errors (§6), nothing from the branch.
- `0508b0b9` + caps patch (= `c16d48e9`): dumps 3 passed, lint clean with the CI require list.

## 4. CI on the fork (head `c16d48e9`)

- GPU Device Parity: run 45949807997 — **success** (both jobs). lavapipe: device tests 50 passed (incl. tier (b)
  and the two new dump tests, which do nothing there without the log); lint step: 3 dump tests passed, **58 shaders,
  0 flagged sites, no required shader missing** (lavapipe W 8 adds the W 8 variants; under forced W 32/64 the wide
  run stops on its plane check after launching, as expected); SPIR-V step passed. macOS (paravirtual Metal): passed.
- Rust Cross-Platform Build, Test, and Release: run 45949810962 — **success** (16 jobs; the release job skipped): "Format and clippy" (`just lint`), "Test workspace (native Linux-x86_64)" (incl. the client's end-to-end tests with `disagreed`), the CUDA host tests and every cross build.
- Earlier runs on `5220ea18`/`0508b0b9` were cancelled by the newer dispatch (the workflow's concurrency group);
  the Rust run on `5220ea18` had shown the `manual_let_else` failure fixed in `0508b0b9`.
- Unrelated: a parity run on `dev/mo-mode` `0b6e22e1` (45790967510) has its macOS job "in progress" since 05:43
  today (a re-run?); not touched.

## 5. `/status` (`scripts/midout_coordinator.py`)

New key `disagreed`: accepted checks whose result differs from their field's canon, by the same rule `agrees`
already applied (and the audit uses): other nice numbers, or other counters under the same shape. Counted in
`accept`, so a resumed server counts the checks on record too. A disagreeing check still never promotes a field to
checked. Docstring lists the keys. Test (`client/src/midout_route/tests.rs`): `end_to_end_against_the_development_server`
asserts `disagreed` 0 after the clean run; `audit_flags_a_check_that_disagrees` now also starts a server on the
state copy holding the disagreeing check and asserts `disagreed` 1, `checked` 0, `submissions` 31.

## 6. macOS clippy (upstream code)

Confirmed on upstream `main` `fdbe07d3` on mayalaran (aarch64): `cargo clippy -p nice_common -- -D warnings` fails
with `unused_self` at `common/src/cpu_join.rs:986` (`pass1`); with `--all-targets` also `unused_mut` at `:2093`
(the pass1 test's `joins`). Cause: both uses sit behind `#[cfg(target_arch = "x86_64")]` (AVX paths), so any
non-x86-64 target sees them, not only Apple.

Branch **`pr/macos-clippy-cpu-join`** on the fork, one commit **`ebba000e`** on `fdbe07d3`: `#[cfg_attr(not(target_arch
= "x86_64"), allow(...))]` on `pass1` and on the `let mut joins`. On mayalaran with its own target dir: clippy lib and
`--all-targets` with `-D warnings` clean. Rust workflow dispatched on it: run 45949549267 — **success** (16 jobs, release skipped; "Format and clippy" and the workspace tests green on Linux x86-64).
No pull request opened.

Two-line description:
> CPU join: clippy `-D warnings` failed on non-x86-64 hosts (Apple Silicon): `pass1` reads `self` and the pass1 test
> pushes to `joins` only on the x86-64 AVX paths. Allow `unused_self` / `unused_mut` there on other targets only.

## 7. Not done / open

- No kernel was changed, so no Metal re-run after a kernel change was needed; tier (b) ran on the M4 at `5220ea18`.
- Plane width 16 and the test-only variants (above) stay outside the dump.
- The lint step still reads WGSL only (no MSL).
- `TopFdKernel b57` is in the existing dump but not in the existing `--require` list (pre-existing; not changed).
