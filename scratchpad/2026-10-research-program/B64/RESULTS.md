# B64 RESULTS: the first profile of base-64 fields, and the walk's per-pair floor (RTX 3080, 2026-11-11)

Box: Vast **60171046** (`nice-research-b64-profile`, machine m34532), RTX 3080 10 GB, driver 610.57.04, CUDA 12.8,
Ryzen 9 3900X (24 threads), 31 GB, toolchain 1.99.1. **Power cap: 260 W at first; the host raised it to 300 W at
06:02:29 UTC and it stayed at 300 W for every run used here** (default 320 W; the timed runs sat at 294–299 W, ~1,810–1,840
MHz under load). Raw logs `raw/box/`, scripts `raw/scripts/`, every table is `python3 raw/scripts/analyze.py raw/box`
(→ `raw/analysis.txt`). Provenance: **[M]** measured here, **[D]** derived from [M] by arithmetic, **[A]** assumed or
taken from another report, **[E]** estimate (instruction counts, no run).

Trees (each + `raw/scripts/patch_harness.py`: the throughput harness takes a list of field starts,
`NICE_TEST_JOIN_LIST`, and prints one `FIELD` line per field; no production code changes):
**M** = upstream main `c0c357a`; **S** = fork `pr/check-d` `a97e3d7` (main + #250 + #251);
**E** = fork `exp/l51-profile` `14f87cd` (L51's profile timers and ablation/knob switches; its `join_kernel` is main's,
and #250 is inert at b64 because the FD top kernel is off there), pushed with the harness patch as fork branch
**`exp/b64-profile` `44eee52`**; **E2 / E3** = E + `patchB.py` (walk variants) [+ `patchH.py` (entry wave once per
bucket)]; **SF** = S + `patchF.py` (`NICE_EXP_FD_POW2` turns the FD top kernel on at b64). Backend cubecl-cuda.

Fields: 10 per base at 0.05, 0.15, …, 0.95 of the base range, aligned to 1e17 from the range start, so each 1e16 field
is the first tenth of the 1e17 field at the same position (`raw/scripts/starts.py`, `lists.sh`): b64
[37778931862957161709568, 75557863725914323419136), b62 [3226266762397899821056, 12769214149485414002626).
Admissible n = n × roots/(b − 1): b64 8/63, b62 2/61. Each base-mean run is one process (one untimed 1e14 warm-up field,
then the 10 fields through the client's route with 2 fields in flight, as the client runs them); s per admissible n =
the process's wall seconds for the 10 fields ÷ their admissible n. Every process's `join_kernel` was replayed through the
driver's JIT (`*_jit.txt`): **no base-mean, profile, tile or FD process compiled a spill variant** (46–48 registers,
`local=0`; the ablation modes 35–40, mode p 55–58); the screen's and Task B's spill variants are listed in §4 and §7.

**Harness artefact, found late [M]:** every unpinned process compiles some kernels during its first timed field (the
1e14 warm-up uses other comptime values): the first b64 1e16 field of an unpinned process costs 18.0–18.3 s against
16.44–16.47 s with a pinned PTX cache (`pp_P0_*` against `b_v0_*`/`s_base_*`, same binary), **~1.7 s once per process**.
It is in every number below that comes from a fresh process, the same in both arms of every A/B (so ratios are only
diluted, e.g. a true ×1.03 on the 34.5-s screen pair reads ×1.028), ~1.9 % of a 1e16 base-mean run and ~0.2 % of a
1e17 one. Production processes pay it once per process lifetime, so the base means are also given corrected [D].

**Exactness [M]:** `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field` on M at b64 (device hits and both survivor
counts asserted equal to the CPU join's): the 0.05 field at 1e16, 48 partitions spread over its slice (survivors
2,836,249,711, checked 172,308,464), and at 1e17, 32 partitions of slice 0 of 10 (2,084,088,060 / 126,626,839): **ok**
(`x_M_e16.log`, `x_M_e17.log`). Every timed run of every tree then gave the same counts per field list (b64 1e16:
2,002,378,404,775 / 123,965,333,469; b64 1e17: 18,307,299,160,809 / 1,132,282,528,251; b62 1e17: 7,633,686,660,396 /
471,347,472,139), and the 1e16 tiles of two 1e17 fields gave exactly those fields' counts (§3).

**Two runs excluded (disturbances outside this container):** M's first b64 1e16 run (06:00–06:03) ran its first five
fields inside the host's 260 W period and took 28.3 / 33.0 / 39.6 s on fields that cost 11.3 / 13.4 / 16.6 s in every
later round (×2.5); S's second b64 1e17 run (08:16–08:38) ran its fields 1–6 at half speed (247–287 s against 120–137 s)
**with the card at full power (299 W) and full clock (1,830 MHz) throughout**, i.e. something else was using the GPU
(not visible from the container; cause unknown). Both are listed in `analysis.txt`, used nowhere, and were repeated
(M 1e16 rounds 2–4, S 1e17 round 4). From 08:40 `memwatch.txt` logs the card's memory against this container's (no
foreign use seen after that). Every other run's per-field times agree with its other rounds within ~2 %.

## Summary

All on one RTX 3080 at a 300 W cap; [M] measured, [D] derived, [A] assumed/taken from another report, [E] estimate.

- **Base means [M], s per admissible n (10 fields at 0.05–0.95; 3–4 rounds unless noted):**
  **b64 1e17: main 6.46e-15 (82.0 s per field), stack 6.16e-15 (78.2 s); b64 1e16: main 7.47e-15 (9.48 s), stack
  7.02e-15 (8.91 s); b62 1e17 (1 round): main 1.47e-14 (48.2 s), stack 1.21e-14 (39.6 s).** Each fresh process pays a
  ~1.7 s kernel compile in its first timed field (corrected [D]: b64 1e17 6.45e-15 / 6.15e-15, 1e16 7.34e-15 /
  6.89e-15). Whole base on this card [D]: **b64 2.96e7 s on the stack (3.10e7 on main), b62 3.78e6 s (4.60e6): b64 ≈
  7.8× b62** (b64 costs half of b62 per admissible n, with 15× the admissible n).
- **Empty fields [M]: 3 of 10 at b64 at both sizes** (0.25, 0.45, 0.75; the 1e17 field at 0.85 is nearly empty), 2 of
  10 at b62. An empty field costs ~1.1 s of idle GPU at either size.
- **Shares of a b64 field [M]** (main's kernels, profiled, 1e16 / 1e17): **top certificates 17.2 / 17.8 %** (direct
  `top_kernel`, FD off at power-of-two bases), bucket 1.3 %, **join 68.0 / 67.3 %** = base 12.3 %, AND 17.3 %, walk
  rounds 13.0 %, prefilter + stage 25.1 % (**survivor path 38–40 %, the largest block**), **check 11.0 / 10.8 %** (≈ 6.5 %
  on the stack [D]), slice setup 1.6 %, other ~1 %. Per op: 1.32–1.34 ps per pair (base 0.22–0.26, AND 0.29–0.39),
  16–20 ps per AND survivor, 0.084 ns per full check (main's), **0.230 ns per top test (0.104 ns with FD)**; b62 [A]:
  0.26 / 0.30 ps, 17.4 ps, 0.111 ns, 0.158 ns (FD). b64's buckets hold 1,400–1,750 tops (8 roots) × 220–330 entries.
- **Field size [M]: the same n cost the same at 1e16 and 1e17 (±1 %, exact same counts); the only difference is the
  empties' idle second, which 1e16 pays 10× as often: insert b64 at 1e17, worth ~3–4 % of the base [D].**
- **Constants [M]: nothing moves b64 by ≥ 3 %** (2 rounds: best TRANSPOSE_MIN 128 ×1.00–1.01, SURV_FLUSH 768
  ×0.99–1.02; EPT 1/3, AND_GROUP 2, TOP_CAP 128 lose 4–6 %, TOP_CAP 512 ×0.87). The list bounds never bound.
- **New, measured: the FD top kernel at b64 (one constant, `TOP_FD_AT_POW2_BASES = true`) is ×1.13 on b64 1e17 fields**
  (×1.141, ×1.129, ×1.125 in 3 rounds on the stack; ×1.04–1.07 on 1e16), exact (dense CPU compare and all counts); the
  top phase halves (0.230 → 0.104 ns per test, 16.7 % → 8.4 % of the field). NiceMark has no b64 scenario, so it
  cannot move.
- **b = 2^6 [M, SASS]:** no division survives anywhere at b64 (comptime base: shifts and masks); the residue is
  `walk_pf_lean`'s `mul_hi(F, 64)` as `IMAD.HI` in the walk round (~1–2 % [E]).
- **Roadmap (§6), ranked:** (1) FD at b64 ×1.13 [M, simple]; (2) insert at 1e17 ×1.03–1.04 [M/D, config];
  (3) #251 ×1.05–1.06 at b64 [M, in review]; (4) the survivor path (38–43 % of the field) ~×1.12 if L37's compaction
  estimate held [E, very large]; (5) binary top stepping ~×1.04–1.05 after (1) [E, medium–large]; (6) walk digit shifts
  ~×1.01–1.02 [E, simple]; (7) entry wave once per bucket ×1.005 [M, dead]; (8) binary check ≤ ×1.03 [E]; (9)
  `sorted_layer` off the device thread ×1.01 on this CPU [M share]. (1)×(2)×(3) ≈ ×1.23 on main [D].
- **Task B [M]:** the per-pair floor is the walk's round structure (a round runs while any lane of 32 has a bit; at
  low density one ~41-instruction round per chunk-slot for one busy lane ≈ 0.09 ps per pair [D]), not the vote or
  the barrier. One walk over both entry slots: ×1.00 at b62 1e17 / b60 1e16 / b64 1e16 (3 rounds); dropping the
  plane barrier: ×0.88–0.90. No small change reaches ×1.03 at today's shape; the merged walk is worth carrying into
  the low-density shape [E].
- **Two disturbances outside the container** (06:00–06:02 and 08:18–08:35 UTC: half throughput at full power and
  clock) hit one run each; both runs are excluded and were repeated.
- **The box (60171046) can be destroyed:** everything is in `raw/box/`, nothing is running on it.

## 1. Base means (Task A.1)

Seconds per admissible n, 10 fields at 0.05–0.95, unprofiled, 300 W [M]; rounds in brackets.

| field set | M (main c0c357a) | S (pr/check-d a97e3d7) | S over M |
|---|---|---|---|
| **b64 1e17** | **6.461e-15** (82.04 s per field) [6.453, 6.460, 6.575, 6.462] | **6.160e-15** (78.22 s per field) [6.164, 6.148, 6.160] | **×1.049** (1.047, 1.069, 1.049) |
| **b64 1e16** | **7.469e-15** (9.48 s per field) [7.461, 7.469, 7.478] | **7.019e-15** (8.91 s per field) [6.897, 7.032, 7.021, 7.017] | **×1.064** (1.061, 1.064, 1.066) |
| **b62 1e17** | **1.470e-14** (48.20 s per field) [1 round] | **1.209e-14** (39.64 s per field) [1 round] | ×1.216 (1 round) |
| *corrected for the first field's compile (−1.7 s per process) [D]* | b64 1e17 6.447e-15, 1e16 7.335e-15, b62 1e17 1.465e-14 [A: b62's compile assumed the same] | b64 1e17 6.147e-15, 1e16 6.885e-15, b62 1.204e-14 | |

- **Empty fields [M]:** at b64 the fields at 0.25, 0.45 and 0.75 are empty at **both** sizes (3 of 10; the 1e17 field at
  0.85 is almost empty too: 20 s against 120–150 s for the others); at b62 the fields at 0.05 and 0.35 (2 of 10). An
  empty field costs **~1.1 s of wall time with the GPU idle** at either size (the next field's host setup, which a
  non-empty field hides under its device time).
- **Counts per admissible n [M/D]:** b64 1e17: AND survivors 1.44e-4, full checks 8.9e-6; b64 1e16: 1.58e-4, 9.8e-6;
  b62 1e17: 2.33e-4, 1.44e-5 (N1's CPU sample: b64 1.55e-4 / 9.6e-6 [A]). AND pairs per admissible n on the profiled
  fields: 4.2e-3 (1e16 at 0.05) to 7.5e-3 (1e16 at 0.35).
- **Why the 1e16 sample costs more per n than the 1e17 sample:** not the field size (§3: identical n cost the same at
  both sizes within ±1 %). Each 1e16 field is the first tenth of its 1e17 field, and those tenths carry 9 % more AND
  survivors per n than their 1e17 fields as a whole (1.58e-4 against 1.44e-4), plus the empties' idle second weighs 10×
  more. **The 1e17 sample (10× the n) is the better base estimate: 6.16e-15 s per admissible n on the stack (6.15e-15 corrected).**
- **Whole bases on this card at 300 W [D]:** b64 = 4.80e21 admissible [A, N1] × 6.160e-15 = **2.96e7 s (8,210 h) on S**,
  3.10e7 s on M; b62 = 3.13e20 × 1.209e-14 = **3.78e6 s (1,050 h) on S**, 4.60e6 s on M. **b64 ≈ 7.8× b62 on the stack
  (6.7× on main)**; per admissible n b64 is about half of b62 (0.51× on S).
- **b62 against yesterday's [A]:** N1's mid-base b62 field (L30's start) cost 61.9 s at 340 W; this sample's b62 base
  mean on M is 48.2 s per field at 300 W (the 10 fields range 18–75 s; L30's field is 22 % dearer than the mean per
  N1, so ~50 s expected at 340 W: consistent).
- **The stack is worth much less at b64 than at b62:** #251's check kernel takes ×1.22 at b62 1e17 but only ×1.05–1.06 at
  b64, because main's check is already cheap there (0.084 ns per check at b64, its divisions by b and b² being shifts;
  check 10.8–11.0 % of a b64 field on main, §2).

## 2. Where a b64 field goes (Task A.2)

Tree E (main's kernels + L51's profile), 300 W, profile on (per-kernel syncs), mode c [M]. 1e16: fields at 0.05, 0.35,
0.55, 2 rounds (6 field-runs); 1e17: fields at 0.05 and 0.55. Shares of the profiled field excluding the profile's own
count probe (0.85 s per 1e16 field, ~8 s per 1e17 field).

| phase | b64 1e16 (3 fields × 2 rounds) | b64 1e17 (2 fields) | b62 1e17 (N1, 340 W, [A]) |
|---|---|---|---|
| **top certificates** (`top_kernel`, every partition; FD off at b64) | **17.2 %** | **17.8 %** | FD 22.7 % |
| bucket | 1.3 % | 1.3 % | 3.3 % |
| **join** | **68.0 %** | **67.3 %** | 54.8 % |
| · base (z: work items, batch loads, transposed copy, entry waves) | 12.3 % (12.0–12.6) | 12.5 % (0.55) | 11.6 % [D from N1 §1] |
| · AND (a − z) | 17.3 % (16.5–18.2) | 16.7 % (0.55) | 13.4 % |
| · walk rounds (b − a) | 13.0 % (11.6–13.9) | — | 9.6 % |
| · prefilter + stage (c − b) | 25.1 % (23.2–26.9) | — | 20.2 % |
| · survivor path (c − a) | 38.1 % (34.8–40.7) | 39.1 % (0.55) | 29.8 % |
| **check** (main's kernel) | **11.0 %** | **10.8 %** | 11.5 % |
| slice setup (`upload`: host sort 1.2 %, buffers 0.5 %) | 1.6 % | 1.7 % | 5.5 % |
| inputs, reads, unattributed | 0.8 % | 1.1 % | 2.3 % |

- **Mode p (walk + prefilter, no stage) compiled 55–58 registers at b64** (4 cubes per SM, against c's 46–47), so p − b and
  c − p are not separable here (c − p came out negative); the table gives prefilter + stage together (c − b).
- **On the stack [D]:** S's check replaces main's; S is ×1.049 (1e17) to ×1.064 (1e16) faster on the whole field, all of
  it from the check (#250 is inert at b64). So S's check is ≈ 10.8 % − 4.5 % ≈ **6.5 % of a b64 1e17 field** (and every
  other share is ×1.049 larger: top ~18.7 %, join ~70.6 %).
- **Per operation [M/D]** (b64, 300 W, ~1,835 MHz profiled; b62 from N1 at 340 W, ~1,825 MHz, [A]):

| | b64 1e16 | b64 1e17 | b62 1e17 [A] |
|---|---|---|---|
| mean tile (tops × entries per bucket) | 1,446–1,749 × 223–328 | 1,373–1,577 × 231–283 | 467 × 330 |
| top batches of 256 per bucket | ~6–7 | ~6 | ~2 |
| AND pass rate (survivors ÷ pairs) | 3.7–4.5 % | 4.1–4.2 % | 3.87 % |
| prefilter keeps | 6.1–6.2 % | 6.1–6.2 % | 6.1 % |
| lanes used in the entry waves (pairs ÷ padded pairs) | 44–64 % | 45–56 % | 64 % |
| join per pair (all) | 1.32 ps | 1.34 ps | 1.24 ps |
| · base / AND per pair | 0.22–0.26 / 0.29–0.39 ps | 0.24 / 0.32 ps | 0.261 / 0.302 ps |
| · survivor path per AND survivor | 16.4–19.7 ps | 18.3 ps | 17.4 ps |
| full check (main's kernel) | 0.084 ns | 0.084 ns | 0.111 ns (N1, profiled) |
| top test | **0.230 ns** (`top_kernel`, direct) | 0.231 ns | **0.158 ns** (FD) |

- **Top certificates at b = 2^6 [M + code]:** the FD kernel is off at power-of-two bases by design
  (`TOP_FD_AT_POW2_BASES = false`: "`top_kernel`'s division is shifts there and FD measured slower"), so every one of the
  ntlay × 4,096 top tests (1.0–1.2e10 per 1e16 field, ~1e11 per 1e17 field) runs `top_kernel`: square and cube of both
  interval endpoints in 16-bit limbs, then `cert_power`'s digit scan, whose divisions by `chunk_div` = 64^5 = 2^30 and by
  64 are shifts and masks at b64 (comptime base). 3,368 SASS instructions, 102 registers, no division sequence
  (`raw/box/sass_c/p_c_e16_r1_1_*.sass`). **0.230 ns per test, 1.46× the FD test's cost at b62** (clock-matched within 1 %).
  Whether FD now wins at b64 (FD round 2, #250, postdates the decision) is measured in §5.1: **it does now, ×1.13 at 1e17, and the FD test costs 0.104 ns at b64**.
- **Stepping the tops in binary [E]:** at b = 2^6 a partition step moves an endpoint by a power of two, so n² and n³ step by
  shifted copies of the endpoint (2aδ + δ², 3a²δ + 3aδ² + δ³ with δ = 2^(6·f0)), i.e. plain multi-word binary adds, and
  every base-64 digit is a 6-bit field of the binary result: no packed-digit carry normalisation and no division at all.
  At ~76-bit n that is 5 words for n² and 8 for n³: an FD step of ~40 instructions plus a top-down digit scan of the
  ~10–12 certified digits per power by bit slicing (~5 per digit), ~150–200 instructions a test against today's few
  thousand. Possible, exact by construction (the same digits), b64-only (b32 is not searched). See the roadmap (§6).
- **The 8 roots [M + code]:** at b64 a bucket is the union of 8 root groups, so the mean bucket holds **~1,400–1,750 tops
  against ~470 at b62**, while its entries (220–330) still fit one wave of 512. The kernel loops over the bucket's top
  batches (TOP_CAP 256) **outside** its entry waves, so each entry wave is loaded and prepared (112 SASS instructions
  per thread for its two entry slots, 12 of them global loads [M, SASS 0x1a60–0x2150]; the batch's top load and
  transposed copy are 230) **once per batch: ~6–7 times per bucket at b64, twice at
  b62**. That ordering was tuned when buckets had ~2 batches; the one-wave case could prepare the wave once per bucket
  (tested as v6, §7: ×1.005 at b64 spill-free, so the repeated preparation is hidden, not costly). The bucket kernel and the transposed AND have nothing per-root in them.

## 3. Field size (Task A.3)

**The same n at both sizes [M]:** the 1e17 fields at 0.05 and 0.55 against their twenty 1e16 tiles (`t_*`, one process
each, same trees, both non-empty everywhere):

| | 1e17 fields (wall s, from the base-mean runs) | the same n as 20 × 1e16 (wall s) | 1e16 over 1e17 |
|---|---|---|---|
| S | 103.0 + 133.8 = 236.8 | 234.9 | ×0.992 |
| M | 107.5 + 139.9 = 247.4 | 250.0 | ×1.010 |
| counts | 2,224,082,083,177 + 3,092,989,872,066 survivors | identical | exact |

- **On non-empty ground the field size does not matter (±1 %, opposite signs on the two trees):** the work is identical
  to the pair (the tiles' survivor and check counts are the 1e17 fields' exactly), and the fixed costs per field are
  hidden: a 1e16 field's host setup (~0.9–1.1 s) and a 1e17 field's ten slice setups (~8–9.6 s) run beside the device's
  work on the field before (wall − device sum: 1.6 s over 20 tiles, ~1 s per 1e17 field).
- **What differs is the empty ground:** an empty field costs ~1.1 s with the GPU idle at either size [M]. 30 % of b64 is
  empty at both sizes in this sample, so per 1e17 of range: 1e16 pays 10 × 1.1 s on each empty stretch, 1e17 pays 1.1 s.
  On the base-mean runs that is 3.3 s of 89.1 s (3.7 %) at 1e16 against 3.5 s of 782.7 s (0.45 %) at 1e17 [M/D].
- **Answer: insert b64 at 1e17. It matters by ~3–4 % of the base (≈ 0.3e6 s ≈ 90 h of this card) [D],** all of it from
  empty fields' idle setup; the non-empty cost per n is the same at both sizes. Not measured: the server's per-field
  claim/submit overhead (10× fewer claims at 1e17) and the longer field time on slow cards (a 1e17 b64 field is 20–150 s
  here; ~5× that on a small GPU), which only matter for preemption losses.

## 4. Constants at b64 (Task A.4)

Tree E, unprofiled, every value its own comptime kernel, b64 1e16 fields at 0.35 + 0.55 (the two heaviest non-empty
1e16 fields of the sample, 34.5 s together) in one process per run; 2 interleaved rounds (round 2 reversed), today's
constants at the start, middle and end of each block; ratio = local base ÷ variant (the base runs before and after),
> 1 is faster [M] (`chain_screen.sh`, `s_*`). A run whose `join_kernel` compiled a spill variant was re-run (up to
twice). Every run gave the same counts (687,610,801,525 / 42,436,400,204).

| knob | value (today's in bold) | round 1 | round 2 | `join_kernel` regs | verdict |
|---|---|---|---|---|---|
| ENTRIES_PER_THREAD | 1 | ×0.960 | ×0.949 | 40 | loses 4–5 % (even with 44–64 % of the lanes in use at b64) |
| | **2** | 1 | 1 | 46–48 | stays |
| | 3 | ×0.953 | ×0.944 | 63–64 | loses 5–6 % |
| TRANSPOSE_MIN | 128 | ×1.010 | ×0.999 | 46 | noise (base runs scatter ±1 %) |
| | **192** | 1 | 1 | | stays |
| | 256 | ×1.007 | ×0.979 | 47–48 | noise / −2 % |
| AND_GROUP | 2 | ×0.947 | ×0.940 | 39–40 | loses 5–6 % |
| | **4** | 1 | 1 | | stays |
| | 8 | ×1.009 | ×0.998 | 48 | noise |
| TOP_CAP (TMIN scaled) | 128 (TMIN 96) | ×0.960 | ×0.956 | 46–48 | loses 4 % |
| | **256** | 1 | 1 | | stays |
| | 512 | ×0.875 | ×0.874 | **40 + 16 B spill in every process (6 of 6)** | loses 12.5 % (3 cubes per SM and the spill) |
| SURV_FLUSH | 256 | ×0.999 | ×0.992 | 47–48 | noise |
| | **512** | 1 | 1 | | stays |
| | 768 | ×1.017 | ×0.990 | 47 | noise |
| stage check | **once per top batch** | 1 | 1 | | stays |
| | once per work item | ×0.988 | ×0.979 | 47 | loses 1–2 % |

- **No constant moves b64 by 3 % or more**; nothing went to three rounds (the rule's trigger was never met). Today's
  constants, tuned at b58–b62, are at their optimum at b64 too. The base's own runs scattered 34.18–34.84 s (±1 %).
- **Partitions per launch / slots and the survivor-list bounds:** the plan put 6–8 partitions per launch on non-empty
  b64 fields (16 on empty ones), and in all 270 field-runs of this session nothing was retried, split or refused: the
  list bounds never bind at b64 [M]. Not swept (no knob in E; the plan sizes them from device memory).
- **Tuned around 2 roots?** The knobs that would amortise the per-batch work over b64's 6–7 batches per bucket are
  TOP_CAP (512: shared-memory bound, 3 cubes per SM, and a spill: ×0.87) and EPT (wider waves: ×0.94–0.95). Neither can;
  changing the loop order (the entry wave once per bucket, §7 v6) does but gains only ×1.005: the per-batch entry
  preparation is hidden. Nothing else in the bucket/wave logic depends on the root count.

## 5. What is specific to b = 2^6 (Task A.5)

Read from the SASS the driver JIT produced for a b64 process's kernels (`raw/box/sass_c/`, tree E = main's kernels;
`top_kernel` 3,368 instructions / 102 registers, `bucket_kernel` 344 / 37, `join_kernel` 1,184 / 47, `check_kernel`
608 / 37) [M]:

- **No division sequence anywhere at b64.** The base is a comptime parameter of every kernel, so every `/ b`, `% b`,
  `/ b^k`, `% b^k` (including `chunk_div` = 64^5 = 2^30 in the top certificate's digit scan, M = 64^3 and b^mid = 64^2 in
  the entry's key-level arithmetic, `dm_div`) compiles to shifts and masks. The only magic multiplies left are by
  `0x4104105` (÷ 63, the digit-sum class, b − 1 is not a power of two) in `join_kernel`'s work-item header, once per
  work item, and one runtime-divisor division (`I2F`/`MUFU.RCP`, 3 instructions) outside the loops.
- **`walk_pf_lean` pays for its general-base form inside the walk round:** the prefilter's two digits per power come
  from `h = mul_hi(F, b)` and `g = mul_hi(F·b, b)`; at b = 64 the compiler emits `IMAD.SHL` + 4 × `IMAD.HI.U32 …, 0x40`
  (0x3460–0x34e0) where `h = F >> 26` and `g = (F >> 20) & 63` are one or two ALU shifts. The fixed-point constants are
  exact at b64 (C = 2^32/b² = 2^20), so the change is only the instruction form: ~2 of the round's 41 instructions, and 6
  of its 8 `IMAD`-pipe operations move to the ALU pipe [E]. Walk rounds + prefilter are ~38 % of a b64 field, so this
  is worth ~1–2 % [E] (a b64-only `if comptime!(base.is_power_of_two())` branch; b62 unchanged).
- **The top certificate:** `top_kernel` at b64 is the direct form (squares and cubes of both endpoints in 16-bit
  limbs, then a shift-and-mask digit scan); its cost is the multiplications and the scan, 0.230 ns per test (§2). FD
  is off there by `TOP_FD_AT_POW2_BASES`; §5.1 measures it on today's FD. Binary stepping (§2) is the b64-specific form.
- **The check:** main's `check_kernel` at b64 (0.084 ns per check) has no division either; #251's base-b² limb form
  handles powers of two with shifts (`join_check::qdiv`). A pure binary check (n² and n³ in 32-bit words: 3 × 3 and
  5 × 3 word products, digits as 6-bit fields) would cut the multiply count ~3× against 12-bit limbs [E]; the check is
  ~6.5 % of a b64 field on the stack, so at most ~3 % [E].
- **The AND, the transposed copy, the bucket kernel and the walk's bit iteration** do nothing base-specific.

### 5.1 The FD top kernel at b64 (tree SF = the stack + an environment switch for `TOP_FD_AT_POW2_BASES`) [M]

One binary, FD off (today) and on alternated in the same order-rotated chain (`chain_F.sh`, `chain_F2.sh`, `f_*`).
Exactness first: the dense CPU compare with FD on (`x_SF_fd_e16`: the 0.05 1e16 field, 48 partitions; hits and both
counts equal to the CPU join's: 2,836,249,711 / 172,308,464, **ok**), and every timed run gave today's counts.

| fields | FD off (s) | FD on (s) | on over off |
|---|---|---|---|
| b64 1e16 at 0.35 + 0.55, round 1 / 2 / 3 | 31.87 / 32.76 / 32.66 | 30.67 / 30.70 / 30.67 | **×1.039 / ×1.067 / ×1.065** |
| b64 1e17 at 0.55, round 1 | 135.02 | 118.32 | **×1.141** |
| b64 1e17 at 0.05 + 0.55, round 2 / 3 | 236.67 / 236.44 | 209.59 / 210.13 | **×1.129 / ×1.125** |
| · per field, rounds 2–3 (device s) | 0.05: 101.81, 101.83; 0.55: 133.65, 133.39 | 0.05: 89.22, 89.42; 0.55: 119.15, 119.50 | 0.05 ×1.140; 0.55 ×1.119 |

- **FD is now faster at b64: ×1.13 at 1e17 (×1.141, ×1.129, ×1.125 in 3 rounds) and ×1.04–1.07 at 1e16.** FD round 2
  (#250, on the stack) postdates the "FD measured slower" decision behind `TOP_FD_AT_POW2_BASES = false`.
- With FD the plan puts **13 partitions per launch instead of 7 (1e16) and 11–13 instead of 5–6 (1e17)**, halving the
  launches (586 → 316 per 1e16 field, 5,846 → 3,061 per 1e17 field). Unprofiled, the gain per 1e16 field is uneven (the
  0.35 field's device time 16.79 → 16.74 s, the 0.55 field's 13.90 → 12.76 s); the profile below shows the top phase
  itself halving on every field.
- **Profiled (tree EF = E + the same switch, mode c, one process per setting, `pf_*`) [M]:** with FD on, the top phase
  of the 1e17 field at 0.55 falls from 24.10 s to 10.84 s (**0.230 → 0.104 ns per top test**; the same 0.104 ns on the
  1e16 fields), launches halve (5,846 → 3,061), and the join, check and bucket phases stay within ±2 %. **The top share
  of a b64 1e17 field drops from 16.7 % to 8.4 %** (join 76.3 %, check 12.1 % of the profiled field with FD on, main's
  check). The FD top test at b64 (0.104 ns) is cheaper than at b62 (0.158 ns at 340 W, N1 [A]).
- **This is a one-constant change (`TOP_FD_AT_POW2_BASES = true`), b64 only**, exact by the dense compare and the counts.
  NiceMark cannot move: its nice-only scenarios are b58, b60 and b62 (`bench_defs.rs`), where the flag's path is never
  taken. Not measured: other GPUs (Metal, AMD, small NVIDIA cards), main's FD (round 1) at b64. The CPU route is unaffected.

## 6. Roadmap: b64 levers, ranked (Task A.6)

Gains are per b64 field (1e17, the stack unless noted), × = faster. Basis: [M] measured here (rounds given), [D] derived
by arithmetic from [M], [E] estimate from instruction counts or shares, no run. PR bar: ×1.05 (simple) to ×1.10 (very
large), one change per PR, exact counts, no NiceMark scenario below ×0.98.

| # | lever | gain at b64 | at b62 | basis | size | what would kill it |
|---|---|---|---|---|---|---|
| 1 | **FD top kernel at b64**: `TOP_FD_AT_POW2_BASES = true` | **×1.13 at 1e17** (×1.141, ×1.129, ×1.125: 3 rounds); ×1.04–1.07 at 1e16 (3 rounds) | n/a (FD already on) | [M] §5.1 on the stack (#250's FD round 2; with main's FD not measured), one binary, exact (dense CPU compare + counts) | **simple (one constant)** | another GPU (Metal/AMD) where FD loses at b64; NiceMark cannot move (its nice-only scenarios are b58/b60/b62 only, so the flag's path is never taken there) |
| 2 | **insert b64 at 1e17, not 1e16** | ×1.03–1.04 of the base (the empties' idle setup) | (b62 is 1e17 already) | [M] §3 tiles (same n: ±1 %), empties 1.1 s each [M], share [D] | none (server config) | a server-side per-field cost; a preemption-heavy fleet on slow cards |
| 3 | **#251 (the stack's check kernel)** | ×1.049 (1e17, 3 rounds: 1.047, 1.069, 1.049), ×1.064 (1e16, 3 rounds) | ×1.22 (1e17, 1 round) | [M] §1 | in review | — |
| 4 | **the survivor path** (walk rounds + prefilter + stage: **38–40 % of a b64 field**, the largest block; 25 % is the prefilter) | the only ≥ 10 % block left (after #1: ~43 % of the field); L37's "compact the AND group's 4 chunks × 2 slots with an empty-plane skip" estimate (~30 % of the path) would be ~×1.12 [E, from L37's estimate] | ~×1.09 [E] | [M] shares; gain [E] | very large | L37 H1's fate (compaction overhead ≥ rounds saved, ×0.91–0.94 [A]); Task B (§7): neither the plane barrier nor the slot loop is removable |
| 5 | top certificates stepped in binary (b64 only: FD steps as multi-word binary adds, digits as 6-bit fields) | after #1 the top phase is **8.4 %** of a 1e17 field [M, §5.1]; a binary FD at ~2–3× fewer instructions than today's FD would save ~4–5 %: **~×1.04–1.05 [E]**; without #1 it was 16.7 % | none | [E] §2 instruction count; the share [M] | medium–large (a third top kernel, b64 only, its own exactness tests) | #1 already taking most of the top share; the group append and its atomics (not the arithmetic) dominating a cheap test |
| 6 | **b64 shift form of `walk_pf_lean`'s digits** (`F >> 26`, `(F >> 20) & 63` for `mul_hi(F, 64)`) | ~×1.01–1.02 [E] | none | [E] §5: 2 of 41 instructions per round, 6 IMAD-pipe ops to ALU | simple (comptime branch) | issue not the limit in the round (it is latency-bound on the `LDS` of the top's terms) |
| 7 | entry wave prepared once per bucket (b64 buckets hold 6–7 top batches) | **×1.005** (pinned spill-free, 3 rounds: ×1.003, 1.006, 1.006) | ×1.015 (pinned, 3 rounds) | [M] §7 v6 | medium | dead at b64: the per-batch entry preparation is hidden under the other warps' work; and 7 of 9 unpinned processes compiled a spill variant |
| 8 | binary full check at b64 | ≤ ×1.03 [E] | none | [E] §5 (check ~6.5 % on the stack) | medium | #251's form already near its floor at b64 |
| 9 | `sorted_layer` off the device thread (L51 #2) | ×1.01 here (1.2 % of a b64 field on a Ryzen 3900X) | ×1.03–1.04 on L51's Broadwell [A] | [M] share | simple–medium | fast host CPUs (the fleet's) |
| — | **no-go at b64:** every retune knob (§4, all < 3 %; TOP_CAP 512 ×0.87, EPT 1/3 ×0.95, AG 2 ×0.94); one walk over both entry slots (Task B v2, ×1.00); removing the walk's plane barrier (×0.88) | | | [M] | | |

**Combined [D, multiplicative, not measured together]:** #1 × #2 × #3 ≈ ×1.13 × 1.035 × 1.05 ≈
**×1.23** on today's main at b64, before any medium change; #4 (the survivor path) is the remaining large one.

## 7. Task B: the walk's per-pair floor

Tree E3 (E + `patchB.py` + `patchH.py`), one binary, variants as comptime kernels via `NICE_EXP_JOIN_STAGE` (bit 0 keeps
L51's meaning), 3 interleaved rounds (order rotated), unprofiled, 300 W, fields b62 1e17 (L30's field, 7997740455941656911841),
b60 1e16 × 2 (L30's), b64 1e16 at 0.35 + 0.55 (`chain_B.sh`, `b_*`) [M]. Exactness: each variant at 1e14 b62 and b64 with
the stride compare of hits (`bsan_*`: all pass with L47's counts 1,439,469,648 / 88,159,810 and 5,702,041,796 /
346,647,759), and every timed run gave the field's exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60
460,847,952,346 / 30,871,838,404; b64 687,610,801,525 / 42,436,400,204).

**What the floor consists of (SASS of b64's `join_kernel`, 0x3330–0x3830, one copy per entry slot) [M]:** per (chunk of
32 tops, entry slot) a lane pays the pass mask (2 instructions), the range-test word (one `LDS` and a branch, per
chunk), the popcount for the survivor count, and the loop's entry and final exit (`ISETP`, `MOV`, `VOTE.ANY`, `BRA`:
4). Each round costs ~41 instructions for the whole warp: 17 of loop control and bit pick (`BREV`/`FLO` for the
lowest bit, `BSSY`/`BSYNC`, the barrier, which compiles to a `NOP` plus the reconvergence) and ~24 of `walk_pf_lean`.
A round runs while **any** of the warp's 32 lanes has a bit left, so a (chunk, slot) costs max-over-lanes rounds. At
~4 % pass (1.3 bits per lane-chunk-slot) that is ~4 rounds for ~1.3 useful ones per lane; at N1's future density
(0.34 %) it is one round per chunk-slot in which ~1 lane of 32 works. **That round, not the vote or the barrier, is
the floor:** 45 warp-instructions per 1,024 padded pairs is 0.09 ps per pair at 272 warp-instructions a clock and
1.83 GHz [D], most of N1's fitted 0.13–0.15 ps.

| variant (one change each) | b62 1e17 | b60 1e16 | b64 1e16 | `join_kernel` | verdict |
|---|---|---|---|---|---|
| v0 today (spill-free processes; mean s) | 59.64 | 24.57 | 34.59 | 46–48, 2 of 9 processes the 40 + 24 B spill variant (excluded from the mean) | |
| **v2: one walk over both entry slots** (rounds = max of pop0 + pop1, one entry/exit per chunk) | ×0.996, ×0.998, ×1.004 | ×1.003, ×1.006, ×1.004 | ×0.996, ×0.997, ×0.998 | 47–48, no spill | **×1.00: neutral.** It saves ~17 % of the rounds at 4 % pass [E: max over 32 lanes of Bin(64, p) against twice that of Bin(32, p)], and each round grows by the slot selects (8 `SEL`s) [E] |
| **v4: no plane barrier in the round** | ×0.892 (3 rounds within 0.1 %) | ×0.896 | ×0.875 | 48 + 8–16 B spill | **×0.88–0.90: the barrier pays for itself** (as the kernel's comment says: without it ptxas keeps a `YIELD` and more registers) |
| v6 (Task A lever, §6 #7): entry wave once per bucket | ×1.004, ×1.004, ×1.002 | ×1.001, ×1.004, ×1.020 | ×1.011, ×1.023, ×1.005 | a spill variant in 7 of 9 processes (40–48 regs + 16–56 B); spill-free in 2 | ×1.00–1.02 |
| v6 pinned spill-free (`.maxnreg 48`: 48 regs, no spill) against today's pinned spill-free image (`chain_P.sh`, `pp_*`) | **×1.015, ×1.014, ×1.016** | — | **×1.003, ×1.006, ×1.006** | 48, no spill | ×1.005 at b64, ×1.015 at b62: below 3 % |
| v6 pinned at `.maxnreg 56` (4 cubes per SM) | ×0.981, ×0.983, ×0.983 | — | ×0.965, ×0.964, ×0.966 | 56 | loses |

- **Answer [M]: at today's shape no small change removes a useful part of the floor.** The vote and the loop entry are
  ~4 instructions per (chunk, slot), negligible; the barrier cannot go (×0.88); merging the slots' loops is neutral
  (×1.00). The floor is the max-lane round structure itself, which only a compaction across lanes or chunks changes
  (L37 H1 tried one and lost, ×0.91–0.94 [A]). No variant reached ×1.03, so no A/B and no NiceMark (the rule's trigger).
- **For the low-density shape [E]:** v2's merged loop halves the minimum rounds per chunk (one instead of one per slot)
  where most chunk-slots have one busy lane; at N1's 0.34 % pass that is up to ~half of the floor (0.18 → ~0.13 ps per
  pair). Worth carrying into the new shape's prototype, not today's kernel. Diff: `patchB.py`, +45 lines (one kernel
  branch).

## 8. Files

- `RESULTS.md` (this file), `BRIEF.md`; `raw/analysis.txt` = `python3 raw/scripts/analyze.py raw/box` (base means, profiles,
  screen, every other run with its counts and its `join_kernel` registers/spill, the exactness tests).
- `raw/box/` = the box's `/root/b64/logs`: per run `NAME.log` (harness output: `FIELD` lines, `GPU_PROFILE` lines for
  profiled runs, `JOIN THROUGHPUT`), `NAME.smi` (nvidia-smi every 5 s: clock, power, cap, temperature, utilisation,
  throttle reasons), `NAME_jit.txt` (the process's join kernels through the driver's JIT); `chain_*.out` (the chains'
  one-line summaries), `build_*.log/out`, `trees.txt`, `box-info.txt`, `power.txt`, `nvidia-smi.txt`, `memwatch.txt`
  (card memory against this container's, from 08:40), `sass_c/` (SASS of every kernel of one b64 process, `p_c_e16_r1`).
  Prefixes: `san_` sanity, `x_` exactness (dense CPU compare), `a_` base means, `p_` profiles (mode in the name),
  `t_` 1e16 tiles of two 1e17 fields, `s_` retune screen, `f_` FD at b64, `bsan_`/`b_` Task B, `pp_` pinned v6 images,
  `pf_` profiles with FD on/off.
- `raw/scripts/` (run on the box from `/root/b64/scripts`): `setup.sh`, `build.sh`, `run.sh`, `jit.sh`, `exact.sh`,
  `cfg.sh` (L51's), `lists.sh` + `starts.py` (the fields), `patch_harness.py`, `patchB.py`, `patchH.py`, `patchF.py`,
  `go.sh`, `after_*.sh`, `chain_base.sh`, `chain_prof.sh`, `chain_screen.sh` (with base round 4 and the tiles),
  `chain_F.sh` (+ `after_X.sh`: its rounds 2–3 at 1e17), `chain_X.sh` (+ `after_PF.sh`: 1e17 base-mean rounds), `chain_B.sh`, `chain_P.sh`, `chain_PF.sh`, `memwatch.sh`, `ptxjit.py`/`cbor_min.py`/`pin.py`/`jitlog.py`
  (L45/L51's), `analyze.py`, `pull.sh`, `ssh.sh`.
- Fork branch **`exp/b64-profile` `44eee52`** = `exp/l51-profile` + the harness list (tree E). The other trees are that or
  `pr/check-d` plus the patch scripts above, applied on the box. Experimental only; no PR.


