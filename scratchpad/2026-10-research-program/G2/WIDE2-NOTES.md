# The middle-out join, step 9W: the wide path's check, expansion and shared memory (2026-11-20, from 06:02 UTC)

Brief `G2/BUILD-BRIEF-9W.md` (rules of `BUILD-BRIEF-1.md`). Branch `dev/mo-clean` from `c2152084`, worktree
`~/projects/nice/.worktrees/midout-clean`, pushed to the fork only. Box: Vast 61587396, RTX 3080 at its host's
240 W cap, 16 threads visible with a 5-CPU quota (`cpu.max` 512000/100000), Ubuntu 24.04, CUDA 12.8, Mesa 25.2.8
lavapipe, Rust 1.100.0. Production hosts mapped to 127.0.0.1 and ::1 at 06:03 UTC before anything of ours ran
(`build9w/raw/proof_hosts_block.txt`; every timed or card run re-checks it first, `hosts_proof.txt` in its
directory). Box scripts `G2/build9w/box/`, raw logs `G2/build9w/raw/`. Labels as in `DESIGN.md`: [measured],
[proven], [judged].

The box's host was shared and busy (load average 15–28 on the host while nothing of ours ran): CPU timings move by
several per cent between runs; GPU timings were taken with nothing else of ours running.

## A. The sampled CPU check at base 65 (`commit A`)

### What was done

- `cpu::slice_join_threads(base, sh, pip, threads, sink)`: the CPU reference's slice on several threads, with
  `std::thread::scope` (no new dependency: `rayon` is a dependency of the client, not of `nice_common`, so it was
  not used). `slice_join` is `slice_join_threads` with 1 thread, and with 1 thread it runs exactly the old loop.
  Three independent pieces run in parallel:
  1. the parents: the bottoms' depth-first walk is split below digit 0 (one walk per first digit), then sorted by
     `r` as before;
  2. the tops: one unit (digit `k − 1`) per task (`unit_tops`, b tasks), put back in unit order;
  3. the classes: `threads` classes at a time; each class's survivors are buffered and passed to `sink` on the
     calling thread in class order once the wave is done (memory: one wave's survivors, ~33 MB at b65 with 4
     threads).
- `gpu::sample_threads(requested)`: 0 means the CPUs this process may use (`available_parallelism`, which reads
  the cgroup quota) less one for the thread that queues the device's work, at most `SAMPLE_THREADS_MAX` = 4, at
  least 1. `GpuOptions::with_cpu_threads`, `WideOptions::cpu_threads` (0 = that default); both benches take
  `--cpu-threads N`.
- The route switches the sampled check on at base 65 (`FieldJoin::cpu_check_default` is true for both paths), and
  the two comments that explained why it was off (`route.rs`, `WideOptions::cpu_check`) now give the measured times.

### Why the result is the same [proven]

- Counts: every field of `Counts` is a sum over parents, units or classes of integers; addition is order-free.
- The parents: the walk from each first digit produces exactly the residues below it, each once; the union over
  first digits is the single walk's set; the list is then sorted by `r` (distinct residues), so it is identical.
  The later stable sort by `(class, key)` starts from the same list, so the per-class order is identical.
- The tops: each unit's list is computed by the same function and put back at its unit's index.
- The survivors: within a class the work is the single-threaded loop, unchanged (the code was moved into
  `SliceSetup::class`, not altered); the classes' outputs are replayed in class order, so `sink` sees the same
  calls in the same order.
- Besides, neither comparison depends on order: the sampled check sorts both lists (`cpu_slice`,
  `wide_cpu_slice`, `sample_compare`, `wide_sample_compare` call `sort_unstable`), and its counts are sums.

### Tests [measured]

- Tier (a), new: `cpu::tests::threaded_slice_join_equals_single_threaded`: every slice of three small bases
  (b20 (2,4), b24 (1,4), b25 (2,5); survivors present) with 2, 3, 7 and 64 threads (more threads than classes
  included) in `u64` masks and 3 threads in `u128`: counts equal and the `sink` sequence equal element for element.
  11 s on the box.
- Tier (c), new: `cpu::tests::threaded_slice_join_real_slices` (feature `midout-box-tests`; `MIDOUT_CPU_THREADS`,
  `MIDOUT_CPU_SLICES`): base-65 slice 717171717 and base-64 slice 712012851 on 1, 2, 3, 4, 5 and 16 threads, every
  count and the survivor sequence equal to the 1-thread run's (`raw/cpu_a1/`). Pass.

### The thread-count table (box above, `raw/cpu_a1/run.txt`, 06:23–06:30 UTC, nothing else of ours running)

| threads | b65 slice 717171717 (s) | b64 slice 712012851 (s) |
|---|---|---|
| 1 | 105.89 | 29.47 |
| 2 | 58.13 | 18.78 |
| 3 | 40.35 | 13.23 |
| 4 | 33.41 | 10.72 |
| 5 | 23.98 | 6.78 |
| 16 (on a 5-CPU quota) | 27.00 | 14.27 |

Every row: survivors 16,482,926 / checked 527,041 / tops 1,701,945 / parents 1,268,336 (b65) and 11,768,560 /
337,904 / 238,813 / 1,042,046 (b64), and the survivors in the same order. The 5-thread rows are faster than
linear against the 4-thread ones: the host was shared and its load moved during the run (single runs; the order
was 1, 2, 3, 4, 5, 16); the field runs below are the better measure of what 4 threads take.

**Base 65 fits**: 4 threads (the default on this box) take 29–35 s during a field of ~57 s, i.e. 0.51–0.61 of the
field (≤ 0.8 required), and the host never waited for it (0.0 s in all five fields below). Single-threaded it
took 106 s here (70–93 s on earlier boxes).

### Does the check starve the device's thread? (`raw/chk_a1/`, 06:39–06:57 UTC)

Five warm fields per base with the check on (default threads: 4) and off, alternating (on first on fields 1, 3,
5), one process per run after a warm-up field; same binaries (`a1b`). "Alone" = the field's own time with the CPU
threads running beside it, before the check's device rerun; "whole" adds the rerun.

| base | off (mean s) | on, alone | on, whole | CPU slice | device rerun |
|---|---|---|---|---|---|
| 65 (fields 13731 … 260893) | 57.144 | 57.556 (+0.72 %) | 58.506 (+2.38 %) | 29.0–34.5 s, host waited 0.0 s | 0.86–1.03 s |
| 64 (fields 13107 … 222822) | 31.584 | 31.554 (−0.09 %) | 31.936 (+1.11 %) | 7.6–11.6 s, host waited 0.0 s | 0.32–0.43 s |

- **Base 64: no starvation** (−0.09 %, inside the pairs' ±3 % scatter; the pairs alternate which runs first and
  the first of each pair was the slower in 4 of 5). The check's whole cost at b64 is its device rerun (+1.1 %
  here; 0.16 s = +0.4 % on the 11-19 box): the rerun is not touched by this change (the final timing below
  compares the head with `c2152084`, both with the check on).
- **Base 65: +0.7 % while the 4 CPU threads run** (positive in all five pairs, 0.0–1.9 %), +2.4 % in all with
  the device rerun (~1 s of 57). Not capped further: base 65 has no 1 % limit in the brief and 3 threads would
  take ~40 s (still inside the field) for perhaps half the +0.7 % [judged]; the cap is one constant
  (`SAMPLE_THREADS_MAX`).
- Thread priority was not lowered (no portable call in `std`; `libc` would be a new dependency of
  `nice_common`) and was not needed at b64.

## B. Where the wide expansion spends its time

### Before: the time by part (`raw/xabl_base/`, 06:30–06:39 UTC) [measured]

Method: a diagnostic build of `c2152084` (never committed; `raw/xdiag.patch`) whose wide expansion reads ablation
bits from `MIDOUT_XABL` (ORed into its fault word); cumulative timing stops on base-65 field 77777 (4,225 slices),
one cold process per run (the one-time cost cancels in the differences): stop 3 = through the main kernel, stop 5
= through the expansion. Each ablation removes one part and keeps the rest's data flow live.

| run (stop 5 unless said) | field s | expansion ms/slice | what it removes |
|---|---|---|---|
| stop 3 (twice: 42.69, 42.71) | 42.70 | — | — |
| full (twice: 57.25, 57.29) | 57.27 | **3.45** | — |
| no list writes (prefilter still computed) | 57.11 | 3.41 | the survivor-list writes |
| trivial prefilter (`rf % 31 == 0`: ~3 % pass, as `pf_w2`) | 49.34 | 1.57 | `pf_w2` and `pf_w2_fixed`'s arithmetic |
| no per-bit work | 45.83 | 0.74 | child-list reads, clip test, prefilter, writes |
| no per-bit work, no top walk | 45.38 | 0.63 | + the probe-slot walk, `thd`, the top's context |
| no record read | 43.07 | 0.09 | everything but the slab walk and the plane sums |
| F_NOPF (every survivor written, no prefilter) | 58.10 | 3.65 | (the earlier "not the prefilter" comparison) |

**By part, per slice** (differences of the rows): launch, slab walk, plane sums 0.09 ms; record reads 0.54;
top walk and context 0.11; per survivor bit, the child-list read, clip test and writes 0.83 (of which the writes
0.04); **the prefilter's arithmetic 1.88 ms** (55 %). So the earlier reading (`BUILD-NOTES.md` §13.4: "not the
prefilter at all") was wrong: F_NOPF removes the prefilter but writes all 16.5M survivors instead of 0.5M, and
the two happened to cost about the same. What makes the prefilter dear here is not only its arithmetic but how
often a plane runs it: one record per lane and two loops (the record's low word, then its high word), so a plane
pays max(bits in a lo word) + max(bits in a hi word) rounds per take: ~3.4 rounds for ~35 bits per 32 records
[judged from the narrow path's bits-per-record histogram, §12.3 of `BUILD-NOTES.md`].

### What was removed (`commit B`)

1. **Two records per lane, one loop over both** (the base-64 path's `keep_bits2` pattern): each lane loads two
   records of a take together and walks the lowest set bit of the first nonzero of their four words (a lo, a hi,
   b lo, b hi), so a plane pays max over lanes of (bits of a + bits of b) prefilter rounds instead of max(a lo) +
   max(a hi) per record. The per-record work moved into `wrec_top` (probe slot → top index, child-list position)
   and `wtop_ctx` (the top's h and unit, its range-clip bounds as two numbers `[lo, hi]` on r_f, the small-n
   flag); the slice's digits and their value are read once per thread; `put_bits_w` writes the kept bits.
2. **The prefilter's digit test as one mask**: every digit of r² and r³ mod b^(k+2) ORed into one two-word mask,
   distinct iff it holds 2(k + 2) bits; the four digits at positions k and k + 1 into a second that must miss the
   top's `mhi`. The same predicate as testing each digit against the earlier ones [proven: a set of 2(k + 2)
   digits is repeat-free iff its one-hot union has 2(k + 2) bits], with ~5 fewer operations per digit.
   `pf_w` (the earlier digit form, A/B only) is unchanged.

Not done: the survivors' work spread over a plane (each set bit a work item: removes the remaining divergence,
needs the record's context in shared memory or reloaded per bit); u32 one-hot words instead of `(u64, u32)` in
`dbit` (small). The order of the entries in the survivor list changes (it was already set by the planes'
atomics; nothing reads it in order: the check is per entry, its account is a count and an index sum).

### After [measured]

Interleaved stops on field 77777, `c2152084` (ref) against the B tree (new), 07:39–07:46 UTC, with the A gate's
lavapipe tests running on the CPU beside it (`raw/bstop_b1/`):

| | stop 3 (s) | stop 5 (s) | expansion ms/slice |
|---|---|---|---|
| ref | 43.02, 42.98 | 56.42, 57.35 | 3.29 |
| new | 42.57, 43.04 | 50.76, 51.80 | **2.01** |

−1.28 ms per slice (−39 %), −9.4 % of a base-65 slice. The quiet five-field timing is in §D.

Exactness of B (CUDA, `raw/bpar_b1/`, binary of the B tree before formatting; the committed tree differs by
`cargo fmt` and one doc-table row): `wide_slices_equal_cpu` b30 100, b40 1234, b50 77777; **b65 717171717,
532260419 (the range's start's clipped top), 1160290624 (the last slice)**; with the prefilter off (whole survivor
sets) b40 1234 and b65 717171717; **b64 forced wide 712012851** (checked 337,904 = the narrow path's);
`wide_whole_small_bases_vs_brute_force` (17 shapes, bases 10–25, nice = {69}); `wide_faults_are_loud` b65 (every
fault loud, F_BAD_PARENT and F_PF_DROP by the sampled check). All pass. Tier (b) on lavapipe (both compilers,
wide b40 included) and the card tier: §E.

ACO for GFX1201 (W 64, `raw/spv/c1_w/`, the B+C tree): `wexpand` 72 VGPRs, 20 waves, 1,174 instructions (was 48,
32, 2,015); its per-bit loop 658 vcyc against 771 per loop before (now one loop where there were two).

## C. The wide main kernel's shared memory on the RX 9070 XT (`commit C`; offline)

### The 3 KB [measured from the SPIR-V's explicit layout]

`wide_kernel` at base 65, W 64 (`raw/spv/base_w/`, `c2152084`): 10 shared arrays, densely packed, ending at
23,680 bytes (ACO's granule: reported 24,576), 8 waves per SIMD, 192 VGPRs:

| array | entries | bytes |
|---|---|---|
| `prob_d` (probe digits 0–15, 4 words) | 576 × 16 B | 9,216 |
| `sl` (slice rows: 67 × 32 words) | 2,144 | 8,576 |
| `pq` (pending parents / probe list) | 640 | 2,560 |
| **`prob_e` (probe digits 16–17)** | **576** | **2,304** |
| `cmv` | 96 | 384 |
| `comm`, `commh`, `wcnt`, `s_nl`, `s_np` | 32 each | 640 |
| **total** | | **23,680** |

The 12-wave threshold on GFX1201 is 21,504 bytes (128 KB per WGP / 6 workgroups of 4 wave64, 1 KB granule; the
narrow kernel sits exactly at it). Over by 2,176 bytes raw (3,072 as ACO rounds).

### What was changed

- `prob_e` is gone for `maxpop` ≤ 18: the four probe words use bits 0–27 (four 7-bit digits each); digits 16 and
  17 go into bits 28–31 (low four bits in words 0 and 2, high three in words 1 and 3) when the probes are loaded,
  and `probe_digit` reads them back (`(w0 >> 28) | ((w1 >> 24) & 0x70)`). Above 18 (base 68: 19) the fifth array
  stays, so bases 68–70 run the same code as before. The probe window (576), the instances per job and the rows are
  unchanged.
- `s_np` and `s_nl` are one word each (only `[0]` was ever used).
- New layout: 21,128 bytes (`raw/spv/c1_w/`). Not changed: `sl`'s odd row stride (67, for conflict-free banks),
  `pq`, `cmv`.

### The offline compile [measured, ivory, container `g2mesa`: Mesa 26.0.8 RADV/ACO for GFX1201 on the drm shim]

SPIR-V dumped on the box (test binary with `cubecl/spirv-dump`, `MIDOUT_FORCE_W=64`, lavapipe COMPILE-ONLY run
of `wide_slices_equal_cpu` at b65, `box/wdump.sh`), compiled with `aco.sh`, summarised with `preflight.py`; the
same method for `c2152084`'s binary as the before. 13 modules each; spirv-val passes all but `wscatter` (the
known duplicate-`ArrayStride` note, unchanged). 25 minutes including the dump binaries' builds.

| `wide_kernel`, b65, W 64 | `c2152084` | B + C |
|---|---|---|
| LDS (ACO) | 24,576 | **21,504** |
| waves per SIMD | 8 | **12** |
| VGPRs | 192 | 120 |
| spills, scratch | 0, 0 | 0, 0 |
| instructions | 2,393 | 2,412 |
| phase 3b loop (vcyc / LDS ops per wave-iteration) | 181 / 43 | 187 / 41 |
| phase 3a loop | 56 / 23 | 59 / 22 |

ACO now gives the kernel the narrow kernel's resources (120 VGPRs, 21,504 B, 12 waves). The digit extraction
costs +3 % VALU in phase 3b and saves 2 LDS loads per wave-iteration.

Exactness of C (CUDA, `raw/cpar_c1/`, the B+C tree): b65 717171717 and 532260419 and b64 forced wide 712012851
(`maxpop` 17: digit 16 through the nibbles) against the CPU reference n for n and every count; `wide_faults_are_loud`
b65 (every fault loud). Then the full gate (§E). Base 68 and up (`maxpop` 19) compile the same code as before
(`maxpop > 18` keeps `prob_e`); not run (no card here fits b68).

### The predicted effect on the RX 9070 XT [judged; it cannot be timed today]

What is known: on that card b65 took 47.80 s per warm field (11.31 ms per slice, 3.02 fs; 3.12 with the cold
field) and b64 4.312 ms (0.99 fs), main kernel 2.607 ms (`build4s/window_1119/`). On the 3080 b65's main kernel is
~6.7 ms of a ~13.5 ms slice. If the 9070's non-main stages relate to the 3080's at b65 as they do at b64 (1.705 /
2.026 = 0.84), the 9070's b65 main kernel takes ~5.6 ms, against ~3.2 ms if it related as at b64 (0.47 × 6.7): the
wide kernel is ~1.8× slower there than the narrow kernel's analogy, which is what 8 waves instead of 12 would do
to a latency-bound kernel (×1.5 at most from occupancy).

- **Range: 0 to −1.9 ms per b65 slice from C** (0 if the kernel is issue-bound at 8 waves; −1.9 ms if it gains
  the full ×1.5), plus B's expansion work, which on that card is a smaller share (the narrow expansion takes 0.36 ms
  there against 1.1 ms on the 3080): −0.2 to −0.6 ms [judged].
- **Prediction: b65 on the RX 9070 XT 2.4–3.0 fs per admissible n, central 2.7** (from 3.02 warm), i.e. ×2.4–3.0 of
  base 64's 0.99 there (×3.1 before), central ×2.7.
- What could make it miss: RADV choosing different code at 120 VGPRs; the kernel being bound by LDS bandwidth
  (phase 3b's 41 LDS ops per wave-iteration) rather than latency; the +3 % VALU of the digit extraction.

## D. The timings (`raw/five_final/`)

(pending)

## E. Tiers per commit

| commit | lint (`just lint` + 3 middle-out clippy sets) | production's CI tests | tier (a) | tier (b) lavapipe WGSL / SPIR-V | card tier (CUDA) | raw |
|---|---|---|---|---|---|---|
| A `1d4d6920` | clean | workspace pass; `nice_common --features gpu --lib` 293 pass, 0 fail, 72 ignored; client cubecl-cuda 27 pass | release pass (219 s), debug pass (2,088 s, CPU-contended) | 8 / 8 pass each | tier (b) on CUDA, 2 b64 slices n for n, both prefilter forms, narrow faults, parent sharing, b65 slice, wide faults: all pass | `lint_a1b/`, `suite_a1/`, `a1/`, `card_a1/` |
| B `64cf6c24` | clean | all three pass | release pass | 8 / 8 pass each | all pass | `x_b1/`, `card_b1/` |
| C `85185fef` | clean (`l_c1/`; the gate's first lint run found two decimal bit masks, fixed before the commit) | all three pass | release pass | 8 / 8 pass each | all pass | `x_c1/`, `l_c1/`, `card_c1/` |

Every tree was tested as the exact committed tree, file for file (md5 of every `midout/*.rs` compared between
ivory and the box), except that C's suite and tier runs were built before a code comment's wording and a mask's
spelling (`112u32` → `0x70u32`, the same value) were changed; its lint and card tier were run on the final file.
Tier (a) in debug was run for A only (CI runs release; 35 minutes here). Lint in `just lint` is the box's
`just` 1.59.

## F. The design directory, re-checked against `85185fef`

`tools/check_refs.py interactive/midout-map.html`: 14 BAD of 88 at the new head (all line shifts from A in `gpu.rs`,
`cpu.rs`, `route.rs`), fixed in the map's `N` array (each mapped by its old line's exact text at `c2152084`):
88 refs, 0 bad. `DESIGN.md`'s inline refs (`tools/print_inline_refs.py`): 20 lines' numbers remapped the same way
(`gpu.rs` after line 3816 +27 to +29, `cpu.rs:702` → 914, `gpu_wide.rs` +1), each target line read. The head
named where references were checked: the map (4 places), `DESIGN.md` lines 4 and 612, `README.md` lines 4 and
19 → `85185fef`. No other wording changed.

**What in `DESIGN.md` is now out of date** (not edited):

- §1 "Where it stands" (l. 77) and §8's table (l. 542–543): base 65 on the 3080 is now §D's number, not 3.47;
  "untuned there" for the RX 9070 XT is now "shared memory fixed offline, not run".
- §2's table, stage 4 (l. 106) and stage 7 (l. 109): the b65 expansion's cost and the sampled check's "27 s of CPU
  per 30.6 s field" (one thread); now 4 threads by default, 7.6–11.6 s at b64, 29–35 s at b65 on a 5-CPU box.
- §2 stage 0 (l. 127–128): the sampled slice goes to "a host thread"; now a host thread that runs the CPU
  reference on up to 4 threads.
- §4 "What nothing catches" (l. 334–335): "at base 65 the sampled check is off": it is on now.
- §6.7 "Not explained" (l. 447–449) is about the narrow expansion (unchanged); §6.9 (l. 471–473) still right.
- §8 "The earlier ratios" (l. 563–564): the conclusion drawn from "3.64 ms against 3.37 ms" (that the wide
  expansion's time is not the prefilter) was wrong: by ablation the prefilter's arithmetic was 1.88 of 3.45 ms.
- §8 (l. 565–566): branch size "13,939 at `c2152084`"; now 14,407 insertions in 24 files against `origin/main`
  (as fetched on ivory today).
- §9 (l. 583–585): "untuned on the RX 9070 XT (3 KB over)" and "what the wide expansion spends ~3.3 ms on is not
  known; it is not the prefilter": both answered (§B, §C); the 12-wave kernel has not run on the card.
- §9 (l. 589–591): "The sampled check does not fit base 65 … not built": built and on.
- §10 (l. 612): "18 commits on the development trunk": 21. The file table's line counts (l. 620–626): `cpu.rs`
  1,460, `gpu.rs` 4,881, `gpu_wide.rs` 4,710, `route.rs` 173.
- `README.md` l. 4: "since 2026-11-19 evening" (the head moved today).
- The interactive map's panels for the sampled check and the wide expansion carry the same old statements
  (thread count, "not the prefilter", the b65 numbers); its line numbers are current.

## G. What is left

- **Run the 12-wave wide kernel on the RX 9070 XT** (b65 fields; the prediction in §C), and the B expansion there.
- The wide expansion's remaining divergence (per-bit work items over the plane) if b65 matters more: §B "not done".
- The sampled check's device rerun costs ~1 s per b65 field (+1.7 %) and 0.3–0.4 s at b64 on this box (0.16 s on
  the 11-19 box): unchanged by this work; a check that reuses the field run's own list for the sampled slice
  would remove it.
- Base 65's +0.7 % with the 4 CPU threads beside the device thread: 3 threads would halve it at ~40 s per
  slice [judged]; not measured.
- Bases 68–70 keep the fifth probe array (19+ digits); a 6-word packing was not attempted.

(further sections follow)
