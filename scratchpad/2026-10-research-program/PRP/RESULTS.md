# PRP: two join PR branches on upstream main, with their CUDA numbers (2026-11-12)

Labels: **[M]** measured here, **[D]** derived from measured numbers, **[A]** assumed or taken from elsewhere (cited).

## Branches

- Upstream main: **`a7a59c11`** (#253). Trees: **M** = main, **S** = change 1, **F** = change 2.
- **S: fork `pr/join-survivor-stage-512` = `0d84d0a2`**, one commit on `a7a59c11`: `common/src/cubecl_join.rs`
  (`SURV_SH_CAP` 1024 → 512, `SURV_FLUSH` 512 → 256, their docs; +12/−4) and one CHANGELOG line ending
  `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
- **F: fork `pr/join-prefilter-shift-pow2` = `93a7ef66`**, one commit on `a7a59c11`: `walk_pf_lean` takes its four
  digits by shifts when the comptime base is a power of two (b64), by multiplies otherwise; its doc; a host test
  `fx_digits_are_bit_fields_at_powers_of_two`; one CHANGELOG line with `#NNN`. 2 files, +62/−5.
- Both pushed to the fork as new branches (plain push, accepted, about 18:15 UTC, after every exactness check had passed). PR bodies: `PR-BODY-stage.md`,
  `PR-BODY-shift.md`. No PRs opened.

## Box

Vast 60383994, RTX 3080 10 GB, **power cap 320 W** (default; not changeable from the container), driver 595.91.07,
CUDA 13.2 driver API, i9-7960X (32 threads), toolchain 1.99.1 (the repo's pin). One target directory per tree
(`/root/prp/target-{M,S,F,T16,T512,C}`, clippy in `target-clippy-{S,F}`); every binary's md5 and source commit is in
`raw/box/out/build_all_*.out`:

| binary | tree | features | md5 |
|---|---|---|---|
| M / S / F | a7a59c11 / 0d84d0a2 / 93a7ef66 | `gpu,cubecl-spirv` (CUDA + wgpu with CubeCL's SPIR-V compiler) | 143dfb3a / b1381ff9 / d4491674 |
| M_naga / S_naga / F_naga | same | `gpu` (CUDA + wgpu via naga) | 0c7871cb / 8829a2f2 / 52b7c3b6 |
| client_M / client_S / client_F | same | `nice_client --features gpu` (NiceMark) | 9fb1cc42 / 22f59904 / f11e10b2 |
| T16, T512 | S + `raw/scripts/patch_cnt.py` (throwaway) | `gpu,cubecl-spirv` | df07df7d, 882c1f8a |
| C | F + `raw/scripts/patch_cpufx.py` (throwaway) | `cubecl` | c0738169 |

The binaries differ from each other (md5) and each was copied from its own tree's target directory right after its
build. Identity checked on what each process compiled [M]: the join kernel's `shared_mem_bytes` in every timed
process's PTX cache is 14,460 for every S process (16) and 18,556 for every M (16) and F (16) process
(the 4 KiB stage difference); F's b64 join kernel source has the shifts and M's the multiplies (below); T16/T512 print
their stage size in their own output.

## Checked by reading (S)

- Every use of `SURV_SH_CAP` / `SURV_FLUSH` (`cubecl_join.rs` on main): the two shared arrays' size; the walk's
  `at < SURV_SH_CAP` (else the pair goes to the list directly through its own `surv_count` reservation); the flush test
  `sc >= SURV_FLUSH` once per batch of tops after the two barriers (#249); `flush_survivors`' `n = min(sc,
  SURV_SH_CAP)`; the end-of-kernel flush. Nothing else (host, plan, other kernels) reads them. A pair that finds the
  stage full is never dropped; the stage size cannot change the counts. Docs that state sizes: only the constants'
  (updated). The join kernel's doc ("staged ... goes to the list once it is half full") and the walk comment ("a batch
  can add more than the half left ... the pairs past a full stage go to the list directly") hold at 512/256 unchanged.
  L51's "no pair past a full stage at b60/b62" is a fork write-up, not a comment in the code; with 512/256 it is no
  longer true at b60 (below), which is fine by construction.
- Shared memory of the join cube on CUDA [M, from the generated source]: 18,556 B on main (17 arrays), so 14,460 B
  with S [D]. On sm_86 at 46–48 registers a 256-thread block fits 5 per SM by registers; shared memory allowed 5 (main)
  and 6 (S) [D]: still register-bound.

## Exactness

**Host tests** (all non-ignored tests of `nice_common`, binaries S and F): S 247 passed, F 248 passed (the new test
included) [M] (`raw/box/logs/t/host_*.log`). `cargo fmt --all --check` and `cargo clippy -p nice_common --all-targets
--features gpu,cubecl-spirv -- -D warnings` with 1.99.1: clean for S and F [M] (`fmt_*.log`, `clippy_*.log`).

**CUDA device tests** (`--ignored cubecl_join::tests::cubecl_cuda`, 7 tests: CPU-reference parity over the 17 windows
incl. b50/b54/b64 and the b57 frontier field, tight layouts, slices, refused layouts, production shape re-runs; FD vs
top kernel (26 fields, 279 batches, 23 with a clipped block); top certificates vs lockstep scan and CPU; the dense,
whole-field and throughput tests skip themselves without their opt-in variables):
- S: 7 passed [M] (`cuda_S.log`).
- F: the first run (`cuda_F.log`) **failed** in `cubecl_cuda_top_fd_matches_the_top_kernel` with CubeCL's "can't
  allocate buffer of size: 2589212672": it ran while the overflow stream's dense tests and the source dump held device
  memory in other processes (my scheduling, not the branch). Re-run alone on an idle card (1 MiB used before): **7
  passed** [M] (`cuda_F2.log`; FD vs top: 26 fields, 279 batches, 423,104,943 tops).

**Dense compare against the CPU join** (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`, hits and both
survivor counts asserted equal; `x_*.log`) [M]:

| tree | field | partitions | join survivors / checked | result |
|---|---|---|---|---|
| S | b60 1e16 at 1447429612114824200908 (0.55) | 48 (2 slices, 9 a launch) | 2,011,244,757 / 134,795,310 | ok |
| S | b62 1e17 at 7520566762397899821056 (0.45) | 32 of slice 0 (15 a launch) | 679,431,359 / 41,427,678 | ok |
| F | b64 1e16 at 39667831862957161709568 (B64's) | 48 (1 slice, 15 a launch) | 2,836,249,711 / 172,308,464 | ok |
| F | b64 1e17 at 58557331862957161709568 (0.55) | 32 of slice 0 (13 a launch) | 2,803,067,823 / 173,796,394 | ok |

The two b64 rows have exactly B64's counts on the same fields (`../B64/PR-RESULTS.md`).

**Stage overflow (S)**: throwaway builds of S that count the pairs written past a full stage (`patch_cnt.py`: one atomic
on the direct path into a second word of the join-survivor counter, summed on the host; `xc_*.log`), dense compare
again [M]:

| build | b60 1e16, 48 partitions | b62 1e17, 32 partitions | b64 1e17, 32 partitions | counts vs CPU join |
|---|---|---|---|---|
| T16 (stage 16, flush 8) | **123,932,078** of 134,795,310 checked | **37,554,910** of 41,427,678 | | equal (ok) |
| T512 (stage 512, flush 256 = S) | 93,908 | 0 | 79 | equal (ok) |

So the direct path carries 92 % of the survivors in T16 and the hits and counts are still exact.

**lavapipe** (Mesa llvmpipe, LLVM 20.1.2; `VK_ICD_FILENAMES` = lvp; every wgpu test of `cubecl_join`, `--skip cuda`):
S_naga, S (SPIR-V), F_naga, F (SPIR-V), and M_naga: **8 passed each** [M] (`lvp_*.log`); the parity test reports all 17
windows "agrees (FD tops: true)", the b64 window `(11,4,2)` included on both compilers for F.

**What the b64 window asserts (F)**: `check_window` at b64 [52125117810081128433988, +300000), (t, k, p) = (11, 4, 2):
f0 = 13 − 11 = 2 and mid = 2 (b^(k+2−f0) = 64^4 < 2^32), so k = 4 ≥ 2 runs `walk_pf_lean` with the shift form [D, by
reading `FieldSetup::new`]. Per batch it asserts the join-survivor count equals the CPU's, the sorted list of prefilter
survivors (as n) equals the CPU join's pairs filtered by `mid_mirror` (the prefilter by its definition), and at the end
the hits. The dense b64 compares above run the production shape (k = 6) through the same kernel.

**F is identical code at every other base** [M]: CUDA source of every kernel from `CUBECL_DEBUG_LOG` on one 1e14 field
each at b58, b60, b62, b64, M against F (`cuda_src_{M,F}.log`, `raw/scripts/srchash.py`, `srchash_cuda_MF.txt`).
CubeCL emits the mutable locals' declarations and the shared arrays' offsets in a per-process order (even unchanged
kernels differ raw); with those two canonicalised (declarations sorted, offsets dropped), 20 of 21 kernels are
identical (all five per base at b58/b60/b62, four at b64, the smoke kernel) and the b64 join kernel differs in 12 lines
(12 removed, 12 added): `__umulhi(f, 64)` / `f * 64` → `f >> 26` / `f << 6`, for both entry slots. The 1e14 runs gave
the same counts on M and F at every base. The WGSL that naga gets differs between any two processes in many more ways
(not canonicalised; not used).

## CPU join prefilter (F)

`cpu_join::Fx::digits` holds b as a runtime `u64`, so no compiler folds its multiplies by 64 [read]. Throwaway C
(`patch_cpufx.py`: the shift form behind `NICE_EXP_FX_SHIFT=1`, decided per `Fx::new`; the timing test on any field),
b64 1e16 at 0.55, every 256th partition (16), one thread pinned to CPU 2, alternating, 3 rounds [M]
(`raw/box/logs/cpufx/`): multiply 2,615 / 2,604 / 2,620 ms per partition, shift 2,705 / 2,708 / 2,715 ms: **shift
×0.965, slower**, counts identical. (A CUDA test suite ran on the box at the same time; the order alternated and the three
rounds agree within 0.6 %.) Not changed.

## Speed on CUDA

**Method** [M]: binaries M, S, F (above); `raw/scripts/ab.sh` → `run.sh`: the throughput harness
`cubecl_cuda_join_throughput_fixed_fields` (one untimed 1e14 warm-up field just below the start, then the timed
fields through the client's route); seconds = the harness's wall time for the timed fields. Fields: b62 1e17 at
7520566762397899821056 (0.45), b60 1e16 at 1447429612114824200908 (0.55) (both `../N16/raw/scripts/env.sh`), b64 1e17 at
58557331862957161709568 (0.55), b64 1e16 × 2 consecutive from the same start (0.55 and the next 1e16; `../B64/RESULTS.md`
starts). Three rounds 18:14–19:50 UTC, then (after NiceMark, time allowing) a fourth 20:09–20:41; each field runs M, S, F
back to back, order M S F / S F M / F M S / F M S. Nothing else ran on the box (no build, no test). nvidia-smi every 2 s; MHz and W = medians over samples at ≥ 90 % utilisation; cap
320 W in every run. Each process's join kernel replayed through the driver JIT from its own PTX cache (`ptxjit.py`):
`regs+local`; 40+24 is the known spill variant.

**Thermal: this card throttles on temperature** [M]. In the first attempt (18:08–18:12, `raw/box/logs/aborted/`), runs
back to back reached 89 °C and 1,500 MHz (throttle reason 0x20, SW thermal slowdown), and the second run of a pair
paid for the first's heat (S b62 73.46 s against M's 67.77 s). I stopped it and made every run start at ≤ 60 °C (waits
of 40–149 s, logged as `cooled …` in each START line). Even so, a b64 1e17 run (145 s) spends about half its samples in
thermal slowdown and settles at 1,560–1,630 MHz and 245–256 W, below the 320 W cap; the shorter fields stay at
1,725–1,830 MHz and 288–319 W (power-capped, reason 0x04). Every tree runs the same thermal course, which is why the
ratios hold, but the b64 1e17 numbers are for a throttled card.

**Counts identical** in every run of a field (M, S and F, all rounds), no re-runs:
b62 1e17 1,097,114,812,011 / 66,862,268,894; b60 1e16 190,770,281,868 / 12,786,993,080; b64 1e17 3,092,989,872,066 /
191,683,594,021 (B64's counts for this field); b64 1e16 × 2 674,468,878,644 / 41,802,516,096.

| field | M s (r1–r4) | S s | **M/S** per round → median | F s | **M/F** per round → median |
|---|---|---|---|---|---|
| b62 1e17 | 66.43, 66.75, 66.77, 66.72 | 66.38*, 66.51, 66.86, 66.86 | 1.001*, 1.004, 0.999, 0.998 → **×1.000** | 66.88, 67.40*, 66.67, 66.65 | 0.993, 0.990*, 1.001, 1.001 → **×0.997** (code identical: A/A) |
| b60 1e16 | 12.17, 12.11, 12.13, 12.16 | 12.31, 12.18, 12.11, 12.07* | 0.989, 0.994, 1.002, 1.007* → **×0.998** | 12.13, 12.13, 12.12, 12.26 | 1.003, 0.998, 1.001, 0.992 → **×1.000** (A/A) |
| b64 1e17 | 144.95, 145.43, 146.15, 146.41 | 145.98, 141.28, 146.54, 146.87 | 0.993, 1.029, 0.997, 0.997 → **×0.997** | 143.23, 143.57, 142.67, 141.34 | 1.012, 1.013, 1.024, 1.036 → **×1.019** |
| b64 1e16 × 2 | 30.08, 30.00, 30.06, 30.22 | 30.07, 30.20, 29.53, 30.20 | 1.000, 0.993, 1.018, 1.001 → **×1.000** | 29.60, 29.67, 29.57, 29.64 | 1.016, 1.011, 1.017, 1.020 → **×1.016** |

(*) the 40-register spill variant of `join_kernel` in that process (S b62 r1, F b62 r2, S b60 r4); every other process
46–48 registers, no spill. Without those rounds: M/S b62 ×0.999 (n = 3), M/S b60 ×0.994 (n = 3), M/F b62 ×1.001 (n = 3).
Medians of four are the mean of the middle two.

Per-run clock and power (`raw/ab_table.txt`, from `analyze.py`): b62 1,725–1,785 MHz, 288–307 W; b60 1,800–1,830 MHz,
317–319 W; b64 1e17 1,560–1,628 MHz, 245–256 W; b64 1e16 1,785–1,808 MHz, 318–319 W. Cool-down before a run 40–149 s.

- **S on CUDA: neutral** [M]: ×0.997–×1.000 by field median; the lowest single round ×0.989 (b60 r1). Nothing below
  ×0.98. As expected [D]: the kernel is register-bound at 5 blocks per SM with either stage.
- **F on CUDA: ×1.019 at b64 1e17, ×1.016 at b64 1e16** [M] (every round ≥ ×1.011); the ×1.01–1.02 estimated from
  SASS earlier [A, brief]. At b62 and b60 F compiles main's code (above), so its rows there are an A/A test of this
  protocol: ×0.997 and ×1.000, single rounds within ±1 %: that is this box's noise for one ratio.
- Worst single round across both: S b60 1e16 round 1, ×0.989; F b62 (identical code) round 2 with the spill variant
  ×0.990. Worst field median: S b64 1e17 ×0.997.

## NiceMark

`raw/scripts/nm.sh`: `client_X niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, four rounds 19:50–20:08
UTC, orders M S F / S F M / F M S / M F S, each run started at ≤ 60 °C (cooled 55–82 s), nothing else on the box.
Every run 1,785–1,800 MHz, 318–319 W, cap 320 W [M] (`raw/box/logs/nm/`; `raw/nm_table.txt`).

| | M | S | F |
|---|---|---|---|
| score per round | 9950.0, 9946.1, 9950.1, 9906.4 | 9894.4, 9927.7, 9964.9, 9904.6 | 9883.9, 9973.3, 9970.8, 9928.0 |
| ratio to M per round | | 0.994, 0.998, 1.001, 1.000 → **×0.999** | 0.993, 1.003, 1.002, 1.002 → **×1.002** |
| b58 MSD-weak (median, min round) | | ×0.999 (0.994) | ×1.003 (0.997) |
| b58 MSD-strong | | ×1.001 (0.987) | ×1.005 (0.989) |
| b60 MSD-weak | | ×1.000 (0.991) | ×0.999 (0.990) |
| b62 MSD-weak | | ×0.997 (0.996) | ×0.998 (0.995) |

NiceMark's nice-only scenarios are b58/b60/b62 only, so for F it is an A/A run (identical code); for S it is the
regression check. No scenario median below ×0.997, no single round below ×0.987 (S b58 MSD-strong round 1).

## RX 9070 XT (from `../EXPERIMENTS.md` N17.1, not measured here) [A]

S: ×1.055, 1.056, 1.060 at b62 1e17; ×1.057, 1.056, 1.056 at b60 1e16 (three rotated rounds); b64 1e17 with a 256
stage ×1.062 (one round); screen at b60 512/256/128 ×1.063/1.048/1.054 (one round). F: b64 1e17 150.16 → 142.90 s,
×1.051 (one round, experiment binary P = f049415 on a tree without #254).

## Caveats (what I would flag before sign-off)

- The CUDA numbers are for a card that throttles on temperature; runs were started cool and every tree followed the
  same course, but the b64 1e17 runs sit at ~1,575 MHz / ~250 W, not at the 320 W cap.
- F's CUDA device suite first failed on a device-memory allocation while my other GPU streams were running; it passed
  on an idle card. S's suite passed while sharing the card. Neither is a code failure, but the first F log is kept.
- The RX 9070 XT numbers are not from these commits: S's were taken with the sizes switched by an environment variable on
  an experiment tree, F's with the experiment commit (one round, on a tree without #254). Nothing here re-measures that
  card. No Apple GPU was measured.
- F's gain on NVIDIA is ×1.016–1.019 (below the ×1.05 bar on its own); its case rests on the one-round ×1.051 on the
  RX 9070 XT.
- The WGSL that naga gets was not compared M vs F (its text differs between any two processes); the identical-code
  claim at non-power-of-two bases rests on the canonicalised CUDA source.

## Files

- `raw/box/logs/`: A/B runs (`ab_*.log`, `.smi`, `_jit.txt`), `nm/` (NiceMark JSON, `.err`, `.smi`), `t/` (tests,
  dense runs, source dumps, hashes), `cpufx/`, `aborted/` (the first A/B start, see above).
- `raw/box/out/`: build logs and summaries, `ab.out` (rounds 1–3), `ab4.out` (round 4), `nm.out`, `tests.out`.
- `raw/ab_table.txt`, `raw/nm_table.txt`: `analyze.py`'s output (every run with clock, power, registers, counts).
- `raw/scripts/`: `setup.sh`, `build.sh`, `build_all.sh`, `tests.sh`, `run.sh`, `ab.sh`, `nm.sh`, `analyze.py`,
  `srchash.py`, `patch_cnt.py`, `patch_cpufx.py`, `cpufx.sh`, `ptxjit.py` + `cbor_min.py` (from B64).
- `raw/prp.bundle`: main + the two branches as built.
