# L44 ROADMAP: where the time goes after the November stack, and the shortlist for next week (2026-11-06)

Analysis only: no GPU, no builds, no pushes. Every number is tagged **[M]** measured (by the lead cited), **[D]**
derived by arithmetic from measured numbers (derivation given), or **[E]** estimate (a model or an assumption).
The arithmetic is `raw/scripts/budget44.py` (output `raw/budget44.txt`); `raw/scripts/loops.py` reads the SASS
loops of the check and fill kernels (`raw/sass/`, unpacked from `L41/raw/box/sass/B/`, the post-#241 base);
`raw/cubecl_join_main.rs` is `git show origin/main:common/src/cubecl_join.rs` (6f060a9).

"Post-stack" = upstream main 6f060a9 (#215, #216, #222, #235–#240) + #241 (top record) + #246 (lean prefilter).
#247 (CPU FD tops) does not touch the GPU path. G-cycles = device seconds × mean SM clock in GHz.

## Summary

- **The post-stack b62 1e17 field on a 180 W RTX 3080 is 100.4 s [M] (147.8 G-cycles)**; b60 1e16 19.65 s [M]
  (28.9 G). By phase [D]:

  | phase | b62 1e17 s | share | b60 1e16 s | share |
  |---|---|---|---|---|
  | top: FD kernel incl. seeds | 26.0 | 25.9 % | 4.15 | 21.1 % |
  | top: scan + fill + clipped launches (residual; two routes agree) | 8.7 | **8.7 %** | 1.40 | 7.1 % |
  | bucket | 2.2 | 2.2 % | 0.39 | 2.0 % |
  | join: base (work items, top batch, wave loads, chunk bookkeeping) | 20.9 | 20.8 % | 4.68 | 23.8 % |
  | join: AND | 1.1 | 1.1 % | ~0 | ~0 % |
  | join: walk rounds (vote, pop, loop) | 8.9 | 8.8 % | 1.49 | 7.6 % |
  | join: prefilter (`walk_pf_lean`) | 14.8 | 14.7 % | 3.80 | 19.3 % |
  | join: stage + flush | 3.6 | 3.5 % | 0.49 | 2.5 % |
  | check | 9.5 | **9.5 %** | 2.25 | **11.4 %** |
  | other (upload per slice, per-batch inputs, read, gaps) | 4.8 | 4.8 % | 1.01 | 5.1 % |

- **Cycles do not depend on the cap** [M]: #241's b62 1e17 field is 158.5–164.4 G-cycles in seven runs on four boxes
  at 150, 180 and 320 W. So the shares above hold at any cap; only the clock moves (post-stack b62 1e17 ≈ 111 s at
  150 W, 100.4 s at 180 W, ≈ 80 s at 320 W [E]), and the clock depends on the code's power density (§1.5).
- **Four findings that change the plan:**
  1. **The top phase's non-FD part, top scan + top fill, is ~8.7 % of b62 1e17 and ~7 % of b60** [D], untouched by
     every lead since L31 measured it at 0.22–0.26 ns per kept top (then 4.9 % of a b62 1e16 field). It is two
     returning global atomics and two scattered stores per kept top. A static bucket order of the top layer removes
     it (§3e, shortlist 1).
  2. **The check is 9.5 % / 11.4 %** [D], double its share when L4 was closed (3–5 %). Its grid (1024 cubes) runs 3
     waves where 2.51 are needed on a 3080 (6 cubes per SM), and it re-derives the 8 low digits of n² that the join
     already proved distinct; the n² scan does not use n³'s known low digits (§3c, shortlist 4).
  3. **The join is its instruction count plus a constant ~34 G-cycles (23 s, 23 % of the field)** [D]: L41's issue
     model predicts #246's measured saving to 95 % (15.0 of 15.8 G), and the non-issue remainder was the same before
     and after #246 (34.5 → 33.9 G). That remainder is SM-clock-bound (not DRAM: cycles are cap-invariant) and
     unattributed; per-chunk barrier waits are the leading suspect (§1.4, shortlist 5).
  4. **FD persistence across batches is not worth ×1.035** (L35) or ×1.022 (L36): both priced the seed's compute and
     the memory capacity, not the per-batch load and store of the state, 1.07 GB per b62 1e17 batch (6.9 TB per
     field). Revised net −1 % to +2 % [E] (§2, bundle A).
- **Bundles of parked items:** the top-kernel bundle reaches ×1.05–1.07 only with persistence swapped out for two
  more stepped-slot trims and more slots per batch (shortlist 2). The lean-body join bundle (TT2 + WH + COMPACT=2 +
  group walk) is ×1.01–1.03 at best and breaks the 48-register budget: no-go (§2).
- **Shortlist** (§4): (1) static bucket order of the top layer, gated on a 1–2 h measurement, ×1.05–1.12 [E];
  (2) FD top kernel round 2, ×1.05–1.07 [D/E]; (3) the CPU lean prefilter on #247, CPU join ×1.06–1.10 [D];
  (4) check kernel rework, ×1.045–1.07 [E]; (5) re-price the lean join (measurement, decides the 23 s).

## 0. Sources, their hardware, and what kind of number each is

All GPU numbers are an RTX 3080 10 GB under a host power cap (every timed run sat at its cap, `SW power cap`).

| source | what is used here | cap (box) | kind |
|---|---|---|---|
| L1 PROFILE-3 | counts per b62 1e17 field (30.64 M prefixes, 3,844 partitions, 6,439 batches, 6.57 slots, 3.82e10 tops); per-batch lever (−38 % batches ×0.994 ± 2.5 %) | 180 W (m139250) | [M] |
| L31 SCOPING | `top_scan` + `top_fill` = 1.17 s per b62 1e16 field (4.51e9 kept tops), 1.76 s per b60 1e16 field (6.87e9), profiled with one extra sync per batch, #235 tree | 180 W (m139250) | [M] |
| L35 | FD kernel per (prefix, slot): stepped 0.198 / seeded 0.350 ns (b62 1e17), 0.192 / 0.329 (b60); persistence ×1.035 | 180 W | kernel [M]; persistence [E] |
| L36 | all5 profile (binary = main 6f060a9's, md5 dee33bc6): b62 1e17 top 40.57 / bucket 2.56 / join 76.66 / check 11.16 / other 5.60 s; b60 likewise; stepped-slot ablation; three trims whole-field ×1.041 (b62), ×1.04 clock-matched (b60) | **150 W** (m137673) | [M] |
| L37 | join of main by ablation, cycles column: base 39.9 / AND 1.7 / walk 16.8 / prefilter 36.1 / stage 5.5 % (b62); base split (top gather 18.6 s, entry loads 10.5 s); lane utilisation 24.8 %; H1, H2, COMPACT=2 | **150 W** (m137672) | [M], stripped-kernel marginals |
| L38 (#241) | main 120.37 s @ 1427 MHz → 109.46 s @ 1502 (b62 1e17); b60 23.12 → 21.82 s | 180 W (m139246) | [M] |
| L39 | bottom record neutral; #241 at 320 W: 86.78 s @ 1882 MHz | **320 W** | [M] |
| L40 | group walk; walk counters (rounds per group); #241 at 150 W: 118.9 s @ 1379 | **150 W** | [M] |
| L41 SCOPING | SASS instruction/pipe model of the join (1.46e13 warp instructions per b62 1e17 field) | — | [E] (SASS counts × measured unit counts) |
| L41 RESULTS (#246) | #241 108.97 s @ 1501 → 100.38 s @ 1472 (b62 1e17); b60 22.04 → 19.65 s; screen per level; rounds unchanged | 180 W | [M] |
| L43 | TT2 + WH ×1.017 / ×1.019, AU and PC lose, registers | 180 W (m139246) | [M] |
| L42, #247 | CPU: FD tops ×1.25–1.29, lean prefilter ×1.05–1.08 standalone, FD + lean ×1.23–1.29 (prototype) | Zen 2, 4 vCPU | [M] |

## 1. The post-stack budget

### 1.1 Derivation (`raw/scripts/budget44.py`)

1. **Total** [M]: L41's A/B, PR side = #241 + #246: b62 1e17 100.383 s at 1472 MHz = 147.76 G; b60 1e16 19.649 s at
   1469 MHz = 28.86 G. (A later session on the same box: 97.99 s for the same binary, so ±2.5 % between sessions.)
2. **Phases that #241 and #246 do not touch** (top, bucket, check, other) [D]: L36's all5 profile shares (150 W) ×
   main's cycles at 180 W (L38: 120.369 s × 1.427 GHz = 171.77 G for b62 1e17; 33.55 G for b60). The all5 binary is
   main 6f060a9's byte for byte. L38 found the top kernels unchanged by #241 (±0.8 %), and #246 changes only
   `join_kernel`.
3. **The join, two routes** [D]: (1) total − untouched phases = 72.43 G (b62 1e17) / 15.36 G (b60); (2) main's join
   (56.1 % of 171.77 G) − #241's measured 7.36 G − #246's measured 15.80 G = 73.27 G / 15.53 G. **They agree to
   1.2 %**; the table uses route 1 (it sums to the measured total) with route 2's split scaled to it.
4. **Inside the join** [D]: L37's marginal costs in cycles (the order z → a → b → p → c); #241's 7.36 G off the base
   (it changed only the batch load); #246's 15.80 G split by L41's screen into prefilter (FX + MT + GM, 7.7 of 9.5
   points at b62; 11.6 of 13.7 at b60) and walk (RC, the residue test that left the round).
5. **Inside the top phase** [D]: the FD kernel from kernel-alone timings at 180 W (s = 0.197, g = 0.352 ns per
   (prefix, slot) at b62; 0.192 / 0.329 at b60; L35 and L38's `topt`) over the field's pairs (1.178e11; 1.908e10)
   at the field's mean slots per batch (6.57; 5.33), converted at ~1.47 GHz: 38.2 G / 6.1 G. The rest of the top
   phase is scan + fill + the clipped-block launches. **Cross-check:** L31 measured scan + fill at 0.22–0.26 ns per
   kept top at 180 W (with and without its extra sync's ~0.3 ms per batch); × 3.82e10 kept tops = 8.4–9.9 s at
   ~1.46 GHz = 12.3–14.5 G against the residual's 12.8 G. At b60: 1.4–1.8 s (with and without the sync) against the residual's 1.40 s.

### 1.2 b62 1e17 (one field, 180 W, at the post-stack clock 1472 MHz)

| phase | G-cycles | s | share | basis |
|---|---|---|---|---|
| **top** | 51.0 | 34.7 | 34.5 % | [D] L36 share × 180 W main |
| · FD kernel (stepped 19.7 s, seeds 6.3 s, of which 2.8 s is the seeds' excess over a stepped slot) | 38.2 | 26.0 | 25.9 % | [D] kernel timings × field counts, ±5 % |
| · scan + fill + clipped launches (≤ 22 early-exit launches a field, est. < 0.2 s) | 12.8 | 8.7 | 8.7 % | [D] residual; L31 scaled: 12.3–14.5 G |
| **bucket** | 3.2 | 2.2 | 2.2 % | [D] |
| **join** | 72.4 | 49.2 | 49.0 % | [D] two routes ±1.2 % |
| · base (work items, top batch + transposed copy, wave loads, per-chunk stage check) | 30.8 | 20.9 | 20.8 % | [D] L37 − #241; a first-added marginal, see §1.4 |
| · AND (#239's transposed ORs) | 1.6 | 1.1 | 1.1 % | [D] cycles; 3.3 s in time-equivalent (its power costs clock) |
| · walk rounds (vote, guard, pop; residue test gone with RC) | 13.1 | 8.9 | 8.8 % | [D] |
| · prefilter (`walk_pf_lean`) | 21.8 | 14.8 | 14.7 % | [D] |
| · stage + flush | 5.2 | 3.6 | 3.5 % | [D] |
| **check** | 14.0 | 9.5 | 9.5 % | [D] |
| **other** (upload 11× per field, 6 input buffers per batch, read, unattributed) | 7.0 | 4.8 | 4.8 % | [D] |
| **total** | **147.8** | **100.4** | | [M] |

Survivor path (walk + prefilter + stage) 40.0 G = 27.1 % of the field.

### 1.3 b60 1e16 (per field, 180 W, at 1469 MHz)

| phase | G-cycles | s | share |
|---|---|---|---|
| **top** | 8.15 | 5.55 | 28.2 % |
| · FD kernel (stepped 2.98 s, seeds 1.18 s; seeds' excess 0.49 s) | 6.10 | 4.15 | 21.1 % |
| · scan + fill + clipped (residual; L31 scaled 1.4–1.8 s) | 2.05 | 1.40 | 7.1 % |
| **bucket** | 0.57 | 0.39 | 2.0 % |
| **join** | 15.36 | 10.45 | 53.2 % |
| · base | 6.88 | 4.68 | 23.8 % |
| · AND (L37: −0.5 % of the join in cycles, i.e. 0 within noise; 4.4 % in time) | ~0 | ~0 (≤ 0.6) | ~0 % |
| · walk rounds | 2.19 | 1.49 | 7.6 % |
| · prefilter | 5.58 | 3.80 | 19.3 % |
| · stage + flush | 0.71 | 0.49 | 2.5 % |
| **check** | 3.30 | 2.25 | 11.4 % |
| **other** | 1.48 | 1.01 | 5.1 % |
| **total** [M] | **28.86** | **19.65** | |

All [D] as for b62. b60's prefilter is the larger share (its walk is the longest per group, 32.7 rounds against 24.0,
L40), its check is the larger share (more checks per prefix), and its top phase the smaller.

### 1.4 Inside the join: two accountings, and what is left unexplained

The L37 split is additive but order-dependent: the base was priced first, alone, where its latency is exposed. Its
removable cost is smaller; the realised cuts say so: #241 realised 36 % (cycles) of what L37 priced on the two extra
top arrays, L39 0 % of the entry loads' 10.5 s, WH (L43) ~31 % of it for 57 % of the wave loads. **L41's issue model
gives the other accounting** [D/E] (warp instructions ÷ 272 issue slots per clock; L41 budget units with the #246
round of 41 + 16 × 0.394 issued):

| unit | warp instructions per field | G-cycles at full issue |
|---|---|---|
| walk rounds (1.284e11 × 47.3) | 6.07e12 | 22.3 |
| AND groups | 1.92e12 | 7.1 |
| per chunk (stage check, 2 barriers, pass words, + RC) | 1.32e12 | 4.9 |
| per batch (gather, transposed copy, + `dh` and gating) | 7.5e11 | 2.8 |
| per wave (entry loads, key-level terms) | 3.6e11 | 1.3 |
| work items | 7e10 | 0.3 |
| **issue total** | 1.05e13 | **38.6** |
| **join, measured/derived** | | **72.4** |
| **non-issue remainder** | | **33.9 (23.0 s, 22.8 % of the field)** |

- **The model reconciles the measured cuts:** #246 predicted 15.0 G, measured 15.8 G (95 %); TT2 predicted 1.7 G,
  measured 2.0 G in time at the screen's clock (L43); WH 0.7 G of instructions + ~1.7 G of latency (measured 2.4 G);
  #241 cut no instructions and its 7.4 G came out of the non-issue part (42.7 → 34.5–35.3 G). The non-issue part
  stayed at 34–35 G through #246.
- **What the non-issue time is not:** DRAM time. Cycles are cap-invariant (§1.5), so it scales with the SM clock:
  dependency stalls, shared-memory and L2 latency, barrier waits, atomics, kernel tails.
- **Leading suspect: barrier waits at the per-chunk stage check** (two cube barriers per 32-top chunk, eight warps
  whose round counts differ: a plane runs 2.4× a lane's mean bits, L40). Evidence for: L40's group walk (stage checked
  once per four chunks) saved ~17.6 G in cycles against ~7.8 G by its issue count [D/E]. Evidence against: L37's mode 7
  (stage check every 4 chunks alone, on main) moved the join −1.7 %, noise-level. Shortlist 5 settles it.
- **Consequence for planning:** instruction cuts in the join pay about 1:1 in cycles, less the clock the cap takes
  back (§1.5). The AND's instructions (7.1 G) are mostly hidden behind the walk (its marginal is 1.6 G).

### 1.5 Wall time at a power cap, and the clock effects

- **Cycles are invariant across caps** [M]: #241 at b62 1e17: 164.0, 158.5, 163.0 G (150 W, three A/Bs), 163.6,
  163.0, 164.4 G (180 W, three boxes), 163.3 G (320 W); b60: 31.5–32.8 G across the same caps. So wall time =
  cycles ÷ mean SM clock; the shares in §1.2–1.3 are the wall-time shares at any cap, if every phase runs at the run's
  mean clock (per-phase clocks are not resolvable with 5-s sampling; L37's whole-run means by kernel mode at 150 W
  were AND-only 1189, no-AND 1273, full 1297 MHz, so LDS-dense phases may sit a few % lower).
- **Post-stack at the three caps:** b62 1e17 ≈ 111 s at 150 W (~1330 MHz [E]: #241 ran 1334–1379, #246 takes ~2 %),
  **100.4 s at 180 W** [M], ≈ 80 s at 320 W (~1845 MHz [E]: #241 ran 1882). b60 1e16 ≈ 21.7 / 19.65 / 15.6 s.
  Even the 320 W card sat at its cap (L39).
- **Clock effects seen** (the changed side's mean SM clock minus the base's, same cap, same box):

  | change | cap | Δ clock | cycles ratio | time ratio | share of the cycle gain kept in time |
  |---|---|---|---|---|---|
  | #241 top record (fewer L2/DRAM sectors per top listing) | 180 W | **+75 MHz** | ×1.034 | ×1.100 | **290 %** |
  | #240 FD top kernel (fewer wide multiplies and divisions) | 180 W | +21 | ×1.127 | ×1.143 | 113 % |
  | L36.2 FD trims | 150 W | ~0 | ×1.04 | ×1.041 | ~100 % |
  | #246 lean prefilter (same memory work in fewer cycles) | 180 W | −29 | ×1.103 | ×1.086 | 84 % |
  | L40 group walk (38 % of lanes busy instead of 25 %) | 150 W | −57 | ×1.120 | ×1.056 | 47 % |
  | L43 AU (denser LDS issue) | 180 W | −33 | ×1.018 | ×0.995 | < 0 |
  | L37 H1 compaction (12 shuffles a round) | 150 W | −71 | ×1.005 | ×0.940 | < 0 |

  **Rule** [E, from these seven]: cutting memory-side traffic buys clock (the change's time gain exceeds its cycle
  gain); raising the useful work per cycle in an issue-bound kernel spends clock (leaner code → lower clock: #246
  kept 84 % of its cycle gain, the group walk 47 %). Price ALU/issue trims at 50–85 % of their cycle gain in wall
  time under a cap.

### 1.6 Uncertainty, and where sources disagree

| item | spread | trusted, and why |
|---|---|---|
| total | ±2.5 % between sessions (100.4 / 98.0 s) | the interleaved A/B, 3 rounds, 0.1 % spread |
| untouched phases | ±1–2 points each | one profile (L36, 150 W); its total matched the unprofiled run at a matched clock (136.6 s excl. probe at 1213 MHz vs 140.1 s at 1184), so the profile's sync gaps are small; PROFILE-3's +7 % overhead was a slower, loaded host |
| join total | routes 1 and 2 differ 1.2 % | route 1 (sums to the measured total) |
| join parts | ±2 G each | L37's modes ±1–3 %, whole-run clocks for the cycle column ±2 %; #246's split from a 2-round screen whose GM point disagrees between bases (b62 +0.1, b60 +3.0) |
| base: 41 % (L37) vs ~10 G removable (realisations) | large | additive split from L37; removability from L38/L39/L43, which measured what the stripped kernel over-priced |
| AND: 5.1 % (time) vs 1.7 % (cycles) of the join | 3× | cycles for work; the time view includes the clock its LDS density costs the whole kernel |
| FD kernel 38.2 G, residual 12.8 G | ±2.5 G | the residual agrees with L31's directly measured scan + fill scaled by kept tops (12.3–14.5 G) |
| FD persistence: ×1.035 (L35) vs ×1.022 (L36) | | L36's seed count (field mean 6.57 slots, not the first slice's 5); both omit the state traffic (§2) |
| per-batch cost: profile intercepts 2.8 ms vs lever ≤ 1.8 ms | | the unprofiled lever (PROFILE-3 §6); the FD seed is a new per-batch cost since |
| check: PROFILE-3 slope 86.5 ps + 1.92 ms/batch vs ~51 issue slots per check by SASS (~61 derived) | | SASS (§3c); the intercept is likely collinearity (checks per batch are nearly constant across b62 fields) |

## 2. Bundles of parked items

**A. Top kernel: L36.2 trims + FD persistence** (the brief's example).
- Trims (LC0 carried c0 and b^c0 − d, LSCAN bookkeeping-free scan path, LCLIP no a/e on steps): [M] whole field on
  all5 at 150 W, b62 1e17 −6.3 G-cycles (per round −5.8, −6.3, −8.6 G), b60 −1.3 G (−0.7 to −1.4). The FD kernel is
  unchanged by #241/#246 (L38), so the cycles transfer: **×1.04–1.045 at b62 1e17, ×1.025–1.05 at b60** [D].
- Persistence: L35 (×1.035) and L36 (×1.022) priced the seeds' compute and ~700 MB of capacity. **Not priced: the
  state has to be loaded at each batch's start and stored at its end**: 192 B × 2 × 2.79 M prefixes = **1.07 GB per
  b62 1e17 batch, 6.9 TB per field** [D], ~1.4 ms at peak bandwidth against the FD kernel's ~4.0 ms per batch, to
  save 0.43 ms of seed work. Overlappable in principle (the kernel is compute-bound), but ~270 GB/s during the FD
  kernel is ~15 W at ~7 pJ/bit [E], 8 % of a 180 W cap, and the cap turns watts into clock (§1.5). **Net −1 % to
  +2 % [E].** A 48-byte state (P² and P³ digits only, the rest rebuilt by digit additions) cuts the traffic to a
  quarter; still ≤ 2 %.
- Independent of each other (trims cut the stepped slot, persistence turns seeds into steps); FD kernel at 110
  registers, 2 blocks/SM, LC0 −5; no small-bucket exposure; NiceMark gets the trims only (its bit-reversed samples
  seed every slot).
- **Honest bundle: ×1.04–1.06 at b62 1e17, ×1.03–1.06 at b60 [E] — does not reliably clear 5 %.** Swap persistence
  for (i) the append's plane scans as a ballot + popcounts and (ii) x mod b^c0 from the words just below c0 (L36
  §4(e): "a few %" and 3–6 % of the 29 G stepped slot), and (iii) more slots per batch (SURV_PER_PREFIX 2 → 1:
  PROFILE-3 measured 6,439 → 3,974 batches, 10.6 slots on average, the first plan at 2,451 of 2,560 MiB; seeds −38 %
  = −1.6 G; the same knob was ×0.994 ± 2.5 % before the FD kernel made seeds a per-batch cost): **×1.05–1.07 / ×1.04–1.065
  [E]** → shortlist 2.
- To measure: rebase `exp/top-fd-ablate` (47c1b36, switches 512/1024/2048) onto #241; add switches for (i), (ii) and
  a dummy-state switch (load and store 192 B per prefix per batch, result unused) that prices persistence's traffic
  in one kernel-alone run; then a whole-field A/B.

**B. Join on the lean body: L43's TT2 + WH + L37's COMPACT=2 + L40's group walk.**
- TT2 + WH: [M] ×1.017 / ×1.019 (b64 ×1.059), NiceMark ×1.024, MSD-strong ×0.998, on #241. The same 2.6–2.7 G on
  the lean body → ×1.018 [E]. **Registers:** on #241 the pair kept 40 by spilling 8 B (ptxas aims at 6 cubes because
  CubeCL's shared memory is one dynamic array); WH alone took 47–48; #246 is 45, or 40 + 28–44 B of spills in about
  half of the compiles. Together past 48 → 4 cubes/SM, or more spills [E].
- COMPACT=2: [M] ×1.015 time but ×1.007 cycles on main; the lean round is 41 % cheaper in issue, so ~×1.005 [E];
  45 registers on main + FX's 5 → ~50. Drop.
- Group walk: rounds ×0.646 [M] at +10 (no pick) to +29 (pick) instructions a round; on the lean round of 47 issued
  that is −22 % to +4 % of the round's issue → ≤ 3 % of the field on large batches [E], the small-batch loss
  (MSD-strong ×0.963 [M]) unchanged, registers 46–47 + 5. Drop (L41 SCOPING's warning holds on this count).
- **Honest bundle: ×1.01–1.03 at b62 1e17 [E], with a register-budget failure likely. No-go.** TT2 alone (~1 %) is a
  rider for a future join PR. To measure if ever: one binary on #246 with `NICE_EXP_JOIN_WB` 17/2; a register gate
  (≤ 48, no spills, b60/b62/b64) before any timing; ~1 day, ~$0.8.

**C. Structural (per batch and per slice):** slots per batch 6.57 → 10.6, reuse of the six per-batch input buffers,
the next slice's upload overlapped with the current slice's last batches: FD seeds −1.1 %, inputs −0.5–1.5 %,
slice gaps −1–2.5 % [E] → ×1.02–1.045. Needs the unprofiled gaps measured (shortlist 5's session); the slots part
rides with shortlist 2.

**D. The check** (grid sizing + known low digits) and **E. static bucket order** are new directions, §3.

## 3. New directions (thought through, not prototyped)

**(a) The AND testing fewer digits per entry — no-go.** The AND is 1.1 % of the field by marginal cycles (≤ 4.8 % by
its instruction count, mostly hidden behind the walk). Digits that every top of a slice certifies are already gone
from the entries (#215's field-certificate prune), so the AND never sees them; skipping digits that no top of a chunk
has needs a per-digit test that costs what the OR does. Dropping one of the 12 digits raises the pass bits by
~1/(1 − p) with p ≈ 0.25–0.30 the chance a top certifies that value [E], i.e. ~+30 % walk rounds (+6–7 G) to save
~0.6 G. A stronger AND is not available: every other digit depends on the pair.

**(b) A cheaper or stronger exact prefilter — no-go now.** The lean body's 25 prefilter instructions per round
(3 LDS, 6 FMA, 2 + 4 + 2 for `seen` and the shifts, 7 compares) reject 93.9 % of lanes; popcount distinctness
costs the same (L41 §3.2); early exits do not pay in SIMT (all ~8 live lanes reject together in ~6 % of rounds, L41).
Rejection per instruction is already best for the membership part (≈ 7 instructions reject 60–85 %), and it is
folded in branch-free. Stronger, mid = 3: 32-bit fixed point fails at b³ (Δ < 2b⁶ ≈ 1.1e11 > 2^32), so u64 fixed
point, ~+16–20 instructions; for every lane +9.4 G against −6.3 G of checks (loss); only inside the pass branch (39 %
of rounds) +3.7 G against −6.3 G → ×1.00–1.02 [E], and less once the check is cheaper. Revisit after (c)/shortlist 4.

**(c) Fusing stage + check with the walk — no-go; the lever is the check kernel itself (go, after scoping).**
- In place: 0.49 checks per plane-round; one check is ~1,620 warp-instructions per warp-iteration [E, SASS below] at
  one or two live lanes, ~30× its compacted cost. At flush time (compacted, inside the join): the check's 9 KiB of
  shared memory per cube takes the join from 5 to 3 cubes/SM, to save the list round trip (~1 TB, ~1 %).
- **The check kernel as compiled** (b62, `raw/sass/check_kernel_b62_1.sass`, post-#241; `raw/scripts/loops.py`):
  712 instructions; the n² scan pass is a 214-instruction loop around a **49-instruction 64-bit division per limb**
  (28 `IMAD`). n² < 2^146 starts at 5 limbs and loses about one per pass (÷ 62^5 ≈ 2^29.8, 5 digits a pass), so a
  pass costs ~214–410 instructions. The join's survivors have digits 0–7 of n² and n³ distinct, but the scan seeds
  its duplicate mask with nothing and tests n² against itself only: the first possible rejection is at digits 8–9
  (pass 2), and because a warp runs until its last lane dies, warps run passes 1–4 always and pass 5 in ~80 % [E:
  random-digit model] → ~1,620 warp-instructions per iteration, ~51 issue slots per check, against ~61 derived from
  the budget (14.0 G-cycles for 6.26e10 checks) [D]. The check is issue-bound by its long divisions, and most of the
  cost is in passes 1–3, which every lane needs.
- **Grid:** `CHECK_CUBES` = 1024; at 38 registers and 256 threads the check fits 6 cubes per SM, 408 on a 3080:
  2.51 waves run as 3, ~16 % of the kernel idle [E] (a 4090's 768 slots: 1.33 → 2 waves).
- **Rework** [E, same model]: (i) a device-sized grid: −16 %. (ii) Skip the two low passes: n mod b^8 =
  (P mod b^5)·b³ + r0 gives n² mod b^8 and n³ mod b^8 cheaply (base-b^4 halves); subtract and divide n² exactly by
  b^8 = 2^8·31^8 (a shift, then two limb-wise exact divisions by 31^4 = 923,521: multiplies, no division); start the
  scan at digit 8 with the 16 known low digits of n² and n³ in the mask: ~1,620 → ~1,090 per iteration, −33 %.
  Seeding alone, without (ii), saves only ~4 %: the cost sits in the first passes. (iii) Also seed the top's
  certificate (record words 2–3, the sector P is read from), stopping each scan below the certified positions so no
  digit is counted twice: ~800 per iteration, −51 %. Together −44 % (i + ii) to −59 % (i–iii) of the check →
  **×1.045–1.06 (b62 1e17), ×1.05–1.07 (b60)** → shortlist 4. Exact by construction (the same digits, each tested
  once); the scoping must confirm the death-pass distribution on real survivors. L4 (closed: "the final check is
  3–5 % of GPU time") is reopened with this written reason: the share doubled and the check re-derives what the join
  proved.

**(d) The per-batch structure (6,439 batches) — no-go as a standalone lever, ~3–6 % in total now** [E].
- PROFILE-3 §6 (L1.7) bounded the non-FD per-batch cost at ≤ 1.8 ms (central ~0.5 ms) per batch, unprofiled [M]:
  ≤ 11.6 s, central 3.2 s, of today's 100 s field, i.e. ≤ 12 % / ~3 %; the same absolute seconds now weigh twice
  as much as on the 223 s field it was measured on.
- New since: **the FD seed is a per-batch cost**, (g − s) × prefixes per slice = 0.43 ms per b62 1e17 batch, 2.8 s
  (2.8 %) [D]; b60 0.49 s (2.5 %).
- Per batch the device also runs 6 small host-to-device creates, 6–7 kernel boundaries (the bucket kernel is a single
  partial wave of (b − 1)·slots = 305 cubes), and the check's wave quantization (c).
- Levers: more slots per batch (+1.1 %, rides with shortlist 2), persistence (no-go, §2A), buffer reuse
  (+0.5–1.5 %, host only), overlapping a slice's upload (+1–2.5 %, needs a second set of buffers). None reaches 5 %.

**(e) What grew in relative terms.**
- **Top scan + top fill: 8.7 % (b62 1e17) / 7.1 % (b60)** [D] (L31: 4.9 % of a b62 1e16 field on #235; unchanged
  code since). The fill (`raw/sass/top_fill_kernel_b62_1.sass`: 128 instructions, its root loop 4 `ATOMG` + 4
  `STG`) does, per kept top and root (nroots = 2 at b60/b62, 4 at b58, 8 at b64), a returning global atomic on a
  contended bucket cursor and a scattered 4-byte store into `tl`: ~7.6e10 of each per b62 1e17 field. It is latency-
  and atomic-bound, not issue-bound. **Go: static bucket order** (shortlist 1). A top's bucket at slot v is
  `key·(b−1) + (root − c − v) mod (b−1)` with key and c = `tl_m1·pdiv_m1 mod (b−1)` fixed per prefix
  (`top_fd_kernel`: `pc = (tl_m1·pdiv_m1 + v) % m1`). Sort each slice's top layer by (key, c) on the host once:
  for any slot, a bucket's tops are the kept members of nroots static groups. The FD kernel (and the clipped launch)
  appends kept tops per (slot, group) with one plane-aggregated atomic (a plane of sorted prefixes is almost always
  one group: ~740 prefixes per group at b62 1e17); `top_scan`, `top_fill`, `tl` (~145 MB per layout) and the 2
  `bucket_cnt` atomics per kept top go; the join reads a group's records contiguously instead of through `tl`.
  Exactness: the same (entry, top) pairs per bucket in a different order, which atomics already made arbitrary.
  Risks: tiny groups (b58 MSD-strong) make planes span many groups (segmented append, a per-lane fallback); nroots
  ranges per work item (8 at b64). Est. −10 to −17 G → **×1.05–1.12** [E, conditional on the fill's price].
- **The check: 9.5 % / 11.4 %** (4.1 % on main 04693ac, L36) → (c), shortlist 4.
- **The bucket kernel: 2.2 % / 2.0 %** (0.9 % on 04693ac): one partial wave per batch, independent of the top stage,
  so it could overlap the FD kernel, but CubeCL runs one stream. No-go now.
- **Other: 4.8 % / 5.1 %**: per-slice upload (11 slices, ~0.25 s each), per-batch input creates. Measure in shortlist
  5; bundle C.
- **Host MSD/interval setup:** 16 s of CPU per b62 1e17 field, overlapped with the device (each slice is prepared
  during the previous one; 6× headroom against 100 s). Not on the critical path, even with the CPU join beside it.

**(f) The clock/power angle — no standalone project; use it to price and to choose.**
- Rule from §1.5: memory-side cuts gain clock (#241 kept 290 % of its cycle gain), denser issue loses it.
- Power-heavy work, by the evidence: LDS-dense code (the AND-only kernel ran 84 MHz (b62) / 170 MHz (b60) below the AND-free one, L37;
  AU −33 MHz), shuffles (H1 −71 MHz), and L2/DRAM traffic (removing two sectors per top listing bought +75 MHz).
  Multiply-heavy FD code ran +21 MHz against the division-heavy `top_kernel`.
- Cheaper-in-watts formulations of the same work: the fill's returning atomics and scattered stores (removed by
  shortlist 1: expect a clock bonus like #241's); the check's random 32-byte gather of P per survivor (~2 TB per
  field; staging P with the survivor needs +2 KiB of join shared memory, i.e. 4 cubes/SM, unless `t_rlo`/`t_rhi`
  leave shared memory — L41's RC form 0 — a ≤ 2 % rider [E]); the AND's random-bank `LDS` (a digit-major `t_tr`
  read as one `LDS.128` per digit for 4 chunks: −3 instructions per digit and fewer wavefronts, ≤ 1 % [E]);
  persistence's 6.9 TB (§2A).
- Measuring watts per kernel needs kernel-alone loops sampled by NVML at ≤ 100 ms; ~$0.1 inside shortlist 5's
  session.

## 4. Shortlist for the coming week (ranked by expected gain × confidence per day)

| # | item | expected gain | confidence | cost | prerequisite PRs | kill criterion |
|---|---|---|---|---|---|---|
| **1** | **Static bucket order for the top layer** (§3e): sort each slice's top layer by (key, c); per-(slot, group) append in the FD kernel and the clipped launch; drop `top_scan`, `top_fill`, `tl`, `bucket_cnt`; the join reads group ranges. **Step 0 (gates the build):** profile the post-stack tree with one sync after `launch_top` (L31's method) to price scan + fill. | **×1.05–1.12 at b62 1e17, ×1.05–1.10 at b60 1e16 [E]**; NiceMark small-bucket risk | low–medium (the fill's 8.7 % / 7.1 % is inferred two ways; the design is unbuilt) | step 0: 1–2 h GPU, ~$0.3; build 2–3 days, ~$1.5 | #241, #246 (stack on #246: touches the FD append, the join's batch load, the plan footprint) | step 0: scan + fill < 5 % of the field → stop; prototype < ×1.05 at b62 1e17 or b60 1e16, any NiceMark scenario < ×0.98 over 6 rounds, or exactness failing twice |
| **2** | **FD top kernel, round 2** (§2A): L36.2's LC0 + LSCAN + LCLIP, the append's ballot, x mod b^c0 from the top words only, SURV_PER_PREFIX 2 → 1; persistence only if the dummy-state run shows its traffic hidden. | **×1.05–1.07 at b62 1e17, ×1.04–1.065 at b60 [D for the trims' ×1.04; E for the rest]** | medium (clearing 5 % at both fields is about even odds) | 1.5 days, ~$1 | #241 (`top_rec` writes in `top_fd_kernel`); independent of #246 | A/B < ×1.05 at either field → park on the branch (no PR at the trims' ×1.04); any NiceMark scenario < ×0.98; the device test failing twice; the larger plan not fitting a 10 GB card's 2.5 GiB → drop that part |
| **3** | **CPU lean prefilter** (L42's `prefilter_lean`, FX + MT + GM, no RC) on #247 | **CPU join ×1.06–1.10** at b60 1e16 and b62 1e17 slice 0 [D: ×1.050–1.077 measured standalone; ×1.26 measured with the FD prototype]; GPU budget unchanged | high | 0.5 day, $0 (ivory, CPU only) | #247; #246 for the shared proof | < ×1.05 at both shapes on #247 over 4 alternating rounds, or any survivor/checked count differs |
| **4** | **Check kernel rework** (§3c): a device-sized grid, the n² scan seeded with n³'s low 8 digits and the top's certificate, the two known low passes replaced by an exact division by b^8. Scoping first: SASS pass costs and a CPU simulation of the pass at which checks die, on CPU-join survivors of a b62 partition. | **×1.045–1.06 at b62 1e17, ×1.05–1.07 at b60 [E]** | low–medium | scoping 0.5 day, $0; build 1–1.5 days, ~$1 | #241 (the check reads `top_rec`) | scoping predicts < 3 % of the field → stop; A/B < ×1.05 at both fields → keep at most the grid fix as a rider if ≥ 1 %; NiceMark < ×0.98 |
| **5** | **Re-price the lean join** (measurement; same box and session as 1's step 0): L37's modes z/a/b/p/c and mode 7 (stage check every 4 chunks) ported to #246; the spill (40 + 28–44 B) and no-spill register variants timed separately (record which one each process compiles); unprofiled per-batch gaps; kernel-alone watts. | 0 directly; decides whether the join's 23 s (22.8 %) of non-issue time has a lever: a per-group stage check, if the barrier hypothesis holds, est. 0–6 % [E] | n/a | ~3 h GPU, ~$0.4 | #246 | stop at 3 h; no build unless one part shows ≥ 5 % of the field |

**Not on the list, and why:** FD persistence as designed (its state traffic, §2A); the lean-body join bundle
(registers, §2B); the bottom record (closed, L39); AU and PC (both lose, L43); H1/H2 (killed, L37); mid = 3
(§3b); fusing the check into the join (§3c). TT2 (~1 %) and the plain clip-word copy (×1.003 / ×1.012, L41) are
riders for whichever join PR comes next.

**Suggested week** (open-PR cap: #241, #246, #247 are open, so at most two more):
1. Day 1: one 150 or 180 W 3080 box (~4 h, ~$0.7): item 1's step 0 and item 5, the dummy-state persistence run and
   `CHECK_CUBES` as an env knob for a quick grid check. On ivory meanwhile: item 3 (CPU, $0) and item 4's scoping.
2. Days 2–3: item 2 (prototypes exist), A/B with NiceMark ≥ 6 rounds.
3. Days 3–5: item 1 if step 0 said go; item 4's build if its scoping predicts ≥ 3 %.

## Files

- `ROADMAP.md`: this file.
- `raw/scripts/budget44.py` → `raw/budget44.txt`: the budget, the issue model, the cycles across caps.
- `raw/scripts/loops.py`: backward branches with body size and opcode mix of a `cuobjdump` SASS file.
- `raw/sass/`: the post-#241 base's `check_kernel` (b60, b62), `top_fill_kernel`, `bucket_kernel` (b62), SASS and
  CubeCL CUDA, unpacked from `L41/raw/box/sass/B/`.
- `raw/cubecl_join_main.rs`: `common/src/cubecl_join.rs` at upstream main 6f060a9 (read-only copy).
