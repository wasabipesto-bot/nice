# L24 proposal: the finite-difference detailed kernel on the browser GPU path

2026-10-31. Builds on `L24/PLAN.md`; read against #225 at dbe2ab7 (open), main 472c9a0 and #227 (L23, open). Nothing built or run. **H** = hypothesis.

## 1. Scope and PRs

| PR | changes | tests | merge evidence |
|---|---|---|---|
| **(a)** shared seed, on #225 | Moves the u32-only `fd_seed_split16(nw: &Array<u32>, sd, cd, ds, dc, ddc, comptime…)` out of `fd_seed`. The wgpu branch becomes "u64 → `limbs` words → call"; the CUDA/HIP branch is untouched. The step helpers, `fd_to_digits` and `NO_CARRY` become `pub(crate)`. | existing `cubecl_fd_seed_matches_cpu` and `cubecl_fd_matches_cpu_detailed` | CI green (lavapipe naga and SPIR-V, macOS). **M4 native**: seed 132/132 windows, FD suite exact. CUDA FD suite on a Vast RTX box. WGSL differs from #225 only in word extraction. M4 NiceMark within noise of 1216. |
| **(c)** browser parity | `e2e.mjs` gains: a `parity` step (§3.3); an adapter assertion with `--expect-vendor`; `--chromium-arg` for dev-only flags (`--hw` stays flag-free); a report-only raw-WGSL Metal probe; and `parity.html` for manual runs (harness-served, not deployed). It runs on today's kernel. | the step itself, with a SwiftShader subset in CI | CI green, added time stated; one `--hw` log each from mayalaran and demoux |
| **(b)** web FD kernel | `detailed_fd_kernel_u32`, `fd_mask_u32` and `process_range_detailed_web_kernel(…, WebKernel)`, behind the unchanged `process_range_detailed_web_async`. `detailed_kernel_u32` stays for b65–97, for out-of-plan candidates, and as the reference. `lib.rs` is unchanged. | new ignored `web_fd_matches_cpu_detailed` and `web_fd_seed_matches_cpu`; host test `web_fd_launch_bounds`; the existing `web_kernel_*` tests now run FD at b≤64 | CI with e2e parity; WGSL lint clean at 44 bases; M4 native tests and full headless parity; demoux Chromium parity or the maintainer's Firefox Nightly `parity.html`; suite A/B in the PR body; one-line CHANGELOG |

**Merge order: #225 → (a) → (c) → (b)**, so the harness is proven on today's kernel and (b)'s own CI run is its browser evidence.

## 2. Design

### 2.1 Kernel

`detailed_fd_kernel_u32` is #225's kernel with every u64 site replaced:

| #225 | web |
|---|---|
| u64 `start`, `count`, `off`, `stride` | words `s0..s3`; u32 `count`, `off`, `stride`, with `off < count + stride ≤ 32M + 4096·256·R < 2³⁰` asserted on the host |
| `n_lo/n_hi` into `fd_seed` | `nw[0..4] = s + off` by carry chain (as in `detailed_kernel_u32`), then `fd_seed_split16(&nw, …)` |
| u64 mask and cached `ms` | `(lo, hi)` and `(ms_lo, ms_hi)`. Per digit: `bit = 1u << (d & 31u)`, `sel = (d >> 5u) - 1u`, `lo |= bit & sel`, `hi |= bit & ~sel`. If tuples fail, use a two-word local `Array`. |
| popcount | `countOneBits(lo) + countOneBits(hi)` |
| near-miss `x_lo/x_hi` | `nw + i` over four words, on the rare path |

The digit arrays are #225's: four digits per u32 in byte lanes, stepped with biased adds. Words per thread:

| base | S | C | dS | dC | ddC | total | fast S/C |
|---|---|---|---|---|---|---|---|
| b40 | 4 | 6 | 3 | 5 | 3 | 21 | 3/5 |
| b50 | 5 | 8 | 3 | 6 | 3 | 25 | 3/6 |
| b64 | 7 | 10 | 4 | 7 | 4 | 32 | 4/7 |

Plus four mask words and about 100 seed temporaries at b64, dead after the seed (WGSL's function-space limit is 8,192 B). Every array index must be comptime after unrolling: a runtime index forces the array into memory (and Tint adds a clamp). `run_len` stays a runtime scalar.

### 2.2 Launch shape against WebGPU defaults

No u64 values and no 64-bit atomics are used.

| item | value | limit |
|---|---|---|
| workgroup | 256 | 256 |
| workgroups per FD dispatch | ⌈⌈count/R⌉/256⌉ clamped to 1..4096 (977 at 32M, R = 128) | 65,535 |
| shared memory | 4 × (b+1) × 4 B ≤ 1,040 B | 16 KB |
| buffers | hist, miss count, miss data (160 KB), CubeCL info | 128 MiB; 8 per stage |
| bins | u32, `64 × 32M < 2³²` (unchanged) | — |

A batch is about 250k threads, one run each; per-dispatch time falls about 3×, widening the watchdog margin.

### 2.3 Readback and host split

Each batch `[a, z)` splits the way #225's `detailed_impl` does. FD takes `[max(a, reg_lo), min(z, reg_hi))`. `detailed_kernel_u32` takes the rest, which is the whole batch when there is no plan (b > 64).

Both kernels write the same `hist`, `miss_count` and `miss_data` (5-word records) within the batch's one flush, so the tail stays one `read_async([hist, miss_count, miss_data])`. Conservation, overflow check, host sort and `worker.js` slicing are unchanged. `WebKernel::{Division, FiniteDifference{run_len, batch}}` is `pub(crate)` for tests and `ensure!`s run length, batch ≤ 32M and the u32 bound.

### 2.4 Metal checklist

Chrome (Tint), Safari (WebKit) and Firefox (naga) all emit MSL for Apple's compiler.

- [ ] No `/` or `%` on a dividend that is, or folds to, `x >> 16u`. The seed starts each chunk from the top-limb pair (#225's fix). The prologue, mask, step and near-miss path do not divide.
- [ ] No division of a product's high half. This is impossible without u64; the `t >> 16` carries only feed adds and ORs.
- [ ] The fallback's scan stays a runtime loop with a loop-carried `rem`; never unroll it. `(rem << 16) | (vi >> 16)` is the bad form once `rem` folds to 0.
- [ ] WGSL lint over the `CUBECL_DEBUG_LOG` dump of both kernels at all 44 bases. It flags `u64|i64`, and any `/` or `%` whose let-substituted dividend is `… >> 16u` or `0 | (… >> 16u)`. This is best-effort; the M4 runs decide.
- [ ] mayalaran runs both Apple paths: native (naga) and headless Chromium (Tint).
- [ ] The raw-WGSL probe runs in Chromium on the M4. **H:** Tint's guarded `tint_div` triggers the bug just as `naga_div` does.

## 3. Testing that works headless

### 3.1 Layers

| layer | path | where and when |
|---|---|---|
| Native web tests: b40/b50 `windows()` at 1e5 × four `SHAPES` (batch ≤ 32M), b10–24 in full, and the `fd_seed_split16` probe (44 bases × 3 × 1,024 n, word for word) | naga → SPIR-V; CubeCL SPIR-V | **Always on**: CI gpu-parity on lavapipe, which runs every ignored test. Locally: ubuntu:24.04 + rustup in podman on ivory (not bookworm's Mesa 22). |
| SwiftShader e2e: offline b40 field CPU = GPU, exact b49 submit, parity subset. Tint rejects any u64. | Tint → SPIR-V | **Always on**: CI |
| WGSL lint (§2.4) | WGSL as browsers get it | per kernel change (Q7) |
| M4 native tests | naga → MSL | mayalaran, offline build, permission |
| M4 headless Chromium `--hw`: parity, probe, suite | Tint → MSL | mayalaran, Playwright, permission |
| demoux native tests; Chromium with dev flags | naga/Tint → RADV | permission; native build optional (disk 97 % full) |
| demoux Firefox Nightly: `parity.html`, GPU suite | Firefox wgpu → RADV | **maintainer**, about 20 min |

### 3.2 Headless Playwright on real GPUs

The harness calls `chromium.launch({channel: "chromium", headless: true})`. That is new headless, the full browser; the default headless shell has no GPU.

| platform | flags, in order | status |
|---|---|---|
| M4 over SSH | none | **Likely**: the 08-28 A/B harness there ran the GPU backend at 6.57e8 n/s (SwiftShader: ~1.2e6). That harness is gone. |
| | `--enable-unsafe-webgpu`, then `--ignore-gpu-blocklist` | **H**: only needed if no adapter appears |
| | `--use-angle=metal`, `--enable-features=Vulkan` | expected no-ops (ANGLE is WebGL; Dawn drives Metal); tried once |
| | `--enable-webgpu-developer-features` | diagnostic; **H**: unmasks `description` |
| 9070 XT, Linux | none | **Known to fail** (08-28): no adapter; Chrome's Linux rollout excluded AMD |
| | `--enable-unsafe-webgpu --enable-features=Vulkan`, then `--use-angle=vulkan`, `--ignore-gpu-blocklist` | **H**: works headless without DISPLAY. Dev-only, never user advice. |
| | Playwright Firefox, three prefs | **H**: no hardware run is recorded |

**Adapter assertion.** In (c), on the main thread:

```js
const a = await navigator.gpu?.requestAdapter();
const i = a?.info ?? (await a?.requestAdapterInfo?.());
rec = {vendor: i?.vendor, architecture: i?.architecture, description: i?.description,
       fallback: i?.isFallbackAdapter ?? a?.isFallbackAdapter};
```

With `--hw`, the run fails unless all of these hold:

- an adapter is returned;
- `fallback !== true`;
- no field matches `/swiftshader|llvmpipe|lavapipe|software|basic render/i`;
- `vendor` equals `--expect-vendor` (`apple` or `amd`);
- a warm (second) 2e8-number b40 `process_chunk_gpu` call runs above 1e8 n/s (SwiftShader: ~1e6). This check does not depend on the info strings; the offline field is too small, since its rate includes shader compile.

CI asserts the inverse (SwiftShader pinned). The wasm `gpu_init()` name is logged too; wgpu 29 fills it from `info.description` alone, so it may be blank under Chrome.

**First half-day, on today's main wasm.**

- **H1.** Unflagged headless Chromium reaches Metal over SSH.
- **H2.** Chromium 151 reports `vendor` and `architecture` unflagged, with `isFallbackAdapter` on `GPUAdapterInfo`.
- **H3.** SwiftShader reports `google` / `swiftshader`.
- **H4.** The demoux flags work.
- **H5.** The Tint probe runs the six `metal_half_shift_div_repro` variants × K ∈ {3, 1000, 2500, 12167, 21952, 32768}.
- **H6.** Node and Playwright's mac-arm64 Chromium can be staged from ivory into `~/claude-exp-<date>`, with `PLAYWRIGHT_BROWSERS_PATH` inside it. mayalaran's downloads stalled on 10-10.

This is also the first exactness check of today's browser kernel on Apple through Tint (the notes record only its rate). If H1 fails: the table's flags, then `channel: "chrome"`, then a logged-in GUI session (Q6); else the M4 naga path plus Firefox-on-Mac by hand, with Tint-on-Apple stated as untested.

### 3.3 Parity windows

Each window compares the raw JSON strings of `process_chunk_gpu` and `process_chunk_wasm` byte for byte (no `JSON.parse`, so values above 2⁵³ stay exact). After #227 both sides are FD; the native tests keep the division reference.

| set | `--hw` windows |
|---|---|
| full ranges | bases 10–25: 13 bases, 8.7e6 numbers, including 69 at b10 and the 27 near-misses up to b24 |
| bases 27–64 | start, middle and end, 1e5 each |
| M4 failure bases | 23 and 25 whole (above); 27–30, 49, 50, 52–55 get 4 more seeded 1e5 windows each |
| digit-gain points | every in-range dS/dC/ddC gain point at every base (BigInt, as `windows()`), 1e5 centred; at b40 dS 3,276,800,000,000 and dC 3,783,722,724,161, at b50 dS 48,828,125,000,000,000 and dC 56,381,862,225,549,391 |
| kernel boundary | b40 and b50 `[rs−5e4, rs+5e4)`; b40 `[re−5e4, re+5e4)`; b10 `[47, 200)` |
| partial runs | at the b40 and b57 starts, lengths 1, 2, 61, 127, 128, 129, 255, 257 and 100,001 |
| near-misses | b49 `[20363742218551559, +1e5)` (…601559 with 45 uniques); b40, 1e5 around 1,917,398,732,423 (37) |
| fallback only | b80 and b97 starts, 5e4 |

**CI subset**, trimmed if it adds more than 2 min:

- b10 `[47, 200)`
- b23 in full
- b40: the start, the start straddle, the dS gain point, and lengths 1, 61 and 129
- the b49 near-miss window
- the b50 dC gain point
- b57, b64 and b80 at 2e4 each

Run length 1 and the seed words stay native-only unless a test export is added (Q4).

## 4. Performance

| n/s | b40 | b50 |
|---|---|---|
| browser per-number, M4 Chromium (08-28) | 6.57e8 | — |
| browser per-number, 9070 XT, Firefox Nightly | 1.2e9 | — |
| native wgpu, M4: per-number → FD | 8.12e8 → 2.435e9 | 4.81e8 → 2.187e9 |
| native FD on AMD | — | — |
| GPU score reference | 2.4e9 | 1.5e9 |

**Projections (H).**

- **M4**: the browser's per-number kernel ran at 0.81 of native's. Taking 0.7–0.8 of native FD (lower, since a 2e8 suite window is one ~0.1 s slice and fixed costs weigh more) gives 1.7–2.0e9 at b40 and 1.5–1.8e9 at b50: browser GPU NiceMark about 840–1,000, against about 270 today (b50 inferred).
- **9070 XT**: about 3.5e9 at b40 (no native AMD FD number exists).

**Measurement.**

1. **Suite A/B**: Playwright drives the real page (`testMode=suite`, GPU, 60 s), old (main) and new builds side by side, alternating over 3 rounds, capturing the page's `benchmark report` (rates, repetitions, `warmup_seconds`) and the adapter record, as `l23-speed.mjs` did. M4 and demoux; the maintainer repeats it in Firefox Nightly.
2. **Kernel only**: `process_chunk_gpu` over 2e9 at the b40 and b50 starts in a fresh page, 2 untimed calls, median of 3.
3. **Compile time**: first call minus a steady call, per base and kernel, on SwiftShader, the M4 and demoux.
4. **Tuning**: R ∈ {64, 128, 256} timed natively on RADV and the M4; the browser confirms only if R changes.

**Risks.**

- **Compile time** of unrolled per-base shaders (pre-fix b40 WGSL: 3,774 lines). D3D12 is unmeasured; uploads would show it in `warmup_seconds`.
- **Register pressure** is invisible behind Tint, Metal and D3D; comptime indices are the only lever.
- **Tails**: 250k threads is 3.8 full-occupancy waves on the 9070 XT (64 CUs × 1,024) but about 1.3 on a 4090-class card (about 64 % efficient). R = 64 cuts that loss to about 15 % for about 5 % more seed work; a 64M batch also fits the drain bound but doubles dispatch time on slow iGPUs (Q5).
- **Safari**: own WGSL compiler, same Apple backend, worker support undetermined; Playwright's WebKit is not Safari and safaridriver needs a GUI session.
- **Untested drivers** (Intel, Qualcomm, Mali, NVIDIA under Chrome): the server validates near-misses, not histograms, so a miscompile would go unseen, as for today's kernel.

## 5. Work breakdown (half-days)

| # | step | ½d | after | machine |
|---|---|---|---|---|
| 1 | Headless bring-up: H1–H6 and the probe, on today's wasm | 1 | permission | mayalaran (+ demoux) |
| 2 | (a) refactor; lavapipe seed and FD suites; WGSL diff | 1 | #225 | ivory (podman with L23's cgroupfs override) |
| 3 | (a) on hardware: M4 seed, FD and NiceMark; CUDA FD suite (~1 h, ~$0.3) | 1 | 2 | mayalaran (same window as 1, after 2), Vast |
| 4 | (c) parity, assertion, probe, `parity.html`; SwiftShader timing | 1.5 | 1 | ivory |
| 5 | (b) kernel, mask, host split | 2 | 2 | ivory |
| 6 | (b) native tests, seed probe, WGSL lint, clippy (host; wasm32 `--no-deps`) | 2 | 5 | ivory or a Vast CPU box with lavapipe |
| 7 | (b) on hardware: M4 native and full headless parity plus suite A/B; demoux | 2 | 4, 6 | mayalaran, demoux |
| 8 | Tuning, only if step 7 shows a tail | (1) | 7 | mayalaran, demoux |
| 9 | PR bodies, CHANGELOG lines, review fixes | 1 | all | ivory |

**Total: 11.5 half-days (about 6 days); 12.5 with tuning.** PLAN.md's 5 days left out the bring-up and the hardware cycle for (a).

**Maintainer:** approve the split and order; merge #225; grant two ~3 h mayalaran windows (steps 1+3, 7+8); for demoux, a 2 h SSH window or ~20 min of Firefox Nightly against the ivory dev server; ~$0.3 of Vast.

## 6. Open questions

1. (a) as its own PR after #225, or a second commit on #225 (one review and one M4 cycle fewer)?
2. Merge order (a) → (c) → (b)?
3. Wait for #227, so browser parity compares the two FD paths from the start?
4. A test-only wasm export (feature-gated or `#[doc(hidden)]`) for run shapes and the word-for-word seed probe in the browser?
5. Run length 128, or 64 for large-GPU tails if it costs under 3 % on the M4 and the 9070 XT?
6. Can mayalaran keep a logged-in GUI session (fallback if headless misses Metal; only route to Safari)?
7. WGSL lint as a CI step, or PR evidence only?
8. CI time the SwiftShader parity subset may add (proposed: ≤ 2 min)?
9. A Windows (D3D12) machine or a Safari user to open `parity.html` once?
10. `"detailed_kernel":"fd"` in `gpu_build_info`? (A URL-parameter kill switch to the per-number kernel would be a new feature needing its own yes.)

## 7. Decisions (maintainer, 2026-10-31)

All ten open questions were answered by the director and agreed by the maintainer:

1. (a) is its own PR after #225 (merged 2026-10-31); one M4 seed-test cycle for it alone.
2. Merge order (a) → (c) → (b).
3. Do not wait for #227; the division reference lives in the native lavapipe tests.
4. Add the test-only wasm export, `#[doc(hidden)]`.
5. Run length 128 by default; measure 64 on the M4 and the 9070 XT in the tuning half-day; switch only if ≥ 3 % better on both.
6. No GUI session on mayalaran; plan on headless Metal; ask only if the first half-day finds it missing.
7. The WGSL lint becomes a CI step.
8. SwiftShader parity subset capped at 2 minutes of CI time.
9. Windows and Safari skipped unless a machine turns up; gap noted in the PR.
10. `"detailed_kernel":"fd"` in `gpu_build_info`; no kill switch.

Authorisation: mayalaran for 16 hours from 2026-10-31 ~16:30 UTC, or until the web GPU runner is complete; demoux by request. Start: (a) and the headless bring-up in parallel.
