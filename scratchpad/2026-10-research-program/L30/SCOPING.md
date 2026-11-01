# L30: the cost of AND survivors in `join_kernel`, and a prefilter that runs before the stage (RTX 3080 10 GB at 180 W, 2026-11-01)

PROFILE-3 put AND-survivor handling at 26 % of a b62 1e17 field (60.8 ps per AND survivor, from a fit). This measures it directly, counts what the prefilter does, and prototypes the change the counts point to.

**Summary**
- **Survivor handling is larger than the fit said.** Removing it piece by piece (runtime ablations of the same kernel, profiled join phase, b62 1e16, 2 rounds) gives **81 ps per AND survivor, 73 % of the join kernel and 35 % of the field** (the fit's 61 ps / 26 % is the collinear split between AND lanes and survivors). Per AND survivor:
  - **`mid_pass` arithmetic 35.5 ps (44 %)**: about 290 SASS instructions per survivor. It rebuilds all 8 digit columns of n² and n³ (72 products, 24 divisions by 62) although positions 0..k−1 are already in the bottom's mask; only positions k and k+1 are new.
  - staging and the flush's machinery 17.7 ps (22 %): stage reads, plane scans, two `sync_cube` per 256-survivor round. **The shared atomic itself is about 1 ps**: a second one per survivor costs +1.0 ps.
  - set-bit walk 14.9 ps (18 %): 7.5 survivors per 32-lane round (23 % of lanes).
  - list writes and the per-round global atomic 11.9 ps (15 %): 3.8e8 flush rounds per field, 2.6 ns each.
  - The check kernel adds 86.5 ps per list entry (PROFILE-3), 5.3 ps per AND survivor at a 6.1 % keep rate.
- **Fewer survivors (exact counts, b62 1e16 / b62 1e17 / b60 1e16):** `mid_pass` keeps **6.13 / 6.13 / 6.70 %** and tests two positions (k = 6, k+1 = 7). Position k alone keeps 26.4 / 26.4 / 27.6 %; n²'s digit at k alone 52.2 / 52.2 / 53.4 %. **A third position (k+2) keeps 20.3 / 20.3 / 21.1 % of the list**: 80 % fewer full checks, worth at most 1.9 % of a b62 1e17 field. Every pairing top certifies only above k2, so a per-position certificate rule changes nothing.
- **Cheaper per survivor:** plane-ballot compaction of the staging atomic can save about 1 ps (0.4 %). That is not a lever. **What is a lever is the hoisting the CPU join already does** (`cpu_join::prefilter`). The prefilter is affine in the top's next two digits D: x2 = (⌊R²/bᵏ⌋ + 2R·D) mod b², and likewise for n³. That splits it into a per-top part (D), a per-entry part (4 numbers, built once per wave) and about 50 instructions per pair. That is cheap enough to run in the walk, before the stage, so only the 6 % that pass are staged.
- **Prototype (`NICE_EXP_L30=256` on fork `exp/join-survivors`, about 110 lines): ×0.833 at b62 1e17 (2 rounds), ×0.839 at b62 1e16 (3 rounds), ×0.803 at b60 1e16 (3 rounds), device time, against the same binary's main kernel.**
  - Clock-normalised it is ×0.847 / ×0.860 / ×0.819. The card is at its 180 W cap and runs the prototype 1–3 % faster.
  - At b62 1e17 that is **−37.8 s per field, 3.3× the 5 % bar** (11.3 s) and 1.7× the 10 % bar.
  - **Exact.** AND survivors match PROFILE-3's exact counts to the last digit at all three sizes. The list is the exact prefilter survivors, the same in every run. The stage overrun is gone (0 at all sizes; main overruns 1.1e-4 at b62 1e17 and 3.9e-3 at b60). The CPU-join comparison on 4 partitions of the b62 field passes with equality.
  - Survivor handling falls from 81 to 46 ps per AND survivor: walk 15, the walk prefilter 27 (with its per-entry terms), staging, flush and list 3.4. Registers fall from 62 to 44 (4 → 5 cubes per SM), but capping the prototype at main's occupancy costs it only 1.3 %, so the gain is the work removed.
- **Go.** The walk prefilter clears the 5 % bar at both live sizes with a wide margin. What is left after it, ranked:
  1. Run the prefilter densely (plane-compacted) instead of at the walk's 23 % lane use: est. −10 to −20 ps per AND survivor, 5–10 % more. Specified in §6, not prototyped.
  2. A third prefilter position, only on the 6 % that pass: about 1–1.5 % net.

## 0. Setup

- **Box:** Vast 58597514 (`nice-research-survivors`), machine m139250 (PROFILE-3's).
  - RTX 3080 **10 GB**, driver 580.159.03, CUDA 13.0, **power limit 180 W** (default 340, max 374; `raw/box/power.txt`).
  - Under load: 171–180 W at 1,440–1,550 MHz, SW power-cap flag.
  - Xeon E5-2630 v4, cgroup quota 9.6 CPUs.
- **Code:** fork branch **`exp/join-survivors`** on `bddf20f` (= `rp/gpu-profile-3`: upstream main 9bde4a8 + the profile timers and knobs).
  - `62cf8b3`: `NICE_EXP_L30=xm` selects comptime variants of the join kernel (0 = main's).
    - Bits: 1 counts prefilter variants; 2 runs `mid_pass` twice; 4 walks without staging; 8 flushes without `mid_pass` or writes; 16 runs `mid_pass` without list writes; 32 skips the walk; 64 adds a second shared atomic per survivor; **256 is the prototype**.
    - The survivor buffer carries 14 more counters.
  - `a6a0ffb`: 512 (walk prefilter, no staging) and 1024 (32-bit digit tests).
  - `655f953`: 2048 (6 KiB shared pad: at most 4 cubes per SM).
  - Binaries: `l30` 31f331e5 (§1–5), `l30b` 93fd5578 (ablation round 2, 32-bit test, 1e17 counts), `l30c` a754b8ad (occupancy), `base` b81cd953 (`bddf20f` itself, = PROFILE-3's knob binary).
- **Fields:** PROFILE-3's starts: b62 7997740455941656911841 (1e16 × 2 fields; 1e17 × 1), b60 1366406074057412100454 (1e16 × 2). Each process starts with a 1e14 warm-up field (JIT), left out.
- **Runs:** `raw/run.sh NAME BASE FIELDS SIZE PROF XM` (the PROFILE-3 harness, `cubecl_cuda_join_throughput_fixed_fields`), chained by `raw/chain{1..5}.sh`, one at a time.
  - A/B pairs are interleaved (control, prototype, control, …).
  - Ablations are profiled (`NICE_EXP_GPU_PROFILE=1`, the join phase is the kernel's own time between syncs). The A/B is unprofiled device seconds.
  - Round 2 of the ablations overlapped a niced `-j 4` build. Its join phases agree with round 1 to 0.3–4.6 %; its per-batch phases (probe, bucket, check) are inflated and not used.
- **Control.** The control kernel is `xm = 0` of the same binary. That is main's kernel with two unused buffer bindings and one `& 1` on the seed flag. **It runs at main's speed.** Interleaved with `bddf20f`'s own binary (`chain5`, b62 1e16), main's binary took 18.14 (first run of the session, cool card), 18.44 and 18.59 s; `xm = 0` took 18.32 and 18.68 s in the same chain, and 18.58–18.75 in the others.

## 1. Where the 60.8 ps go

### 1a. Ablations (b62 1e16, profiled join phase, s per field)

Each variant removes one more piece, and all of them run the same AND work. 8.18e10 AND survivors per field.

| variant (`xm`) | what is gone | registers | join s (r1, r2) | mean |
|---|---|---|---|---|
| main (0) | — | 62 | 9.327, 8.902 | **9.114** |
| no list writes (16) | the flush's global atomic per round and its list stores (`mid_pass` still runs) | 60 | 8.125, 8.154 | 8.139 |
| no `mid_pass` (8) | + `mid_pass` (pass = 0) | **38** | 5.180, 5.085 | 5.133 |
| no staging (4) | + the shared atomic and stores, every flush | 63 | 3.679, 3.690 | 3.684 |
| no walk (32) | + the set-bit walk (AND only) | 63 | 2.483, 2.453 | 2.468 |
| `mid_pass` twice (2) | adds a second `mid_pass` per staged survivor | 61 | 12.185, 11.853 | 12.019 |
| second shared atomic (64) | adds a dummy shared atomic per staged survivor | 64 | 9.411 (r1) | +0.084 against r1 |
| **walk prefilter (256)** | prototype | **44** | 6.352, 6.186 | **6.269** |
| walk prefilter, no staging (768) | prototype minus staging, flush and list | 44 | 5.905 (r2) | |
| walk prefilter, 32-bit tests (1280) | prototype variant | 44 | 6.654 (r2) | |

Registers are ptxas 12.8 (`-O3`, sm_86) on the CUDA that CubeCL emitted for each variant (`raw/sass/registers.txt`). At 57–64 registers a cube of 256 gets 4 per SM, at 44 it gets 5, at 38 it gets 6.

| piece | s per field | **ps per AND survivor** | share of the survivor cost |
|---|---|---|---|
| set-bit walk (rounds, `ctz`, range test) | 1.216 | **14.9** | 18 % |
| staging and flush machinery (shared atomic, stage stores and reads, plane scans, 2 `sync_cube` per round) | 1.448 | **17.7** | 22 % |
| `mid_pass` arithmetic | 2.905 by doubling (3.007 by removal, which also moves 4 → 6 cubes per SM) | **35.5** | 44 % |
| list writes and the per-round global atomic | 0.975 | **11.9** | 15 % |
| **total** (main − no walk) | **6.646** | **81.3** | 73 % of the join, **35 % of the field** (profiled, 18.9 s) |
| of the staging: the shared atomic | 0.084 (1 round) | 1.0 | |
| check kernel, per list entry (PROFILE-3: 86.5 ps) | (check phase) | 5.3 per AND survivor | |

- **Against PROFILE-3's fit** (60.8 ps per survivor, 1.18 ps per real lane-pair, 238 ps per top): the fit's AND-and-top terms come to 1.93 s per field here, and the no-walk kernel measures 2.47 s. The fit's survivor term is 4.97 s against 6.65 s measured. Survivors are 4 % of pairs at every base, so the regression could not split the two. The ablation can.
- **The no-`mid_pass` variant also changes occupancy** (38 registers). Doubling `mid_pass` keeps it at 61–62 and gives the same cost (35.5 against 36.8 ps). The occupancy effect is therefore small, which §5's occupancy cap confirms: within about ±2.5 ps per survivor of the split above.

### 1b. Operation counts

Static SASS (sm_86, nvcc 12.8 `-O3`) of a CUDA mirror of each form, fully unrolled, so static = dynamic (`raw/sass/opcount.cu`, `.sass`):

| form | SASS per survivor | IMAD | SHF | LOP3 | other |
|---|---|---|---|---|---|
| `mid_pass` (k2 = 8) | **≈ 290** (303 with the harness) | 139 | 86 | 47 | 4 loads of the top's words, ISETP/PLOP3/PRMT |
| walk prefilter, 64-bit masks | **≈ 50** (65 with 7 loads of harness) | 17 | 16 | 15 | 3 SEL, 2 ISETP |
| walk prefilter, 32-bit words | ≈ 56 (70) | 16 | 12 | 10 | 14 ISETP, 7 SEL |

What `mid_pass` does per survivor:
- 8 digit extractions (3 of r0, 5 of `P mod b⁵`), each a multiply-high division by 62 plus a multiply-subtract;
- 2 × 36 column products and 2 × 8 column reductions (another 16 divisions by 62 with remainders);
- 8 rounds of two 64-bit `1 << g` masks and their tests.

Only positions 6 and 7 can fail. Positions 0..5 are the bottom's mask, which the AND already tested against the certificate, and every listed entry has them distinct. The top's 5 digits are constant per top and are re-extracted for every survivor.

- **Lane use.** The flush runs `mid_pass` at 216 of 256 lanes per round (84 %; 761 staged survivors per flush, 3.5 rounds). So about 345 lane-slots per survivor give 35.5 ps: 0.10 ps per lane-slot at 1,470 MHz, about 75 % of the SMs' issue rate (4 warp-instructions per clock per SM).
- The walk runs at **7.5 survivors per 32-lane round (23 %)** at b62 and b60 1e16, and 7.95 at b62 1e17.

## 2. Fewer survivors: exact counts

Per staged AND survivor (the counting variant, `xm = 1`; the stage's overrun, which is not counted, is ≤ 0.4 %). "Keeps" is the share that passes.

| | **b62 1e16** (2 fields) | **b62 1e17** (1 field) | **b60 1e16** (2 fields) |
|---|---|---|---|
| staged AND survivors | 163,510,221,239 | 1,020,728,382,786 | 459,054,646,906 |
| **main's `mid_pass` keeps** (positions k, k+1 against the bottom's digits and, with the seed, the certificate) | **6.133 %** | **6.131 %** | **6.699 %** |
| position k only (both powers) | 26.41 % | 26.40 % | 27.63 % |
| position k, n² only | 52.19 % | 52.19 % | 53.40 % |
| **positions k..k+2** | **1.242 % = 20.25 % of main's list** | **1.241 % = 20.25 %** | **1.412 % = 21.08 %** |
| tops with certificate floor ≥ k2 (seed) / ≥ k2+1 / = k+1 | 100 % / 100 % / 0 | 100 % / 100 % / 0 | 100 % / 100 % / 0 |
| survivors per walk round (of 32 lanes) | 7.47 | 7.95 | 7.48 |
| staged per flush; per flush round (of 256) | 761; 216 | 789; 217 | 652; 206 |

- **What `mid_pass` tests:** the 4 digits at positions k = 6 and k+1 = 7 (with k2 = k + 2 = 8; `b⁵ < 2³²` holds at every join base, so every production field has this depth). They must be distinct, must miss the 12 digits of positions 0..5, and must miss the top's certificate when its floor is ≥ k2, which here is every survivor.
- **One more position (k+2):** the list shrinks to 20.3 % (b62) or 21.1 % (b60), i.e. **79–80 % fewer full checks**.
  - Value at b62 1e17: 0.8 × 6.26e10 list entries × 86.5 ps = **4.3 s, 1.9 %** of main's field (2.3 % of the prototype's), plus a little in list writes. That is the ceiling.
  - Cost on every AND survivor (in the walk, at 23 % lane use): about 15–25 more instructions per round, i.e. 8–13 ps per AND survivor, 8–13 s at 1e17. A net loss.
  - Cost only on the 6 % that pass (at the flush, with the entry's carries mod b³ staged alongside): under 1 s.
  - Net about **1–1.5 %** (§6).
  - Testing position k+2 needs `P mod b⁶`, which does not fit u32 at b ≥ 41 (the reason k2 stops at k + 2 today). The affine form needs only D's three digits (< b³) and carries mod b³.
- **An earlier partial test** (n²'s digit at k before staging) keeps 52 %; both powers at k keep 26 %. With main's flush that would cut staging, flush and `mid_pass` work by half or three quarters, but the affine form makes the full two-position test cheap enough to run there instead (6 %). §4's prototype does that, so the partial test is superseded.
- **The certificate rule** (test position j against the certificate whenever floor > j, instead of only when floor ≥ k2) never applies: every top that pairs has floor ≥ k2+1.

## 3. Cheaper per survivor

- **The stage's atomic is not the cost.** It is one shared `fetch_add` per survivor, from up to 7–8 lanes of a plane at once. A second one (`xm = 64`) adds 0.084 s per field, 1.0 ps per survivor. Ballot compaction (one atomic per plane per round) can save at most that: **≤ 0.4 % of the field. No.**
- **The flush's machinery is** (17.7 ps): every round of 256 staged survivors pays the plane scans, the `plane_tot` loop and two `sync_cube`. The per-round global atomic (`out_count`) plus its broadcast and the list stores add 11.9 ps more. All of it scales with *staged* survivors.
- **`mid_pass` recomputes, per survivor:**
  - what is constant per top: the top's 5 digits (5 divisions), and every column product among them;
  - what is constant per entry: r0's 3 digits, its squares' and cubes' low columns, the 12 digits of positions 0..5.
- **The CPU join hoists both** (`cpu_join::prefilter`). With R the bottom's k digits and D the top's digits at k, k+1 (`n = R + D·bᵏ`), the prefilter's digits are those of x2 = (a2 + p2·D) mod b² and x3 = (a3 + p3·D) mod b². The terms are:
  - a2 = ⌊R²/bᵏ⌋ mod b² and a3 = ⌊R³/bᵏ⌋ mod b² (per entry and key digit);
  - p2 = 2R mod b² and p3 = 3R² mod b² (per entry);
  - D (per top).

  Per pair that is 2 multiplies, 2 reductions mod b², 4 digit splits and the mask tests: about 50 SASS instructions against about 290.

## 4. The prototype: the prefilter in the walk (`xm = 256`)

What changes, about 110 lines in `cubecl_join.rs` (the rest of the branch is instrumentation):

- **Bucket kernel.** The digit columns run to k+2 instead of k; the extra digits are zeros, so the compiler folds most of it. Per extended entry it writes two words (`ext_q`):
  - Q2 = digits k−1..k+1 of R′² as a number (< b³);
  - Q3 = the same for R′³;
  - C3 = 3·r0² mod b³, 18 bits split over the two words' top bits.

  R′ is the entry with key digit 0.
- **Join kernel, top chunk load:** `t_dm[i] = (P mod b⁵) / b³ | seed << 16`, one more 1 KiB shared array.
- **Join kernel, wave load** (once per entry per 256 tops):
  - t2 = (Q2 + dkey·2r0) mod b³ and t3 = (Q3 + dkey·C3) mod b³.
  - The key digits are t2 mod b and t3 mod b, which replaces `ext_pk`; the carries are t2 / b and t3 / b.
  - p2 and p3 come from r0 mod b².
  - Two packed registers per entry.
- **Walk.** After the range test, `walk_pf` runs the affine test against the entry's mask (in registers) and the top's certificate (already in shared memory). Only survivors that pass are staged. The flush only compacts and writes, with no `mid_pass`. AND survivors are counted per thread, one atomic per plane at the end.
- **The production shape is required** (f0 = 3, k = 6, k2 = 8, key level). `JoinParams::for_length` gives that for every field the join takes at bases 40–64. The host refuses other shapes with this knob.

### Exactness

| field | AND survivors (prototype; main's survivors + overran) | list = full checks: prototype, every run | main (includes the overrun, unfiltered) |
|---|---|---|---|
| b62 1e16 × 2 | **163,513,599,082** (PROFILE-3's exact count) | 10,027,698,695 | 10,030,861,960–10,030,876,123 |
| b62 1e17 × 1 | **1,020,844,021,499** (PROFILE-3's) | 62,584,252,554 | 62,692,756,297–62,692,787,848 |
| b60 1e16 × 2 | **460,847,952,346** (PROFILE-3's) | 30,871,838,404 | 32,547,306,118–32,547,623,690 |

- Main's list minus its overrun, plus the overrun's own 6 % that would pass, equals the prototype's list.
- The stage never overruns now (0 in every run). At b60 that removes 1.68e9 unfiltered full checks per two fields.
- `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field` (4 partitions of the b62 1e16 field, `xm = 256`) passes with survivors and checked equal to the CPU join's, and no spill (`raw/box/dense_pf.log`).
- No hits anywhere.

## 5. A/B (unprofiled device seconds per field)

| field | control (main's kernel, `xm = 0`) | walk prefilter | **ratio of medians** | clock-normalised | saving per field |
|---|---|---|---|---|---|
| **b62 1e17**, 2 rounds | 225.33, 226.15 (1,449 MHz) | 189.41, 186.54 (1,473 MHz) | **×0.833** | ×0.847 | **−37.8 s** |
| b62 1e16 (2 fields), 3 rounds (control: 5 rounds) | 18.745, 18.576, 18.678, 18.316, 18.679 | 15.462, 15.673, 15.797 | **×0.839** (range ×0.825–0.862) | ×0.860 | −3.0 s |
| b62 1e16, against main's own binary | 18.137, 18.443, 18.585 (`bddf20f`) | as above | ×0.850 | — | −2.8 s |
| b62 1e16, all 8 controls pooled | median 18.581 | as above | ×0.844 | ×0.861 | −2.9 s |
| b60 1e16 (2 fields), 3 rounds | 42.76, 43.12, 43.26 | 34.64, 34.69, 34.19 | **×0.803** (×0.790–0.811) | ×0.819 | −8.5 s |

Clock-normalised = s × (mean SM MHz at ≥ 90 % utilisation) / 1,500. Both kernels sit at the 180 W cap; the prototype runs at 1–3 % higher clock.

- **Against the bars at b62 1e17:** 5 % is 11.3 s and 10 % is 22.6 s; the prototype saves 37.8 s (35.5 s clock-normalised).
- **b60 gains more** (×0.80): survivors are 31 % of its profiled field against 26 % at b62 (PROFILE-3), and its 0.4 % stage overrun goes too.
- **Where the saving comes from:** survivor handling 81.3 → 46.5 ps per AND survivor (§1a: 9.11 → 6.27 s of join per field, −2.85 s profiled; the A/B saves 3.0 s at b62 1e16). The bucket kernel pays +0.025 s per field for the longer columns. The check kernel is unchanged (same list).
- **Occupancy** (`raw/box/occ_*`, 2 rounds, b62 1e16): a 6 KiB shared pad that caps a cube at 4 per SM.

  | kernel | unpadded (s, r1 / r2) | padded to ≤ 4 cubes per SM | effect of the pad |
  |---|---|---|---|
  | main (62 registers, already 4 per SM) | 18.43 / 18.74 | 19.02 / 19.03 | +2.4 % (the larger shared carveout costs L1) |
  | prototype (44 registers, 5 per SM) | 15.67 / 15.67 | 15.88 / 15.88 | **+1.3 %** |

  So at most about 1.3 % of the prototype's 16 % is its extra occupancy. The rest is work removed.
- **32-bit digit tests** (`xm = 1280`): 15.96 / 15.95 s against the prototype's 15.57 / 15.71 in the same binary, i.e. 2 % slower, as the SASS count says (56 against 50). Keep the 64-bit form.
- **Main's binary against `xm = 0`** (`chain5`, interleaved): 18.44 / 18.59 s against 18.32 / 18.68 s, i.e. equal within the ±1 % spread. The prototype against main's binary is ×0.850 at b62 1e16 (median 18.44, three runs incl. the cool first one); the 1e17 and b60 controls are `xm = 0` only.

## 6. Candidates, ranked (b62 1e17 unless said)

| # | change | evidence | expected | clears 5 %? |
|---|---|---|---|---|
| 1 | **Prefilter in the walk, affine form** (prototype) | measured ×0.833 (b62 1e17), ×0.839 (b62 1e16), ×0.803 (b60 1e16); exact | **−16.7 %** | **yes, 3.3×** |
| 2 | **Dense prefilter**: after #1, run `walk_pf` on plane-compacted survivors instead of in the sparse walk | walk + prefilter are 42 of the remaining 46 ps per AND survivor, at 23 % lane use (7.5 survivors per round); the same 50 instructions at about 85 % would cost about 7 ps instead of 27 | −10 to −20 ps per AND survivor: **5–10 % of the post-#1 field** | likely, unproven |
| 3 | Third prefilter position (k+2), on the survivors #1 passes | list −80 % (20.25 % kept, exact); check at 86.5 ps per entry | ≤ 4.3 s gross; **1–1.5 % net** | no |
| 4 | Smaller stage (`SURV_SH_CAP` 1024 → 256) | after #1 the stage fills about 16× slower; overrun 0 | frees 6 KiB of shared memory per cube; no measured need (5 cubes per SM are register-bound) | no |
| 5 | Ballot compaction of the staging atomic | a second atomic costs 1.0 ps per survivor | ≤ 0.4 % (≤ 0.03 % after #1) | no |
| 6 | Partial test before staging (n²'s digit at k) | keeps 52 % | superseded by #1 (keeps 6 %) | — |
| 7 | Per-position certificate rule | 0 survivors affected | 0 | no |

### #2, specified for a follow-up

- **The problem.** Each lane walks its own set bits; a round lasts as long as the plane's busiest lane. That is 7.5 survivors per 32-lane round, so `walk_pf` (about 50 instructions) runs at 23 % lane use: 27 ps per AND survivor, 60 % of what is left.
- **Per chunk of 32 tops, per entry slot j:**
  1. The lane's survivors are `x = pm[j] & vv[j]` (range test folded in).
  2. `c = popcount(x)`, then `base = plane_exclusive_sum(c)` and `tot = plane_sum(c)`.
  3. Rounds of 32 over `0..tot`. Lane i takes survivor `s = round·32 + i` and finds its owner lane, the last lane with `base ≤ s`: a 5-step binary search over `plane_shuffle(base, ·)`.
  4. It pulls the owner's `x`, `ac`, `pc`, `mlo`, `mhi` and `r0` with `plane_shuffle` (6 shuffles).
  5. It selects the (s − base)-th set bit of `x`. CubeCL has no `fns`: use a popcount-halving search, about 10 ops.
  6. Range test, `walk_pf`, stage on pass.
- **Cost.** About 80–90 instructions per round at full lanes, against about 65 per round at 7.5 survivors now. Per AND survivor that is about 3 warp-instructions against 9.
- **Risks.** Register pressure (the shuffled values), and plane-op portability (`plane_shuffle` is in WGSL subgroups and Metal SIMD-groups; the join already needs plane ops).
- **Alternative.** Stage 16-bit (slot, bit) records into the existing stage, with the entry terms in shared memory (+8–10 KiB per cube: risks occupancy).
- **Measure it the same way** (`xm` bit, A/B b62 1e16 3 rounds and b62 1e17 2 rounds, counts equal).

### What #1 needs before a PR

- **Footprint** (`join_plan::Footprint`): `ext_q` is 8 B per (entry, slot) and replaces `ext_pk`'s 4 B. That is +4 B per entry-slot against the lists' 4·b B, about +1.6 % of the per-slot footprint at b62.
- **Apple Metal rule** (METAL-FIX): no division by a constant of a bare half-width shift.
  - Every division in the new code divides a sum, a mask or a loaded word.
  - The nearest is `((ac >> 16) + (pc >> 16)·dm) % b²`, a sum. Before merging, either check it on the M4 or keep a3/p3 in their own registers (+2 registers).
- **Shape.** Keep `mid_pass` as the fallback for parameter shapes other than (f0 3, k 6, k2 8, key level), or assert the shape.
- **Tests.** Run the wgpu reference test (`cubecl_join_matches_the_cpu_reference`) as well as CUDA.
- **Accounting.** Count AND survivors per thread (as the prototype does) and drop the flush's `staged[0]`. The overrun path stays as a safety net and now carries prefiltered survivors.

## 7. After #1: what the b62 field is made of

Profiled, b62 1e16, prototype (`ab256_*_p1`): 15.5 s per field.

| part | share |
|---|---|
| top certification | 7.7 s (49 %) |
| join | 6.3 s (41 %): AND lanes and per-top work 2.5 s (16 %), survivors 3.8 s (24 %) |
| check | 0.75 s (5 %) |
| bucket | 0.24 s |

Top certification becomes about half the field, and is the next single lever after #2.

## Raw data and scripts

All in `L30/raw/`:
- **Box logs** `box/`:
  - ablations `ab<xm>_e16_b62_p{1,2}.log`;
  - counts `st_e16_b62.log`, `st_e17_b62.log`, `st_e16_b60.log`;
  - A/B `c0_*`, `pf_*`, `base_*`;
  - occupancy `occ_*`;
  - 32-bit `pf32_*`, `pfb_*`;
  - CPU comparison `dense_pf.log`;
  - `.smi` clock/power traces, `power.txt`, `nproc.txt`, build logs.
- **Kernel sources** `box/cubecl_xm*.txt.gz` (CubeCL compile logs, gzipped) and `sass/`:
  - `join_kernel_xm*.cu` extracted;
  - `registers.txt` (ptxas -v per variant);
  - `opcount.cu`/`.sass` (op counts).
- **Scripts:** `setup.sh`, `setup_nice.sh` (builds), `run.sh`, `chain1.sh`–`chain5.sh`, `analyze.py` (`python3 analyze.py box`: runs, counts, profiled phases, A/B; output in `analysis.txt`).
