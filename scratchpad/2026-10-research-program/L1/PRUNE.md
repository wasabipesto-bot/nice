# L1 follow-up: drop the bottoms that meet the field's certificate (2026-10-28)

**Verdict: adopt.**
- On an RTX 3080, at the profile run's fields (1e16, 2 per base), the prune cuts time per field by **13.2 % (b58), 12.7 % (b60), 29.3 % (b62) and 39.1 % (b64)**: 1.15× / 1.15× / 1.42× / 1.64×, with spreads of 0.6–2.4 % over 3 interleaved rounds.
- NiceMark nice-only gains 18–44 % per scenario, and every scenario takes the join (score 2892 → 3705, +28 %).
- Nothing regresses, and every base clears the 5 % bar by at least 2.5×. Output is exact: the CPU and GPU parity tests pass unchanged.
- With the prune the best join wave drops to **EPT 2**, a further 5–14 %. Prune + EPT 2 against main's current EPT 4 is ×1.5 at b62 and ×1.9 at b64 (cross-run).
- One side effect to fix: more survivors overrun the join kernel's stage at b62/b64 (2–2.5e-4 of them). That is benign (+0.3–0.4 % full checks) but above the dense test's 1e-4 limit for a b64 1e16 field.

## Code

Branch `rp/field-cert-prune` on the fork (`wasabipesto-bot/nice`), on origin/main `85b5b4e`.

| commit | what |
|---|---|
| `71a085e` | test only: the throughput harness takes bases 58 and 62 and `NICE_TEST_JOIN_SIZE` |
| `c1174c1` | **the prune** |
| `e252bf4`, `c1306b5` | test only: the prune check takes `NICE_TEST_PRUNE_FIELDS`; a lint allow |
| `4670ffe` | test only: harness `NICE_TEST_JOIN_STARTS`; warm-up field at most 1e14 (as `rp/gpu-profile` cfeb93d). **B tree of the A/B.** |

Other branches:
- `rp/field-cert-prune-base` = `85b5b4e` + `71a085e` + `4670ffe`'s harness change cherry-picked as `2d740d3`. **A tree of the A/B.** Both trees run the same harness. The only non-test difference is `c1174c1`.
- `rp/field-cert-prune-ept` = `4670ffe` + `6e4e895`: the `NICE_EXP_JOIN_EPT` override of `rp/gpu-profile` 69a83b5, without its profile.

### What changed (line numbers at `c1306b5`)

- `common/src/overlap_join.rs`
  - `FieldSetup.fc: u64` (l. 861–868) is the field's certificate `base.cert(s, e − 1, k)`. `top_side` computes it (l. 1005–1027).
    - If the certificate fails (a repeated constant digit), `fc = 0` and nothing is pruned.
    - The top layer is then already empty: each top certifies a sub-interval, whose digit set is a superset. A `debug_assert` checks this.
    - An empty `tlay` already returns early on both paths (`cpu_join` l. 383, `cubecl_join::run_slice` l. 1997).
  - `FieldSetup.bp_all: Arc<(Vec<u32>, Vec<u64>)>` (l. 875–878) is `bpre` before the prune.
  - `FieldSetup::prune_bottoms` (l. 966–1003) keeps the `m & fc == 0` entries, rebuilds `seg`, and logs `keeps X of Y bottom prefixes` at debug level.
  - `new` prunes by its own `fc`. `sub_range` re-prunes `bp_all` by **the slice's own** `fc`.
    - Soundness needs this. `plan_join` builds its probe over one prefix block, then takes the first slice from it with `sub_range`. `run_field` takes later slices from the first slice's setup.
    - So a parent's certificate is in general not a subset of the slice's, and reusing a pruned list would drop live bottoms.
- `common/src/join_plan.rs` `Footprint::with_prefixes` (l. 168–170) sizes buffers by `bp_all`'s length, the unpruned count. Layouts, slots per launch and slice caps are identical to main; the A/B shows the same batches and slots on both trees.
- `common/src/cpu_join.rs` tests each added digit against `mask | fc`:
  - `extend` (l. 469, 487): the fixed partition digits;
  - `list` (l. 573, 582): the last (key) digit.
- `common/src/cubecl_join.rs`
  - `bucket_kernel` takes `fc_lo, fc_hi: u32` (l. 155–156, 165). The partition-digit test is `(m | fc) & bb` (l. 231); the key-digit test uses `mf = m | fc` (l. 239–241, 265).
  - `JoinDevice.fc` (l. 1276, 1436–1439) is passed at launch (l. 1625–1626).
- **Unchanged:** the AND, `ext_m` (the bottom's own mask, which the AND and the full check's known-LSD mask read), the reference `join_range`, and every other kernel.

## Exactness

On ivory (CPU, release; `prune-raw/ivory-*.log`):

- **New test** `cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate`, on every `PLAN_FIELDS` field. It asserts:
  - `fs.fc == cert(s, e − 1, k)`;
  - `fc = 0` prunes nothing;
  - the pruned `bpre` (class, residue, mask) equals the unpruned one filtered by `m & fc == 0`;
  - on 2 live partitions per field and every key digit, the CPU bottom lists (key, class, residue, full mask, carries) equal the unpruned lists filtered by `mask & fc == 0`.
  - It also passes on the 4 throughput fields at 1e14, the 8 L1 fields, and the 8 A/B fields at 1e16.
- **Existing tests:**
  - the cpu_join / overlap_join / join_plan unit tests: 19 passed;
  - `cpu_join_matches_the_reference_on_production_fields` (`NICE_TEST_CPU_JOIN_REF=2`, b42–b64) passed. It checks join survivors, prefilter survivors and hits against the unpruned reference.
- **Lint:** fmt clean; clippy (default features, `--all-targets -D warnings`) clean.

On the box (`prune-raw/box/exact.log`, `clippy.log`; prune tree, `--features gpu`):

- The CUDA kernel compiles (NVRTC at first launch) and runs.
- `nice_common` non-ignored tests: 194 passed.
- **CubeCL CUDA join tests**, all passed:
  - `cubecl_cuda_join_matches_the_cpu_reference`: every window, tight layouts, slices and refused layouts agree with the unpruned reference;
  - `..._on_a_dense_field` (`NICE_TEST_JOIN_DENSE=64`, b58 1e15): 2.6e-5 of survivors overran the stage, within its 1e-4 limit;
  - `..._on_a_whole_field` (`NICE_TEST_JOIN_FULL_FIELD=1`, b42; `fc = 0` there, so a regression check only).
- The throughput harness with **`NICE_TEST_JOIN_COMPARE=1`** (2 fields of 1e14 per base at the A/B starts, b58/60/62/64): the join and the stride pipeline agree (found 0 = 0 on every base).
- `cpu_join_matches_the_reference_on_production_fields` passes again here.
- `cargo clippy -p nice_common --all-targets --features gpu -- -D warnings` is clean. `rustfmt` is not installed on the box; fmt was checked on ivory.

**The counters move by the survivor-stage overrun, not by a change in what is found.**
- On the 1e16 fields the prune tree counts fewer AND survivors and more prefilter survivors than main:
  - b62: −3.7e7 survivors (2.0e-4 of them), +3.5e7 checked;
  - b64: −2.16e8 (2.5e-4), +2.02e8;
  - b58: −1.1e6 (1.4e-6), +1.0e6;
  - b60 goes the other way: +4.4e6, −4.1e6.
- In every case Δchecked / Δsurvivors = 0.93–0.94 = 1 − the prefilter's keep rate (6.3 %). That is exactly the documented overrun path: a survivor that overruns the join kernel's shared stage goes to the list unprefiltered and uncounted.
- The prune packs a bucket's survivors into fewer entries, hence fewer waves, so a 32-top chunk overruns more often at b62/b64.
- Cost: +0.3–0.4 % full checks, already inside the timings below.
- **Flag:** at b64 1e16 the overrun share (≥ 2.5e-4) is above the dense-field test's 1e-4 limit. A dense b64 version of that test would now fail on the limit, though not on exactness. Flushing per 16 tops, or a bigger stage, would restore the margin.
- Both trees run to run: survivors vary by 4e3–7e5 (timing-dependent overruns).

## Bottoms before / after

Per partition, summed over key digits. The CPU lists equal the GPU's per-key lists by construction. Logs: `ivory-bottoms-before-after.log`, `box/exact.log`.

**The A/B fields (1e16, the profile run's starts):**

| base | field | fc digits | bpre before → after | listed bottoms before → after | pruned |
|---|---|---|---|---|---|
| 58 | 104400216587923470200, both fields | 4 | 142,260 → 96,352 | 3.17M → 1.28M | 59.5 % |
| 60 | 1366406074057412100454, both fields | 4 | 137,775 → 101,400 | 3.23M → 1.47M | 54.6 % |
| 62 | 7997740455941656911841 / +1e16 | 6 / 5 | 176,671 → 94,818 / 108,355 | 4.50M → 1.16M / 1.50M | 74.3 / 66.7 % |
| 64 | 41242006262957161709568, both fields | 7 | 180,003 → 93,846 | 4.85M → 1.11M | 77.1 % |

The "before" lists reproduce GPU-RESULTS' listed entries per field: 3.17M × 3364 partitions × 8 slices = 8.5e10 at b58.

**Production size (1e14) and the L1 fields:**

| base | field | size | fc digits | listed before → after | pruned |
|---|---|---|---|---|---|
| 58 | item 18 | 1e14 | 6 | 3.17M → 0.78M | 75.5 % |
| 60 | THROUGHPUT_STARTS | 1e14 | 6 | 3.23M → 0.86M | 73.4 % |
| 62 | PLAN | 1e14 | 8 | 4.50M → 0.61M | 86.3 % |
| 64 | PLAN | 1e14 | 9 | 4.85M → 0.73M | 85.0 % |
| 57 / 50 / 42 | PLAN | 1e14 / 1e14 / 1e13 | 6 / 2 / 0 | 2.86M → 0.53M / 1.16M → 0.70M / unchanged | 81.5 / 39.7 / 0 % |
| 58 | item 18 / item 23 | 1e15 | 5 / 4 | 3.17M → 0.98M / 1.16M | 69.0 / 63.3 % |
| 60 | item 23 / plan | 1e16 | 5 / 4 | → 1.08M / 1.47M | 66.6 / 54.6 % |
| 62 | item 23 / plan | 1e16 | 5 / 6 | → 1.49M / 1.16M | 66.8 / 74.3 % |
| 64 | item 23 / plan | 1e16 | 7 / 7 | → 0.87M / 1.11M | 82.0 / 77.1 % |

The 1e15/1e16 rows reproduce RESULTS.md's `prune_window`. Fields at production size (1e14) know 6–9 digits and lose 73–86 % of their bottoms, so the 1e16 A/B below understates the production gain.

## GPU A/B

**Setup.**
- Box: Vast 58056651, RTX 3080 10 GB, driver 580.126.09, 48 visible cores, the same machine as GPU-RESULTS. SM clock 1830 MHz, about 231 W, 55 °C while running.
- Trees: A = `/root/main` at `2d740d3`, B = `/root/prune` at `4670ffe`. Each was built with `cargo build --release -p nice_client --features gpu` and `cargo test --release -p nice_common --features gpu --no-run`.
- Nothing else ran during the timed runs.
- Raw logs: `prune-raw/box/`. Tables: `prune-raw/ab_tables.md`, generated by `prune-raw/analyze_ab.py`.

### Fixed-field throughput (primary)

`cubecl_cuda_join_throughput_fixed_fields` with `NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64`.
- Starts, via `NICE_TEST_JOIN_STARTS`, are GPU-RESULTS': b58 104400216587923470200, b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568.
- Each base gets a 1e14 warm-up first.
- Order A B A B A B (`box/ab.sh`). The figure is the harness's `per_field` (wall seconds / 2 fields, two fields in flight).

| base | tree | r1 | r2 | r3 | **median s/field** | spread | device s/field | batches | slots |
|---|---|---|---|---|---|---|---|---|---|
| 58 | main | 69.36 | 69.17 | 69.79 | **69.36** | 0.9 % | 68.92 | 5468 | 5 |
| 58 | prune | 60.18 | 59.59 | 60.27 | **60.18** | 1.1 % | 59.76 | 5468 | 5 |
| 60 | main | 45.72 | 45.19 | 45.26 | **45.26** | 1.2 % | 44.87 | 5445 | 4 |
| 60 | prune | 39.54 | 39.08 | 39.52 | **39.52** | 1.2 % | 39.14 | 5445 | 4 |
| 62 | main | 27.07 | 26.98 | 26.79 | **26.98** | 1.0 % | 26.28 | 2632 | 16 |
| 62 | prune | 19.10 | 19.07 | 18.98 | **19.07** | 0.6 % | 18.37 | 2632 | 16 |
| 64 | main | 85.39 | 83.41 | 83.42 | **83.42** | 2.4 % | 83.08 | 3329 | 6 |
| 64 | prune | 50.91 | 50.79 | 50.63 | **50.79** | 0.6 % | 50.42 | 3329 | 6 |

| base | speed-up (median) | time saved | main's join-kernel share (GPU-RESULTS) | time saved ÷ join share |
|---|---|---|---|---|
| 58 | **1.153×** | 13.2 % | 64.8 % | 20 % |
| 60 | **1.145×** | 12.7 % | 55.8 % | 23 % |
| 62 | **1.415×** | 29.3 % | 57.9 % | 51 % |
| 64 | **1.643×** | 39.1 % | 82.6 % | 47 % |

- Main's device seconds reproduce GPU-RESULTS' unprofiled 68.8 / 45.2 / 26.1 / 83.1.
- **The join kernel saves less than the pairs fall.**
  - Pairs fall by 55–77 %. The saving (time saved ÷ main's join share) is 20–51 % of the kernel's time, slightly less, since the bucket kernel, 3–7 % of the time, also does 30–48 % less work.
  - The 74 ps-per-survivor term does not move.
  - Wave padding (GPU-RESULTS' lane model) explains part of the gap at b62/b64, where buckets of about 1,200 entries took 2 waves of 1,024 and the pruned ones (about 280–400) take 1.
  - At b58/b60 the buckets were already one wave (padded/pairs 1.07–1.10), yet the join still saved 20–23 %. So a partly filled wave costs less than a full one, and the pure padded-lane model overstates the padding.
  - This run has no profile to split it further. The EPT sweep below tests the wave size directly.

### NiceMark nice-only

`nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, `RUST_LOG=info`, A B A B A B (`box/nicemark.sh`; `box/nm_r*_{main,prune}.{json,err}`).
- **Every scenario took the join**: `route: join` in the JSON on both trees.
- Each sample covers most of the first slice's partitions:

| scenario | sample | main rates (n/s) | prune rates (n/s) | main median | prune median | spread main / prune | **prune / main** |
|---|---|---|---|---|---|---|---|
| b58_msd_weak (1e15) | 3.1k/3364 partitions, 1 slice, 6 slots | 1.29e14, 1.30e14, 1.29e14 | 1.52e14, 1.53e14, 1.51e14 | 1.289e14 | 1.516e14 | 1.0 / 1.1 % | **1.176** |
| b58_msd_strong (1e15) | all 3364, 1 slice, 16 slots | 7.45e14, 7.53e14, 7.50e14 | 1.00e15, 9.94e14, 9.91e14 | 7.501e14 | 9.941e14 | 1.1 / 0.9 % | **1.325** |
| b60_msd_weak (1e16) | 1.9k/3600 of slice 1 of 7, 4 slots | 2.58e14, 2.57e14, 2.63e14 | 3.12e14, 3.08e14, 3.10e14 | 2.582e14 | 3.101e14 | 2.3 / 1.2 % | **1.201** |
| b62_msd_weak (1e16) | all 3844 of slice 1 of 6, 6 slots | 2.95e14, 2.97e14, 2.99e14 | 4.28e14, 4.24e14, 4.34e14 | 2.974e14 | 4.278e14 | 1.2 / 2.4 % | **1.439** |
| **score** | | 2873, 2892, 2898 | 3705, 3690, 3705 | 2892 | 3705 | 1.0 / 0.5 % | **1.281** |

- The NiceMark references (`bench_defs.rs`) were pinned on main and will read about 28 % high on the prune.
- The scenario fields are the ones the fleet's estimator and score use, so they need re-pinning if the prune merges.

### Wave size with the prune (EPT sweep, priority 4)

Tree `/root/ept` = `rp/field-cert-prune-ept` `6e4e895`: the prune plus the `NICE_EXP_JOIN_EPT` override. Each run is the first 1e16 field of a base after a 1e14 warm-up, `NICE_TEST_JOIN_FIELDS=1`.
- b62/b64: EPT 2, 3, 4, 5 in two interleaved rounds (`box/ept.sh`).
- Then one extra round (`box/ept2.sh`): EPT 1 at b62/b64, and EPT 4, 2, 1 at b58/b60.
- Logs: `box/ept_r*_e*_b*.log`.

| base | EPT 1 | **EPT 2** | EPT 3 | EPT 4 (production) | EPT 5 | EPT 2 vs 4 |
|---|---|---|---|---|---|---|
| 58 | 62.90 | **56.09** | – | 61.02 | – | **×1.088** (1 round) |
| 60 | 39.14 | **36.98** | – | 38.93 | – | **×1.053** (1 round) |
| 62 | 25.31 | **24.74, 24.88** | 25.57, 25.33 | 26.30, 26.30 | 27.41, 27.32 | **×1.060** |
| 64 | 47.86 | **43.70, 45.06** | 47.69, 47.10 | 50.52, 50.59 | 53.91, 54.71 | **×1.139** |

Wall s/field with one field (setup not overlapped); device seconds are 0.7–0.9 s lower.

- **With the prune the best wave is EPT 2 (512 entries) at every base.** It is 5–14 % faster than EPT 4, and EPT 1 is worse than 2 everywhere.
- That fits GPU-RESULTS' rule, EPT = ceil(mean probed-bucket occupancy / 256). Pruned occupancy at these fields is about 280–420 entries (1212 × 0.23 at b64 up to 931 × 0.45 at b60), which gives 2.
- At production size (1e14) the prune leaves fewer entries (about 160–250), so the rule would give 1 there. That is unmeasured. Since EPT 1 lost at every 1e16 field, I would not extrapolate.
- **Combined, against main** (cross-run: main's figures are GPU-RESULTS' first-field device seconds on this machine):
  - b62: prune + EPT 2 = 24.05 s against main EPT 4 = 36.2 s (**×1.51**) and main's best, EPT 5 = 32.4 s (×1.35);
  - b64: 43.68 s against 83.5 s (**×1.91**) and 70.3 s (×1.61).
  - This **replaces GPU-RESULTS' EPT 5 recommendation (and #205's EPT 6) once the prune is in**. Those were fitted to unpruned buckets of about 1,200 entries.
- Caveats:
  - b58/b60 had one round only.
  - One GPU model; the 4090/A100/9070 XT have different wave economics.
  - The counters show a pre-existing overrun effect that is not the prune's. At b60, EPT 1 counts 3.7e8 more survivors (and 3.5e8 fewer checked) than EPT 2/4: about 1.6e-3 of the field's survivors overrun the stage at EPT ≥ 2, on main as well as the prune (A/B b60 counters are within 4e6 of each other).


## Not done / caveats

- No production-size (1e14) GPU A/B. Those fields lose more bottoms (73–86 %) than the 1e16 fields measured, so the gain there is probably at least as large. That is unmeasured.
- The A/B fields have no nice numbers (found 0), so hits equality on them is trivial. Exactness rests on the parity tests listed above, which do find hits (69 in base 10, the b42 field and the windows).
- The CPU join's speed-up was not timed; RESULTS.md's bound applies.
- The first box (58053611) refused ssh keys, which cost about 40 minutes.
- No profiled run (`NICE_EXP_GPU_PROFILE`) with the prune, so the phase split of the saving is inferred, not measured.
- `CARGO_TARGET_DIR` on ivory was shared with `.worktrees/rp-l1` as instructed. That worktree's test binary `nice_common-ff746edb5f48128a` is now this branch's build; rebuild it before reusing it.
