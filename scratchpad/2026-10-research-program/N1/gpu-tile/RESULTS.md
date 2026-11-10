# N1 GPU tile: what a (top, bottom) pair costs in the dense phase at other join shapes (RTX 3080, 2026-11-10)

Box: Vast **60024264** (`nice-research-n1-tile`, machine m156393), RTX 3080 10 GB, **power limit 340 W** (default 380 W),
driver 595.99.02, Xeon E5-2690 v4, 28 CPUs, toolchain 1.99.1. The production field ran at ~1,920 MHz; the harness, which
holds the card at the cap (337–338 W), at ~1,825 MHz. Everything below was measured on this box between 06:25 and 07:16 UTC.
Provenance tags: **[M]** measured here, **[D]** derived from [M] by arithmetic, **[A]** assumed or given by the brief,
**[E]** estimate (instruction counts, no run).

Trees: **E** = fork `exp/l51-profile` `14f87cd` (L51's profile timers and ablation modes on d813aea). Its `join_kernel`
is **byte-identical** to upstream main `c0c357a`'s (checked by diffing the function), so its ablations are today's kernel.
**T** = upstream main `c0c357a` + the test-only harness (`common/src/n1_tile.rs`), binary md5 `b620a506`; **T2** = T + the
harness's no-AND mode (md5 `fab809bb`) = fork branch **`exp/n1-gpu-tile` `c81875f`** (pushed; no PR). Production kernels in
T are c0c357a's (the harness is `#[cfg(test)]`).

## Summary

- **Calibration at today's shape (b62 1e17 field at 7226266762397899821056 = 3226266762397899821056 + 40000·10^17, all
  3,844 partitions through `run_slices`, 11 slices, 3 interleaved rounds) [M]:** **2.4655e13 AND pairs, 9.534e11 AND
  survivors (pass 3.87 %), 5.800e10 full checks** per field; dense phase (L51 mode a: base + AND) **0.563 ps per pair**
  (base 0.261 + AND 0.302); survivor path (c − a: walk rounds + prefilter + stage) **17.4 ps per AND survivor** (= 0.673 ps
  per pair; walk rounds 5.6, prefilter 11.7, stage 0.05). Today's main (c0c357a, unprofiled) **61.93 s per field** here →
  **5.91e6 s per b62 base** [D]. The director's estimates: pairs 2.6e13 ✓ (−5 %); survivors 6.7e11 ✗ (+42 %); 0.8 ps per
  pair and 36 ps per survivor were 180 W-box numbers (this box runs the same kernel ~1.4× faster).
- **Harness vs production at today's shape:** the harness reproduces production's dense cost per pair **only within
  −19 %, at the edge of the 20 % bar**, and only with a cache-friendly bottom-list layout (L1: 0.455 against 0.563). Its
  split is base −7 %, **AND −30 %**. A production-like scattered gather (L53) makes it load-bound at 1.09 ps (+93 %), and a
  middle layout (L5, 0.517, −8 %) matches the total by coincidence with the wrong split (its AND hides under the loads; L39's
  lesson). The likely cause of the missing 19 %, measured: production's buckets vary around their mean of 467 tops and
  small buckets/remainders (< 192 tops) take the per-top AND at 0.85–0.97 ps per pair against 0.46 at 471 tops (§2.3). **So
  the absolute harness numbers are low by ~20–30 % for the AND part; I project with ratios calibrated part by part
  (base ×1.07, AND ×1.43) as the central case, and show the uncalibrated harness as the optimistic bound.**
- **Dense cost per pair at the new shape (L1, D_T 17; harness ps, ratio to the harness's own today-shape 0.455) [M]:**

  | tile (tops × entries) | orientation | word | D_B 12 | D_B 18 | D_B 20 |
  |---|---|---|---|---|---|
  | 471 × 336 (today's mean) | today | u32 | **0.455** (1.00) | 0.570 | 0.609 |
  | 1,460 × 14,750 (f0 4, k 9) | today | u32 | 0.322 (0.71) | **0.410 (0.90)** | 0.437 (0.96) |
  | 1,460 × 14,750 | today | u64, 4 chunks a pass | 0.272 (0.60) | **0.323 (0.71)** | 0.339 (0.75) |
  | 1,460 × 14,750 | reverse | u32 | 0.400 | **0.410 (0.90)** | 0.407 |
  | 1,460 × 14,750 | reverse | u64, 4 chunks a pass | 0.292 | **0.295 (0.65)** | 0.293 |
  | 785 × 14,750 (f0 3, k 9, assumed) | today / reverse | u64, 4 chunks | — | 0.279 / 0.327 | — |
  | 24 × 7,200 (k 10) | today (per-top) / reverse | u32 | 1.108 / 3.394 | 1.110 / 3.393 | 1.109 / 3.398 |

  **The AND part does scale with the digit count** (u32: 17–18 fs per pair per entry digit at every shape; u64: 10–14);
  **the per-wave base does not, and it falls 2.4× in the big tile** (0.243 → 0.103 ps per pair: full waves, one entry load
  per 256 tops, few work items). That is why 18 digits in the big tile cost no more than 12 in today's tile (u32) and 29 %
  less in u64. With D_T 15 the reverse orientation gets cheaper (u64: 0.278); k 10's 24-top tiles cost ×2.7–11 the big tile's.
- **Survivor handling at the new density [M]:** the walk is **not proportional to survivors**: per pair it is ≈ 0.13–0.15 ps
  + 14 ps × pass rate (5 densities, 0.11–2.4 %, every orientation and word). At production's 3.87 % the fit gives 0.682
  against production's measured 0.673 ps per pair (−1.4 %: the survivor path is reproduced). At the new 0.34 % it is
  **0.18 ps per pair = 54 ps per survivor**, 3.1× today's per-survivor cost: survivors ÷ 10.8 buys the survivor path only
  ÷ 3.2–3.5.
- **Whole-base b62 projection (central / optimistic; D_B 18, D_T 17; other overhead 2 % of today [A]) [D]:**

  | shape | u32, today orientation | u32, reverse | u64, today orientation | u64, reverse |
  |---|---|---|---|---|
  | **f0 4, k 9** | **×2.56** / ×3.08 | ×2.61 / ×3.06 | **×3.01** / ×3.53 | ×3.20 / ×3.58 |
  | **f0 3, k 9**, every top a full FD test (0.158 ns) | **×2.81** / ×3.11 | ×2.74 / ×3.01 | **×3.19** / ×3.43 | ×3.05 / ×3.24 |
  | f0 3, k 9, children certified at 0.45 of a full test [E] | ×3.50 / ×3.97 | ×3.39 / ×3.81 | ×4.09 / ×4.51 | ×3.87 / ×4.19 |

  **Against the ×3 rule: u32 (portable) misses at both shapes (×2.6–2.8 central, ×3.0–3.1 only uncalibrated); u64 (CUDA
  only) clears it narrowly (×3.0–3.2 central)**, and the margin is inside this projection's own uncertainties (other
  overhead 0–7.7 %: ×3.4 to ×2.6; the pair and survivor counts are the director's model, not a prototype). **f0 3, k 9 with
  cheap child certification is the only variant clearly past ×3 (×3.4–4.1 central)**: at f0 3 the top tests (5e15) are
  40 % of the new total if each costs a full FD step.
- **Not measured:** the real bucket-size distribution of the new shape (one mean tile plus a ×0.25–×2 size scan, §2.4); the
  list building of the transversal unit; staging and the check (taken as a tenth, [A]); CPU/WebGPU; child certification
  (instruction estimate only); clocks other than this 340 W card.

## 1. Calibration (step 1): today's kernel on real data

`raw/scripts/chain_cal.sh`, 3 interleaved rounds of six processes (modes c a z T b p, order rotated), each one untimed
1e14 warm-up field then the b62 1e17 field at **7226266762397899821056** (3226266762397899821056 + 40000·10^17), 3,844
partitions, 11 slices, 3,205 batches. Medians of rounds; every round in brackets. `raw/analysis.txt` (`analyze.py`).

| mode (E = c0c357a's join kernel + L51's profile) | join s per field | field device s | `join_kernel` regs (rounds) |
|---|---|---|---|
| c full | **30.49** (30.49, 30.49, 30.44) | 60.15 | 48, 48, 48 |
| a AND only (dense phase) | **13.89** (13.83, 13.89, 13.90) | 37.43 | 39, 40, 40 |
| z no AND (base) | **6.44** (6.39, 6.45, 6.44) | 30.16 | 38, 36, 37 |
| b walk without prefilter / stage | 19.26 (19.20, 19.66, 19.26) | 42.72 | 39, 40, 40 |
| p walk + prefilter, no stage | 30.44 (30.39, 30.70, 30.44) | 53.93 | 46, 47, 47 |
| **T = c0c357a, unprofiled** | — | 60.40 (60.33, 60.40, 60.87) | 48, 46, 46 |

- **Counts** (mode c, every round the same, and T the same): **pairs 24,655,129,828,963** (padded 3.8273e13, lanes used
  64.4 %), **AND survivors 953,434,284,645** (pass **3.87 %**), **full checks 58,004,430,167**, kept tops 3.7376e10,
  listed entries 5.2785e10, buckets 1.5992e8 → **mean tile 467 tops × 330 entries** (the brief's 2,000 × 350 is not
  today's mean; both were run). No `join_kernel` image of any process compiled the spill variant (every one `local=0`).
- **Per pair and per survivor [D]:** dense (a) 13.89 s / 2.4655e13 = **0.5634 ps per pair**: base (z) **0.2611** + AND
  (a − z) **0.3023**. Survivor path (c − a) 16.60 s = **0.673 ps per pair = 17.41 ps per AND survivor**: walk rounds (b − a)
  5.37 s = 5.63 ps, prefilter (p − b) 11.18 s = 11.72 ps, stage (c − p) 0.05 s.
- **Field profile** (mode c, median): top FD 12.62 s (22.7 %), bucket 1.82 (3.3 %), join 30.49 (54.8 %: dense 25.0 %,
  survivor path 29.8 %), check 6.43 (11.5 %), slice setup 3.05 (5.5 %), inputs/reads/unattributed 1.25 (2.3 %); the
  shares match L51's (180 W box) within 1–2 points.
- **Today's base [D]:** T's unprofiled field 61.93 s (61.86, 61.93, 62.38) × 95,430 fields [A] = **5.91e6 s** on this card.
  Profiled seconds are scaled to it by ×1.113 (the profiled field minus its count probe is 55.65 s; as in L51, the profile's
  syncs make the profiled field faster than the unprofiled one).
- **Against the director's estimate:** pairs 2.6e13 → 2.47e13 [M] ✓; survivors 6.7e11 → **9.53e11** [M] (+42 %; L51's L30
  field had 1.02e12); 0.8 ps per pair and 36 ps per survivor were 180 W numbers (L51: 0.78 ps at ~1,400 MHz; here 0.563 at
  ~1,920 MHz). Per-pair and per-survivor costs transfer between boxes only as ratios.

## 2. The tile harness (step 2)

### 2.1 What it is

`common/src/n1_tile.rs` (fork `exp/n1-gpu-tile`), test `n1_tile::tests::n1_tile_harness`, one comptime kernel
`tile_kernel` per (word, AND group, transpose gate, walk, no-AND). It is the production `join_kernel`'s dense phase with
the production code copied: per work item a bucket of `nbat` batch-side items loaded **256 at a time as the production
8-word top records** (words 2–7: mask bit-reversed into shared memory, range words with the clip test, id, D → the lean
prefilter's `t_dm`, seed → `t_glo/t_ghi`), the production **transposed copy** (`TRANSPOSE_MIN` 192, below it the per-top
AND), then **waves of 512 register-side items (EPT 2)** loaded through a list index from `ext_m`/`ext_q`/`bp_r`-shaped
arrays with the production key-level arithmetic, the production **AND over AND_GROUP chunks per set-bit iteration**, the
clip-word range test and the popcount. The production stage's 8 KiB of shared memory is kept so occupancy is the
production 5 cubes per SM (shared-memory bound). Survivors are counted (popcount), not walked, unless `walk` is set
(production walk rounds + `walk_pf_lean`, prefilter passes counted, not staged). Masks are random digit sets of exactly
D_B / D_T of 62 digits; tops' digit count is fixed (production's varies; the fixed mean is an assumption).

- **u64 words**: `t_tr` as 64-bit words (64 tops per chunk; each thread builds one digit's word of 64 tops); AND group 2
  (128 tops per set-bit iteration, as today) or 4 (256); pass masks u64, walked as two 32-bit halves.
- **Orientation is the data**: today's = tops on the batch side (transposed, D_T digits), bottoms in registers (D_B);
  reverse = bottoms transposed in chunks of 32/64, tops in registers ORing one word per digit of their own mask.
- **Correctness:** the AND survivor counts are identical across u32 / u64 AG 2 / u64 AG 4 and transposed / per-top paths
  for the same data (e.g. `T_B18_T17_S1` 46,394,174 in all three words; `T_B20_T15_S2` 53,014,699 in all six variants), and
  the pass rates equal the hypergeometric ones (C(62−D_T, D_B)/C(62, D_B): 1.331 %, 2.419 %, 0.247 %, 0.093 % …).
- **Layout of the register-side gather** (process-level, `NICE_N1_LGAP`): **L1** = each bucket's list indices increasing
  by 1 (contiguous: the transversal design's materialised lists), **L5** = increasing with mean gap 5, **L53** = mean gap
  53 (production's arithmetic: a bucket's ~330 entries spread over its class segment of ~17,900 in a 1.07 M-entry slot)
  but without production's cross-bucket L2 sharing. Pools: 1,071,229 register-side items (one slot's bpre), 4 Mi
  batch-side records (128 MiB).
- Timing: one launch of ~5e10 pairs (25–100 ms) per measurement, mean of 3 launches per round, **5 rounds per process,
  configurations interleaved (order rotated per round), every grid at least 2 processes** (L1 and L5); per-process JIT
  replay (`*_jit.txt`): every harness kernel in every process allocated without spills (u32 37 regs, u64 AG 2 40, u64
  AG 4 48, walk 44; none `local>0`). Spreads below are min–max over all rounds of all processes.

### 2.2 Calibration of the harness against step 1 (D_B 12, u32, today's orientation)

| layout | 471 × 336 (today's mean), D_T 17 | vs production 0.563 | 2,000 × 350, D_T 17 |
|---|---|---|---|
| L53 (production's gap, no L2 sharing) | 1.088 [1.088–1.089] | +93 % | 1.032 |
| L5 | 0.517 [0.515–0.529] | −8 % | 0.468 |
| **L1 (contiguous)** | **0.455 [0.450–0.461]** | **−19 %** | 0.414 |

Base / AND split (T2's no-AND mode; base = everything but the AND, with one shared read per chunk kept), 471 × 336:

| | base ps/pair | AND ps/pair |
|---|---|---|
| production (z, a − z) | 0.261 | 0.302 |
| harness L1 | 0.243 (−7 %) | 0.211 (**−30 %**) |
| harness L5 | 0.483 | 0.028 (hidden under the loads) |

**Verdict, plainly: the harness reproduces production's dense cost per pair within 20 % only in the L1 layout, at −19 %,
and its AND is 30 % cheaper than production's.** L5's −8 % is a coincidence of a load-bound kernel (its AND costs almost
nothing because it overlaps the gather), so it is not used for costs; L53 shows that a scattered gather without production's
L2 reuse is a different, load-bound kernel (its numbers are upper bounds, not costs). L1 has production's base within 7 %,
and the AND gap has a measured candidate cause:

### 2.3 Why production's AND costs more: small buckets (L1, D_B 12, u32, 336 entries; ps per pair) [M]

| tops per bucket | 471 | 400 | 300 | 192 | 150 | 100 | 60 |
|---|---|---|---|---|---|---|---|
| production gate (TRANSPOSE_MIN 192) | 0.457 | 0.573 | 0.520 | 0.535 | **0.848** | **0.902** | **0.973** |
| always transposed | 0.457 | 0.511 | 0.539 | 0.535 | 0.634 | 0.633 | 0.920 |

Production's buckets are a distribution around 467 tops; a bucket or remainder batch under 192 tops takes the per-top
AND at up to twice the per-pair cost (L51: 5–15 % of production's pairs are not in transposed batches). A single
mean-shape tile has none of them. This is consistent with the −30 % AND gap but does not prove it (the production
distribution was not measured). (Side note: at 100–150 tops the transposed form is 26–30 % cheaper here; L51's
TRANSPOSE_MIN 128 screen found +0.5 % on the field, so this is not a lever for today's kernel.)

How the projections use this: **central** = harness base × 1.073 + harness AND × 1.433 (each part scaled by production ÷
harness at today's shape, i.e. assuming the new shape's tiles vary as much as today's buckets); **same-layout** = the whole
harness number × 0.563/0.455; **optimistic** = the harness as measured (L1, no correction).

### 2.4 Dense phase per pair by digits, word width, orientation and tile (L1, the primary table) [M]

ps per pair, median [min–max over rounds, 2–6 processes]; the full table with per-process medians, L5 and L53, is
`raw/tables.txt`. Ratios inside the harness are the primary result (today's mean tile, u32, D_B 12 = 0.455; brief's 2,000 ×
350 = 0.415).

D_T 17:

| orientation | tile | word | D_B 12 | D_B 18 | D_B 20 |
|---|---|---|---|---|---|
| today | 2,000 × 350 | u32 (AG 4) | 0.415 [0.405–0.420] | 0.524 [0.515–0.531] | 0.558 [0.554–0.567] |
| today | 2,000 × 350 | u64 AG 2 | 0.362 [0.353–0.366] | 0.447 [0.444–0.457] | 0.476 [0.474–0.478] |
| today | 2,000 × 350 | u64 AG 4 | 0.331 [0.328–0.337] | 0.391 [0.389–0.396] | 0.410 [0.406–0.416] |
| today | **1,460 × 14,750** | u32 (AG 4) | 0.322 [0.312–0.331] | **0.410 [0.402–0.423]** | 0.437 [0.433–0.444] |
| today | 1,460 × 14,750 | u64 AG 2 | 0.303 [0.293–0.306] | 0.376 [0.373–0.381] | 0.400 [0.397–0.404] |
| today | 1,460 × 14,750 | u64 AG 4 | 0.272 [0.270–0.274] | **0.323 [0.320–0.328]** | 0.339 [0.337–0.343] |
| today | 785 × 14,750 | u32 / u64 AG 2 / u64 AG 4 | — | 0.397 / 0.333 / 0.279 | — |
| today | 24 × 7,200 (per-top, as gated) | u32 / u64 AG 2 / AG 4 | 1.108 / 1.142 / 1.148 | 1.110 / 1.144 / 1.145 | 1.109 / 1.142 / 1.147 |
| today | 24 × 7,200, forced transpose | u32 / u64 AG 2 / AG 4 | 1.502 / 1.338 / 1.978 | 2.010 / 1.734 / 2.520 | 2.184 / 1.870 / 2.663 |
| reverse | 2,000 × 350 | u32 / u64 AG 2 / AG 4 | 0.433 / 0.451 / 0.406 | 0.434 / 0.453 / 0.409 | 0.436 / 0.455 / 0.410 |
| reverse | **1,460 × 14,750** | u32 (AG 4) | 0.400 [0.396–0.408] | **0.410 [0.401–0.414]** | 0.407 [0.401–0.414] |
| reverse | 1,460 × 14,750 | u64 AG 2 | 0.339 [0.329–0.343] | 0.340 [0.337–0.343] | 0.342 [0.340–0.344] |
| reverse | 1,460 × 14,750 | u64 AG 4 | 0.292 [0.287–0.299] | **0.295 [0.288–0.298]** | 0.293 [0.288–0.299] |
| reverse | 785 × 14,750 | u32 / u64 AG 2 / AG 4 | — | 0.436 / 0.372 / 0.327 | — |
| reverse | 24 × 7,200 | u32 / u64 AG 2 / AG 4 | 3.394 / 2.946 / 2.760 | 3.393 / 2.967 / 2.762 | 3.398 / 2.971 / 2.769 |

D_T 15 (only the reverse orientation, whose register side is the tops, moves): 1,460 × 14,750 reverse u32 0.369 / 0.376 /
0.375, u64 AG 2 0.312 / 0.312 / 0.312, **u64 AG 4 0.278 / 0.278 / 0.278** (D_B 12 / 18 / 20); today's orientation within
±0.005 of the D_T 17 values (e.g. u64 AG 4 0.273 / 0.322 / 0.339). 785 × 14,750 D_T 15: today u64 AG 4 0.280 (D_B 18),
0.296 (D_B 20); reverse 0.308 / 0.311.

Base / AND split at 1,460 × 14,750 (T2, D_T 17) [M]: today's orientation base **0.103** (against 0.243 at 471 × 336);
AND u32 0.218 / 0.303 / 0.333 (D_B 12 / 18 / 20: 17–18 fs per entry digit), u64 AG 4 0.169 / 0.220 / 0.236 (12–14 fs).
Reverse: base 0.155; AND u32 0.246 (14.5 fs per top digit, D_T 17), u64 AG 4 0.133 (7.8 fs).

Tile-size scan around f0 4, k 9 (L1, D_B 18, D_T 17, 2 processes × 5 rounds; `raw/tsize.txt`) [M]: entries 7,375–29,500
change nothing (±3 %); 3,688 costs +3–5 %. Tops matter through the last batch: today's orientation u64 AG 4 is **0.274 at
730 tops** (2 × 256 + 218, all transposed), 0.325 at 1,460 (180-top remainder takes the per-top AND), 0.293 at 2,920, 0.41
at 365; u32 0.40–0.42 at 730–2,920, 0.44–0.47 at 365; reverse u64 AG 4 0.28–0.29 from 1,460 tops up, 0.33 at 730, 0.37 at
365 (a wave of 512 lanes holds the tops). So the 1,460-top point is representative to ±10 %, on the dear side for today's
orientation in u64.

Readings:
- **The AND part scales with the register-side digit count, the per-wave base does not.** Going from today's tile to the
  big tile removes 58 % of the base (wave padding 35 % → 1 %, one entry load per 256 tops, few work items), which pays for
  the 50 % more digits of k 9: **u32 at D_B 18 in the big tile costs 0.90× today's tile at D_B 12; u64 AG 4 0.71×; the
  reverse u64 AG 4 0.65×.**
- **u64 helps only with AND group 4** (256 tops per set-bit iteration: the iteration's ~11 instructions amortised over
  twice the tops); u64 AG 2 is 6–15 % cheaper than u32, AG 4 16–25 %. It costs 48 registers (still 5 cubes per SM, the
  shared-memory bound).
- **Reverse vs today's orientation** at the new tile: equal in u32 at D_T 17 (0.410 both, D_B 18), reverse ahead in u64
  (0.295 vs 0.323) and with D_T 15 (0.278); it loses on small top counts (lanes idle).
- **k 10's 24 × 7,200 tile loses outright** (≥ 1.1 ps per pair in either orientation, ×2.7–11 the big tile's cost).
- The L5 tables (`raw/tables.txt`) are 0.38–0.47 in the big tile, nearly flat in digits and words: there the loads hide
  the AND. They are not the cost model (§2.2); they show that a GPU whose gather is slower than this 3080's L1-layout one
  gains less from u64.

## 3. Survivor handling at the new density (step 3) [M]

The real walk (production plane rounds with `sync_plane`, `walk_pf_lean` on every AND survivor; passes counted instead of
staged) driven from the harness on random masks, at five densities (D_B/D_T 12/15, 12/17, 18/14, 18/15, 20/15 → 2.42 %,
1.33 %, 0.395 %, 0.247 %, 0.106 %), tiles 2,000 × 350 and 1,460 × 14,750, both orientations, u32 and u64 AG 2, layouts L1
and L5 (`twalk_*`; walk minus dense, same process and round). Table `raw/tables.txt` § survivor path.

| 1,460 × 14,750, L1 | pass 2.42 % | 1.33 % | 0.395 % | 0.247 % | 0.106 % | fit (ps/pair) |
|---|---|---|---|---|---|---|
| today, u32: ps per pair | 0.455 | 0.340 | 0.203 | 0.171 | 0.123 | 0.134 + 14.36 × pass |
| · ps per survivor | 19.3 | 26.1 | 51.3 | 70.3 | 117 | |
| today, u64 AG 2: ps per pair | 0.449 | 0.335 | 0.201 | 0.170 | 0.124 | 0.135 + 13.96 × pass |
| reverse, u32 | 0.463 | 0.346 | 0.206 | 0.168 | 0.123 | 0.138 + 14.35 × pass |
| reverse, u64 AG 2 | 0.466 | 0.346 | 0.219 | 0.186 | 0.144 | 0.155 + 13.71 × pass |

- **Check against production:** the 2,000 × 350 L1 u32 fit (0.150 + 13.78 × pass) gives **0.682 ps per pair at
  production's 3.87 %, against the measured 0.673 (−1.4 %)**. The harness reproduces production's survivor path; the
  projections still scale by the 0.986.
- **At the new density the walk is a per-pair cost, not a per-survivor one:** 0.13–0.15 ps per pair is paid whether or not
  a bit is set (per chunk and entry slot: the plane vote, the loop, the barrier; at 0.34 % a 32-top chunk mask of a lane is
  non-zero 10 % of the time, but a plane runs a round when any of its 32 lanes has a bit). At f0 4, k 9 (pass 0.34 %) the
  survivor path is **0.18 ps per pair = 54 ps per survivor** (f0 3: 0.30 %, 0.177 ps, 59 ps), against 0.673 ps per pair /
  17.4 ps per survivor today. **Survivors fall ×10.8 per base, the survivor path only ×3.2–3.5.** (Cheaper walk idea, not
  priced: one plane ballot per chunk over both entry slots instead of a vote per slot.)

## 4. Optional: certifying the 62 children of a certified top (step 4) [E]

Today's FD top test (0.158 ns per test on this card = L51's 0.21 ns at 180 W [D]) is `top_fd_step` (five packed-digit
vector additions: square ~6 words, cube ~9 words, ~7 instructions a word: ~160 instructions) plus `cert_power_fd` per power
(a scan of 4–5 packed words from the top digit, ~10 instructions per digit in the run, plus `add_scaled_pow` of every word
below the certificate into the binary remainder: ~250–350 per power) plus the group append: ~800–900 instructions.

A child of a certified f0 4 top, n ∈ [(P·b + c)·b³, (P·b + c + 1)·b³): its powers are (P·b + c)^k·b^(3k), so the c-step is
the same finite-difference step as today's partition step over the packed digits (~160; the low digits change too, so the
step cannot be confined to a window). Only the certificate gets cheaper: the parent's certificate depth is known, so the
scan starts there (1–2 words per power instead of 4–5) and the remainder below it can be stepped in binary with the same
increments (a 2–3-limb add and a compare per power) instead of being rebuilt from the digits. **≈ 160 + 2 × (60 + 20) + 40
≈ 360 instructions against ~850: about 0.45 of a full test (range 0.3–0.6), i.e. ~0.07 ns.** At f0 3 with 5e15 tests per
base this takes the tops from 7.9e5 s (40 % of the new total) to 3.8e5 s: **f0 3, k 9 goes from ×3.19 to ×4.09 (u64,
today's orientation) and from ×2.81 to ×3.50 (u32)**. The FD kernel's measured time is ~3× its issued instruction count
(108 registers, low occupancy), so the true ratio may differ either way; it needs a prototype.

## 5. Whole-base b62 projection [D]

`raw/scripts/project.py raw/box` → `raw/projection.txt` (every variant, D_B 18/20, D_T 17/15, three calibrations,
sensitivities). Model per base, with today's measured pieces in this card's seconds (base 5.91e6 s = 95,430 × 61.93 s):

| term | today [D] | new: how [D/A] | f0 4, k 9 | f0 3, k 9 |
|---|---|---|---|---|
| dense | 1.475e6 (25.0 %) | pairs [A: 8.0e-3 / 4.3e-3 × 3.13e20] × harness ps (§2.4, L1) calibrated (§2.3) | 1.19e6 (u64 today) – 1.53e6 (u32 today) | 0.55e6 – 0.80e6 |
| survivor path | 1.763e6 (29.8 %) | pairs × walk fit at the new pass (§3) × 0.986 | 0.50–0.55e6 | 0.26–0.29e6 |
| tops | 1.341e6 (22.7 %) | tests [A: 1.4e14 / 5e15] × 0.158 ns (today's FD s ÷ 8.9e10 tests a field [A]) | 2.2e4 | 7.9e5 (child certs at 0.45 [E]: 3.8e5) |
| check | 6.82e5 (11.5 %) | a tenth [A] | 6.8e4 | 6.8e4 |
| bottoms | 1.93e5 (3.3 %, bucket kernel) | 1.5e15 [A] × 44.6 ps (today's bucket kernel per extension [D]) | 6.7e4 | 6.7e4 |
| other | 4.56e5 (7.7 %: slice setup, inputs, reads) | 2 % of today [A] (units of ~1 ms, setup gone) | 1.18e5 | 1.18e5 |

Speedups (central = part-calibrated / same-layout / optimistic = harness as measured), D_B 18, D_T 17:

| variant | f0 4, k 9 | f0 3, k 9 (full FD tops) | f0 3, k 9 (child certs 0.45 [E]) |
|---|---|---|---|
| today orientation, u32 | **×2.56** / ×2.69 / ×3.08 | **×2.81** / ×2.89 / ×3.11 | ×3.50 / ×3.63 / ×3.97 |
| today orientation, u64 AG 2 | ×2.76 / ×2.85 / ×3.24 | ×3.02 / ×3.08 / ×3.28 | ×3.83 / ×3.91 / ×4.25 |
| today orientation, u64 AG 4 | **×3.01** / ×3.13 / ×3.53 | **×3.19** / ×3.24 / ×3.43 | **×4.09** / ×4.19 / ×4.51 |
| reverse, u32 | ×2.61 / ×2.68 / ×3.06 | ×2.74 / ×2.79 / ×3.01 | ×3.39 / ×3.46 / ×3.81 |
| reverse, u64 AG 4 | **×3.20** / ×3.20 / ×3.58 | ×3.05 / ×3.05 / ×3.24 | ×3.87 / ×3.87 / ×4.19 |

- D_T 15 adds 0–0.1 (reverse u64 AG 4 at f0 4: ×3.30); D_B 20 subtracts 0.05–0.1 (today u64 AG 4 at f0 4: ×2.92).
- **Other overhead** 0 % instead of 2 %: +5–7 % (f0 4 u64 today ×3.21, u32 ×2.70); at today's 7.7 %: −15 % (×2.57, ×2.23).
- Child-certificate cost at f0 3: 0.35 → ×4.33 / ×3.67 (u64 / u32, today's orientation); 0.6 → ×3.78 / ×3.27.
- Reading: **the dense phase becomes the majority of the new base (55–66 %) and is where the ×3 is decided**; the survivor
  path is the second term (22–30 %) because of the walk's per-pair floor (§3); tops, checks, bottoms and overhead are
  ~12 % at f0 4. At f0 3 the pairs halve (4.3e-3) and the tops come back (40 %), so f0 3 is better than f0 4 exactly when
  child certification is cheap.

## 6. What the model misses (my judgement)

1. **Counts are the director's model** (pairs, survivors, top tests, bottoms per admissible n), not a prototype; the
   ×3 margin is smaller than their plausible error. The model reproduced today's pairs within 5 % but today's survivors
   only within 42 % on this field (6.7e11 vs 9.53e11).
2. **The harness's calibration is borderline** (−19 % in total, −30 % in the AND); the central projection assumes the new
   shape's tiles vary as much as today's buckets. The transversal unit's tiles (per residue-class pair of one partition
   value) could be more uniform, which would move it toward the optimistic column (+0.3–0.5 in speedup).
3. **List building and memory of the transversal unit are not in it**: materialising 1.5e15 bottoms (16 B) and the tops
   per unit, sorted into tiles, is ≥ 2.4e16 B written and read once more (≈ 3–6e4 s at 760 GB/s, ~1 % of today), plus
   per-unit launches (9.2e8 units; at 10–20 µs of fixed cost each, 0.9–1.8e4 s). Both fit in the 2 % "other", barely.
4. **L1 assumes contiguous bottom lists**; if the new unit gathers entries through an index as today (L5-like), the u64
   gains shrink (L5: 0.38–0.47 in the big tile, nearly flat across words), i.e. the design must lay bottoms out contiguously per tile.
5. **Survivors are uniform in the harness**; production's cluster (correlated digits). The walk fit matched production at
   today's density, but at 0.3 % clustering would lower the per-pair floor's share (fewer chunks with a lone survivor):
   in the new design's favour.
6. **The prefilter and check at k 9** are taken as today's per survivor and a tenth of today's checks; k 9 changes the
   middle digits (k..k2) the prefilter tests, so its pass rate (≈ 6 % assumed) and cost per survivor are assumptions.
7. **One card, one clock**: 340 W 3080 at 1,825–1,920 MHz. Ratios between variants should transfer to other CUDA cards;
   u64 shared words are CUDA only (WebGPU/Metal get the u32 column, i.e. ×2.6–2.8), and a load-bound GPU sees less of the
   big tile's gain (L5 column).
8. **Not measured:** child certification (estimate only), the real tile-size distribution of the new shape, staging, the
   bucket/list kernels of the new design, b60/b64.

## 7. Files

- `RESULTS.md` (this), `BRIEF.md`.
- `raw/analysis.txt` (`analyze.py raw/box`: calibration + every harness row), `raw/tables.txt` (`tables.py raw/box`: §2–3
  tables incl. L5/L53, D_T 15, per-process medians), `raw/projection.txt` (`project.py raw/box`, with CHILD/OTHER
  sensitivities), `raw/tsize.txt` (tile-size scan), `raw/n1_tile.rs` (the harness source as built for T2).
- `raw/box/`: the box's logs — `cal_<mode>_r<n>.{log,smi}` + `_jit.txt` (calibration chain), `tcal_*`, `tgrid{17,15}_L{53,5,1}_p{1,2}`,
  `twalk_L{5,1}`, `tbase_L{5,1}_p{1,2}` (T2), `tf03_L{1,5}_p{1,2}`, `tptop_L{1,5}_p1`, `ttsize_L1_p{1,2}`, `mem_*`/`smoke1`
  (first layout probe, superseded by `tcal_*`), `build_*.log`, `trees.txt`, `power.txt`, `box-info.txt`, `nvidia-smi.txt`.
- `raw/scripts/` (run on the box from `/root/n1`): `setup.sh`, `build.sh`, `run.sh` (production harness), `tile.sh`
  (tile harness), `cfgs.py` (configuration sets), `chain_cal.sh`, `chain_tile.sh` (stopped after its L53 grids, replaced
  by `chain_tile2.sh`), `chain_base.sh`, `chain_f03.sh`, `chain_ptop.sh`, `ptxjit.py`/`cbor_min.py`/`jitlog.py` (L45's),
  `analyze.py`, `tables.py`, `project.py`, `pull.sh`, `ssh.sh`.
- Fork branch `exp/n1-gpu-tile` `c81875f` (harness only; experimental, no PR). The box can be destroyed: everything is in
  `raw/box/`, nothing is running on it.
