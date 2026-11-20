# CEIL: how far is the middle-out pairing from its floor? (results, 2026-11-20)

*Counting study on the CPU reference (`dev/mo-clean` `c2152084`), scratch branch `exp/mo-ceiling`, rented box
Vast 61586715, 2026-11-20 06:05–09:20 UTC. Labels: **[M]** measured (raw file named), **[D]** derived from
measured counts by arithmetic shown, **[P]** proven, **[J]** judged. Base 64 unless said. Brief: `BRIEF.md`;
the director's priors: `NOTES.md`.*

## Verdict

**Below ×1.3 at base 64; at base 65 the counts cross ×1.3 only in combination and only before the decision
data is paid for. The line is closed; the tables below are the measured ceiling.**

- **Base 64** (all 4,032 jobs of 10 slices; 8 typical): in the kernel's own cost model (lane slots × 17 ORs per
  slot in rounds of 16 chunks, which reproduces the card's 60.5 % busy fraction: 0.6050), the best order of Q1 is
  lexicographic on the full child mask, **×1.0045** [M]. The L order of Q2 is **×0.893**: its self-collision
  test kills 50.6 % of visits but replaces, not adds to, the key's 50.8 % (in L order the common masks are empty).
  The best hybrid is ×0.923 [M]. Probe sharing (Q4) in lockstep: ×1.13–1.17 against today's kernel; with lex
  ×1.14–1.18; with L order or a hybrid ×0.99–1.04 [M]. **Best exact variant: ×1.18 at most.**
- **Base 65** (wide path; 2 slices, all 4,160 jobs): today's skip is weaker (kept 0.615, busy 0.711) and the
  magnitude of L helps: L order ×1.14, hybrid with 5 bits of L **×1.19** [M]; with probe sharing the hybrid
  reaches **×1.35 (wave of 64) to ×1.39 (warp of 32)** in counted work [M, `raw/combos_65.txt`]. But each
  (top, cell) needs its extended certificate: 33 evaluations of n², n³ per top for j = 5, against 137 lane slots
  of pairing per top at base 65 (one root, one job per top). At the tops stage's measured price (3080: 0.393 ms
  for ≈ 440k certificates per slice, i.e. ≈ 33 lane slots of the main kernel per certificate; even at a tenth of
  that per cell end) the table costs about three times the 35 lane slots per top it saves [J, from measured stage
  costs]. Net: no gain at base 65 either.
- **Records and survivors** do fall a lot (L order ÷6.8 / ÷7.3 at b64, ÷8.2 / ÷8.7 at b65; Q3 ÷2.1 / ÷2.2),
  which only the expansion stage (8 % of a slice) would feel.
- **Not an order or a test, and the only number that might matter: chunk width.** 128 or 256 children per word
  halve or quarter the lane slots at the same bytes: ×1.0 if the card's slot is LDS-bandwidth-bound, up to ×2.0 /
  ×3.9 if it is instruction-bound; `G2/BENCH.md`'s slot sits at 2× its bandwidth floor, which in a two-part model
  gives about ×1.3 (128) to ×1.6 (256) [J]. One microbenchmark of phase 3b settles it; it is what I would
  measure first.
- **Exactness:** 1,095,468,692 discarded survivors over every pass and variant (32,825,596 of them passing the
  prefilter), every one checked by brute force on the full digits of n² and n³: **0 nice, 0 claim failures** [M].
  The instrument reproduces `slice_join` exactly on all 12 slices and in every pass (Q0).
- **Most kept visits are empty** (not asked): 91.1 % today; a perfect skip at any price would give ×2.0 at base
  64 (×1.66 at base 65), the ceiling of any skip test in this lane layout.

## Q0: the instrument reproduces today [M]

Raw: `raw/s_64_<pip>.txt` (lines `VAR code` and `Q0REF`), compared by `box/analyze.py 64` →
`raw/analysis_64.txt`. On **every** slice the study's own walk in the code's order equals `cpu::slice_join`'s
counters exactly, field for field (children, chunks, flat, kept, words = records, survivors, checked):

| slice (pip) | how chosen | children | chunks | flat visits | kept | kept/flat | records | survivors | checked | busy (rounds) |
|---|---|---|---|---|---|---|---|---|---|---|
| 712012851 | parity runs, design doc | 33,705,647 | 528,635 | 250,486,772 | 123,163,397 | 0.4917 | 10,929,765 | 11,768,560 | 337,904 | 0.6050 |
| 502136830 | parity runs | 33,654,175 | 527,842 | 250,156,876 | 123,181,024 | 0.4924 | 10,917,490 | 11,756,699 | 338,191 | 0.6061 |
| 4977728 | parity runs | 33,718,638 | 528,831 | 251,447,411 | 123,690,652 | 0.4919 | 10,986,804 | 11,830,109 | 339,922 | 0.6052 |
| 0 | first of the range | 25,398,288 | 398,762 | 157,406,427 | 0 | 0 | 0 | 0 | 0 | — |
| 1073741823 | last of the range | 25,362,171 | 398,238 | 157,262,759 | 45,317,999 | 0.2882 | 5,066,885 | 5,552,884 | 144,425 | — |
| 952265258, 830186330, 630629006, 457254635, 298641742 | `random.Random(20261120).randrange(64**5)` ×5 | 33.66–33.75M | 527.9–529.4k | 249.9–251.5M | 122.8–123.6M | 0.4906–0.4924 | 10.92–10.98M | 11.75–11.83M | 335.7–338.7k | 0.6040–0.6061 |

- Slice 712012851 matches the design document's numbers (33.7M children, 529k chunks, 250M flat, 123M kept, 49 %,
  10.9M records, 11.77M survivors, 338k checked) and the busy fraction of today's order under the kernel's round
  structure is **0.6050**, the card's measured 60.5 % [M].
- The first slice (digits 4–8 all 0) is degenerate: every one of its 157M visits is removed by the common-mask
  skip; no survivor (every parent there has r < 2^24, so r² < 64^8 and digit 8 of r² is 0 in every child [P];
  the tops' side I did not analyse). The last slice keeps 0.288. Both are excluded from the "typical" aggregates
  below (8 slices: the 3 named + 5 random; `raw/analysis_64_typical8.txt`) and included in `raw/analysis_64.txt`.
- All 4,032 jobs of every slice were counted (no sampling). Per-slice spread of every ratio below over the 8
  typical slices is under ±0.3 % (e.g. L-order work 1.1175–1.1206, lex 0.9953–0.9959) [M].
- The brief's 64-chunk wave model gives busy 0.4919 for today's order, not 0.605: the kernel's lanes are the 16
  chunks of a round (`gpu.rs` phase 3b: `q = t % 16`, `my_lslots += min(32, nlist − e0) · nch`), so every
  lane-slot number below uses rounds of 1,024 children; the 64-chunk column is in the raw tables.

## Q1: what a sort key can buy [M, 8 typical slices, `raw/analysis_64_typical8.txt`; greedy: 3 named slices]

| order (64-child chunks) | kept / flat | busy (rounds) | lane slots rel. | work rel. (= ×) | ORs rel. (dense ideal) | oracle lane slots rel. |
|---|---|---|---|---|---|---|
| no key (k = 0; = parent r order) | 0.9997 | 0.9997 | 1.230 | 1.230 (×0.81) | 2.035 | 0.612 |
| key k = 2 | 0.7380 | 0.856 | 1.061 | 1.061 | 1.501 | 0.550 |
| k = 4 | 0.5929 | 0.729 | 1.000 | 1.000 | 1.206 | 0.512 |
| k = 6 | 0.5184 | 0.638 | 1.000 | 1.000 | 1.054 | 0.504 |
| **k = 8 (today)** | **0.4918** | **0.6050** | **1** | **1** | **1** | **0.503** |
| k = 10 | 0.4884 | 0.601 | 1.000 | 1.000 | 0.993 | 0.503 |
| k = 12 | 0.4884 | 0.601 | 1.000 | 1.000 | 0.993 | 0.503 |
| k = 16 | 0.4884 | 0.601 | 1.000 | 1.000 | 0.993 | 0.503 |
| lexicographic, full child mask | 0.4585 | 0.567 | 0.9955 | **0.9955 (×1.0045)** | 0.932 | 0.504 |
| greedy clustering (3 slices) | 0.4059 | 0.413 | 1.209 | 1.209 | 0.824 | — |
| today's key, 32-child chunks | 0.4490 | 0.554 | 1.991 | 1.991 issue / 0.996 bytes | 1.822 | — |
| lex, 32-child chunks | 0.4061 | 0.503 | 1.983 | 1.983 / 0.991 | 1.648 | — |
| today's key, 128-child chunks | 0.5519 | 0.678 | 0.503 | 0.503 issue / 1.006 bytes | 0.563 (per 128-bit OR) | 0.251 |
| (wide pass) lex, 128 | 0.5215 | 0.643 | 0.5005 | 0.5005 / 1.001 | — | 0.252 |
| (wide pass) today's key, 256 | 0.6260 | 0.767 | 0.2537 | 0.2537 / 1.015 | — | 0.126 |
| (wide pass) lex, 256 | 0.5985 | 0.737 | 0.2524 | 0.2524 / 1.010 | — | 0.126 |

(wide-pass rows: the 4 typical slices 712012851, 502136830, 4977728, 952265258 run again with the wide list,
`raw/w_64_*.txt` → `raw/analysis_64_wide.txt`; slices 0 and 1073741823 are in `raw/analysis_64_wide_all6.txt`. The
wide run's `code` row equals the main run's on every slice, so the two passes share one baseline.)

- **The curve "kept fraction against bits of key" is flat after 8 bits**: 1.000 → 0.738 → 0.593 → 0.518 →
  0.492 → 0.488 → 0.488 → 0.488 (k = 0, 2, …, 16). Lexicographic on all 64 digits gets 0.459, greedy
  clustering (the strongest chunking I could build for one job) 0.406: the practical floor of the common-mask
  skip for 64-child chunks of one job is about 0.41, ×1.21 below today's 0.49 in visits [M].
- **None of it reaches the lanes.** Lane slots are set by (probe, round) listings: a probe costs 16 lanes in a
  round if any of the round's 16 chunks keeps it. Keys beyond 4 bits change lane slots by < 0.05 %; lex by
  −0.45 %; greedy *adds* 21 % (its chunks are good alone but heterogeneous within a round). Busy 0.605 is a
  property of the round, not of the key.
- **Oracle** (a probe listed for a round only if some chunk of it gives a nonzero word, i.e. a perfect skip test
  at any cost): 0.503 of today's lane slots. No skip test of any kind can do better than ×1.99 in this layout,
  and the common-mask skip is already as good as orders can make it.
- Chunk width is the only lever that moves lane slots (×0.5 per doubling); whether that is work depends on what a
  wider slot costs on the card (Q5).

### Something not asked that matters more: almost every kept visit is empty [M, 8 typical slices]

- Today **91.1 % of kept visits produce a zero word** (986.3M kept, 87.5M records); only 5.4 % of lane slots
  produce a record, and a record holds 1.08 survivors. In L order with the extended digits 98.7 % of kept visits
  are empty. The pairing's cost is dominated by proving emptiness, not by finding survivors.
- That emptiness is not cheaply predictable by anything the counts can see: the oracle (list a probe for a round
  only if a word will be nonzero) is 0.503 of today's lane slots, so a free and perfect predictor would give ×2.0;
  every exact predictor I can write costs about as much as the 17-OR word it would save (a pair-cover test, for
  instance, is 17 ANDs per visit). The ×2.0 is the ceiling of the whole skip family in this layout.

## Q2: the magnitude of L [M, 8 typical slices]

Proof and exactness argument: the first section below. Every number here is from the code's own tops, children
and classes, children of a job re-sorted.

| order, interval for the extended certificate | dead (a) self-collision | dead (b) common mask with ext. digits | dead (c) either | kept | ext. digits per visit (mean) | ORs / kept | records | survivors | checked | work rel. | oracle lanes rel. |
|---|---|---|---|---|---|---|---|---|---|---|---|
| today (key 8), none | 0 | 0.5082 | 0.5082 | 0.4918 | 0 | 16.38 | 87.54M | 94.27M | 2.703M | 1 | 0.503 |
| today's order, exact chunk interval | 0.0243 | 0.5094 | 0.5252 | 0.4748 | 0.10 | 16.50 | 80.45M | 86.37M | 2.460M | 1.0136 | 0.483 |
| **L order, exact chunk interval** | **0.5060** | 0.0003 | 0.5060 | **0.4940** | 2.37 | 18.69 | **12.84M** | **12.94M** | **0.352M** | **1.1194** | 0.116 |
| L order, 32-child chunks | 0.5323 | 0.0003 | 0.5324 | 0.4676 | 2.52 | 18.86 | 10.85M | 10.89M | 0.295M | 2.251 issue / 1.126 bytes | 0.196 |
| L order, no extension (plain) | 0 | 0.0003 | 0.0003 | 0.9997 | 0 | 16.40 | 91.70M | 94.27M | 2.703M | 1.2303 | 0.612 |
| hybrid j = 1, cell | 0.0723 | 0.4498 | 0.4904 | 0.5096 | 0.30 | 16.67 | 69.61M | 73.66M | 2.065M | **1.0835** | 0.459 |
| hybrid j = 2, cell | 0.1118 | 0.3713 | 0.4426 | 0.5574 | 0.46 | 16.84 | 60.81M | 63.55M | 1.757M | 1.1352 | 0.437 |
| hybrid j = 3, cell | 0.1711 | 0.2669 | 0.3911 | 0.6089 | 0.71 | 17.05 | 51.21M | 52.99M | 1.457M | 1.1215 | 0.392 |
| hybrid j = 4, cell | 0.2533 | 0.1480 | 0.3621 | 0.6379 | 1.08 | 17.37 | 39.23M | 40.21M | 1.102M | 1.1287 | 0.317 |
| hybrid j = 5, cell | 0.3402 | 0.0339 | 0.3614 | 0.6386 | 1.49 | 17.76 | 28.86M | 29.37M | 0.803M | 1.1403 | 0.243 |
| hybrid j = 6, cell | 0.4135 | 0.0003 | 0.4136 | 0.5864 | 1.87 | 18.12 | 21.49M | 21.77M | 0.594M | 1.1507 | 0.187 |
| hybrids j = 1–6, exact chunk interval | within 0.01 of the cell rows | | | 0.505–0.633 | | | | | | 1.085–1.149 | |

(dead fractions are of all visits; (a) and (b) overlap, (c) is their union; "work rel." = lane slots × 17 plus
the extended digits the slot must also OR, against today's; hybrid rows without extension in `raw/`.)

- **(a)** In L order half of all visits (0.506) are dead by self-collision alone, without reading a child — the
  director's prior said "the same size as the common-mask skip": it is, almost to the digit (0.506 against
  0.508).
- **(b)** In L order the common mask is empty (children of a chunk share nothing; 0.0003 dead), so the two skips
  do not add: **(c) = 0.506 in L order against 0.508 today**. Every hybrid lies between and keeps more
  (0.51–0.64). The two skips are strongly anti-correlated in the sort, as feared.
- **(d)** Extended digits per visit in L order: 0: 0.5 %, 1: 10.7 %, 2: 47.0 %, 3: 36.0 %, 4: 5.6 %, 5: 0.2 %
  (mean 2.37; 2.17 over kept visits); in hybrids 0.30 (j = 1) to 1.87 (j = 6) [M, `hist=` fields].
- **(e)** With the extended digits ORed, records fall ÷6.8 and survivors ÷7.3 in L order (12.84M and 12.94M on
  8 slices against 87.5M and 94.3M); `checked` (what reaches the full check) ÷7.7. But each kept slot now ORs
  18.7 digits, lanes stay as busy as today (0.619), so the kernel's **work rises ×1.12**.
- **Best exact combination of Q2: none beats today.** The cheapest is hybrid j = 1 at ×0.923 (1.0835) [M].
- **Exactness, mandatory check [M]:** on all 10 slices, every survivor of today's word that any extended
  variant discards was taken through brute force (n², n³ in full): 0 nice, 0 claim failures (the digits at the
  claimed positions are the claimed digits, and with the bottom's 20 they contain a repeat). Counts on the 10
  slices: L order 85,655,250 discarded (2,464,667 of them would have passed the prefilter), hybrids 21.0M–77.0M
  each, today's order with exact interval 8.5M; **778,087,960 discarded survivors checked in total, 22,891,953 of
  them passing the prefilter, 0 nice, 0 claim failures**
  (`raw/analysis_64.txt`, "Exactness"). Plus ~20,000 random intervals per slice cross-checked against
  `top_cert_split` and containment (instrument section).

## Q3: digit 10 from the bottom's side [M, 8 typical slices]

- (child, a0) pairs whose two new digits (digit 10 of n² and n³: `(d10(r²) + 2·r0·a0) mod 64`,
  `(d10(r³) + 3·r0²·a0) mod 64`) collide with each other or with the child's 20: **0.5381** (9.29e9 of 1.73e10;
  the director's 54 % [P] confirmed).
- With a per-(chunk, a0) dead word ORed into each kept visit: **records 87.54M → 42.05M (×0.480), survivors
  94.27M → 43.54M (×0.462)**; `checked` unchanged (every removed survivor fails the prefilter, which tests the
  same digits: 0 violations [M]); visits whose dead word covers the whole chunk: 0.01 % of kept (no skip, as
  expected).
- Cost [J]: building the 64 dead words per chunk is about 45 ops per child (coset-table lookups, one per bottom
  digit and power) plus a 64×64 transpose: ~3.3k ops per chunk, about half the chunk's pairing work (≈ 385 lane
  slots × 17 ≈ 6.5k ORs); plus one OR per slot (+6 %). It moves work from the expansion (records ÷2) into the
  main kernel: net negative for the kernel, small for the slice.

## Q4: sharing ORs between probes [M]

Probes' digits written in descending digit frequency (of the job's probes); sharing = the OR of the common
prefix with the previous probe is reused (a trie walk).

| model | today (17 ORs per slot) | probes' own digit counts | shared, probes by top value | shared, probes in mask (trie) order |
|---|---|---|---|---|
| per chunk, over kept probes (dense ideal; 8 slices) | — | 1 | 0.939 | 0.832 |
| lane model, summed over slots (8 slices) | 1 | 0.964 | — | **0.7945 (×1.26)**; with lex order 0.7908 |
| lockstep, 16 stream segments, wave of 4 streams (RDNA wave64) | 1 | 0.991 | — | **0.865 (×1.157)**; with lex 0.861 (×1.162) |
| lockstep, wave of 2 streams (CUDA warp32) | 1 | 0.980 | — | **0.836 (×1.196)** |

(lockstep rows: wide pass, 4 typical slices, `raw/analysis_64_wide.txt`; the list of a round is cut into 16 contiguous segments, one per
stream, and a wave pays its largest per-step OR count; ratios are against the same lockstep walk at 17 ORs per
slot, which is itself 1.019 × today's lane slots × 17 because the 16 segments are uneven at the end of a list.) Needs a stack of up to 17 partial ORs per lane (34 32-bit
registers on a kernel at 72–120) and a variable trip count. Below ×1.3 alone; with lex ×1.16–1.20.

## Q5: one cost model [M for counts, J for the per-visit costs]

| variant | kept visits rel. | ORs rel. (dense) | lane slots rel. | busy | work = lane slots × ORs per slot, rel. | × against today |
|---|---|---|---|---|---|---|
| today (key 8, 64) | 1 | 1 | 1 | 0.6050 | 1 | 1 |
| best Q1 order: lex, 64 | 0.932 | 0.932 | 0.9955 | 0.567 | 0.9955 | ×1.0045 |
| Q2 L order + extension | 1.004 | 1.146 | 0.982 | 0.619 | 1.1194 | ×0.893 |
| best Q2 hybrid (j = 1, cell) | 1.036 | 1.055 | 1.068 | 0.587 | 1.0835 | ×0.923 |
| Q3 dead word (today's order) | 1 | 1.061 | 1 | 0.605 | 1.059 (+1 OR) + build | ×0.94 or less |
| Q4 trie (today's order), lockstep wave64 / warp32 | 1 | 0.83 | 1 | — | 0.865 / 0.836 | ×1.157 / ×1.196 |
| oracle skip (today's order) | — | — | 0.503 | 1.0 by construction | 0.503 | ×1.99 (unreachable bound) |
| 128-child chunks (key 8), bytes / issue | 1.12 | — | 0.503 | 0.678 | 1.006 / 0.503 | ×0.99 / ×1.99 |
| 256-child chunks (key 8), bytes / issue | 1.27 | — | 0.2537 | 0.767 | 1.015 / 0.2537 | ×0.99 / ×3.9 |
| L order + extension, 128-child chunks | 1.09 | — | 0.495 | 0.672 | 1.124 / 0.562 | ×0.89 / ×1.78 |

- Today's model: busy 0.6050 against the card's 60.5 % [M]. Its work counted with each probe's own digit count
  instead of the unrolled 17 is 0.964 (the padding to MAXPOP costs 3.6 %).
- Wider chunks under a two-part slot cost (half of today's slot is the LDS-bandwidth floor and scales with
  width, half is fixed: `G2/BENCH.md`, 17.6 ps measured against an 8.7 ps floor): 128 → 0.503 × 1.49 = 0.75
  (**×1.33**), 256 → 0.254 × 2.47 = 0.63 (**×1.6**) [J]. Not a count; one microbenchmark of phase 3b at width
  128 decides it.

### What each variant needs per visit (Q5, the decision) [judged from the kernel's code, `gpu.rs` phases 3a/3b]

| variant | data per probe | data per chunk (or round) | decision per (probe, chunk) visit | extra per kept slot |
|---|---|---|---|---|
| today (key order, common-mask skip) | 17 digit codes (`tdig`, 4 words) | per round, a 16-bit chunk mask per digit value (`cmv`, from the transpose) | 17 lookups OR'd per (probe, round), i.e. ~1.1 op per visit | none (17 ORs, unrolled) |
| Q1 other keys, lex, greedy | same | same | same | none; the sort is the parents' (`hsort`) or, for lex/greedy, a sort on child masks per class (more expensive than the 8-bit bucket sort; greedy is O(children²) per job) |
| Q2 L order, exact interval | top value T (2 words) | the chunk's first and last L | n = T·b⁴ + L at both ends, n² and n³ high parts (about 12 32-bit multiplies per end for n², 20 for n³), compare, extract 2–4 digits, test against the probe's mask: ~60–90 ops, i.e. 4–5× a whole word | the extended digits (mean 2.2, up to 5): a variable-length OR tail |
| Q2 L order, by breakpoints | the L values where n² position 16/17 and n³ position 29/30 change (about 20–45 per probe over L's 1.7e7, from the widths in NOTES §4) and the digits between | first L, last L | probes walk chunks in L order: a pointer advance and a table read, ~3–5 ops | as above |
| Q2 hybrid (j bits of L, then the key) | a 2^j-entry table (dead bit + ≤ 3 digits) per top, built once per slice from n², n³ at the 2^j + 1 cell ends (shared by the top's 8 jobs at base 64, 1 at base 65); priced in Q6: at base 65 it costs more than it saves | the cell range of the chunk | one table read (two for a chunk spanning two cells) | as above |
| Q3 dead word per (chunk, a0) | a0 = h mod 64 | 64 words (one per a0), built per chunk: per child ~45 ops (coset table lookups) + one 64×64 transpose ≈ 3.3k ops per chunk, about half the chunk's pairing ORs (≈ 385 lane slots × 17 ≈ 6.5k) | none (no visit is skipped: 0.01 % of kept visits are fully dead) | one OR (+1/17 ≈ +6 %) |
| Q4 shared ORs between consecutive probes | the probe's digits in a fixed digit order and its LCP with the previous listed probe | none | none | variable-length loop (uniform within a 16-lane stream, divergent across the 4 streams of a 64-lane wave); a stack of up to 17 partial ORs (34 32-bit registers) |

## Q6: base 65 [M, 2 slices, all 4,160 jobs each; `raw/s_65_*.txt` → `raw/analysis_65.txt`]

Slices 767142814 and 364171716 (`random.Random(20261165).randrange(65**5)` ×2), two-word masks (`u128`), the
generic certificate walk (no base-64 fast path). Base 65 is about 8× a base-64 slice here (1.27M parents, 1.70M
tops, 42.1M children, 270M flat visits), so it ran a reduced list of 7 variants (`q6`) and then a second one
(`q6b`, below). The wide kernel ORs `maxpop` = 18 words per slot at base 65 (`gpu_wide.rs`
`WideCaps::for_base`), so work here is lane slots × 18 (+ extension).

**Q0 at base 65:** both slices equal `slice_join`'s counters exactly (children 42,111,669 / 42,209,161; flat
270,407,872 / 270,680,341; kept 166,429,655 / 166,491,195; records 15,354,420 / 15,356,190; survivors 16,485,076 /
16,488,269; checked 526,498 / 527,292).

| variant (64-child chunks) | dead (a) | dead (b) | kept | ORs / kept | records | survivors | checked | busy (rounds) | work rel. | × |
|---|---|---|---|---|---|---|---|---|---|---|
| today (key 8) | 0 | 0.3847 | **0.6153** | 16.11 | 30.71M | 32.97M | 1.054M | **0.711** | 1 | 1 |
| key 12 | 0 | 0.3899 | 0.6101 | 16.11 | 30.60M | 32.97M | 1.054M | 0.705 | 1.000 | ×1.000 |
| lex | 0 | 0.4110 | 0.5890 | 16.11 | 30.38M | 32.97M | 1.054M | 0.698 | 0.975 | ×1.026 |
| **L order + extension** | **0.5577** | 0.0002 | **0.4423** | 18.76 | **3.74M** | 3.78M | 0.119M | 0.691 | **0.879** | **×1.138** |
| hybrid j = 1, cell | 0.1273 | 0.3312 | 0.5844 | 16.53 | 22.53M | 23.85M | 0.760M | 0.696 | 0.993 | ×1.008 |
| hybrid j = 2, cell | 0.2660 | 0.2693 | 0.5339 | 17.15 | 14.10M | 14.68M | 0.463M | 0.690 | 0.944 | ×1.059 |
| hybrid j = 3, cell | 0.3379 | 0.1970 | 0.5283 | 17.54 | 10.28M | 10.58M | 0.331M | 0.744 | 0.886 | ×1.129 |

Second pass (`q6b`, slice 767142814 only; `raw/q6b_65_767142814.txt` → `raw/analysis_65_q6b.txt`; the second
slice of this pass was stopped at 08:31 UTC to leave time for `q6c`, partial raw in `raw/aborted/`):

| variant | dead (a) | dead (b) | kept | records | busy | work rel. | × |
|---|---|---|---|---|---|---|---|
| hybrid j = 4, cell | 0.3741 | 0.1206 | 0.5477 | 4.28M | 0.810 | 0.852 | ×1.174 |
| **hybrid j = 5, cell** | 0.3997 | 0.0444 | 0.5729 | 3.79M | 0.869 | **0.8385** | **×1.193** |
| hybrid j = 6, cell | 0.4298 | 0.0005 | 0.5699 | 3.36M | 0.875 | 0.843 | ×1.186 |
| L order, 32-child chunks | 0.6312 | 0.0002 | 0.3688 | 1.14M | 0.578 | 1.773 issue / 0.886 bytes | |
| L order, 128-child chunks | 0.4675 | 0.0003 | 0.5325 | 2.90M | 0.830 | 0.422 issue / 0.844 bytes | ×2.4 / ×1.19 |

(today's row on this slice: kept 0.6155, busy 0.711, records 15.35M; 0 nice and 0 claim failures among the
66.7M survivors these five variants discard.)

- **The picture differs at base 65, in the direction the brief asked about:** today's skip is weaker there (kept
  0.615 against 0.492 at base 64; busy 0.711), while the L order's self-collision is a little stronger (0.558
  against 0.506). So L order beats today: **×1.138 in work**, records ÷8.2, survivors ÷8.7 [M], and the hybrid with
  5 bits of L **×1.193** (one slice) [M]. The best exact Q2 variant at base 65 is below ×1.3 on its own.
- Exactness at base 65 (`raw/analysis_65.txt`, "Exactness"): 79,006,003 discarded survivors checked by brute
  force over the 4 extended variants and 2 slices (2,542,357 of them passing the prefilter); L order alone
  29,195,567; **0 nice, 0 claim failures** [M].
- Q3 at base 65: (child, a0) dead 0.5314; records ×0.487, survivors ×0.469, 0 violations [M].
- Q4 at base 65 (today's order): summed over slots 0.772 of 18 per slot (×1.30); lockstep wave of 4 streams
  0.837 (×1.195), wave of 2 0.809 (×1.24) [M; the instrument's lockstep baseline is 17 per slot, rescaled to 18
  exactly since the 17 is a constant per step]. The oracle skip is 0.602 of today's lane slots (×1.66).

**Q2 orders combined with Q4's sharing** (`q6c` pass: the probes' own digits shared in mask order, each lane's
extension digits paid per lane; `box/combos.py` → `raw/combos_65.txt`, `raw/combos_64.txt`; work against today's
kernel, lane slots × maxpop, interleaved streams; the lockstep walk itself costs 1.021 × that at 17/18 per slot):

| variant | base 65 (2 slices): no sharing | + sharing, wave 64 | + sharing, warp 32 | base 64 (2 slices): no sharing | + sharing, wave 64 | + sharing, warp 32 |
|---|---|---|---|---|---|---|
| today's order | 1 | ×1.170 | ×1.211 | 1 | ×1.133 | ×1.173 |
| lex | ×1.026 | ×1.199 | ×1.241 | ×1.004 | ×1.138 | ×1.178 |
| L order + extension | ×1.138 | ×1.265 | ×1.299 | ×0.893 | ×0.990 | ×1.016 |
| hybrid j = 3, cell | ×1.129 | ×1.282 | ×1.321 | ×0.891 | ×1.002 | ×1.035 |
| **hybrid j = 5, cell** | **×1.191** | **×1.346** | **×1.385** | — | — | — |

- **In counted work, base 65's hybrid j = 5 with probe sharing passes ×1.3** (×1.35–1.39) [M]. The counts leave
  out what the hybrid's decision needs: per top, the extended certificate of each of its 2^j cells, i.e. n² and
  n³ at the 2^j + 1 cell ends (33 at j = 5). At base 65 a top is a probe of exactly one job (one root:
  1.70M tops, 410 probes per job), so a top's whole pairing is 137 lane slots; the hybrid + sharing saves
  0.257 × 137 ≈ 35 of them. On the 3080 the tops stage computes ≈ 440k certificates in 0.393 ms per slice
  (0.89 ns each) and the main kernel spends 27 ps per lane slot (5.542 ms / 203.6M), so one certificate costs
  ≈ 33 lane slots; even at a tenth of that per cell end, 33 ends cost ≈ 110 lane slots per top, three times the
  35 saved [J, from measured stage costs; base-64 prices applied to base 65]. j = 3 (9 ends, ≈ 30 lane slots at
  the same tenth) about breaks even against its ≈ 30 saved. **So no variant passes ×1.3 once its decision data is
  paid for**, at either base. A way to get a top's cell certificates for a few lane slots each (an incremental
  walk over the cell ends, done in the tops stage) is the one thing that would reopen base 65; I did not find
  one that is obviously that cheap.

## The mutation test on `dev/mo-clean` `c2152084` [M]

Raw: `raw/mut/table.txt` (+ one `.diff` and `.log` per mutant), `raw/mut/baseline.log` (unmutated head: `cargo test
--release -p nice_common --lib midout::` rc 0), `raw/mut/head.txt` (`c2152084`). Script: `box/mut3.py` (the G2
`mut2.py`, paths only changed; line numbers remapped by text from `06d55495`) over `box/mut_list.sh` (the 27
mutants of `G2/build7p/rv/mut2.sh`), own clone `/w/mut` and target `/w/tmut` on the box, run beside the study.

| mutants | result | killed by |
|---|---|---|
| M01–M04, M22 (top certificate, `mhi`) | killed | `top_certificate_equals_its_definition` (M02 also `whole_base_10`) |
| M05, M06, M09, M11–M16, M19, M23, M25 | killed | the whole-base brute-force tests |
| M07, M08, M18, M20, M24 (prefilter, `mm`) | killed | `prefilter_at_base_64_equals_full_digits` (+ whole-base tests except M18) |
| M10a (extra root class) | killed | `known_nice_and_roots`, `roots_equal_production_residue_filter` |
| M10b (extra small root) | killed **after a fix of the list**: the list's sed carried the bash-quoted `\\&\\&`, which put `\== target)` into `arith.rs` and did not compile (rc 101, no test named: `raw/mut/M10b_roots_extra_small.log`); rerun with `\&\&` (`box/mut_list_fix.sh`, `box/mut3fix.py`): `M10b_fixed_roots_extra_small` killed by `roots_equal_production_residue_filter` |
| **M17** (chunk key order reversed), **M21** (prefilter exemption changed on both sides), **M26** (common-mask skip off) | **survive** | none: the same three as the first run (`G2/PR12-NOTES.md` §6); M17 and M26 change only `Counts` work fields, which no ordinary test checks; M21 is the same text on both sides |

**27 mutants: 23 killed on the first pass, M10b killed after the list fix (24), 3 survive: the expected three.**

## What I would build first, and what I could not finish

- **Close the Q2 line** (the magnitude of L): measured ×0.89 for L order and ×0.92 for the best hybrid in the
  kernel's model; its record/survivor cuts (÷7) are worth at most the expansion's 8 % of a slice and cost more in
  the main kernel. Q3 likewise. Orders beyond today's key: ×1.0045 at best.
- **Base 65:** the counts cross ×1.3 only for hybrid j = 5 with probe sharing and before the per-(top, cell)
  certificates are priced; priced from the tops stage's measured cost they lose (Q6). I would not prototype it
  unless a cheap incremental way to produce those certificates in the tops stage turns up.
- **If anything, a one-day card microbenchmark of a 128-child (and 256-child) slot in phase 3b** (four or eight
  u32 per digit word, rounds of 1,024 children unchanged): it alone decides whether the ×0.5 lane slots of a
  wider word are ×1.0 or up to ×2 of kernel work. The counts for it are here (kept 0.552 / 0.627, busy 0.678 /
  0.768, records unchanged). Exactness is free (any chunking is exact).
- **Probe sharing (Q4)** is ×1.15–1.20 in lockstep: engineering, below the bar on its own; it composes with the
  width question.
- **Not finished / not done:** greedy clustering on 3 slices only (×0.83 in lanes there; not needed elsewhere for
  the conclusion); base 65 ran reduced lists (`q6`: 7 variants, 2 slices; `q6b`: hybrids j = 4–6 and L order at
  32/128 on one slice, the second stopped at 08:31 UTC; `q6c`: Q2 × Q4 on 2 slices), never the full 37-variant
  list (started at 07:17, stopped after 3 minutes: a slice of it would have taken about 1.5–2 h; `raw/aborted/`);
  the wide pass (chunk widths 128/256) on 6 slices of base 64, not 10, and not at base 65 except L order at
  128; the cost of the hybrid's per-(top, cell) certificates and of the L order's per-visit endpoints is judged
  from stage timings, not built or measured on a card; Q4's lockstep model ignores the 2-entry unroll of the
  real phase 3b and register pressure.

## The monotonicity argument (Q2), and why the extended tests are exact [proven]

Fix a top prefix p (digits 4–12 of n, at base 64 `p = n div 64^4`) and an interval I = [a, c] of n inside the
top's own interval T = [p·b^4, p·b^4 + b^4 − 1] (clipped to the base's range, as `unit_tops` clips it). For a
power e ∈ {2, 3} and a position q, put g_q(n) = floor(n^e / b^q).

1. n ↦ n^e is increasing on n ≥ 0 and x ↦ floor(x / b^q) is non-decreasing, so g_q is non-decreasing on I.
   Hence g_q(a) = g_q(c) implies g_q is constant on I.
2. The base-b digits of g_q(n) are exactly the digits of n^e at positions ≥ q. So "every digit of n^e at
   positions ≥ q is the same for all n ∈ I" ⇔ g_q(a) = g_q(c). If it holds at q it holds at every q' ≥ q
   (g_{q'} = floor(g_q / b^{q'−q})). The constant positions are therefore an upward-closed set {q ≥ q*}, which is
   what `cpu::top_cert_split`'s top-down walk finds (it stops at the first digit that differs; it gives nothing
   for a power whose length changes, where the leading digit differs).
3. **The top's certificate holds a fortiori on I:** I ⊆ T, so a g_q constant on T is constant on I with the same
   value. The certificate of I contains the top's positions with the same digits, plus possibly positions
   below them: the *extended digits* of I.
4. **Exactness.** For every n ∈ I, n² and n³ carry the certificate's digits at its positions (all ≥ k = 10), and
   their digits at positions 0..k − 1 are the child's 20 digits (n ≡ r mod b^k). If two certificate digits are
   equal (self-collision, test (a)), or a certificate digit is one of the child's digits (test (b), and the
   extended OR set (e)), then n² and n³ together repeat a digit and n is not nice. So these tests remove no nice
   number. They do remove pairs from the shape's survivor set, so `survivors`/`checked` (the audit counters) are
   different counts under them; the nice set is unchanged.

Both 3 and the exactness are also checked by the instrument at run time (below).

## The instrument

- `common/examples/mo_ceiling.rs` on the scratch branch `exp/mo-ceiling` (from `c2152084`, head `52120649`,
  10 ordinary commits; worktree `~/projects/nice/.worktrees/mo-ceiling`, pushed to `fork` as the archive; no
  pull request, nothing to `origin`, nothing on `dev/mo-clean`). It calls the CPU reference's own `parents`,
  `unit_tops`, `key_digits`, `child_mask`, `prefilter`, `top_cert_split` and copies `slice_join`'s preamble
  (key, class segments, probe lists) line for line, so the objects and the order are the code's. Per job it
  rebuilds the children in the code's order, then re-sorts them per variant and counts; jobs run on 18 threads.
  Every slice also runs `cpu::slice_join` itself on a 19th thread (`Q0REF` line), and Q0 compares the two.
- Built and run on the rented box only (`/w/ceil`, target `/w/tceil`, release, `nice_common` only):
  `cargo build --release -p nice_common --example mo_ceiling`, then `box/runslice.sh <base> <pip> 18 [greedy]`
  through `box/batch.sh`; raw output `raw/s_<base>_<pip>.txt` (+ `.err` progress); tables by
  `python3 box/analyze.py 64` (and `65`). `raw/v1/` is the first run of slice 712012851 with an earlier build
  (lane groups fixed at 16 chunks for every chunk size, no oracle counters); its common counters equal the
  final run's.
- **Which build made which raw file** (all on `exp/mo-ceiling`, `git log c2152084..`): `raw/v1/` a3e37266; the
  main base-64 pass `raw/s_64_*` binaries of 0055e1e1 → 9aeddec0 (rebuilt in place between slices; the default
  variant list and every counter used here are identical across them; only `code_c128`'s records, not used from
  this pass, were added in c4ad7a83); the wide pass `raw/w_64_*` 54936ec6 / ae5343e2 (the `wide` list is the same
  in both; the `CMD` line in those files names 9aeddec0, which is wrong: the binary was rebuilt at 07:18 before
  the pass started); the base-65 pass `raw/s_65_*` ae5343e2; `raw/q6b_*` 5214cc01; `raw/q6c_*` 53943f92 (base 64) and 52120649
  (base 65, which adds hybrid j = 5 to the `q6c` list). The box's setup: `box/setup.sh` (rustup 1.100.0,
  the repository's pin; two clones `/w/ceil`, `/w/mut`; two target directories). A copy of the instrument's
  final source is `box/mo_ceiling.rs`.
- **Self-checks at run time** (each slice; an assertion stops the run): the extended rule of `key_digits` over
  all digits agrees with `key_digits` on its 8; every top's certificate recomputed by the study's walk equals
  its mask; on about 20,000 random sub-intervals per slice (spans 2^0–2^24 inside real tops) the study's fast
  base-64 certificate equals the generic one, equals `cpu::top_cert_split` (incl. its `None` on a repeat), and
  contains the top's own certificate position by position with the same digits (point 3 above, checked).
- **The exactness check of every extended test (Q2)**, run on every slice and every variant, not sampled: every
  survivor of today's word that the variant's word drops (a bit set in today's word, clear in the extended one,
  or the whole visit dead) is taken through brute force: n² and n³ in full (`U384`), (i) its digits at every
  position the interval's certificate claims are the claimed digits, (ii) those digits with the 20 bottom digits
  contain a repeat, (iii) `arith::unique_digits` says not nice, and (iv) whether it passes the prefilter is
  counted. Counters `disc_claim_bad` (i or ii fails) and `disc_nice` (iii fails) must be 0.

### Cost model (Q5)

- *Lane slots* follow the kernel (`gpu.rs` phases 3a/3b): a round is 1,024 children (16 chunks of 64), a probe is
  listed for a round when any chunk of the round keeps it, and costs one lane per chunk of the round
  (`my_lslots += min(32, nlist − e0) · nch`). The brief's 64-chunk wave is reported beside it (`busy64`): it does
  **not** reproduce the card; the 16-chunk round does (below).
- *Work* = lane slots × 17 (the kernel ORs MAXPOP = 17 digit words per slot, unrolled, whatever the probe's
  popcount), plus, for an extended variant, Σ over listed (probe, round) of nch × the largest number of extended
  digits among the round's kept lanes (the slot must OR them too). "issue" counts a slot the same at any chunk
  width; "bytes" weights it by chunk width / 64 (an LDS-bandwidth-bound kernel; `G2/BENCH.md` puts the floor
  at 17 × 8 B / 128 B per clock = 1.06 clk per slot and the measured dense cost at about 2× that floor, so
  neither model is the card, and the two bracket it for chunk sizes other than 64).
- *ORs* = Σ over kept visits of the digits ORed (the dense ideal: every lane busy).
- *Oracle lane slots*: a probe listed for a round only when some chunk of the round gives a nonzero word: the
  floor for any skip test, however expensive, under this order and this lane layout.
