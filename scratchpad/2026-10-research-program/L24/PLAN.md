# L24 plan: finite differences in the browser GPU kernel

Read against #225 at dbe2ab7, `cubecl_web.rs`, `wasm-client`, `worker.js`, `bench_defs.rs` and the e2e harness. Nothing was built or run.

## 1. How the browser differs from the native FD kernel

- **No u64 at all.** wgpu on WebGPU has no `SHADER_INT64`, and Dawn/Tint rejects WGSL that names `u64`. #225 uses u64 in five places:
  - the prologue (`start_lo/hi`, `count`, `stride`, `off`);
  - `n_lo/n_hi` passed into `fd_seed`;
  - the mask (`fd_mask -> u64`, `ms`, `m`);
  - the near-miss `x_lo/x_hi`;
  - the popcount split.
  
  The step adds (`fd_add_top`, `fd_add_const_top`, `fd_ripple`) and the split16 seed body are already u32-only. They rely on u32 wrap-around, which WGSL defines.
- **No 64-bit atomics.** Not needed: bins stay u32 under `DRAIN_INTERVAL × CUBECL_WEB_BATCH_SIZE < 2³²`, one bin per candidate.
- **Launch limits.**
  - `WORKGROUP_SIZE` 256 equals WebGPU's default invocation limit.
  - `MAX_CUBES_WEB` 4096 is well under 65535.
  - Shared memory: FD needs only the histogram copies (1,040 B at b64). Today's kernel uses 14.9 KB at b97 because of its scan scratch, against the 16 KB default.
- **Readback.** Each `process_chunk_gpu` slice ends in a single `read_async([hist, miss_count, miss_data])`, which reads the whole 160 KB miss buffer (8,192 records on wasm). `worker.js` keeps two slices in flight, each with its own buffers. FD writes the same buffers with the same 5-word records, and the host already sorts near-misses, so the tail is unchanged.
- **Run length and dispatch time.**
  - A dispatch is 32M candidates. At 128 per run that is 250k threads (977 cubes), about one run each.
  - Per-dispatch work falls about 3×, so watchdog margin improves.
  - 250k threads is about 1.5 waves on a 4090-class card, so there may be a tail effect.
- **Mask today.** Four u32 words (`m0a m0b m1a m1b`; `four_masks` for b>64), set by an `if d < 32 / < 64 / < 96` chain. FD serves b≤64, so it needs two words.

## 2. Port design

**Shared as-is** (made `pub(crate)`):
- `fd_add_top`, `fd_add_const_top` and `fd_ripple`.
- `fd_to_digits` with `wide_chunk = false`. CubeCL folds constant `if` conditions (`cubecl-core-0.10.0/src/frontend/branch.rs:318`), so its u64 branch never reaches WGSL.
- `fd_plan`, `FD_RUN_LEN`, `HIST_COPIES` and `MISS_STRIDE`.

**Refactor of #225:**
- Move `fd_seed`'s split16 branch into `pub(crate) fd_seed_split16(nw: &Array<u32> /*4 words*/, sd, cd, ds, dc, ddc, comptime…)`.
- `fd_seed`'s split16 branch becomes "u64 → four words → call".
- Only the word extraction changes in the WGSL, but re-run `cubecl_fd_seed_matches_cpu` on lavapipe and on the M4.

**Web variants (`cubecl_web.rs`):**
- `fd_mask_u32(x, lo, hi, from, ndig) -> (u32, u32)`:
  - per digit, `bit = 1u << (d & 31)`, `sel = (d >> 5) - 1`, `lo |= bit & sel`, `hi |= bit & !sel`;
  - branch-free, with an explicit `& 31`;
  - tuples are `CubeType` in 0.10 (`element/base.rs:331`); fall back to a two-word local `Array` if the macro refuses.
- `detailed_fd_kernel_u32`, which is #225's kernel with these changes:
  - u32 `count` and `off` (≤ 4096·256·1000 < 2³², asserted on the host);
  - n built as four words with a carry chain, as `detailed_kernel_u32` does today;
  - `ms_lo/ms_hi`;
  - `countOneBits(lo) + countOneBits(hi)`;
  - near-miss n as run start + i over four words, on the rare path only.
- `run_len` stays a runtime scalar.

**Host:**
- `process_range_detailed_web_async` keeps its signature, so `wasm-client/src/lib.rs` is unchanged.
- New `process_range_detailed_web_kernel(…, WebKernel::{Division, FiniteDifference{run_len, batch}})`.
- Each batch splits like `detailed_impl`: inside `fd_plan`'s interval → FD, outside → `detailed_kernel_u32`.
- The u32 per-number kernel stays for b65–97, out-of-range candidates and as reference.
- Optional: `"detailed_kernel":"fd"` in `gpu_build_info`, to spot a stale cached wasm.

**Not proposed:** one u32-only FD kernel shared with native. It would change #225's measured kernel and need re-benchmarking on the 3080, 4090 and M4.

## 3. Exactness

**Native wgpu.** Lavapipe in docker (ubuntu:24.04, since ivory has none), plus CI's lavapipe and macOS jobs, which run every ignored test.
- `web_fd_matches_cpu_detailed`: whole `FieldResults` against `process_range_detailed`.
  - b40 and b50, every `windows()` entry at 1e5: range start and end, straddling the start, 8 random windows, and every in-range dS/dC digit-gain point.
  - All four `SHAPES`, with the batch capped at 32M.
  - The full ranges of b10–24 (27 near-misses).
  - Needs `windows`, `SHAPES` and `cpu_detailed_parallel` exposed as `#[cfg(test)] pub(crate)`.
- The existing `web_kernel_*` tests (b10/40/62/80/97, the b49 near-miss, 69 in b10) run FD at b≤64 automatically. b10 splits FD / per-number at the range end.
- A web seed probe through `fd_seed_split16` at all 44 bases, word for word.
- No-u64 gate: grep the `CUBECL_DEBUG_LOG` WGSL dump of b10–64 for `u64|i64`.
  - Lavapipe accepts u64, so parity tests cannot catch one, and cubecl requests every adapter feature, so a test device without `SHADER_INT64` is impractical.

**Browser (Playwright `run.sh`, CI on SwiftShader).**
- Covered with no change:
  - the offline b40 10M field's CPU/GPU histograms must be equal;
  - the b49 submit must carry 20363742218601559 exactly.
- New `parity` step: `page.evaluate` imports `pkg/*.js` on the main thread and compares the JSON from `process_chunk_gpu` and `process_chunk_wasm` over a fixed list:
  - starts at b10, 23, 25, 27–30, 40, 49, 50, 52–55, 57 (three limbs), 64 and 80 (fallback);
  - the four b40/b50 gain points from the PR body;
  - lengths 1, 61, 129 and 1e5, so runs end partway.
  
  Run length 1 stays native-only, since the production binding takes no shape.

**Metal checklist** (Chrome on a Mac: WGSL → Tint → MSL → Apple's compiler):
- [ ] No `/` or `%` on a bare `x >> 16`. The seed is covered by `fd_to_digits`' top pair. The prologue, mask and step have no division.
- [ ] No high-half-of-product division. This cannot be formed without u64. 16×16 carries (`t >> 16`) enter `fd_to_digits` only through the top pair.
- [ ] The per-number fallback keeps its runtime loop with a loop-carried `rem`. Never unroll it.
- [ ] A script over the WGSL dump flags any `let l_N = … >> 16u` that is later a `/` or `%` operand.
- [ ] M4 runs: the native web tests (naga MSL), then `e2e.mjs --hw` with parity (Tint MSL).

## 4. Browser performance and risks

| rate (n/s) | b40 | b50 |
|---|---|---|
| browser u32 kernel, M4 Chromium (08-28 A/B) | 6.57e8 | not recorded |
| browser u32 kernel, RX 9070 XT Firefox Nightly | 1.2e9 | not recorded |
| native wgpu per-number, M4 | 8.12e8 | 4.81e8 |
| native wgpu FD, M4 | 2.435e9 | 2.187e9 |
| CI SwiftShader, offline field | 1.06e6 | — |
| GPU score reference (shared with the browser) | 2.4e9 | 1.5e9 |

- The browser kernel uses native wgpu's split16 scan: about 200 u32 divisions per number at b50, against about 4 for FD.
- The port adds only the mask pair. A u64 shift is emulated on GPUs anyway.
- **Projection, not a measurement:** about 3× at b40 and 4× at b50, i.e. about 2e9 on the M4 in the browser. A 1e10 field would take about 5 s instead of 15 s.
- Measure with the suite's 2e8 GPU windows; the offline field drops to about 5 ms of kernel time.

**Risks:**
- Under-filled waves at 250k threads. Measure R = 64 against 128. A 64M batch still meets the drain bound (4.10e9 < 4.29e9); change one thing at a time.
- Register pressure behind Tint, D3D and Metal cannot be inspected; only CUDA's 48 registers are known. Every array index must stay comptime after unrolling.
- Compile time of fully unrolled per-base shaders (pre-fix b40 WGSL: 3,774 lines). Unmeasured on SwiftShader (CI time) and on D3D12.
- Safari: the same Apple backend sits behind its own WGSL compiler. Worker WebGPU support and any way to test it are undetermined; Playwright cannot drive Safari's WebGPU.

## 5. Work breakdown (half-days)

| # | step | estimate | needs a browser |
|---|---|---|---|
| 1 | Prerequisite #225 (or stack on it). `pub(crate)` helpers, `fd_seed_split16`, test support; lavapipe seed and FD suites green | 1 | no |
| 2 | `detailed_fd_kernel_u32`, `fd_mask_u32`, `WebKernel` dispatch and fallback split | 2 | no |
| 3 | Native web FD tests, web seed probe, WGSL checks (u64, half-shift division), clippy | 2 | no |
| 4 | e2e `parity` step; CI timing on SwiftShader (`run.sh` in docker on ivory) | 1.5–2 | yes |
| 5 | Hardware, with per-task permission: M4 native tests, `--hw` Chromium parity and suite; demoux Firefox Nightly field and suite; before/after browser GPU NiceMark; cleanup | 2 | yes, apart from the M4 native tests |
| 6 | PR body (numbers there, a one-line CHANGELOG), review fixes | 1 | no |

Total: about 5 days. The ledger's 1–2 days covers steps 1–3.

## Not determined

- The browser's b50 GPU rate. No browser GPU-suite run was found.
- Whether Tint's guarded MSL division triggers the Apple bug. Assume yes.
- Compile time of the FD shaders on SwiftShader and D3D12.
- WGSL-backend register counts.
- Whether there is a wave-tail cost.
- Whether L23 lands first. If it does, the e2e compares two FD implementations; the native tests keep the division reference.
