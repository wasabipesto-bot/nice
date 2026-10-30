# PR #225 on Apple Metal: root cause and fix (2026-10-30, on the M4 "mayalaran")

**Result.**
- **Root cause, verified on the device.** Apple's GPU compiler (M4, macOS 26.3 25D125) miscompiles an unsigned division
  or remainder by a non-power-of-two constant when the dividend is a right shift by half its width:
  - `naga_div(x >> 16u, K)`, which is what naga emits for every WGSL `(x >> 16) / K`;
  - `(x >> 16u) % K`;
  - `uint(ulong p >> 32) / K`, the 2026-10-06 form.
- **Where it hit the FD kernel.** The seed's split16 long division (`fd_to_digits`) is unrolled, so at each chunk's first
  step `rem` is a literal 0. The first dividend is then exactly `top_limb >> 16`, and the n² digits (and n³ at some
  bases) come out wrong.
- **Fix.** The fix is on the fork as `pr/gpu-detailed-fd-metalfix`, three commits on d8038d6 (the gate).
  - The split16 seed now works in 16-bit limbs, in u32 arithmetic only.
  - Each chunk's division starts with the top two limbs as one u32, so no division ever sees a bare shift.
  - The CUDA/HIP path, the hot loop, the mask build and the histogram are unchanged.
- **On the M4.** Every FD test passes, and a 220-window sweep of all 44 bases 10–64 matches the CPU exactly. Speed is
  unchanged against the PR: NiceMark 1216 against 1216, still 3.0× (b40) and 4.5× (b50) over main.

## Branch `pr/gpu-detailed-fd-metalfix` (fork), on d8038d6

| commit | what |
|---|---|
| `d9261a8` | Moves the seed into `fd_seed`, behaviour unchanged. Adds `cubecl_fd_seed_matches_cpu`, which checks the five digit arrays of 1024 n at the start, middle and end of all 44 bases, word for word against the CPU, on whatever wgpu device; it bypasses the gate. Adds `metal_half_shift_div_repro`, the minimal reproducer, `#[ignore]` and also gated on `NICE_METAL_DIV_REPRO=1`, because CI runs every ignored test and this one fails on Apple silicon by design. |
| `af41956` | **The fix.** The gate stays in this commit; its docs (module, `for_device`, CHANGELOG) now name the cause. |
| `297a969` | Reverts d8038d6 (lifts the gate). It is a separate commit, so `af41956` gives "fix plus gate" and the head gives "fix, gate lifted". |

`fmt --check` is clean. Clippy `-D warnings` is clean on `nice_common --all-targets` with `cubecl` and with
`gpu,cubecl-spirv`, at `af41956` and at the head (d9261a8's content: `cubecl` only). The full `just lint` over every
package was not run.

## Root cause: how it was found

1. **Reproduced** both failures at 18cba8b: b50 range start, and base 23.
2. **Stage probe.** The test kernel runs the seed one n per thread and writes out every stage.
   - n² and n³ limbs are exact.
   - **S digits are wrong from digit 0** at b23, b27, b28 and b50.
   - C is wrong at b28 mid, b29, b30 and b52–55.
   - dS, dC and ddC are exact.
3. **Per-step trace of the long division.** The first wrong value is always chunk 0, top limb, the first quotient
   `q1 = (0 << 16 | top >> 16) / K`:

   | base | K | dividend | quotient returned | correct |
   |---|---|---|---|---|
   | b23 | 12167 | 0 | 4 | 0 |
   | b27 | 19683 | 0 | 2 | 0 |
   | b28 | 21952 | 9 | 2 | 0 |
   | b50 | 2500 | 0 | 3 | 0 |

   (`analysis/trace*.py`, `dumps/`.)
4. **The trigger is the shift, not the product.** A first fix (16-bit limbs, no u64 product) returned **byte-identical
   wrong digits**: its first dividend was still a bare `t >> 16`, the top carry.
   - CubeCL one-liners through wgpu:
     - wrong: `(a >> 16) / k`, `(a >> 16) % k` and `u32(u64(a)*u64(b) >> 32) / k`, for k = 3, 1000, 2500, 12167 and 21952;
     - exact: `(a >> 15) / k`, `(a & 0xFFFF) / k`, `a / k` and the OR forms;
     - exact: k = 32768.
5. **It is Apple's compiler, not naga.**
   - naga 29.0.4's MSL is a correct translation: `uint l_6_ = l_2_ >> 16u; naga_div(l_6_, 3u)`
     (`repro/repro_v3_k3.metal`).
   - `repro/shr_div_repro.swift` sends hand-written MSL to Metal directly, with no wgpu and no naga
     (`repro/m4_output.txt`):
     - wrong: `naga_div(x >> 16u, 3u)` (4093 of 4096), `(x >> 16u) % 3u`, `naga_div(x >> 16u, 12167u)` and
       `uint(ulong(a)*ulong(b) >> 32) / 3u`, guarded or not;
     - exact: plain `(x >> 16u) / 3u`, shifts by 1, 8, 15, 17 or 24, a mask, an OR, a power-of-two divisor, a run-time
       divisor and `ushort` division.
   - The desk analysis's `h2_repro.swift` (`logs/h2.log`) agrees. All three product shapes are wrong, and so is its
     "loaded word, no product" control (2755 of 4096), each equal to the low 16 bits' quotient at K = 21952 and 2500.
6. **b23, which the desk analysis's H2 left open.** The wrong quotient is usually the low half's (`(x & 0xFFFF) / K`,
   H2), but not at every K. At K = 12167 a zero dividend returns 4, both in the kernel trace and in standalone MSL
   (`naga_div(3u >> 16u, 12167u)` = 4). So b23 has the same fault, not a second one.
7. **Why the per-number kernel was exact.** Its division is a runtime loop with a loop-carried `rem`, so no dividend is
   ever a bare shift.
8. **Why the CI runner passes.** It runs macOS 26.6.2 on a paravirtual GPU. Not tested here.
9. **Correction to the 10-06 note.** It said naga's guarded division avoids the bug. That holds only for the u64 form.
   For the 32-bit form, the guard is what exposes it.

## The fix (`af41956`)

- **Split16 seed in 16-bit limbs.** `fd_seed` builds n, n², n³, 2n+1, 3n²+3n+1 and 6n+6 from 16-bit limbs, one to a
  u32, by schoolbook.
  - Each product is limb × limb, plus two values below 2^16, so it stays at most 2^32 − 1.
  - With 32-bit limbs the top word is a u64's high half. Dividing that word whole would be the u64 form of the bug,
    which is why the desk analysis warned against folding.
- **Top pair first.** `fd_to_digits` (split16) starts each chunk with `(v[top] << 16 | v[top-1]) / K`.
  - It is the same long division with one division fewer.
  - In chunk 0 the pair is the full sum `t` whose halves made the top limbs, and later it is the previous quotient.
    Every other dividend is `rem << 16 | limb`.
- **Not taken: the per-number kernel's shared-memory, runtime-loop conversion** (the desk analysis's first option). It
  works only as long as the compiler does not peel the loop, and it adds shared memory. This fix removes the pattern
  itself at no cost.

## M4 results (Apple M4, macOS 26.3, wgpu 29.0.4, `--gpu-backend auto` = CubeCL wgpu → naga → Metal)

**Before the fix** (18cba8b plus the new tests): `cubecl_fd_seed_matches_cpu` fails at b23, b25, b27–b30, b49, b50 and
b52–b55. That is more bases than the histogram sweep showed.

**After the fix:**

| test | result |
|---|---|
| `cubecl_fd_seed_matches_cpu` (132 windows of 1024 n) | pass |
| `cubecl_fd_matches_cpu_detailed` | pass |
| `cubecl_reads_back_every_near_miss` | pass |
| `cubecl_matches_cpu_detailed` | pass |
| `cubecl_detailed_survives_more_batches_than_the_task_cap` | pass |
| `metal_half_shift_div_repro` | variants 0–2 fail, controls exact (as designed) |
| sweep, every base 10–64: start (2e5), start at run length 1, mid (2e5), end (1e5), 2 random (1e5) | **220 of 220 windows exact**, 3.08e7 numbers, 26 near-misses |

- **Committed states rebuilt from the bundle and retested.** Both `af41956` (gate) and `297a969` (lifted) pass every test
  in the table. The sweep ran once, on a pre-rebase tree with the same kernel code (it differs from the head only in a
  doc paragraph). In the gate tree the production-routed tests (readback, `cubecl_matches_cpu_detailed`, the batch-cap
  test) run the per-number kernel on Metal, so there only the seed test and `cubecl_fd_matches_cpu_detailed` exercise
  the FD kernel.
- **Debug lines.** The gate tree runs `(Division)` on Metal, and the lifted tree runs the FD kernel.

**Speed.** `nice_client detailed --gpu --benchmark --benchmark-secs 60`, three interleaved rounds (main, pr, fix), with
27 s timed per scenario. Rates are numbers per second, medians of the three rounds.

| tree | b40 | b50 | NiceMark |
|---|---|---|---|
| main 946ec15 | 8.122e8 | 4.814e8 | 330 |
| PR 18cba8b (wrong on Metal) | 2.434e9 | 2.189e9 | 1216 |
| fix | 2.435e9 | 2.187e9 | 1216 |
| **fix / main** | **3.00×** | **4.54×** | **3.68×** |
| fix / PR | 1.000 | 0.999 | 1.00 |

- All rounds were within 0.5 % of each other.
- Rebuilt from the commits: gate 329, lifted 1215.

## Not verified

- **CUDA/HIP.** The wide path is the same code, moved into `fd_seed` and inlined; it was not run (no NVIDIA access in
  this task).
- **Vulkan.** The split16 change also reaches lavapipe, RADV and NVIDIA-Vulkan. It is exact by construction, but not
  run: ivory has no lavapipe. CI's lavapipe job will cover it. Seed speed there was not measured.
- **Other hardware.** No other Apple GPU or macOS version was tested. That is the case for keeping `af41956`'s gate.
- **Upstream report.** Not filed. `repro/shr_div_repro.swift` is ready for Apple Feedback Assistant; filing is the
  maintainer's call.
- **Other kernels.** Any unrolled constant division of a `>> 16` or u64-high-half value on Apple GPUs is suspect. The
  per-number detailed kernel and the WGSL join were exact on this M4; niceonly was not checked.

## Machine use and cleanup

- **Time.** First ssh 15:40:55 UTC, last 16:51:53 UTC: **1 h 11 min**.
- **Watchdog.** Set for 2026-10-31 15:30 UTC, which the run finished well inside. Killed by PID (54951), then its
  `sleep` (66515).
- **Directory.** `~/claude-exp-2026-10-31-fd-metal` (5.5 GB) removed, and `~/claude-exp-*` matches nothing.
- **Processes.** The pid file was empty, and a `ps` check for nice_client, nice_common, cargo, rustc, swiftc, the
  repros and the watchdog found only macOS's own `watchdogd`.
- **Build setup.** Offline, with `CARGO_HOME` inside the directory: an APFS clone plus 179 crates and the index from
  ivory.
- **Touched outside the directory:**
  - macOS's Metal shader caches (`com.apple.metal/*`), as any GPU run;
  - the pre-existing `$DARWIN_USER_TEMP_DIR/xcrun_db`, updated by the toolchain.
  - The Swift module cache was redirected into the directory.
- **Pushes.** Nothing pushed to `origin`.

## Files (`L3/metalfix/`)

| path | what |
|---|---|
| `repro/` | `shr_div_repro.swift` and `m4_output.txt`; the WGSL and MSL of the CubeCL one-liners |
| `logs/` | every M4 run: `c1-*` before the fix, `c4-suite`, `sweep`, `bench-r*`, `final2` with `final-*` and `bench-final-*`, `h2` |
| `analysis/` | the trace and model scripts, the stage-probe test source and the sweep test source |
| `dumps/` | the stage-probe records |
| `scripts/` | the Mac-side scripts |
