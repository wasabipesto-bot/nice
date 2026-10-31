# Experiments

One section per experiment, newest first. Each records: lead id, date, box (Vast id
and GPU, or host), commit(s) under test, exact commands, raw data path, the table,
and the one-line conclusion. Benchmark claims follow PROPOSAL.md §5: same box,
interleaved A/B, ≥3 rounds, median and spread per scenario, no scenario −2 %.

## L3.2 GPU detailed finite differences and the readback fix, protocol on a default-power 3080 (2026-10-30, agent; `L3/PR-RESULTS-3080.md`, `L3/pr-raw/3080/`; PRs #224 readback, #225 FD)

RTX 3080 20 GB (58401551, US), power limit 320 W = default = enforced = max; both kernels hit
it (~318 W): division kernel 1755–1770 MHz, FD 1860–1890 MHz (×1.07 clock). `auto` = CubeCL
CUDA. NiceMark detailed GPU, 150 s, A B C × 3:

| | main | readback (rb) | FD | FD/rb | FD/main |
|---|---|---|---|---|---|
| b40_detailed | 1.018e10 | 1.108e10 (+8.8 %) | 3.352e10 | 3.03× | 3.29× |
| b50_detailed | 7.512e9 | 8.052e9 (+7.2 %) | 2.978e10 | 3.70× | 3.96× |
| detailed GPU score | 4609 | 4986 | 16624 | 3.33× | 3.61× |

2e9 windows: FD/rb 3.09× (b40), 3.60× (b50). One 1e10 field (the new server cap, #223): b50
1.218 s → 0.325 s (3.75×), b52 1.288 → 0.333 s (3.86×); the readback fix is nothing at that
size. Per clock FD/rb ≈ 2.8× (b40), 3.5× (b50), same as the capped card yesterday.
Exactness: all CUDA FD tests; main vs FD identical on 100 windows across every base 10–64
(8.6e9 numbers, 261 near-misses); bases 10–28 in full (73 near-misses). Portability: wgpu uses
a 32-bit split seed (no u64 in WGSL); lavapipe passes via naga WGSL and CubeCL SPIR-V, also
`NICE_CUBECL_WIDE=1`; all 19 CI lavapipe tests pass; Metal translated by naga 29.0.4, no Mac
(the macOS CI job is the first real run); HIP not built. Branch heads: readback 6a1e396
(CubeCL `offset_end` read of `count` records, hand-CUDA slices its copy; 3 tests), FD f3a33cf
(`common/src/cubecl_detailed_fd.rs`, FD_RUN_LEN 128, all of bases 10–64's legal ranges;
division kernel kept above 64 and as reference). 4090 numbers pending (agent running).

## L25.1 Apple half-shift-divide audit of the GPU kernels (2026-10-31, agent; `L25/AUDIT.md`, `L25/raw/`; PR #228, branch `pr/metal-halfshift-top-kernel` 56b68bf on 472c9a0)

Source audit + WGSL dumps of 97 kernels on lavapipe (RTX 3060 box 58492432, $0.056/h, 1.17 h).
**One production kernel carries the pattern: the join's `top_kernel` (`cert_power`,
cubecl_join.rs:656–665)**: unrolled split16 division, first dividend each pass `x[top] >> 16` ÷ b^k;
28–64 flagged WGSL sites per base. Harmless at b40–44 and b57–64 (top limb of n², n³ is 0; b64's
divisor is a power of two); **wrong on Apple at b49–55** (the low-half model predicts 76–100 % wrong
digits) → lost join survivors → a nice number could be missed on a rescan/verification run on a Mac.
Stride prefilter (b ≤ 40 only) has the shape (6 sites) in a paired `/`+`%` form that passed the M4
probe in August (that August mul-sub failure was very likely this bug). Everything else is clean.
**Fix (ed972c7):** powers in 16-bit limbs, top limb pair divided first (the #225 construction);
no flagged sites in any of the 97 dumped kernels; `56b68bf` adds join windows with survivors at b50
(934/97) and b54 (445/51). CUDA 3/3 and lavapipe 3/3 on the branch and on main+windows; host 208;
lint clean. Throughput 0.997 (b58) / 0.984 (b62), inside main's 1.2 % / 2.4 % spread; survivor and
check counts identical over 3 × 1e14 fields per base. Not run on the M4 (needs a window): main +
windows expected to FAIL `cubecl_join_matches_the_cpu_reference`, the branch to pass.

## L23.1 Browser CPU detailed mode on finite differences (2026-10-31, agent; `L23/RESULTS.md`, `L23/raw/`, `L23/harness/`; PR #227, branch `pr/wasm-detailed-finite-diff` fe38c7e on #221's 7019653)

`process_chunk_wasm` → `process_range_detailed_fd` (2 files, 7 lines). Exactness: old wasm (d1ff798)
vs new, same `wasm-pack` command as CI, headless Chromium 151 (Playwright 1.62 image via rootless
podman on ivory): 141 windows, 36.4M numbers, raw JSON byte-identical (benchmark windows in three
chunkings, the 10M offline field, six windows per base 40–64, full ranges of bases 10–24 with 27
near misses, the e2e's b49 near miss above 2^53, 20M around the first b40 near miss). CI's e2e
`run.sh` passes locally; its CPU-vs-WebGPU histogram check agrees.
Speed (page suite, 60 s, 3 workers, interleaved ×3, M n/s): b40 3.564 → 36.571 (×10.3); b50 4.715
→ 31.127 (×6.6); b50_1t 1.782 → 8.776 (×4.9); NiceMark 246 → 1711 (×7.0); spreads ≤1.8 %. Per
number: wasm 683 → 58 ns (b40), 508 → 70 (b50), 655 → 72 (b60); native on the same box 266/43,
414/49, 541/50. The page + worker pool adds ~45–55 ms fixed per suite window (why `_1t` gains less).
Note: wasm32 clippy without `--no-deps` fails on a pre-existing lint at cubecl_web.rs:63 on main too
(CI never runs it); left alone.

## L3.7 Verification of the fixed FD branch on CUDA and lavapipe (2026-10-30, agent; `L3/verify/VERIFY-297a969.md`)

RTX 3080 (58428313, KR; host-capped at 150 W, 1545 MHz), 297a969: fmt, both lint clippy lines +
`--features gpu`, release build; 209 host tests; CUDA `cubecl_cuda_fd_matches_cpu_detailed` (every
window exact, FD = division = CPU on the benchmark windows, 73 near-misses), `..._matches_cpu_detailed`,
`..._reads_back_every_near_miss`, hand-CUDA `gpu_matches_cpu_detailed_small`; lavapipe all six wgpu
tests incl. `cubecl_fd_seed_matches_cpu` 132/132 windows; reproducer passes on llvmpipe. A
diagnostic build confirmed FD serves every b40/b50 window on CUDA and llvmpipe. Speed vs the
pre-fix PR (18cba8b), interleaved: 1.000× (b40), 0.999× (b50); absolute 2.86e10 / 2.50e10 at 150 W.
**#225 → single commit dbe2ab7 on main 9747e39 (tree = 297a969 + main's pool-size change), body
rewritten, marked ready for review, resolution comment posted.**

## L3.6 Root cause and fix on the M4 (2026-10-30, agent, 1 h 11 min of mayalaran; `L3/METAL-FIX.md`, `L3/metalfix/`; branch `pr/gpu-detailed-fd-metalfix` 297a969)

**Apple GPU compiler bug, confirmed with hand-written MSL (no wgpu/naga):** unsigned division or
remainder by a non-power-of-two constant is wrong when the dividend is a right shift by half the
width: `naga_div(x >> 16u, K)`, `(x >> 16u) % K`, `uint(ulong p >> 32) / K`. The unrolled split16
seed (`fd_to_digits`) made the first dividend of every chunk a bare `top_limb >> 16`, so n²'s (and
at some bases n³'s) digits were wrong from digit 0; limbs were exact. b23 is the same bug (at
K = 12167 a zero dividend returns 4), not a second fault. The per-number kernel is exact because
its long division is a runtime loop with a loop-carried remainder.
**Fix (af41956):** the wgpu seed in 16-bit limbs, u32 arithmetic only, each chunk's division
starting from the top two limbs as one u32 (no bare shift; one division fewer per chunk);
CUDA/HIP path, hot loop, mask and histogram unchanged. d9261a8: `fd_seed` + per-n seed test
`cubecl_fd_seed_matches_cpu` (1024 n at start/middle/end of all 44 bases, word for word) + the
minimal reproducer `metal_half_shift_div_repro` (ignored, `NICE_METAL_DIV_REPRO=1`). 297a969
reverts the gate.
**M4:** seed test failed before at b23, 25, 27–30, 49, 50, 52–55 and passes after; all FD/readback
tests pass; 220-window sweep of bases 10–64 (3.08e7 numbers, incl. run length 1) identical to the
CPU. Speed unchanged vs the PR: b40 2.435e9, b50 2.187e9, NiceMark 1216 (main 330): 3.00× / 4.54×.
Not done: CUDA/Vulkan re-run (verification agent), other Apple GPUs/macOS versions, Apple
Feedback report, **nice-only kernels not audited for the pattern (L25)**.

## L3.5 Metal gate for #225 and the desk root cause (2026-10-30, agent; `L3/METAL-ROOT-CAUSE.md`, `L3/pr-raw/gate/`)

Gate commit d8038d6 (head of `pr/gpu-detailed-fd`): the wgpu context records whether the adapter
backend is Metal (wgpu's backend enum, not the name); `DetailedKernel::for_device(base, metal)`
sends Metal to the per-number kernel; CUDA/HIP/Vulkan/DX12/GL keep FD; unit test
`detailed_kernel_by_device`. RTX 3080 box 58419619: fmt, all clippy lines, 210 lib tests, CUDA FD
tests and lavapipe FD tests pass with FD still serving; speed unchanged (b40 3.339e10 vs
3.331–3.467e10; score 16,591–16,614 vs 16,571–17,121).
**Root cause, modelled:** the seed's digit conversion computes `(x >> 16) / K` on the top word x
of n² and n³; if Apple's compiler divides the low 16 bits of x instead (the 16-bit form of the
2026-10-06 `hi(a·b)/K` miscompile), the model reproduces all 400 per-number results at b50 and
77 of 79 sweep windows exactly, including the base bands, the b32 exemption (power-of-two
divisor) and the passing windows inside failing bases. **b23 is not explained** (top words too
small). Artefacts for the Mac: `h2_repro.swift` (standalone Metal reproducer), `seed-dump-diag.patch`
(ignored test `zz_seed_dump_wgpu`, exact on CUDA and lavapipe). Cheapest fix: seed through the
per-number kernel's shared-memory long division (exact on the M4); never fold into one `x / K`.

## L3.4 #225 on Apple M4 (Metal): WRONG RESULTS (2026-10-30, agent, user-authorised 1 h; `L3/METAL-M4.md`, `L3/pr-raw/m4/`)

mayalaran: macOS 26.3 (25D125), M4, Rust 1.99.1; offline build (179 crates copied from ivory);
29 min of machine time, cleaned up. `auto` = CubeCL wgpu, "Apple M4 (Metal, wgpu<wgsl>)".
- `cubecl_fd_matches_cpu_detailed` FAILS (first b50 window; all b40 windows pass under every run
  shape); `cubecl_reads_back_every_near_miss` FAILS at b23; main's tests pass on the device.
- Per-base sweep: FD wrong at b23, b27–30, b49 (mid), b50, b52 (mid), b53–55; division exact in
  all 79 windows. Per n: 77 % wrong at b23 start, 87 % at b50; window histograms move only a few
  percent (the tests barely catch it).
- Every run length fails incl. 1 number per run → not stepping; seed, packing or mask build as
  compiled by Metal. Root cause unknown; prime suspect the Apple Metal compiler (cf. the
  2026-10-06 hi(a·b)/const miscompile seen via cubecl-metal). WGSL + naga MSL dumps saved.
- The CI "cubecl (Metal) on macOS" job (paravirtual GPU, #218) passed the same commit: it does
  not reproduce real-hardware Metal behaviour.
- Speed (3 rounds, spreads ≤0.3 %): b40 8.116e8 → 2.437e9 (3.00×); b50 4.812e8 → 2.183e9 (wrong
  kernel); NiceMark 329 → 1216. No thermal decline over 60 s reruns.
Action: #225 → draft + comment; gate FD off on Metal adapters pending the root cause.

## L3.3 Second card for #224/#225: RTX 4090 (2026-10-30, agent; `L3/AB-4090.md`, `L3/pr-raw/4090/`)

Vast RTX 4090 (58401579, CA, $0.374/h), not power-limited (480 W limit never reached) but
thermally limited (85–90 °C vs 83 °C target, fan 100 %, slowdown active in every snapshot);
clocks ~2.5–2.6 GHz main/rb, ~2.63 GHz FD. Trees main 46e4dc4 / rb 6a1e396 / fd f3a33cf.

| measurement | rb vs main (b40 / b50) | FD vs main |
|---|---|---|
| NiceMark detailed GPU, 6 interleaved rounds | 1.137 / 1.093 | 3.459 / 3.922 |
| NiceMark score (main 11,493) | 12,800 (×1.114) | 42,296 (×3.680) |
| 2e9 windows, 3 rounds | 1.023 / 1.007 | 3.022 / 3.634 |
| 1e10 fields, production path (`--repeat`, mock API, 3×8) | 0.997 / 0.995 | 3.061 / 3.767 |

FD vs rb per clock 2.87× / 3.31× (3080: 2.78× / 3.42×). An FD 1e10 field is ~0.11–0.12 s, so a
4090 needs ~9 claims/s. Exactness: all FD tests under CUDA; results identical across the three
trees on every window and on all 147 production submissions. wgpu FD test ran on llvmpipe only
(the NVIDIA Vulkan driver did not load in the container). Both PR bodies updated with these.

## L1.6 Partitions per launch + pruned buffer sizing, and the flush race (2026-10-30, agent; `L1/LAUNCH-RESULTS.md`, `L1/launch-raw/`; branches `pr/join-partitions-per-launch` c4ac700, `rp/join-flush-barrier` 61e6ba9 → PR #222, `rp/launch-with-barrier`)

RTX 3080 20 GB (58361499, 320 W = default), 10 GB layouts via test-only `NICE_TEST_JOIN_MAX_BUFFER`.
- **1e14, 10 GB budget, 3 rounds:** ×0.881 / 0.868 / 0.793 / 0.832 of main's time at b58/60/62/64
  (16 → 64 partitions per launch; 211–256 → 53–64 batches). 20 GB: ×0.899 / 0.868 / 0.787 / 0.826.
  Cap 64 beats "as many as fit" (105–177) by 1–4 %; a 16–177 sweep is fastest at 64 at every base.
- **1e16: neutral** (×0.992–1.011); 1e15 neutral with b58 1–2 % slower; NiceMark ×1.002
  (b58_msd_weak ×0.969 in 3 rounds, within that scenario's ±3 % noise here).
- **PARKED (director):** the live fields are 1e16 at b60 and **1e17 at b62** (data API
  `fields`, 2026-10-30), so a change that is neutral above 1e15 does not help production and
  does not move NiceMark. The "production size = 1e14" premise in the L1.5 brief came from a
  stale code comment ("Production fields at the frontier are 1e14"). Keep for small-field work.
- **The extra full checks are a race in `join_kernel`'s per-chunk flush decision**, not stage
  overruns: no barrier between the `s_cnt` load and the next chunk's appends, so a late plane
  can decide alone to flush and the cube's barriers pair at different call sites; stale list
  entries get fully checked and entries can be overwritten (survivors never checked). Frequent
  once cubes grid-stride (>16–19 partitions per launch); possible by the code in main's 1e16
  layouts. Instrumented: 12 of 50 base-runs at ≥64 per launch without the barrier showed a
  signature, 0 of 18 with it; 0 of 76 at 16–32. Fix = one `sync_cube()` after the load; cost
  within noise at 1e14 (×0.99–1.00), ≤ ~1.5 % at 1e16 unresolved. **PR #222.**

## L3.1 GPU detailed mode by finite differences, prototype (2026-10-30, agent; `L3/GPU-FD.md`, `L3/raw-fd/`; branch `exp/gpu-detailed-fd` e0c1b4c on the fork)

Vast RTX 3080 (58350503, KR, $0.108/h), **power-capped at 180 W** (default 340 W): the old
kernel ran ~1,425 MHz, FD ~1,690 MHz, so ~1.18× of the gain is clock; per clock FD is ~2.2×
(b40) / 2.7× (b50). 3 interleaved rounds, medians. Best variant v3: 128 numbers per thread,
high words of n²/n³ masked once per run (they change only on a rare carry; removes 14 of 50
masked digits at b50), one rare-carry branch per step.

| measure | b40 | b50 |
|---|---|---|
| benchmark harness, production host path | 2.60× (2.05e10 vs 7.88e9 n/s) | 3.22× (1.86e10 vs 5.78e9) |
| harness, both arms with the near-miss readback fix | 3.22× | 3.97× |
| 2e9-number window (mostly kernel) | 3.28× | 3.97–4.03× |

Run length flat within 3 % from 64 to 512 numbers per thread. Per-thread histogram was 5–7 %
slower than one shared atomic per number; a 2-digit lookup table within 2 % (both off).
Registers 96 (v1) → 48 (v3), no spills, 83 % occupancy; limited by integer instruction rate:
mask build ~4.5 instructions per digit = 55–60 % of the work, digit adds ~30 %.
Exactness: histogram and near-miss list equal the CPU's at every commit; test covers b40/b50
range start/end, 8 random windows, addend digit-gain windows, a window straddling the range
start (split across the two kernels), under 7 option sets, plus the full 2e8 benchmark windows
and every base 10–28 in full (73 near-misses). CUDA parity test, library tests, clippy clean.
**Side finding (independent of FD):** every call copied back the whole 20 MB near-miss buffer
(~1.7 ms over PCIe 3) even with zero misses; reading only what was written gives +5–8 % for
the current kernel and +30 % for FD. Worth its own small PR.
**Caveat for production:** at FD speed a 1e9-number detailed field is ~40 ms of GPU, so the
claim/submit round trip may dominate wall-clock; server-side detailed field size (BACKLOG 13)
becomes the limiter before the 3–4× shows in production throughput.

## L1.5 Join re-profile on main d1ff798 (prune + EPT 2 + closure + memory budget) (2026-10-30, agent; `L1/PROFILE-2.md`, `L1/profile2-raw/`; branch `rp/gpu-profile-2`)

Vast RTX 3080 **20 GB** (58350591, US, $0.149/h; 320 W cap = default; so the memory budget is
4 GiB and 1e16 layouts differ from 10 GB cards). Profiled with the probe readback excluded;
profiling adds 6–10 % at 1e14, ~0 at 1e16; unprofiled main matches within 1.5 %.

| | device s/field (b58/60/62/64) | top | bucket | join | check | other |
|---|---|---|---|---|---|---|
| 1e14 (20 fields) | 0.689 / 0.585 / 0.569 / 0.679 | 22/19/17/9 % | 11/14/16/14 % | 52/50/49/58 % | 6–7 % | 9–12 % |
| 1e16 (2 fields) | 46.3 / 33.9 / 14.6 / 42.9 | 30/34/41/15 % | ≤1 % | 62/57/51/77 % | 5–7 % | 1–3 % |

Refit at 1e16: 0.62 ps per padded lane-pair + 64 ps per AND survivor (rms 5.7 %, max 11 %,
over-predicts b64: empty lanes are cheaper than filled); + 406 ps per top → rms 2.9 %. At
1e14 the two-term fit fails (rms 33 %); + 15.6 ns per (partition, bucket) work item → rms
5.9 %. Each launch costs ~0.5 ms; **the 1e14 per-field fixed cost is 40–74 % of a field.**

**Levers ranked:** (1) more partitions per launch at 1e14: 16→32 gives ×0.92/0.90/0.83/0.87
of the time, 16→64 ×0.88/0.86/0.78/0.83 (b58/60/62/64); 32 fits 10 GB cards, 64 needs the
lists sized by the pruned slice (#215's deferred buffer sizing); one b64 run at 64 showed
0.4 % extra full checks, cause unknown, to be understood first. (2) survivor handling at
1e16: 25–59 % of device time. (3) top certification: 15–41 % (41 % at b62 1e16). (4) real
AND lanes at 1e16: 13–26 %. (5) wave padding: ~0 at 1e14 (EPT 1 costs ×1.08–1.10), 2–7 %
at 1e16, 9–15 % at b64. (6) bucket build 11–16 % at 1e14. (7) b60 stage overrun ~0.3 %.
(8) partitions per launch at 1e16: nothing.

## L2.2 Detailed finite differences through the client, NiceMark protocol (2026-10-30, agent; `L2/PR-RESULTS.md`, `L2/pr-raw/`; PR #221, branch `pr/detailed-finite-diff` 7019653)

Vast box 58350466: Xeon E5-2682 v4 (Broadwell), container quota 15.36 CPUs (`--threads 0`
→ 15), clocks uncapped. A = main d1ff798, B = branch (045797e, comment-only diff to
7019653), `nice_client detailed --benchmark --benchmark-secs 150`, A B A B A B.

| scenario | A (M n/s) | B | B/A |
|---|---|---|---|
| b40_detailed, 15 threads | 51.55 (−0.1/+0.9 %) | 287.95 (−0.2/+1.2 %) | **5.59×** |
| b50_detailed, 15 threads | 33.80 (−0.3/+0.1 %) | 271.09 (−0.0/+0.5 %) | **8.02×** |
| b50_detailed_1t | 2.22 | 15.23 | **6.85×** |
| detailed score | 1247 | 8424 | **6.76×** |

`--threads 1`: 5.57× / 8.12× / 6.80×, score 6.75×. `--threads 64` (4× oversubscribed,
cgroup throttled): 3.10× / 5.15×, score 4.80×; both trees slow, the new loop more. Pinned
per-number: b40 280→50 ns, b50 435→57, b60 560→58. Tests on the box: 180 passed, 5 ignored.
Production = the packed variant only (8 digits per 64-bit biased add); dispatch in common
(`process_range_detailed_fd`, bases 40–64 with a legal range except 63; others → division);
client's CPU chunk path calls it. Not run: GPU-feature clippy, WASM build (CI will).

## L1.4 Prune against new main on an RTX 4090, and the wave size (2026-10-29, agent; `L1/AB-4090.md`, `L1/pr-raw/4090/`)

Vast RTX 4090 (58197772, Poland, $0.375/h; **power-limited to 330 W**, so absolute times
are slow, ratios hold). A = upstream main 2709d3f (+ the two test-only harness commits);
B = `pr/field-cert-prune` 26a8b15 (rebased prune). 3 interleaved rounds, spreads ≤ 2.4 %.

| fields | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| prune vs main, 1e16 (2 per base) | ×1.097 | ×1.084 | ×1.112 | ×1.205 |
| prune vs main, **1e14 (production size, 20 per base)** | ×1.41 | ×1.50 | ×1.87 | ×1.79 |
| prune + EPT 2 vs main, 1e16 | ×1.19 | ×1.16 | ×1.26 | ×1.52 |
| prune + EPT 2 vs main, 1e14 | ×1.55 | ×1.55 | ×1.97 | ×2.08 |
| old pair on this card (85b5b4e base vs prune), 1e16 | ×1.14 | ×1.14 | ×1.37 | ×1.58 |

The 1e16 gains are below the 3080's day-1 numbers because new main carries #205's EPT 6 at
b62/b64 (a bad wave for pruned buckets) and #203/#206's own gains; the card is not the
cause (old pair reproduces the 3080). NiceMark (prune as pushed): 8086 → 9494 (×1.174);
b58 weak ×1.152, b58 strong ×1.330, b60 weak ×1.075, b62 weak ×1.126; all on the join.
**EPT with the prune: 2 < 3 < 4 < 6 in every round at every base**; 2 beats 4 by
×1.07–1.13 and 6 by ×1.15–1.27; at 1e14 EPT 1 is ~5 % better at b58 and tied elsewhere.
Exactness: `NICE_TEST_JOIN_COMPARE=1` 0 = 0 at every base; survivor and check counts identical
to the last digit across trees at 1e14; CUDA parity 3/3; CPU prune test passes; the 3080's
stage-overrun shift does not appear on new main. Bottoms removed: 55–77 % at 1e16, 72–86 %
at 1e14. Not done: the b64 1e16 dense test timed out at 300 s; NiceMark with EPT 2; EPT 1 at 1e16.

## L2.1 Detailed mode by finite differences, CPU prototype (2026-10-29, agent; `L2/RESULTS.md`, branch `rp/l2-finite-diff` on the fork: b003967 scalar, da9aaeb 8 digits per 64-bit add)

`common/src/detailed_fd.rs::process_range_detailed_fd`, same signature and output as
`process_range_detailed`; bases 40, 42–45, 47–50, 52–55, 57–60, 62, 64 (others fall back).
Not wired into the client. ivory, one thread pinned to core 3, the `b50_detailed_1t` window
(base-range start, 1,000,000 numbers), two passes of 3 interleaved rounds, median ns/number:

| base | old | scalar | × | 8 digits per add | × |
|---|---|---|---|---|---|
| 40 | 265 | 60 | 4.4 | 42 | 6.2–6.3 |
| 50 | 416–418 | 73–74 | 5.6–5.7 | 48–49 | 8.5–8.6 |
| 60 | 537–541 | 89 | 6.0–6.1 | 50–53 | 10.1–10.8 |

Old within ±1 %, new within ±2–5 %. Cycles per number at b50: old 1,390, scalar 244, packed 163.
Exactness: 11 tests, all pass for both variants: per-number equality with `get_num_unique_digits`
on 20 seeded 10k windows plus both range ends at b40/50/60 and b42/47/53/59/64; 7 windows per
base around every digit-gain point of n² and n³; b7 and b10 from n = 0; whole `FieldResults`
identical on the b40_detailed and b50_detailed windows; 27 near-misses identical over bases
10–24. Clippy clean, 179 lib tests pass.
Lessons: LLVM first compiled the digit carry as a mispredicted branch (17.5 misses per number,
only 1.6–2.2×); a branch-free select fixed it, and the GPU port must watch for the same. Packed
version profile: adds + bookkeeping 57 %, mask build 30 %, popcount + histogram 13 %. Production
builds target baseline x86-64, so `count_ones()` is a 17-instruction software popcount (both paths).
Next: wire into `client/src/main.rs` (~line 845) and run the 5 % protocol on b40_detailed,
b50_detailed, b50_detailed_1t (needs a box: ivory cannot build the client); then the GPU port
(each thread walks a run of ≥100 consecutive numbers with ~24 u32 of digit arrays in registers).

## L1.3 Field-certificate bottom prune, GPU A/B (2026-10-28, agent; `L1/PRUNE.md`, `L1/prune-raw/`)

Branches on the fork: `rp/field-cert-prune` (head 4670ffe; the prune is c1174c1, the rest
tests), `rp/field-cert-prune-base` (2d740d3 = 85b5b4e + the same harness, the A tree),
`rp/field-cert-prune-ept` (6e4e895, prune + EPT override). Vast RTX 3080 (58056651),
1e16 fields, 2 per base, the L1.2 starts, A B A B A B (3 rounds), median s/field (spread):

| base | main | prune | speed-up | bottoms removed |
|---|---|---|---|---|
| 58 | 69.36 (0.9 %) | 60.18 (1.1 %) | **1.153×** | 59.5 % |
| 60 | 45.26 (1.2 %) | 39.52 (1.2 %) | **1.145×** | 54.6 % |
| 62 | 26.98 (1.0 %) | 19.07 (0.6 %) | **1.415×** | 74.3 / 66.7 % |
| 64 | 83.42 (2.4 %) | 50.79 (0.6 %) | **1.643×** | 77.1 % |

NiceMark nice-only, 3 rounds, every scenario on the join in both trees: b58_msd_weak
+17.6 %, b58_msd_strong +32.5 %, b60_msd_weak +20.1 %, b62_msd_weak +43.9 %; score
2892 → 3705 (+28 %). Batches and slots identical (buffers still sized by the unpruned
count). At 1e14 production size the prune removes 73–86 %, so production gains are
probably larger (unmeasured).

Exactness on the box: CUDA kernel compiles; 194 host tests; `cubecl_cuda_join_matches_the_cpu_reference`,
the dense-field and whole-field CUDA tests, the CPU reference test, and the throughput
harness with `NICE_TEST_JOIN_COMPARE=1` (join = stride on 1e14 fields) all pass; clippy
`--features gpu -D warnings` clean. One behavioural ripple: the prune tree records 0.94× the
AND survivors and correspondingly more unfiltered prefilter survivors (2–2.5e-4 of
survivors), i.e. survivors that overflow the join kernel's staging area go to the check list
unfiltered, as on main but a little more often; +0.3–0.4 % full checks, and b64 crosses the
dense-field test's 1e-4 limit. Fix for the PR: flush every 16 tops or a larger stage.

**EPT sweep with the prune (`rp/field-cert-prune-ept`):** EPT 2 is best at every base:
×1.088 (b58, 1 round), ×1.053 (b60, 1 round), ×1.060 (b62, 2 rounds), ×1.139 (b64, 2
rounds) over EPT 4; EPT 1 worse than 2 everywhere. Prune + EPT 2 vs main at EPT 4:
**1.51× at b62, 1.91× at b64** (against the L1.2 numbers on the same machine, not
interleaved). So PR #205's EPT 6 and the EPT 5 note both give way to EPT 2 once the prune
is in; pruned buckets are 3–4× smaller, so the wave shrinks.

## L1.2 GPU join phase profile by base (2026-10-28, agent; `L1/GPU-RESULTS.md`, branch `rp/gpu-profile` on the fork)

Vast RTX 3080 (instance 58051111, $0.134/h), upstream 85b5b4e + `NICE_EXP_GPU_PROFILE=1`
(costs 3.9–6.3 % of device time; shares from profiled runs, seconds from unprofiled),
1e16 fields, 2 per base, CubeCL CUDA.

| base | roots | device s/field | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|
| 58 | 4 | 68.8 | 19.5 % | 3.8 % | 64.8 % | 4.7 % | 7.3 % |
| 60 | 2 | 45.2 | 23.3 % | 5.1 % | 55.8 % | 5.3 % | 10.5 % |
| 62 | 2 | 26.1 | 21.9 % | 7.2 % | 57.9 % | 3.6 % | 9.5 % |
| 64 | 8 | 83.1 | 7.1 % | 3.3 % | 82.6 % | 3.1 % | 3.9 % |

| base | µs/prefix | RX 9070 XT | AND survivors/prefix | prefilter survivors (= full checks) |
|---|---|---|---|---|
| 58 | 11.44 | 11.2 | 63.7k | 3.84k |
| 60 | 8.51 | 6.8–7.3 | 43.8k | 3.10k |
| 62 | 9.96 | 9.2–9.6 | 34.8k | 2.20k |
| 64 | 26.84 | 19.5 | 139.8k | 8.77k |

- Everything but the join kernel costs 4–5 µs per prefix at every base; tops per prefix
  1180–1300 everywhere. The join kernel carries the whole b64 jump (23.0 µs vs 6.1 at b62).
- Survivors per prefix = tops × roots × bucket occupancy (930–1210 at every base) × AND
  pass rate. b64/b62 survivors 4.02× = roots 8/2. b58/b60 1.45× (pass rate 1.41 % vs 1.81 %).
- **Join kernel cost model** (10 fields, four bases, max error 1.9 %): **0.58 ps per
  lane-pair, lanes padded to whole 1024-entry waves, plus 74 ps per AND survivor.** Wave
  padding is 1.07–1.10× at b58/b60 and 1.69–1.72× at b62/b64 (buckets of ~1200 spill into
  a second wave): ~18 % of b64 device time, 12 % of b62's.
- **Entries per thread (`NICE_EXP_JOIN_EPT`, 2 interleaved rounds, first field):** 5 gives
  ×1.12 (b62) and ×1.19 (b64) over 4; 6 (= PR #205) gives ×1.08 / ×1.13, matching #205's
  own 3080 numbers. So 5 beats #205 by 3.4 % / 5.4 % on this card. Needs a third round and
  other GPUs before it is a claim. The model fitted on EPT 4 predicts 5 and 6 within 0.6–3.4 %.
- L4: the check kernel is 3.1–5.3 % of device time (3.8–9.8 % of the join's), under the
  15 % kill criterion.
- Caveats: no hardware counters (`ncu` blocked on Vast); the b60 window used is denser
  (44k survivors/prefix vs ~26k on the 9070 XT's fields) so b60's µs/prefix reads high.

**What the prune should buy (director's estimate from the model, to be measured):** per prefix the
AND term is tops × roots × padded occupancy × 0.58 ps: b58 2.9 µs, b60 1.5, b62 2.8, b64 11.4;
the survivor term 4.7 / 3.2 / 2.6 / 10.3 µs. Pruning 73–86 % of bottoms (1e14 fields) cuts
the AND term by 2× at the current wave size (one wave instead of two) and by 3–7× with a
smaller wave, leaving survivors unchanged: 10–30 % of device time by base.

## L3.0 Detailed mode on the GPU (2026-10-28, agent; `L3/NOTES.md`)

RTX 3080, `auto` = CubeCL CUDA. b40_detailed 1.04e10 n/s, b50_detailed 7.8e9 (references
2.4e9 / 1.5e9 are for a weaker card). CPU 16 threads: b40 4.4e7, b50 2.86e7, one thread
1.87e6. GPU = 236–273× this CPU. `nvidia-smi dmon`: SM 98–99 %, memory controller 0 %.
Kernel: one thread per number; n², n³ in u32 limbs; digits peeled by long division by b⁵
in shared memory; OR into a mask, popcount, one shared atomic into the histogram. About
750 (b40) / 1,000 (b50) integer ops per number ≈ the card's integer throughput:
**compute-bound on the divisions.** The L2 finite-difference scheme (digit arrays updated by
addition) removes exactly those divisions, so L2 and L3 are one lead with a CPU prototype first.

## L1.1 CPU join counts by base (2026-10-28, agent; `L1/RESULTS.md`, branch `rp/l1-selectivity` a76984f on the fork)

Item 23's field per base plus a second field, 6 stratified partitions per field, ivory (EPYC
Rome) under `nice -n 19`, 3 threads; a second round reproduced counts exactly and stage
times within ±5 %. Ignored tests `cpu_join::selectivity::l1_selectivity`, `l1_probe_windows`.

| | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| roots | 4 | 2 | 2 | 8 |
| L / digits of n², n³ | 12 / 23, 35 | 12 / 24, 36 | 13 / 25, 37 | 13 / 26, 38 |
| bottoms per key list (per class) | 54.8k (961) | 54.9k (931) | 72.7k (1191) | 76.4k (1212) |
| ANDs per top | 3,844 | 1,863 | 2,383 | 9,702 |
| top popcount (n² + n³ known) | 15.7 (7.7 + 7.9) | 16.2 (8.1 + 8.2) | 17.3 (8.9 + 8.5) | 18.4 (9.6 + 8.9) |
| AND pass rate, measured / uniform model | 1.37 / 1.40 % | 1.64 / 1.42 % | 1.25 / 1.23 % | 1.06 / 1.06 % |
| AND survivors per top | 52.7 | 30.5 | 29.8 | 103 |
| full checks per top | 3.3 | 2.0 | 1.9 | 6.6 |
| CPU ms per prefix | 5.8 | 3.5–3.9 | 4.0–4.4 | 11.0–11.5 |
| RX 9070 XT µs per prefix (BACKLOG 68) | 11.2 | 7.0 | 9.4 | 19.5 |

- ANDs per top = roots × mean class size within 0.1 %: hypothesis A holds exactly.
- Pass rates follow the uniform model C(b−pc, 12)/C(b, 12); b64's tops know the most
  digits, so its pass rate is the lowest (0.85× b62). Net AND survivors per top: b64 3.5× b62.
- Tops per prefix (1.2–1.3k) and certificate cost (405–471 ns per prefix tried) are flat.
- Of the +7.6 ms per prefix from b60 to b64: 52 % survivor handling (range test, prefilter,
  dispatch, 32–41 ns each), 33 % the ANDs (0.22 ns each), 9 % full checks. ANDs are 13–17 %
  of a partition at b58–b62 and 26–27 % at b64. CPU scan shares match item 23's Zen 2 profile.
- CPU cost per prefix relative to b60: ×1.6 / 1 / ×1.15 / ×3.1; GPU: ×1.6 / 1 / ×1.33 / ×2.8.

**Lever counts (share of ANDs skipped).** Sub-bucketing by mask ∩ S: digits 0..s−1 skip
21–42 % (s = 4–8); the s most frequent top digits skip 56–81 %, but those digits are the
field's own certificate (4–7 leading digits of n², n³ every top knows). **Dropping bottoms
that share a digit with the field certificate skips 66 / 60 / 70 / 79 % of ANDs at
b58/60/62/64 with no bucketing.** CPU saving bound: 7–12 % at b58–b62, 20–23 % at b64
(only failing ANDs are skipped). GPU share unknown until the GPU profile lands.

## L1.0 Digit-sum class roots per base (2026-10-28, director, no hardware)

In the join each top probes one bottom bucket per root of x² + x³ ≡ b(b−1)/2 (mod b−1)
(overlap_join.rs module doc). The root count by base, from a 3-line enumeration:

| base | b−1 | roots | measured µs/prefix (RX 9070 XT, BACKLOG 68) | survivors per top-layer prefix |
|---|---|---|---|---|
| 58 | 57 = 3·19 | 4 | 11.2 | — |
| 60 | 59 prime | 2 | 6.8–7.3 | ~26k |
| 62 | 61 prime | 2 | 9.2–9.6 | 27–44k |
| 64 | 63 = 7·9 | 8 | 19.5 | 112–176k |

Roots for 40–97: 40:4 41:6 42:2 43:0 44:2 45:2 46:8 47:0 48:2 49:2 50:8 51:0 52:4 53:2
54:2 55:0 56:4 57:6 58:4 59:0 60:2 61:4 62:2 63:0 64:8 65:1 66:4 67:0 68:2 69:2 70:4
71:0 72:2 73:12 74:2 75:0 76:12 77:2 78:4 79:0 80:2 81:2 82:10 83:0 84:2 85:4 86:4
87:0 88:4 89:6 90:2 91:0 92:4 93:2 94:4 95:0 96:4 97:10. (Zero roots = residue-dead
bases, which the server never inserts; matches the known list.)

Reading: the b64 survivor count per prefix is ~4× b62's, exactly the roots ratio 8/2;
per-prefix time is ~2× because the tops phase does not scale with roots. b58 > b60
follows the same ordering (4 vs 2 roots). Hypothesis A of L1 is therefore the
explanation to beat; the CPU counting run (L1/RESULTS.md) checks it and sizes the
signature-bucketing lever.

