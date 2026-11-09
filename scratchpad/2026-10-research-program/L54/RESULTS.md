# L54 RESULTS: the transposed AND's codegen, and the join kernel's register pin (RTX 3080 at 130 W, 2026-11-09)

Base: fork **`pr/top-fd-round2` `d813aea`** (= upstream main `6f060a9` + #241 + #246 + #249 + FD round 2), the binary
`B` (md5 `dd7e5fdf`, the same as L51's `B`). Experiment branch **`exp/join-and-codegen`** on the fork, head
**`19702e1`**: `d91447a` (every AND form below behind `NICE_EXP_AND_FORM`, default 0 = d813aea's kernel; binary `X1`,
md5 `685472df`) and `19702e1` (the PR form of form 2, no knob; tree `P`). On the box these were `003a0e0c` and
`bee17b98`; they were re-committed afterwards with the attribution trailer and a message, and the trees are identical.
Below, the box-time hashes name what ran. Box: Vast **59842997**
(`nice-research-l54-andgen`), RTX 3080 10 GB at a **130 W cap** (default 320 W), driver 580.159.03, CUDA 12.8 (NVRTC
12.8), Xeon E5-2630 v4, 20 CPUs, 15 GB RAM, rustc 1.99.1. Raw: `raw/` (§6).

## Summary

- **Verdict, AND codegen: record only. The kill fires: the A/B is below ×1.03 at both production fields.** Forms 1–3
  run **×1.008–1.016 at b62 1e17 and ×1.016–1.020 at b60 1e16** (3 interleaved rounds against d813aea), although
  their digit loops are a fifth to a third shorter. No `pr/join-and-codegen` was pushed and no NiceMark was run.
- **The fold can be expressed through CubeCL.** NVRTC builds a 64-bit shared address from the zero-extended `u32` index of
  every load (`mul.wide.u32`), so `t_tr[a + 64c]` cannot become `[base + 256c]` unless the compiler can prove `a + 64c`
  does not wrap. Masking the index to the table (`(a) & (TR_WORDS - 1)`, a no-op on every value it takes) proves it. The
  four loads then share one address and take `+0x100`/`+0x200`/`+0x300` as immediates. Offline `nvcc` folds even without
  the mask (it uses 32-bit shared pointers); NVRTC, which CubeCL uses, does not.
- **SASS instructions per digit** in the AND's digit loop (b62, entry slot 0 and 1 alike; the same in all 5 layouts dumped):

  | form | per digit | loads + ORs | address | bit iteration | invariants recomputed | registers (processes) |
  |---|---|---|---|---|---|---|
  | **0** d813aea | **30** | 8 | 8 | 11 | 3 | 46–48, or 40 + 24 B spill (1 in ~7) |
  | **1** fold only (index masked) | **24** | 8 | 3 | 11 | 2 | 46–48 in 3 timed processes; 40 + 24 B in 1 of 2 dump kernels |
  | **2** fold + one word at a time (**the PR form**, `bee17b98`) | **20** | 8 | 3 | 9 | 0 | 47–48, no spill in 36 kernels |
  | **3** form 2 with the group's 4 chunks in 4 shared arrays (no mask) | **19** | 8 | 2 | 9 | 0 | 47–48, no spill in 12 kernels |

  Per (warp, group of 4 chunks) with the production shape's 12 digits per entry: **848 → 704 / 614 / 590 issued**
  (−17 / −28 / −30 %).
- **The leaner bit loop:** the iteration's own form barely matters. Highest-bit forms (`FLO`, then `x ^= 1 << bit`) cost
  as much as `BREV` + `FLO.SH` + `x & (x − 1)` (ptxas rematerialises the constant 1). `trailing_zeros` emits a zero test
  that adds 1–2 instructions. What saves 2 is structural: walk the low mask word, then the high one (x takes y when it
  empties). That removes the per-digit select of the word and of the +32 row offset. Together with the fold this is form 2.
- **A/B** (3 interleaved rounds, Latin-square order, exact counts in every process; × = d813aea ÷ form, > 1 is faster):

  | field | d813aea s/field | form 1 | form 2 | form 3 |
  |---|---|---|---|---|
  | **b62 1e17** | 131.90 | ×1.009 (0.973, 1.015, 1.009) | **×1.008** (0.963, 1.012, 1.008) | ×1.016 (0.954, 1.016, 1.017) |
  | **b60 1e16** | 27.41 | ×1.016 (1.016, 1.020, 1.015) | **×1.018** (1.018, 1.036, 1.011) | ×1.020 (1.026, 1.020, 1.016) |
  | b62 1e16 (2 rounds) | 11.67 | | ×1.010 (1.005, 1.014) | ×1.018 (1.015, 1.021) |
  | b64 1e16 (2 rounds) | 39.11 | | ×1.005 (0.991, 1.019) | ×1.009 (0.987, 1.031) |

  Round 1 at b62 1e17 is biased toward d813aea. Its run was the chain's first process, on a cold card (52 °C against
  57–60 °C for every later run, 880 MHz). Without round 1, form 2 is ×1.012 / ×1.008 and form 3 ×1.016 / ×1.017.
- **Why so little: likely the 130 W cap.** By L51's issue model, a 28 % cut of the AND's issue is ~3.5 % of a b62 1e17
  field in cycles. Between a quarter (b62 1e17) and a half (b60 1e16) of that shows in wall time here, against the
  50–85 % L44/L51 saw at 180 W. Every timed run sat at 125–130 W, at 742–944 MHz. The spill-variant process shows the
  mechanism: it ran **944 MHz** against its spill-free re-run's 863 MHz at the same power, and was still 5.4 % slower.
  On this card the cap turns issue density into clock.
  The clock-normalised ratios cannot be resolved at this level: one side's 5-s clock means scatter by ±6 % between
  rounds. They are in `raw/analysis_ab.txt` and not used. A card with more power headroom should see more of the cycle
  gain. That was not measurable here (the container can neither lift the cap nor lock clocks).
- **Exactness: exact everywhere.** Form 2's PR tree `P` = `bee17b98` passed (§3) CUDA CPU-reference parity incl.
  b50/b54, the FD-vs-top test, the certificate test, both dense fields, whole b42, and the 1e14 compare at b57/60/62/64.
  It also passed lavapipe naga and direct SPIR-V (all 8 wgpu tests of `cubecl_join` on each), CI's WGSL lint (14
  shaders, 0 flagged), fmt and clippy ×3. Every A/B and 1e14 process of every form gave the exact counts. So form 2 is a
  ready rider, though not a PR on its own.
- **L55 verdict: no.** CubeCL 0.10 has no per-kernel register or launch bound. Its CUDA dialect writes
  `__launch_bounds__(cube_dim)` and nothing else. NVRTC's options are fixed (`--gpu-architecture`, `--include-path`,
  `-lineinfo`). The module is loaded with `cuModuleLoadData`, with no JIT options. `#[cube(...)]` accepts launch,
  launch_unchecked, debug, debug_symbols, fast_math, cluster_dim, address_type and the like, and nothing about registers.
  There is no PTX post-pass hook. CubeCL 0.11.3 is the same. `__maxnreg__` cannot be added either: nvcc rejects it next to
  the `__launch_bounds__` CubeCL always emits ("cannot be applied to the same kernel"). **The smallest upstream-friendly
  way** is a `min_cubes_per_sm` kernel option plumbed exactly like `cluster_dim`, which makes CubeCL emit
  `__launch_bounds__(256, 5)`. That is 25 changed lines in 6 files (`raw/l55/cubecl-0.10-min-cubes-per-sm.patch`); usage:
  `#[cube(launch_unchecked, min_cubes_per_sm = 5)]` on `join_kernel` (§4).
- **The spill lottery, now with a cause:** CubeCL's `SharedLiveness` places the shared arrays in `HashSet` order, which
  `std`'s per-process random hasher reorders. So the PTX's shared offsets differ per process, and the driver's ptxas
  sometimes lands on 40 registers + 24 B of spills. d813aea did so in **1 of 12 timed processes** here (×0.949 at b60
  1e16, re-run) and in **3 of 24 kernels in the 1e14 frequency run** (§4.2), as in L51 (5 of 32). Forms 2/3 never did,
  in 48 kernels. That includes the C++ screen on the one dumped layout where d813aea spills, so the new loop's
  allocation seems to avoid it. Nothing guarantees that, though.
- **Box 59842997 can be destroyed:** every log, dump and SASS is in `raw/box/` (pulled 07:33 UTC), and nothing is
  running on it.

## 0. Setup and method

- **Trees** (`raw/box/logs/trees.txt`): `B` = d813aea; `X` = `exp/join-and-codegen` `003a0e0c` (the setup line shows
  d813aea, the tree was reset to `003a0e0c` before the build); `P` = `bee17b98`. Built on the box (`raw/scripts/build.sh`:
  `cargo test --release -p nice_common --features gpu --no-run`, `cargo clean -p nice_common` first). `X1` md5 `685472df`.
- **Forms** (`raw/scripts/patch54.py` = commit `003a0e0c`; `join_kernel` takes a comptime `and_form`):
  - 0: d813aea's loop.
  - 1: `a = (ab + d) & (TR_WORDS − 1)` in d813aea's loop.
  - 2: per entry slot, `x` = low mask word, `y` = high (swapped once if `x` = 0, row base `ab` or `ab + 32`). Per digit:
    `bit = ffs(x) − 1`, `x1 = x & (x − 1)`, `a = (row + bit) & (TR_WORDS − 1)`; then when `x1` is 0, x takes y, y becomes
    0 and the row base moves to `ab + 32`; then the four `t_tr[a + 64c]` ORs.
  - 3: form 2's loop without the mask, the batch's chunks `4g + k` in four shared arrays `t4k[g·64 + d]` (the transposed
    copy writes chunk `cc` to array `cc % 4`).
- **Codegen method** (no timing; `raw/scripts/`): `dumpcu.sh` runs a binary at 1e14 (b62, b60) with `CUBECL_DEBUG_LOG`
  and a fresh CubeCL PTX cache. It writes CubeCL's CUDA source of every kernel and replays the join kernels' PTX through
  the driver's JIT (`ptxjit.py`, L45's), keeping the SASS. `nvrtc.py` + `cuexp.sh` compile a `.cu` the way CubeCL does
  (NVRTC 12.8, `--gpu-architecture=sm_86 --include-path=… -lineinfo`) and JIT it through the driver. This reproduces the
  runtime's SASS exactly (d813aea: 1224 instructions, identical loops). `mkvar.py` rewrites the AND loop of a dumped source
  into the C++ that each candidate CubeCL formulation emits, for a zero-build screen. `andloops.py` finds the AND's digit
  loops (backward branches with `FLO` and as many ORs as `LDS`) and counts them. `cxrun.sh` runs the matrix. Five
  d813aea processes were dumped (`B0`–`B4`, five shared-memory layouts; `B0` is the 40-register spill variant) for the
  screen. Forms 0–3 were then built and dumped (`F0a`–`F3a`), and their SASS matches the screen's.
- **A/B method** (`raw/scripts/chain_ab.sh`, 06:11–07:03 box UTC, nothing else on the box): sides `B` (d813aea's binary)
  and `F1`/`F2`/`F3` (`X1` with `NICE_EXP_AND_FORM`). Rounds 1–3: b62 1e17 (1 field) and b60 1e16 (2 fields); rounds
  1–2: b62 1e16 and b64 1e16 (2 fields each, sides B F2 F3). Side order per round was a Latin square (B F1 F2 F3 / F3 B F1
  F2 / F2 F3 B F1). Harness `cubecl_cuda_join_throughput_fixed_fields` at L30's starts, one untimed 1e14 warm-up field
  per process, metric `per_field=`. Every process had its own PTX cache and was replayed through the driver's JIT
  afterwards. A process that compiled a spill variant was kept as `*_spill0` and re-run (one did: `B` b60 round 2).
  nvidia-smi every 5 s.

## 1. Codegen (no timing)

### 1.1 Why d813aea's four loads each form their own address

CubeCL's CUDA for the inner loop (`raw/box/cu/B0/join_kernel_b62_1.cu`, lines 895–933) is

```
const uint32 l_620 = l_600 + l_615;            // a = ab + d
const uint32 l_621 = l_620 + uint32(0);
const uint32 l_622 = shared_memory_9[l_621];
...
const uint32 l_625 = l_620 + uint32(64);       // and + uint32(128), + uint32(192)
const uint32 l_626 = shared_memory_9[l_625];
```

with `shared_memory_9 = reinterpret_cast<uint32*>(&dynamic_shared_mem[offset])`. NVRTC's PTX (`raw/box/cu/B0`,
`nvrtc/4_*.ptx`): `add.s32 %r896, %r894, 64; mul.wide.u32 %rd172, %r896, 4; add.s64 %rd173, %rd170, %rd172;
ld.shared.u32 [%rd173]`. The index sum is formed in 32 bits and zero-extended, so `zext(a + 64)·4` is not
`zext(a)·4 + 256` unless `a + 64` cannot wrap. ptxas then gives each load its own `IADD3` + `IMAD idx, 4, c[0x2][0x10]`.
Offline `nvcc -ptx` of the same source emits 32-bit shared addresses (`mov.u32 %r927, dynamic_shared_mem; ld.shared.u32
[%r928+260]`) and folds. So the extra arithmetic comes from NVRTC, and a CubeCL-level rewrite has to give the compiler
the no-wrap fact.

### 1.2 The screen (C++ as CubeCL emits it; NVRTC + driver JIT; per-digit SASS of the AND loop, b62)

`raw/box/logs/cxrun_b62.txt` (all 5 layouts; the per-digit counts are identical in every layout):

| rewrite (CubeCL form) | per digit | note |
|---|---|---|
| none (d813aea) | 30 | 8 address + 3 invariants |
| `abm`: `ab = (cb & 7) * 64` (hoisted, free) | 28 | `ab` bounded, `d` not (`ffs − 1` can be −1) |
| `mask`: `a = (ab + d) & 511` | **24** | fold; the 3 invariants partly stay (ULEA + IMAD.U32) |
| `abm` + `dm`: `d = (…) & 63` | 23 | |
| `or` + `abm` + `dm`: `d = bit \| (lo ? 0 : 32)` | 22 | |
| `ctz` + `mask`: `trailing_zeros` for `ffs − 1` | 26 | the `x == 0 ? 32 : …` costs |
| `hi` + `abm` + `dm`: `clz(x) ^ 31`, `x ^= 1 << bit` | 25 | ptxas emits FLO, `31 − x`, `^ 31` |
| `hi2` + `abm` + `dm`: `31 − clz(x)` | 23 | FLO + MOV 1 + SHF + XOR = BREV + FLO + IADD3 + LOP3 |
| `swap` + `abm` + `dm` | 27 | no fold: the row base is carried round the loop, and the compiler apparently does not bound it |
| **`swap` + `mask`** (= form 2) | **20** | with or without `abm`; `ctz` also 20, `hi2` 21 |
| `arr4` (4 arrays, no mask) | 23 | |
| **`swap` + `arr4`** (= form 3) | **19** | `hi2` 20 |

Form 2's loop (`raw/box/cu/F2a/jit/ptx_4_feb1d4e8.sass`, `0x2c40–0x2d70`): `BREV`, `IADD3` (x − 1), `FLO.U32.SH`,
`IMAD.IADD` (row + bit), `IMAD.SHL` (·4), `LOP3 & 0x7fc` (the mask), `LOP3 P0` (x & (x − 1), and its zero test),
`SEL` ×3 (x, y, row), `ISETP` (loop), `LDS [R+0x307c]`, `[R+0x317c]`, `[R+0x327c]`, `[R+0x337c]`, 4 `LOP3` ORs, `BRA`.
Form 3 drops the mask (`LDS [R+imm_k]`, one immediate per array). The group setup outside the loops grows from 28 to 34
instructions (the initial swap). Per (warp, group): `28 + 2·12·30 + 4·25 = 848` (L51's ≈840) → `34 + 2·12·20 + 100 =
614` (form 2), 590 (form 3), 704 (form 1).

Not pursued: a digit list precomputed per wave (packed 6-bit offsets, ~10 instructions a digit). It needs +6
registers at the 48-register line and a zero row for padding digits at b64. `LDS.128` digit-major is L51 §4(b)'s no-go.

### 1.3 The CubeCL builds

| form | b62 / b60 per digit | `join_kernel` (dump process) | SASS total | 1e14 counts |
|---|---|---|---|---|
| 0 | 30 / 30 | 48 / 48 | 1200 / 1192 | exact |
| 1 | 24 / 24 | 46 / 40 + 24 B | 1184 / 1208 | exact |
| 2 | 20 / 20 | 48 / 48 | 1184 / 1184 | exact |
| 3 | 19 / 19 | 48 / 48 | 1216 / 1216 | exact |
| `P` (form 2's PR form) | 20 / 20 | 48 / 48 | 1184 / 1184 | exact |

## 2. A/B (130 W cap; `raw/analysis_ab.txt`, `raw/analysis_runs.txt`)

Medians of the rounds; × = d813aea's s/field ÷ the form's in the same round (> 1 faster); "cycles" = the median over
rounds of (s/field × mean SM MHz) ratios, MHz = the side's mean over its rounds (samples at ≥ 90 % utilisation, 5 s
apart); every process exact.

| field | side | s/field (rounds) | median | × (rounds) | median × | MHz | cycles × | join registers (rounds) |
|---|---|---|---|---|---|---|---|---|
| **b62 1e17** (1 field) | B | 123.873, 132.283, 131.904 | **131.904** | | | 811 | | 48, 48, 48 |
| | F1 | 127.273, 130.293, 130.764 | 130.293 | 0.973, 1.015, 1.009 | ×1.009 | 801 | ×0.998 | 48, 48, 46 |
| | F2 | 128.677, 130.677, 130.899 | 130.677 | 0.963, 1.012, 1.008 | **×1.008** | 801 | ×1.001 | 48, 48, 48 |
| | F3 | 129.857, 130.159, 129.746 | 129.857 | 0.954, 1.016, 1.017 | ×1.016 | 780 | ×1.010 | 48, 48, 47 |
| **b60 1e16** (2 fields) | B | 27.412, 27.429, 27.230 | **27.412** | | | 807 | | 48, 48 (re-run of 40 + 24 B), 48 |
| | F1 | 26.988, 26.880, 26.825 | 26.880 | 1.016, 1.020, 1.015 | ×1.016 | 772 | ×1.060 | 48, 48, 48 |
| | F2 | 26.937, 26.476, 26.929 | 26.929 | 1.018, 1.036, 1.011 | **×1.018** | 768 | ×1.083 | 48, 47, 48 |
| | F3 | 26.709, 26.881, 26.796 | 26.796 | 1.026, 1.020, 1.016 | ×1.020 | 795 | ×1.012 | 48, 48, 48 |
| b62 1e16 (2 fields) | B | 11.630, 11.717 | 11.674 | | | 784 | | 48, 46 |
| | F2 | 11.574, 11.553 | 11.564 | 1.005, 1.014 | ×1.010 | 789 | ×1.003 | 48, 48 |
| | F3 | 11.453, 11.480 | 11.466 | 1.015, 1.021 | ×1.018 | 810 | ×0.985 | 48, 48 |
| b64 1e16 (2 fields) | B | 38.363, 39.865 | 39.114 | | | 817 | | 47, 47 |
| | F2 | 38.692, 39.116 | 38.904 | 0.991, 1.019 | ×1.005 | 814 | ×1.009 | 48, 48 |
| | F3 | 38.853, 38.669 | 38.761 | 0.987, 1.031 | ×1.009 | 800 | ×1.031 | 48, 48 |

- **The cycles column is not usable**: one configuration's per-process clock means scatter by up to ±6 % (e.g. B at
  b60: 756, 863, 803 MHz) while its times agree to 0.7 %. The 5-s samples fall on a mix of kernels with different power
  densities, and the warm-up and compile phases are sampled too. Per-process values: `raw/analysis_runs.txt`.

- **Below ×1.03 everywhere.** Form 3 leads form 2 by 0.2–0.8 %, which is inside the rounds' scatter, so the extra
  arrays do not pay for themselves. Form 1 (the fold alone) is as fast as form 2 within noise.
- **Spill tax on this box:** `B` b60 round 2 compiled the 40-register + 24 B variant: 28.910 s against 27.429 s on the
  re-run (×0.949), at 944 against 863 MHz.
- **Power and clock:** every process 125–130 W (at the cap), 57–60 °C after the first; SM clock means 742–944 MHz.
  In cycles (L51's model): the AND is 14.9 % of the b62 1e17 field and issue-bound at 80–90 %, and form 2 cuts its issue
  by 28 %. That predicts ~3.5 % of the field's cycles. Wall time improved by 0.8–1.2 % at b62 1e17 and ~1.8 % at b60.
- The fleet runs these cards at host-chosen caps (L51's was 180 W). At 180 W L51 expected ×1.02–1.04 for fold + hoist
  and ×1.03–1.05 with the iteration. At 130 W the measurement is ×1.01–1.02.

## 3. Exactness of form 2's PR tree `P` (`bee17b98`)

All on the box, 07:03–07:31 UTC (`raw/scripts/chain_post.sh`: `chain_x.sh P`, with `chain_lvp.sh P P` and
`chain_lint.sh P` beside it). `P`'s own join kernel (`raw/box/cu/P0`): 20 instructions per digit at b62 and b60, 48
registers, no spill, the exact 1e14 counts. So the PR form compiles to form 2's loop.

| check | result |
|---|---|
| `cubecl_cuda_join_matches_the_cpu_reference` (b10's 69, windows b20–b64 incl. **b50 and b54** after refused layouts, the b57 frontier, sliced windows, production shape; `x_P_ref.log`) | **ok** (101 s; 29 windows agree) |
| `cubecl_cuda_top_fd_matches_the_top_kernel` (`x_P_topfd.log`) | **ok** (383 s) |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (`x_P_cert.log`) | **ok** (112 s) |
| dense b58 1e15, 32 partitions (`x_P_dense58.log`) | **ok**: 254,938,965 survivors / 14,396,829 checked, equal to the CPU join (= L34) |
| dense b62 1e16, 4 partitions (`x_P_dense62.log`) | **ok**: 120,013,475 / 7,355,827 (= L34) |
| whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`, `x_P_whole.log`) | **ok**: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits (= L34), against the reference and the stride pipeline |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64 (`cmp_P_e14.log`) | **ok** (join = stride, found 0): b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759 (= L34) |
| host unit tests `join_plan::`, `cubecl_join::` (`x_P_unit.log`) | 8 passed; 7 passed (15 ignored) |
| lavapipe (llvmpipe, LLVM 20.1.2), **naga**: every wgpu test of `cubecl_join` (`lvp_naga_P.log`) | **8 passed**, incl. the join's CPU-reference parity (b50, b54, 50 windows agree) and the FD-vs-top test |
| lavapipe, **direct SPIR-V** (`lvp_spv_P.log`) | **8 passed**, the same |
| CI's WGSL lint (`wgsl_dump_for_lint` on naga, `scripts/wgsl-lint.py` with the workflow's 13 `--require`s; `wgsl_lint_P.log`) | 14 shaders, **0 flagged**; JoinKernel b57 29 constant divisions; rc 0 |
| `cargo fmt --all --check` (`fmt_P.log`) | clean |
| clippy `-p "*" --all-targets -D warnings`: default, `nice_client/gpu`, `nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1; `clippy_*_P.log`) | **all three clean** |
| every A/B process (B, forms 1–3) and every 1e14 process (dumps, frequency run) | exact counts |

**Exact.** Form 2 changes only the order in which an entry's digits are ORed into its accumulators (all of the low word,
then all of the high word, against low-or-high interleaved in d813aea's loop), and the OR is order-free. The mask is the
identity on every index the loop forms: `cb ≤ TOP_CAP/32 − AND_GROUP` at a group's start, so `row + d + 64c ≤
(TR_WORDS − 4·64) + 32 + 31 + 192 < TR_WORDS`.

## 4. L55: a register or launch bound for `join_kernel`

### 4.1 What CubeCL 0.10 offers (read from the 0.10.0 sources in the cargo registry; 0.11.3 checked too)

- **Kernel signature:** `cubecl-cpp` `cuda/dialect.rs` `compile_kernel_signature` writes
  `extern "C" __global__ void __launch_bounds__({cube_dim.num_elems()})`, plus `__cluster_dims__` when set. No minimum
  blocks, no `__maxnreg__`.
- **NVRTC options:** `cubecl-cuda` `compute/context.rs`: `vec![--gpu-architecture=sm_XX, --include-path=…, -lineinfo]`
  (+ the CCCL include path). Nothing configurable, no environment variable (`CUDA_PATH` only moves the include path).
- **Module load:** `cudarc::driver::result::module::load_data` (`cuModuleLoadData`), with no JIT options, so
  `CU_JIT_MAX_REGISTERS` is out of reach.
- **`#[cube(...)]` attributes** (`cubecl-macros` `parse/kernel.rs` `KernelArgs`): `launch`, `launch_unchecked`,
  `debug_symbols`, `no_debug_symbols`, `fast_math`, `debug`, `create_dummy_kernel`, `expand_only`, `cluster_dim`,
  `src_file`, `expand_base_traits`, `explicit_define`, `self_type`, `address_type`. Nothing about registers or occupancy.
- **`KernelOptions`** (`cubecl-runtime` `kernel.rs`): `kernel_name`, `debug_symbols`, `cluster_dim`.
- **PTX post-pass:** none. The PTX is visible only in CubeCL's optional file cache (L45's `pin.py` edits it there, a test
  method, not a production path).
- **`__maxnreg__` is not an alternative** even with a source hook. nvcc 12.8: "The `__launch_bounds__` and `__maxnreg__`
  qualifiers cannot be applied to the same kernel", and CubeCL always emits `__launch_bounds__` (`raw/l55/notes.txt`;
  tested with three one-line kernels). So the bound has to be the second argument of `__launch_bounds__`.
- **Verdict: no.** Per the brief, the variance was not chased further.

### 4.2 Why the variant is a lottery, and how often

`cubecl-opt` `analyses/liveness.rs` `SharedLiveness::allocate_slices` walks `self.at_block(block)`, a `HashSet` of live
shared memories. `std`'s `RandomState` seeds per process, so the arrays' offsets in `dynamic_shared_mem` (and so the
PTX's immediates and address arithmetic) differ per process. The five d813aea dumps had five different layouts
(`t_tr` at byte 4, 40, 12376, 4132 and 15480 in `B0`–`B4`; `raw/l55/notes.txt` lists every array's offset), and ptxas's
allocation follows the PTX. Frequency (driver
JIT replay of every process; `raw/box/logs/bf_*_jit.txt`, `ab_*_jit.txt`):

| binary | 1e14 frequency run (12 processes, b62 + b60 kernels) | timed A/B processes | dumps |
|---|---|---|---|
| d813aea (`B`) | **3 of 24** kernels 40 + 24 B (`bf_B_2` b60, `bf_B_7` b62, `bf_B_12` b60) | 1 of 12 (`ab_B_e16_b60_r2_spill0`) | 1 of 5 processes (`B0`, both kernels) |
| form 2 (`X1`, `NICE_EXP_AND_FORM=2`) | **0 of 24** (47–48) | 0 of 10 | 0 of 1 process (2 kernels) |
| form 1 / form 3 | | 0 of 3 / 0 of 10 | 1 of 2 kernels (`F1a` b60) / 0 of 2 |

The C++ screen on `B0`'s spill layout: every form with the swap allocates 48 registers without spill on it, and every
form without the swap keeps 40 + 24 B (`cxrun_b62.txt`). So form 2's clean record is its own allocation's luck.

### 4.3 The smallest upstream-friendly change

`raw/l55/cubecl-0.10-min-cubes-per-sm.patch` (against the 0.10.0 crate sources; 25 changed lines, 6 files). It mirrors
`cluster_dim` end to end:

1. `cubecl-runtime` `KernelOptions`: `pub min_cubes_per_sm: Option<u32>` (the struct derives `Default` and `Hash`, so it
   also keys the kernel cache).
2. `cubecl-core` `KernelIntegrator`: `.min_cubes_per_sm(n)`.
3. `cubecl-macros`: `KernelArgs::min_cubes_per_sm: Option<Expr>`; both settings builders add `.min_cubes_per_sm(#n)` as
   they add `.cluster_dim`.
4. `cubecl-cpp` `Flags`: `min_cubes_per_sm` from `value.options`; the CUDA dialect writes `__launch_bounds__(threads, n)`.
   HIP's second argument means something else and is left alone; WGSL/SPIR-V/Metal ignore the option.

Use: `#[cube(launch_unchecked, min_cubes_per_sm = 5)]` on `join_kernel`. NVRTC turns it into `.minnctapersm 5`, which L51
measured on the spill image as 44 registers, no spill, ×0.992–0.999 of the 46–48-register code. Checked here with
ptxas 12.8: sm_86 and sm_89 take it; on sm_75 (1024 threads per SM, 4 cubes of 256 at most) ptxas warns "Value of
threads per SM … is out of range. .minnctapersm will be ignored" and compiles normally.

A second, independent upstream fix: allocate shared memories in a deterministic order (sort the live set by id in
`allocate_slices`). The PTX would then be the same in every process: one register variant per kernel and driver. That
removes the 1-in-7 noise from every A/B, though not by itself the spill variant.

## 5. What this leaves

- Form 2 is a finished, measured, exact rider (`19702e1`: `cubecl_join.rs` +40 / −16 and a CHANGELOG line with `#NNN`)
  at ×1.01–1.02 on a 130 W 3080. It is worth reconsidering if a join PR goes up anyway, or as a NiceMark-checked rider
  at a higher cap. Base used: d813aea. `patch54pr.py` applies unchanged to #249's head `87958fd9`; at #246's head
  `f3fb390c` only the `use super::{…}` line differs (no `MAX_ROOTS` yet), and the AND loop is the same text.
- Not measured: the AND phase's own time under this cap (L51's ablation mode `a` with form 2 ported onto `exp/l51-profile`;
  `patch54.py` does not apply there as is). That would turn the "likely the cap" above into a measurement. It is a
  ~40-minute box job, not needed for the verdict.
- The AND's remaining overhead above its floor is the bit iteration (9 of 20) and the per-chunk pass masks. At this cap
  the energy per field, likely dominated by the shared loads the forms leave unchanged, seems to set the time, so trimming
  further instructions would buy even less.

## 6. Files

- `RESULTS.md` (this file), `BRIEF.md`.
- `raw/analysis_ab.txt` (`python3 raw/scripts/analyze54.py raw/box/logs`), `raw/analysis_runs.txt` (per-process time,
  clock, power, temperature, registers).
- `raw/box/logs/` (the box's `/root/l54/logs`): `ab_<side>_<field>_r<n>.{log,smi}` and `*_jit.txt` (A/B), `bf_*`
  (frequency run), `x_P_*`, `cmp_P_e14`, `lvp_*`, `wgsl_lint_P`, `fmt_P`, `clippy_*_P` (exactness), `cxrun_b62.txt`
  (the screen), `build_*`, `trees.txt`, `box-info.txt`, `power.txt`; `raw/box/*.out` (chain outputs).
- `raw/box/cu/`: `B0`–`B4` (d813aea: CUDA sources of every kernel at b62/b60, PTX-cache JIT SASS of `join_kernel`;
  `B0/nvrtc/` its NVRTC PTX), `F0a`–`F3a` (forms 0–3), `P0` (tree `P`). `raw/box/cx_B0/`: the screen's variant sources
  (`v_<variant>.cu.gz`, `mkvar.py` over `B0`'s b62 source) and their driver-JIT SASS (`.sass.gz`).
- `raw/scripts/`: `setup.sh`, `build.sh`, `run.sh`, `cfg.sh`, `dumpcu.sh`, `nvrtc.py`, `cuexp.sh`, `mkvar.py`,
  `cxrun.sh`, `andloops.py`, `region.py`, `ptxof.py`, `ptxjit.py`/`cbor_min.py`/`jitlog.py`/`pin.py`/`pick.py` (L45's),
  `classify41.py` (L41's), `chain_ab.sh`, `chain_post.sh`, `chain_bfreq.sh`, `chain_x.sh`, `chain_lvp.sh`,
  `chain_lint.sh`, `test.sh`, `chain_nm.sh` + `buildclient.sh` + `nm_table.py` (written, not run: no form reached
  ×1.03), `analyze54.py`, `patch54.py` (= `003a0e0c`), `patch54pr.py` (= `bee17b98`'s kernel change), `pull.sh`,
  `ssh.sh`.
- `raw/l55/cubecl-0.10-min-cubes-per-sm.patch` (the upstream proposal), `raw/l55/notes.txt` (the launch-bound and
  `__maxnreg__` checks, the five layouts).
- Branch **`exp/join-and-codegen`** on the fork: `d91447a` (= `003a0e0c`, forms behind `NICE_EXP_AND_FORM`), `19702e1`
  (= `bee17b98`, form 2's PR form with its CHANGELOG line, `#NNN`). No `pr/join-and-codegen` on the fork.
