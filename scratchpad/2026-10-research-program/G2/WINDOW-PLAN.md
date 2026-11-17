# G2 window plan: the RX 9070 XT, at most 45 minutes (draft 2026-11-17; dry-run status at the end)

**What it decides.** The ratio of G2, the CubeCL port of kernel v10 with its GPU preparation, against today's main
on that card, both at base 64.

- **Stop the redesign below ×4.0** same-session (`G2/PROPOSAL.md`).
- The offline prediction is **×4.4 central, ×3.3–5.6** (`G2/PORT-NOTES.md`). The line sits inside the band, which
  is why the hour is needed.

**Binaries.** Build them before the window, with the production client still running.

- **Source:** local branch `g2-cubecl-local`, never pushed. It ships as the thin bundle
  `G2/port/g2-cubecl-local.bundle` (prerequisite: upstream main `7e0113fc`).
- **Unbundle:**
  ```
  git -C ~/nice-src fetch https://github.com/wasabipesto/nice.git main
  git -C ~/nice-src fetch <bundle> g2-cubecl-local:g2-cubecl-local
  git -C ~/nice-src worktree add $W/wt g2-cubecl-local
  ```
- **The two binaries** (`CARGO_TARGET_DIR=$W/target`, release):
  - **g2:**
    ```
    cargo build --release -p nice_common --example g2_cubecl --features cubecl-spirv
    cp $W/target/release/examples/g2_cubecl $W/bin/g2
    ```
    This uses the direct SPIR-V compiler, which is what the card runs in production.
  - **main:** nice_common's test binary at the same commit, with production's features:
    ```
    cargo test --release -p nice_common --features gpu,cubecl-spirv --no-run
    ```
    Then copy the path cargo prints after `Executable unittests src/lib.rs (…)` to `$W/bin/main`. **cargo 1.100
    puts it under `target/release/build/nice_common/<hash>/out/`, not `deps/`.**
  - The library code is main's byte for byte: the branch only adds `common/examples/g2_cubecl.rs`, an `[[example]]`
    entry and an `env_logger` dev-dependency.
- **Data:** `$W/data/su64_712012851/` and `$W/data/su64_391856203/` (tops.bin, surv.bin, meta.txt; 200 MB each)
  from `G2/bench/`.
- **Scripts:** `G2/port/window/*` go to `$W/scripts/`.

## Steps (director, on demoux, production client stopped by the user)

1. Check that `vulkaninfo --summary` shows RADV with subgroup size 64. Then run:
   ```
   W=$W END_AT=$(( $(date +%s) + 44*60 )) sh $W/scripts/go_g2.sh 2>&1 | tee $W/out/go.out
   ```
2. **The order** (in `go_g2.sh`), with time estimates [E]:
   - **Exactness on the card** (≈ 2 min): G2 on the whole first super-unit with the GPU preparation, then the
     second super-unit, with the shuffle transpose (variant A); then the first with the ballot transpose (B).
     - Each run must print `ALL CHECKS PASSED`: every unit's survivor set equals the prototype's, the counts equal
       the CPU reference, the GPU preparation's order equals the CPU's, and the kernel's plane and slab error
       counters are 0.
     - **This is the first execution of the W = 64 code anywhere** (see "What is not yet proven" below).
     - If neither A nor B passes, stop and report.
   - **Three G2 timing rounds**, rotated A / B / C. C is A with one list entry per step.
     - Each round is two runs per variant: `t_*` (GPU prep plus modes 0, 1, 2, 400 launches each, counts checked) and
       `o_*` (no survivor records). About 20 s each, 6 min for the three rounds.
     - **Main's ten base-64 1e17 fields** sit between the rounds, five after round 1 and five after round 2. These
       are the B64.1 fields at 0.05–0.95; 0.25, 0.45 and 0.75 are empty.
     - Each field is one process of `join_throughput_fixed_fields`: an untimed warm-up field, then the timed field.
     - Estimate: about 650 s of fields on this card (the RTX 3080 needed 811 s; the card ran the 0.55 field in
       ≈ 93–101 s against the 3080's 123 s) plus about 5 s per process. About 12 min.
   - **Spare:** one more A round, or a re-run of an off-point main field.
   - **Total about 22 min,** inside 45 with room for one re-run of each kind.
3. **Accept a run** only if `python3 $W/scripts/analyze_g2.py $W/out 3150 300` shows it on point.
   - The median clock must be ≥ 97 % of 3,150 MHz and the power ≥ 90 % of 300 W, over the samples at ≥ 80 % busy
     (N22's rule).
   - G2's runs are bursts. If they come out off point, read their clock rather than rejecting them.
   - Counts must be identical in every G2 run, and survivors / checked in every main field identical to
     earlier runs of that field.
   - An off-point main field is re-run once in the spare, not averaged in.
4. **At the end:**
   - Copy `$W/out` to ivory.
   - Stop any sampler that is still alive by its PID.
   - Remove `$W`.
   - Report.

## What the numbers mean

`analyze_g2.py` prints, per variant:

```
ratio = main base mean / (G2 end-to-end + tops and survivor checks)
```

- **Main base mean:** the ten fields' seconds ÷ (10 × 1e17 × 8/63).
- **G2 end-to-end:** GPU prep plus the full kernel over the whole super-unit, median of three rounds.
- **Tops and survivor checks:** 0.115 fs on the 3080 (`BENCH.md`), scaled by this card's main mean over the 3080's
  6.347 fs. Those are main-type kernels.

| result | reading |
|---|---|
| best variant ≥ ×4.0 | the proposal's go: build the client against option A's wire format |
| best variant < ×4.0 | stop the redesign (the proposal's rule), unless one variant is ≥ ×4.0 and the others are not, in which case that one is the client's form |
| A not exact, B exact | the shuffle transpose has a W = 64 defect; price with B, and fix A on ivory afterwards (no window time spent on it) |
| G2 counts differ between runs | stop: a race on the card that lavapipe did not show |
| a G2 run reports plane errors (`errors: plane N`, N > 0) | RADV ran the kernel with planes other than the 64 the device reports (for example wave32). Re-run the exactness step with `--plane-w 32`, the W = 32 path (one more exactness run, about 40 s), and time that |

## Dry run [M] (ivory, lavapipe 26.0.8 in the `g2mesa` container, 2 threads)

- **Command:**
  ```
  W=…/win DEV=lvp G2JOBS=0-1:0-63 REPS=1 SZ64=1e14 NMAIN=1 END_AT=… sh scripts/go_g2.sh
  ```
  - The binaries are `g2bin/g2_spirv` and `main_spirv_test`, built `--features cubecl-spirv`.
  - On lavapipe the harness's warm-up has to be 1e14: smaller fields route to the stride pipeline, and the
    harness asserts the join.
- **Result:** every stage ran end to end.
  - The three exactness runs passed.
  - All 21 G2 timing runs (three rotated rounds plus the spare) passed, with equal counts.
  - Main's harness ran fields 1 and 6 (620 s and 732 s on lavapipe).
  - The analysis printed its tables. Its verdict path was exercised on synthetic main logs.
  - Logs: `G2/port/raw/dryrun/`.
- **Not exercised:**
  - the AMD sysfs sampler and the OFF-POINT test (lavapipe has no GPU);
  - the W = 64 kernel paths.

## Changes after the CUDA run (2026-11-17 12:00 UTC, `BENCH.md` §"CubeCL port on CUDA")

1. **Rebuild from the current bundle** (head `02075501`). It adds:
   - `--cuda`;
   - ballot ranks (`--ranks 1`, default), without which CubeCL's plane scans cost 0.76 fs on CUDA;
   - queued launches in timing runs.
   The driver's variants take the defaults.
2. **The driver ran end to end on a rented RTX 3080 against the CUDA binaries.**
   - Settings: `HARNESS=cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields`, `G2EXTRA=--cuda`,
     `NMAIN=1`, `REPS=400`.
   - Exactness A / A su2 / B passed. Every timing run passed, with equal counts. Main fields 1 and 6 ran in 93.5 s
     and 124.3 s, matching the client's 96.7 s and 123.1 s.
   - The analysis printed every table.
   - The sampler has nothing to read on NVIDIA. That is expected: it reads AMD sysfs only, so the AMD path of
     `smp.sh` is still unexercised. **The director should check by hand that `$OUT/*.gpu` fills during the first
     exactness run on the card.**
3. **The CubeCL kernel's per-process timing is bimodal on the 3080** (about +25 % in the slow mode).
   - Run **four rounds of A** (move the spare's A into the rounds).
   - Report the median *and* the minimum per variant.
   - If A's rounds split into two clusters, report both and decide on the low cluster only if it is ≥ ×4.0 with
     margin. Otherwise call it inconclusive.
4. **Set `G2BATCH=4032`** if the card allows a 254 MB storage binding (W = 64 needs about 62k slabs of 4 KB).
   Otherwise use `2016`.
5. **The context the director should carry in:** the same CubeCL kernel is **×3.79 against main on the RTX 3080**
   (hand CUDA v10 ×5.07). The ×4.5 AMD prediction rests on main being relatively slower on that card and phase 3
   being faster there.
   - The bottom-side and preparation fixes listed in `BENCH.md` would be worth about +0.4 fs of headroom.
   - **I would land them before the window** (ivory, lavapipe-provable, about half a day) rather than spend the
     hour on a kernel known to carry 0.43 fs of avoidable cost.

## Changes after the fixes (2026-11-17 13:00 UTC)

- **Bundle head `997339bc`.** Defaults: `--xpose 1 --ept 2 --ranks 1 --cmask 1`, with the GPU preparation's rank
  sort and top digits.
- **`go_g2.sh` now:**
  - stops after the first exactness run if the sampler wrote no `busy=` samples on the card (the hand check, made
    explicit);
  - runs **four rounds of A** (round 4 after round 3) and keeps a spare round 5;
  - defaults to `G2BATCH=4032`, one launch per super-unit. Set `G2BATCH=2016` if the card refuses a 254 MB storage
    binding.
- **`analyze_g2.py`** prints each variant's median **and minimum**, flags a spread over 10 % as possible
  bimodality, and gives the ratio for both.
- **Prediction for the card:** central ×5.4 (×4.0–6.9). Stop line ×4.0. A useful extra comparison on the card is
  B = `--cmask 0` (variant C's slot), if a card run should show the in-transpose common masks' worth there.
