# L50 ROADMAP: the CPU join after #247 and #248 — budget and roadmap (2026-11-08; ivory, CPU only)

**Setup.** Worktree `.worktrees/l50-cpu-roadmap`, detached at fork `pr/cpu-join-lean-prefilter` **7f5260b** (= main
6f060a9 + #247 caef70e + #248; differs from L49's 03f42b9 only in the CHANGELOG line). Uncommitted scratch patch
(`raw/l50-scratch.patch`, nothing committed or pushed): seven cargo features of `nice_common`, all off by default —
`l50-prof` (rdtsc per phase per key + counters + a gap histogram + `L50_MAX_STEPS` + recording of the checked n),
`l50-split` (`#[inline(never)]` on `TopFdSetup::{seed, step, cert}`, `CpuJoin::{tops, extend, list, advance}`,
`Fx::dh` and the tops sort, so perf can separate them; costs +0.2 % / +0.7 % per partition), and the five
prototypes `l50-scan2`, `l50-check`, `l50-inl`, `l50-tr`, `l50-rc` (§4). Harnesses `common/examples/l50_prof.rs` (= L49's `l49_ab`
+ setup time + counters) and `l50_check.rs` (the check on recorded survivors), copies in `raw/scripts/`. Builds:
`cargo build --profile profiling -p nice_common --example …` (= release + debuginfo; LTO, 1 CGU), ~40 s each,
target 0.5–0.7 GB.

**Machine.** ivory: AMD EPYC-Rome VM (**Zen 2**), 4 vCPUs, **AVX2, no AVX-512** (so the scan is `scan_avx2`), TSC
2.495 GHz, cores ~3.3 GHz. Every run under `nice -n 19`, gated on 1-min load ≤ 1.5; loads at start 0.9–1.5
(about 25 idle CLI sessions; two other agents only read/write files here). perf 6.12 with the VM's PMU (cycles,
instructions, branch-misses sample per symbol; instruction-level attribution is not reliable in this VM — the
three events land on the same instructions — so only symbol-level shares are used).

**Shapes** (as L42/L49): b60 = NiceMark `b60_msd_weak` start 1157209632114824200908, **1e16** (sampled partitions:
4 on 1 thread, 16 on 4) and the whole **1e14** field (3600 partitions); b62 = the **1e17** field
4473066762334864396992, **slice 0 of 7** (4 / 16 partitions) and the whole **1e14** field at 4473156762334864396992
(3844 partitions); plus NiceMark's **b58 1e15** field (104400216587923470200; 32 / 128 partitions). Counts in every
run equal L49's (b60 1e16 16-partition sample 549,719,536 / 34,926,644; b62 1e17 s0 550,916,180 / 32,806,057; b60
1e14 1,326,103,590 / 84,383,498; b62 1e14 1,470,093,637 / 87,495,922).

## Summary

- **Phase split at production shapes (b60 1e16, b62 1e17 slice 0), 1 and 4 threads alike:** AND scan + extraction
  **38–40 %**, survivor prefilter (incl. the in-range test) **14.6–14.8 %**, full check **11–12 %**, top
  certificates **30–32 %** (FD certificate read 13–15 %, FD steps 9–11 %, seeds 2.2 % / 4.2 %, the loop 3 %), tops
  sort 1.3 %, lists + extension 1.0–1.3 %. The setup ("MSD / interval analysis": top layer, bottom DFS, key sort,
  FD constants) is 2.8 s a slice = **0.03 % of a field on 1 thread, 0.13 % on 4**. At 1e14 the per-partition bottom
  work shows: list 27 % / 36 % and extension 8 % / 11 % (b60 / b62); at b58 1e15 the scan is 76 %.
- **Where the cycles go:** IPC 1.6 in the scan, survivor and check, 2.3–2.5 in the tops; **50 % of all branch
  misses are in the scan** (the "does this 16-chunk hold a survivor" branch, ~0.4 a chunk), 18 % in the survivor,
  15 % in the check. In `scan_avx2` the vector loop is ~36 % of its cycles, the per-survivor extraction ~52 % (each
  survivor is a `vzeroupper` + `call` + reloads of the broadcast top from the stack), class tails ~11 %.
- **Prototypes, measured in place** (A/B, 3 interleaved rounds, medians, survivor / checked / hit counts identical
  to #248's in every run; §4):
  - **two-pass scan** (pass 1: AND + branch-free compaction of the pass bits through a 256-entry LUT; pass 2: the
    survivors): **×1.19 / ×1.20** (b60 / b62, 1 thread), **×1.16 / ×1.18** (4 threads), b58 1e15 ×1.17;
  - **`survivor` inlined into pass 2: +5–6 %** on top;
  - **seeded check** (the 16 digits the join already knows seed the mask; n² and n³ from position 8, five digits
    per long division): ×1.04–1.07 alone, **×1.07–1.11 on top of the two-pass**; on recorded survivors the check
    alone is ×2.1 in this form and **×2.3 with design D's base-b² columns** (§2.3);
  - **all three: ×1.32–1.39 at b60 1e16 and b62 1e17, 1 and 4 threads; b58 1e15 ×1.43; whole 1e14 fields (4 t,
    single rounds) ×1.09–1.17.** Branch misses 62 M → 26 M a partition, IPC 2.1 → 2.8, instructions −3 %;
  - measured and dropped: a bit-sliced (`TRANSPOSE`-style) pass 1, ×0.93–0.98 against the two-pass (×0.84–0.90
    at 1e14); RC (no residue load before the prefilter for unclipped tops), ×0.99–1.02, as L42 found;
    `MAX_STEPS` 8/16/32 (fewer seeds), ≤ ×1.02.
  - After the three, a partition is **tops 44–45 %** (certificate read 19–21 %, steps 14–15 %, seeds 3 % / 6 %,
    loop 5 %), **scan 43–44 %** (pass 1 ≈ 15 %, pass 2 with the prefilter ≈ 21 %, checked path and tails ≈ 8 %),
    check 7 %, sort 2 %, lists + extension 1.3–1.6 %.
- **Shortlist** (§3, ivory/Zen 2 numbers): **(1) two-pass scan with the inlined survivor, measured ×1.22–1.28;
  (2) seeded check with D's base-b² digits, measured ×1.07–1.11 on top of (1); (3) CPU "FD round 2" (L48's
  certificate and step trims + `MAX_STEPS` 8), estimate ×1.06–1.12 on top; (4) a vectorised second pass,
  estimate ×1.05–1.10 on top.** #249's static bucket order maps to the per-key tops sort (1.3 %): no. Design D
  maps in its CPU form (item 2): the early exit stays, the seeding and the cheap digits are the gain.
- **AVX-512 / other hosts** (§2.7, estimates): the scan is the only AVX2/AVX-512 difference; on a Zen 4 core
  `scan_avx512` needs ~¼ of the vector loop's instructions per AND and half the chunk branches, so the scan's
  share falls (~39 % → ~27–30 %) and the two-pass gain shrinks (×1.08–1.15). **Anvil's EPYC 7763 is Zen 3 with
  AVX2 only**: it runs `scan_avx2` as ivory does. demoux's CPU model I did not check.

## 1. The profile at #248's head (7f5260b)

### 1.1 Coarse split (rdtsc per phase per key, `l50-prof`; % of partition TSC, summed over threads; `raw/coarse-runs.txt`)

"tops" = `CpuJoin::tops` (FD advance + certificate + the kept tops' bookkeeping), "extend" the bottom extension
(once a partition), "list" `advance` + `list` (per key), "scan + surv" every class scan with its survivors'
prefilter and full check. The instrumented build runs within ~1–3 % of the plain one.

| shape | threads (partitions) | tops | extend | sort | list | scan + surv | ms / partition-thread | setup s | setup % of field (1 t / 4 t) |
|---|---|---|---|---|---|---|---|---|---|
| **b60 1e16** | 1 (4) | **30.3** | 0.3 | 1.35 | 0.9 | **67.1** | 2245 | 2.85 | 0.04 / 0.13 |
| b60 1e16 | 4 (16) | 30.5 | 0.3 | 1.34 | 0.9 | 66.9 | 2395 | 2.80 | |
| **b62 1e17 s0** | 1 (4) | **31.7** | 0.3 | 1.21 | 1.0 | **65.8** | 2186 | 2.80 (×7 slices) | 0.03 / 0.13 |
| b62 1e17 s0 | 4 (16) | 32.4 | 0.3 | 1.31 | 1.0 | 65.0 | 2386 | 2.77 | |
| b58 1e15 | 1 (32) | 18.9 | 1.0 | 0.67 | 3.4 | 76.1 | 558 | 0.38 | 0.02 / 0.08 |
| b58 1e15 | 4 (128) | 19.1 | 1.0 | 0.74 | 3.4 | 75.8 | 582 | 0.38 | |
| b60 1e14 whole | 1 (3600) | 23.5 | 8.3 | 1.36 | 27.2 | 39.6 | 35.6 (128.2 s) | 0.095 | 0.07 / 0.2 |
| b60 1e14 whole | 4 (3600) | 23.5 | 8.2 | 1.36 | 27.3 | 39.7 | 37.4 (33.6 s) | 0.057 | |
| b62 1e14 whole | 1 (3844) | 17.5 | 10.9 | 0.87 | 35.7 | 35.1 | 42.1 (162.0 s) | 0.097 | 0.06 / 0.2 |
| b62 1e14 whole | 4 (3844) | 17.4 | 10.8 | 0.87 | 35.7 | 35.3 | 44.4 (42.7 s) | 0.093 | |

The setup column is the whole host side before the first partition (`slices_for` + `CpuJoin::new`: the top layer's
MSD/interval DFS and the bottom DFS — `FieldSetup` 1.8 s of the 2.8 s at 1e16 — the key sort and the FD
constants). It runs on one thread while the others wait, so its share is 4× larger in thread-time on 4 threads,
and still ≤ 0.2 %. **The MSD/interval analysis is not a lever on the CPU.**

**Per partition** (1 thread; the 4-thread samples agree): 

| | b60 1e16 | b62 1e17 s0 | b58 1e15 | b60 1e14 | b62 1e14 |
|---|---|---|---|---|---|
| top-layer slots certified (FD) | 5,073,848 | 4,745,415 | 660,347 | 58,922 | 50,363 |
| seeds (share of slots) / steps per slot | 2.30 % / 1.43 | 4.74 % / 1.38 | 5.11 % / 1.38 | 2.98 % / 1.41 | 4.26 % / 1.40 |
| kept tops | 1,763,352 (34.8 %) | 1,513,216 (31.9 %) | 222,189 (33.6 %) | 20,518 | 16,072 |
| extended bottoms / listed (all keys) | 33,488 / 1,149,296 | 33,652 / 1,124,161 | 31,247 / 973,039 | 15,735 / 473,496 | 23,819 / 726,875 |
| ANDs / class scans (ANDs per scan) | 1.145e9 / 3.53e6 (325) | 9.00e8 / 3.03e6 (297) | 2.62e8 / 8.9e5 (294) | 5.49e6 / 4.1e4 (134) | 6.18e6 / 3.2e4 (192) |
| survivors (of ANDs) / checked (of survivors) | 3.42e7 (3.0 %) / 2.17e6 (6.3 %) | 3.44e7 (3.8 %) / 2.05e6 (6.0 %) | 9.99e6 (3.8 %) / 5.63e5 (5.6 %) | 3.68e5 / 2.34e4 | 3.82e5 / 2.28e4 |
| TSC: per slot (tops) / per AND (scan + surv) | 335 / 3.28 | 364 / 3.99 | 397 / 4.05 | 355 / 6.42 | 365 / 5.97 |
| TSC: per listed (list) / per extended (extend) | 44 / 535 | 48 / 460 | 48 / 446 | 51 / 466 | 52 / 480 |

### 1.2 Functions (perf, 1 thread, `l50-split` build; % of samples past the setup; `raw/perf-phases.md`)

| phase | b60 1e16: % cycles | % instr. | % br. misses | IPC | misses / 1k instr. | b62 1e17 s0: % cycles | % instr. | % br. misses | IPC |
|---|---|---|---|---|---|---|---|---|---|
| **AND scan + extraction** (`scan_avx2`) | **39.0** | 34.6 | **50.0** | 1.66 | 5.8 | **37.6** | 33.2 | 49.8 | 1.65 |
| **survivor** (range test + prefilter) | **14.6** | 12.3 | 18.0 | 1.57 | 5.8 | **14.7** | 12.7 | 18.6 | 1.61 |
| **full check** (`get_is_nice_with_known_lsd`) | **11.1** | 9.8 | 14.9 | 1.64 | 6.1 | **12.1** | 10.6 | 15.4 | 1.64 |
| **top: FD certificate read** (`TopFdSetup::cert`) | **14.8** | 18.1 | 6.6 | 2.27 | 1.5 | **13.2** | 16.7 | 5.5 | 2.36 |
| **top: FD step** | **10.9** | 14.0 | 5.1 | 2.40 | 1.5 | **9.3** | 12.3 | 3.9 | 2.46 |
| top: seed (`seed`, `to_digits`, `sum`, `divrem_w4`, `shl_digits`) | 2.2 | 2.5 | 1.0 | 2.18 | 1.5 | 4.2 | 5.1 | 1.7 | 2.28 |
| top: loop + `Fx::dh` | 3.2 | 4.3 | 1.4 | 2.50 | 1.3 | 3.4 | 3.9 | 1.3 | 2.14 |
| tops sort | 1.3 | 1.9 | 0.0 | 2.59 | 0.1 | 1.3 | 1.8 | 0.0 | 2.53 |
| list + advance | 0.9 | 0.9 | 1.8 | 1.80 | 8.4 | 1.1 | 0.9 | 2.1 | 1.59 |
| extend | 0.2 | 0.2 | 0.1 | 1.67 | 1.6 | 0.2 | 0.2 | 0.1 | 1.61 |
| rest (run glue, libc, `__umodti3`) | 1.6 | 1.5 | 1.0 | | | 2.5 | 2.5 | 1.3 | |
| **whole partition** | 100 | 100 | 100 | **1.87** | **4.0** | 100 | 100 | 100 | 1.87 |

The plain build (`raw/perf-phases.md`, 1 and 4 threads) gives the same scan / survivor / check / sort shares (40.0 /
14.4 / 11.2 / 1.4 at b60 1e16 1 t, 40.4 / 14.3 / 11.5 / 1.4 at 4 t; 38.9 / 14.8 / 11.9 / 1.3 and 38.4 / 15.0 /
11.5 / 1.3 at b62) with the tops, extension and lists inlined into one closure (31 %, IPC 2.5–3.0). L49's
single-event profile of the same head had 40.3 / 14.7 / 11.7 (b60): the three-event sampling does not move the
shares. **1e14 whole fields** (plain, 1 / 4 threads): scan 19.5 / 19.5 % (b60), 16.4 / 16.0 % (b62); survivor
12.6–13.9 %; check 6.1–7.5 %; closure (tops + extension + lists) 58–62 %, with a miss rate of 4.1–5.0 per 1k
instructions (the list's per-row keep/drop branch, ~50 % taken).

**Unit costs** (TSC = 2.495 GHz ticks, from the shares × the partition's TSC):

| unit | b60 1e16 | b62 1e17 s0 |
|---|---|---|
| AND in `scan_avx2` (vector loop + extraction + tails) | 1.91 | 2.28 |
| survivor (`survivor` call: range test, prefilter, branch) | 23.9 | 23.3 |
| full check (per checked survivor) | 286 (115 ns) | 322 (129 ns) |
| FD certificate read (per slot) | 163 | 152 |
| FD step (per step; 1.43 / 1.38 a slot) | 84 | 78 |
| seed (per seed) | 1,058 (424 ns) | 1,017 (408 ns) |
| loop + `dh` (per slot) | 35 | 39 |

`scan_avx2` itself, from its cycle samples by address range (b60 1e16, 1 thread; `raw/scripts/annot.py`):
the vector loop (four `vpand`/`vpcmpeqq`/`vmovmsk` groups for 16 bottoms, 28 instructions) is ~36 % of the
function, the extraction loop ~52 % (per survivor: `tzcnt`, bounds check, argument moves, **`vzeroupper` and a
`call` to the non-inlined `survivor`**; the chunk pointer and both broadcast top masks live on the stack because of
the call), class tails and the epilogue ~11 %.

## 2. Phase by phase: the GPU twin, whether it maps, and what it is worth

### 2.1 The AND scan and its survivor extraction (38–40 %; b58 1e15: most of its 76 %)

- **On the CPU now:** per class (~300 bottoms) a top's mask is broadcast and ANDed with 16 bottom masks a step
  (AVX2); the 16 pass bits feed `while bits != 0 { survivor(...) }`. A 16-chunk holds a survivor with probability
  1 − 0.97¹⁶ ≈ 0.39, so that branch is a coin toss: **~0.42 misses a chunk, 30 M a b60 1e16 partition, half of all
  the partition's mispredictions** (~18 cycles each on Zen 2). Each survivor is then a `call` (with `vzeroupper`)
  into the non-inlined `survivor`, and the loop keeps its pointer and both broadcast masks on the stack around it.
- **GPU twin:** the join kernel never runs the prefilter or the check inside its AND loop; survivors are staged
  and flushed to a list (#241/#246, #249's stage-once-per-batch rider), and #239's `TRANSPOSE` bit-slices the top
  batch so an entry's pass mask is an OR of its digits' words.
- **Staging maps directly: the two-pass scan** (`l50-scan2`, ~50 lines in `scan_avx2`). Pass 1 per 16-chunk: the
  same AND, then for each byte of the pass bits a 16-byte store of `LUT[byte] + offset` (u16 indices of its set
  bits, 4 KiB table) and `count += popcount` — no branch. Pass 2: a counted loop over the indices calling
  `survivor`. Classes above 4,096 bottoms keep today's path (none at these shapes). **Measured ×1.16–1.20** (§4),
  and **+5–6 % more with `survivor` inlined into pass 2** (`l50-inl`, §4). L42's estimate for branch-free compaction
  alone was 3–6 %; the rest is the call, `vzeroupper` and spill traffic leaving the vector loop.
- **`TRANSPOSE` (bit-sliced bottoms per class):** L42 put the AND arithmetic at ~0.3 of 2.3 cycles an AND and said
  no. After the two-pass, pass 1 (vector loop + compaction) is ~15 % of the partition (§4). A bit-sliced class (for
  each digit, a bitset of the class's bottoms that use it; ~6 words a digit at 325 bottoms, rebuilt per key from
  the listed masks, ~14 bit-sets a listed bottom) turns a top's ~325 ANDs into ~17 ORs of ~6 words (its
  certificate's digits) and a NOT, whose result is already the bitset the compaction reads. **Prototyped
  (`l50-tr`, §4): ×0.93–0.98 against the two-pass alone — no.** Pass 1 is not bound by the AND's instructions
  any more: the compaction, the per-class loop over the top's digits (data-dependent exit) and the per-key
  transposition take what the ORs save.

### 2.2 The survivor prefilter (14.6–14.8 %)

- **On the CPU now (#248):** 23–24 TSC a survivor: the call, the in-range test's dependent loads (`info[j]` →
  `ext.idx[row]` → `bp_r`), `Fx`'s four multiplies and `fresh4`, and the 6 % keep branch (0.3 misses a survivor
  in all, 18 % of the partition's misses).
- **GPU twin:** #246's lean prefilter — already ported (#248). Nothing further from the GPU maps.
- **CPU-only, after the two-pass:** inlining `survivor` into pass 2 is measured (+5–6 % over the two-pass
  alone). RC (skip the residue load and range test for unclipped tops; L41) is measured again on top of all three
  prototypes: ×0.99–1.02, no — the dependent loads are not the bottleneck. What remains is ~20 % of a partition
  after items 1–2 (pass 2 by address range, §4), ~30 core cycles and ~60–80 instructions a survivor. Running the
  prefilter **vectorised over pass 1's index list** (AVX2: `Info`, `p2`/`p3` and the bottom masks gathered by
  index and row, or `p2`/`p3` folded into a 16-byte `Info`; `Fx` in 32-bit lanes; `fresh4` with `vpsrlvq`; a
  second LUT compaction into the checked list) should take it to ~15–20 instructions a survivor. Estimate
  **×1.05–1.10 on top of items 1–2**, low confidence (Zen 2's gathers cost ~9 cycles each, three per 8
  survivors). Item 4.

### 2.3 The full check (11–12 %) and L47's design D

- **On the CPU now:** `get_is_nice_with_known_lsd(n, b, 3, bp_m)`: the mask seeded with digits 0..2 of n² and n³,
  n² (3 limbs) divided by `b` once per digit from position 3, then n³. On the recorded survivors of one partition
  (2.1 M at b60, 2.0 M at b62; `raw/check-bench.txt`) it converts **9.6–9.8 digits a check** before the verdict,
  286–322 TSC (115–129 ns), 3.9 mispredictions a check.
- **What the join already knows:** positions 0..7 of n² and n³ — the bottom's 12 digits (the AND) and the
  prefilter's 4 — are 16 distinct digits. The check re-derives five of them (n² positions 3..7) by long division
  and learns n³'s 3..7 only after all of n². **Seeded with all 16 and started at position 8, a check converts
  3.4–3.5 digits; 0.7 % of survivors get past n².**
- **Design D's parts on the CPU:** D's gate (n² and n³'s low digits before the cube) exists to keep warps from
  diverging; the CPU exits at the first repeat anyway, so it adds nothing. D's seeding with known digits is L47's
  B, which D dominates on the GPU; on the CPU it is most of the gain. D's arithmetic (n's base-b² limbs, schoolbook
  columns from the low end, a magic-multiply carry normalisation and digit split, the carries of columns 0..3
  only, digits from column 4 on, exit at the first repeat) maps for n²; n³ (0.7 %) can stay on the U256 path.
- **Bench on the recorded survivors** (3 repetitions, ns a check, same verdicts; for every n, every variant tests
  exactly the digits the reference tests before its verdict, seeded and unseeded, and V2's n² digits equal the
  division's):

  | variant | b60 1e16 | × | b62 1e17 s0 | × |
  |---|---|---|---|---|
  | V0 today | 124.6–126.3 | 1 | 129.5–132.0 | 1 |
  | V1 seeded (16 digits), from position 8, one long division a digit | 75.0–77.6 | 1.63–1.68 | 75.6–76.5 | 1.70–1.73 |
  | V3 seeded, five digits a long division (by b⁵), split by constant divisions | 59.7–60.3 | 2.09–2.10 | 60.6–61.4 | 2.11–2.15 |
  | **V2 seeded, n² by base-b² columns (D's arithmetic), n³ as V3's path** | **54.3–56.6** | **2.23–2.30** | **55.8–58.4** | **2.23–2.32** |

- **In place** (V3, `l50-check`: the prefilter's four digits re-derived for the seed, a per-base const-generic
  check): **×1.036–1.067** alone, **×1.07–1.11 on top of the two-pass scan** (where its share is larger), i.e.
  the check's ~11.5 % share cut by ~52 % as the bench predicts. V2 in place
  should add ~0.5 % more (its extra ×1.1 on the check's remaining ~5.5 %); its real merit is no long division and
  no U256 on the common path.

### 2.4 The top certificates (30–32 %)

- **On the CPU now (#247):** per slot 335–364 TSC: the FD certificate read 152–163, 1.38–1.43 steps of 78–84
  (14 biased word additions + 3 `W4` additions each), the loop 35–39, and seeds (2.30 % / 4.74 % of slots at
  ~1,040 TSC = 410–424 ns each: **2.2 % of a b60 partition, 4.2 % at b62**).
- **Seeds:** they are gaps of more than `MAX_STEPS` = 4 key spaces. Gap histogram (`raw/steps-runs.txt`): b60
  1.39 % of slots at 5–8, 0.73 % at 33–256; b62 1.26 % at 5–8, 1.65 % at 9–16, 1.24 % at 17–32. A step costs
  ~80 TSC and a seed ~1,040, so break-even is ~13 steps. **`MAX_STEPS` sweep** (4 / 8 / 16 / 32, 2 rounds,
  1 thread): b60 2283 / 2279 / 2297 / 2277 ms (×1.00); b62 2242 / 2205 / 2228 / 2210 ms (**×1.017 at 8**). A
  cheaper seed in #240's GPU form (P² and P³ by schoolbook in 16-bit limbs, digits by comptime divisions) would
  save at most half the seed: ×1.01 (b60) / ×1.02 (b62). **Below the bar on its own; `MAX_STEPS` 8 rides with
  item 3.**
- **GPU twin: L48's FD round 2** (level 6: c0 and `b^c0 − 1 − d` carried from slot to slot, the short path above
  the run, no a/e/clip work on steps, early-exit carries; −29 to −32 % per stepped slot). The CPU has the same
  slack: `cert` recomputes `ndig(d)` (bit length, table, `W4` compare) and the f64 screen's `w4_f64(d)` for both
  powers every slot although `d` steps by constants; `tops()` forms `lo = p·w`, `a`, `e` and the clip test in
  u128 for every slot although only P = `plo`, `phi` can clip; and every step adds each array's carry word (5 of
  the 14 word additions) whether or not a carry came out. **Maps; estimate −15 to −25 % of the tops' cycles** (the CPU's certificate already runs at IPC 2.3–2.7, the
  GPU kernel's at about half rate).
  Not prototyped.

### 2.5 Lists and extension at small fields

- Production shapes: lists 0.9–1.1 %, extension 0.2–0.3 %. b58 1e15: 3.4 % / 1.0 %. **1e14: lists 27 % (b60) /
  36 % (b62), extension 8 % / 11 %.**
- The extension (446–535 TSC an extended bottom) divides by runtime values in hardware about 15 times a row: the
  fixed digits by `% b` and `/ b` (four a position, two positions), `lo / b^f0`, and the residues mod `M` and
  `b^mid`. `SmallDiv`/`Div64` reciprocals would cut it by more than half (estimate ×1.04–1.06 at 1e14). The lists (~25 TSC a row and key) carry a ~50 % keep/drop branch per row (the closure's 4–5 misses per
  1k instructions at 1e14): the two-pass scan's compaction applies (write always, advance by the keep bit), or
  AVX2 over 8 rows; estimate the lists −30 to −50 %, ×1.10–1.20 at 1e14. **Nothing at production sizes**, so only
  if CPU clients take ≤ 1e15 nice-only fields.

### 2.6 The tops sort, and #249's static bucket order

The per-key sort of the kept tops by `P mod (b − 1)` is the CPU's bucket fill: **1.3 %** (0.7 % at b58). #249's
static order (sort the slice's layer once by key and class) would remove it, but a class's consecutive prefixes
are b − 1 key spaces apart, so FD would step by (b − 1)·h and seed far more often. **No.**

### 2.7 AVX2 vs AVX-512, and other CPUs (estimates; nothing here was measured off ivory)

- **The scan is the only phase that differs**: `scan_avx512` tests 8 bottoms per `vptestnmq` and 32 per chunk.
  On ivory's profile (b60 1e16) the scan is 39 % of the partition: vector loop ≈ 14 %, extraction ≈ 20 %, tails
  ≈ 4 %. On a **Zen 4** core (AVX-512 double-pumped) the vector loop needs ~¼ of the instructions per AND and half
  as many chunk branches (a 32-chunk is empty with probability 0.38, still a coin toss): estimate the scan at
  ~27–30 % of the partition instead of 39 %, i.e. today's code already ~×1.10–1.15 faster per clock there than an
  AVX2 path would be. The two-pass gain then shrinks to **×1.08–1.15** (half the mispredictions to remove; the
  call/`vzeroupper`/spill part unchanged); compaction there would use `vpcompressd` to a register (the
  memory-destination form is reported to be very slow on Zen 4) or the same LUT. Zen 4's faster `div` changes nothing in the production-shape hot path
  any more (#247 removed the certificate's divisions; the check divides by constants); it would shorten the
  extension at 1e14.
- **Anvil (EPYC 7763, Zen 3): AVX2 only, no AVX-512** — it runs `scan_avx2`, so ivory's split and the
  prototypes' gains should carry over, somewhat lower if Zen 3's predictor misses less (estimate two-pass
  ×1.12–1.20).
- **demoux** (12 threads): its CPU model is not in my notes and I did not log in (per-task permission). If it is
  a Zen 4/5 desktop part it takes `scan_avx512`, and the Zen 4 estimate applies.
- Vast boxes are mixed (Rome/Milan AVX2, Genoa/Xeon AVX-512); a PR must restructure all three scans
  (`scan_avx2`, `scan_avx512`, `scan_any`) and should be measured on one AVX-512 host before the gain is quoted
  for the fleet.

## 3. Ranked shortlist

Gains are per partition = per field (setup ≤ 0.2 %), on **ivory (Zen 2, AVX2)** unless stated; "on top of"
means against the build with the items above it. NiceMark's CPU scenarios are these shapes (b58 1e15, b60/b62
3e15 windows of 1e16 fields), so they should move alike; not run (A/B only).

| # | item | gain (ivory) | confidence | cost | kill criterion | hardware |
|---|---|---|---|---|---|---|
| **1** | **Two-pass AND scan with the survivor inlined into pass 2** (§2.1): pass 1 = AND + branch-free LUT compaction of the pass bits into a u16 index list; pass 2 = a counted loop over the list running the in-range test and prefilter inline. All three scans (`scan_avx2`, `scan_avx512`, `scan_any`); classes over 4,096 bottoms done in pieces instead of falling back. | **measured ×1.22–1.28** at production shapes, 1 and 4 threads (two-pass ×1.16–1.20, inlining +5–6 %); b58 1e15 ×1.24 | **high** on Zen 2 (2 A/Bs × 3 rounds, counts identical, mispredictions 62 M → 26 M a partition); medium elsewhere | **1–1.5 days**, $0 (the AVX-512 and scalar paths, `every_scan_finds_the_same_pairs` + a long-class test, NiceMark on ivory) | < ×1.10 at either production shape on ivory, NiceMark CPU score < ×1.05, or any survivor/checked count differing from #248's; on the first AVX-512 host measured, the AVX-512 path < ×1.00 → keep that path's one-pass loop | Zen 2/3 AVX2 as measured; AVX-512 hosts estimated ×1.08–1.15 (§2.7) |
| **2** | **Seeded check** (§2.3): the prefilter hands its four digits to the check; the mask starts with the 16 known digits (positions 0..7 of n² and n³), n² from position 8 by D's base-b² columns (or V3's 5-digit chunks), n³ from position 8; the per-base const-generic dispatch as today. | **measured ×1.07–1.11 on top of item 1** (V3; ×1.04–1.07 alone); V2 ~+0.5 % more (bench ×2.3 vs ×2.1 on the check) | **high** (in place 3 rounds × 2 A/Bs; on 4.1 M recorded survivors every variant tests exactly the reference's digits) | **1 day**, $0 (digit-level host test of the column arithmetic vs U256 digits for 10⁸ random n per base 40–64, the bench's tested-digit equality as a test, b10's 69 and the reference tests unchanged) | < ×1.03 on top of item 1 at either production shape, or any digit-level test failure | none specific (no division by a runtime value; Zen 3/4 alike) |
| **3** | **CPU FD round 2** (§2.4): carried c0 and screen value in `TopFdSetup::cert`, no `lo`/`a`/`e`/clip work for interior slots, carry words only on a carry out, `MAX_STEPS` 8, and a cheaper seed. | **estimate ×1.06–1.12 on top of 1–2** (the tops are 44–45 % of a partition after them; −15 to −25 % of their cycles; `MAX_STEPS` alone ≤ ×1.02, seeds 2.9 % / 6.3 % after 1–2) | low–medium (the GPU's round 2 measured −29 to −32 % per stepped slot; the CPU's certificate already runs at IPC 2.6) | 1.5–2 days, $0 (the FD equality tests of #247 cover it) | a scratch prototype of the certificate and loop trims saves < 10 % of the tops' TSC per slot (the `l50-prof` counter) at b60 1e16 and b62 1e17 → stop | any |
| **4** | **Vectorised second pass** (§2.2): the prefilter run 8 survivors at a time over pass 1's index list (AVX2: `Info`, `p2`/`p3` and the bottom masks gathered by index and row, `Fx` in 32-bit lanes, `fresh4` with `vpsrlvq`, a second LUT compaction into the checked list); `p2`/`p3` folded into `Info` (16 bytes) so a survivor is one load. | **estimate ×1.05–1.10 on top of 1–2** (pass 2 is ~20 % of a partition after them, ~30 core cycles a survivor; −30 to −50 %) | low (gathers are slow on Zen 2; RC showed the scalar loads are not the bottleneck) | 1–1.5 days, $0 | a scratch AVX2 pass 2 < ×1.04 at either production shape | AVX2 hosts; AVX-512 has 16-lane forms and `vpcompressd` |

**Not on the list:** the bit-sliced (`TRANSPOSE`) pass 1 (measured ×0.93–0.98 against item 1); #249's static
bucket order (the tops sort is 1.3–1.9 %, and FD needs the ascending order, §2.6); `MAX_STEPS` alone (≤ ×1.02);
the setup / MSD analysis (≤ 0.2 %); the lists and extension (≤ 1.6 % at production shapes; ×1.15–1.30 together
at 1e14 only, §2.5 — worth it only if CPU clients get ≤ 1e15 nice-only fields); RC (×0.99–1.02).

**Cumulative:** items 1 + 2 measured together **×1.32–1.39** at production shapes (1 and 4 threads); with items 3
and 4 at their estimates, ×1.47–1.71 over #248 on Zen 2.

## 4. Prototypes, measured in place

All on ivory, `nice -n 19`, the `l50_prof` harness (sampled partitions in NiceMark's bit-reversed order, or whole
1e14 fields), one binary per variant built from the same tree, 3 rounds with the order reversed every other
round, load gate ≤ 1.5. **ms per partition-thread, medians** (wall s for 1e14), × against `plain` (= #248's head)
of the same A/B. **Survivors, checked and hits are identical to the plain build in every run of every variant**
(counts in `raw/ab-runs*.txt`). Scripts `raw/scripts/run_chain2.sh` … `run_chain6.sh`, tables
`raw/scripts/abtable.py` → `raw/ab-summary.txt`.

**A/B 1** (`raw/ab-runs.txt`; 06:28–06:52 UTC):

| shape | plain | two-pass scan (`l50-scan2`) | seeded check V3 (`l50-check`) | both | per round (both) |
|---|---|---|---|---|---|
| b60 1e16, 1 t | 2227 | 1870 **×1.191** | 2115 ×1.053 | 1737 **×1.282** | 1.269, 1.296, 1.304 |
| b62 1e17 s0, 1 t | 2166 | 1801 **×1.203** | 2051 ×1.056 | 1679 **×1.290** | 1.291, 1.244, 1.278 |
| b60 1e16, 4 t | 2382 | 2047 ×1.163 | 2299 ×1.036 | 1839 ×1.295 | 1.278, 1.290, 1.295 |
| b62 1e17 s0, 4 t | 2275 | 1924 ×1.183 | 2175 ×1.046 | 1778 ×1.280 | 1.255, 1.418, 1.272 |
| b58 1e15, 1 t | 537 | 458 ×1.172 | 503 ×1.067 | 407 ×1.320 | 1.320, 1.335, 1.332 |
| b60 1e14 whole, 4 t (1 round) | 33.7 s | | | 29.3 s ×1.150 | |
| b62 1e14 whole, 4 t (1 round) | 44.1 s | | | 37.7 s ×1.168 | |

**A/B 2** (`raw/ab-runs2.txt`; 06:53–07:10): `survivor` inlined into the two-pass scan's second pass (`l50-inl`):

| shape | plain | two-pass + check | two-pass + inlined survivor | **two-pass + check + inlined survivor** | inlining alone (× on two-pass + check) |
|---|---|---|---|---|---|
| b60 1e16, 1 t | 2217 | 1739 ×1.274 | 1758 ×1.261 | **1637 ×1.354** | ×1.062 |
| b62 1e17 s0, 1 t | 2181 | 1656 ×1.317 | 1677 ×1.301 | **1570 ×1.389** | ×1.055 |
| b60 1e16, 4 t | 2456 | 1887 ×1.302 | 1911 ×1.285 | **1784 ×1.376** | ×1.058 |
| b62 1e17 s0, 4 t | 2284 | 1805 ×1.265 | 1827 ×1.250 | **1714 ×1.333** | ×1.053 |
| b58 1e15, 1 t | 561 | 407 ×1.378 | 423 ×1.325 | **386 ×1.452** | ×1.054 |

(A/B 2's plain medians are 0–3 % above A/B 1's on the same shapes, so its ratios read ~2 % high; within A/B 2
the inlining is +5.3–6.2 %.)

**Counters** (`perf stat`, counting, 1 thread, past the setup, per partition; `raw/perfstat-runs.txt`):

| b60 1e16 | instructions | branches | branch misses | IPC | cycles |
|---|---|---|---|---|---|
| plain | 1.59e10 | 1.87e9 | **6.2e7** (3.3 %) | 2.09 | 7.6e9 |
| two-pass + check | 1.56e10 | 1.67e9 | **2.6e7** (1.5 %) | 2.70 | 5.8e9 |
| two-pass + check + inlined survivor | 1.54e10 | 1.64e9 | 2.6e7 (1.6 %) | 2.82 | 5.5e9 |

(b62 1e17 s0: 1.51e10 → 1.46e10 instructions, 5.9e7 → 2.4e7 misses, IPC 2.13 → 2.60.) **The instruction count
barely moves (−3 %); 36 M of 62 M mispredictions a partition go, and IPC rises from 2.1 to 2.8.** The seeded
check's instruction savings and the compaction's added work roughly cancel.

**The profile after the three** (split build with all three, perf, 1 thread; `raw/perf-phases-after.md`):

| phase | b60 1e16 % cycles | b62 1e17 s0 | IPC |
|---|---|---|---|
| scan: pass 1 (AND + compaction) | ~14.6 | ~14.5 | |
| scan: pass 2 (inlined survivor + prefilter) and the rest of `scan_avx2` | ~29 | ~29 | 2.4–2.5 (whole scan) |
| full check (V3) | 6.8 | 6.9 | 2.4–2.6 |
| top: FD certificate read | 21.4 | 18.6 | 2.6–2.7 |
| top: FD step | 14.9 | 13.7 | 2.7 |
| top: seeds | 2.9 | 6.3 | 2.6–2.7 |
| top: loop + `dh` | 5.2 | 4.8 | 2.3–2.5 |
| tops sort | 1.9 | 1.8 | |
| lists + extension | 1.3 | 1.6 | |

(The scan's pass-1 / pass-2 split is from its cycle samples by address range: pass 1 ≈ 33 %, pass 2 ≈ 48 %,
the checked path and class tails ≈ 18 % of the function.) **After the prototypes the tops are 44–45 % of a
partition and the scan 43–44 %.**

**A/B 3** (`raw/ab-runs3.txt`; 07:14–07:37): the bit-sliced pass 1 (`l50-tr`: per key, each class's listed
masks transposed into a bitset per digit; a top's pass bits = NOT of the OR of its digits' bitsets; the same LUT
compaction and pass 2), both with the seeded check and the inlined survivor:

| shape | plain | two-pass + check + inlined survivor | bit-sliced pass 1 + check + inlined survivor |
|---|---|---|---|
| b60 1e16, 1 t | 2240 | 1701 ×1.317 | 1739 ×1.288 |
| b62 1e17 s0, 1 t | 2168 | 1558 ×1.392 | 1673 ×1.296 |
| b60 1e16, 4 t | 2470 | 1848 ×1.336 | 1849 ×1.336 |
| b62 1e17 s0, 4 t | 2344 | 1688 ×1.389 | 1822 ×1.287 |
| b58 1e15, 1 t | 551 | 387 ×1.426 | 412 ×1.338 |
| b60 1e14 whole, 4 t (1 round) | 32.7 s | 29.9 s ×1.094 | 36.4 s ×0.898 |
| b62 1e14 whole, 4 t (1 round) | 42.5 s | 37.8 s ×1.125 | 50.8 s ×0.837 |

**A/B 4** (`raw/ab-runs4.txt`; 07:38–07:45): RC on top of all three, ms per partition-thread per round:
b60 1e16 1 t 1664/1617/1618 → 1562/1607/1613 (×1.007), b62 1e17 s0 1 t 1544/1521/1518 → 1540/1481/1520
(×1.001), b60 4 t 1777/1748/1809 → 1808/1740/1711 (×1.021), b62 4 t 1797/1643/1661 → 1989/1661/1675 (×0.992).
**No gain.**

**Other measurements:**
- `MAX_STEPS` 4 → 8 / 16 / 32 (`raw/steps-runs.txt`, §2.4): ≤ ×1.017.
- The check on recorded survivors (`raw/check-bench.txt`, §2.3): V1 ×1.63–1.73, V3 ×2.09–2.15, V2 ×2.23–2.32.

## 5. Caveats

- **One machine, one microarchitecture.** Every number is ivory's (EPYC Rome VM, Zen 2, AVX2). The two-pass gain
  is mostly branch mispredictions and call overhead, both of which differ by core; the AVX-512 path was not run.
  Before quoting item 1 for the fleet, measure one AVX-512 host (a Zen 4 Vast box or demoux, with permission).
- **Noise.** Sampled 1e16/1e17 partitions scatter ±3 % run to run (single rounds up to ±8 % when another process
  ran: e.g. A/B 1's b62 4 t round 2 plain at 2513 ms); every ratio is a median of 3 interleaved rounds and the
  plain medians of the four A/Bs agree within 3 %. The 1e14 whole-field rows are single rounds.
- **perf in this VM**: sampling three events at 2 kHz slows the runs ×1.6–2.1, but the shares match L49's
  single-event profile (40.3 / 14.7 / 11.7 vs 40.0 / 14.4 / 11.2 at b60); instruction-level attribution is not
  trustworthy here, so the pass-1 / pass-2 split of the scan (§4) is a cycle-sample address split, ± a few points.
- **Prototype scope.** `l50-scan2`/`l50-tr` touch `scan_avx2` only and need classes ≤ 4,096 bottoms (production
  classes are ~300); `l50-check` covers bases 58/60/62/64 with `f0 = 3`, `k2 = 8` (every production shape), and
  re-derives the prefilter's four digits instead of passing them; `l50-inl` inlines `survivor` everywhere. They
  are exact on every run here (counts) and the check variants on every recorded survivor (tested digits), but they
  have no unit tests; a PR needs the tests listed in §3.
- **Not measured:** NiceMark (the A/B harness samples the same partitions NiceMark does, in the same order); b64
  and b57 shapes; V2 (base-b² columns) in place; the FD round-2 trims and the vectorised pass 2 (estimates only).

## Files

- `raw/l50-scratch.patch`: the scratch tree against 7f5260b (features `l50-prof`, `l50-split`, `l50-scan2`,
  `l50-check`, `l50-inl`, `l50-tr`, `l50-rc`); `raw/scripts/l50_prof.rs`, `raw/scripts/l50_check.rs`: the
  harnesses (copied into `common/examples/` for the build).
- `raw/coarse-runs.txt` (§1.1; also the b58 runs), `raw/perf-runs.txt` + `raw/perf-phases.md` (§1.2, perf of the
  plain and split builds, 1 and 4 threads, all shapes), `raw/perf-phases-after.md` (§4, after the prototypes),
  `raw/perfstat-runs.txt` (§4 counters), `raw/steps-runs.txt` (`MAX_STEPS` sweep + gap histograms),
  `raw/check-bench.txt` (§2.3), `raw/ab-runs.txt` … `ab-runs4.txt` + `raw/ab-summary.txt` (§4),
  `raw/build2.log` (builds, md5s).
- `raw/scripts/`: `run_chain1.sh` … `run_chain6.sh`, `build2.sh`, `perfsym.py` (per-symbol shares, IPC, misses),
  `phases.py` (symbols → phases), `annot.py` (cycle samples by address within a function), `abtable.py`.
- Worktree `.worktrees/l50-cpu-roadmap` (detached at 7f5260b, uncommitted scratch patch): CLEANUP-PLACEHOLDER
