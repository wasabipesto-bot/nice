# Results: pin the MSD floor in the threaded-pipeline test

The branch is `pr/pin-floor-in-pipeline-test` on `fork` (wasabipesto-bot/nice). It has one commit, `a7c13a2`, on top of origin/main `9ab3a3c`.
The worktree is `/home/claude/projects/nice/.worktrees/pr-pin-floor`, and the PR body is `PR-BODY.md` in this directory.

## Where the build ran

ivory has 4 cores and about 7 GB of RAM. Free disk went from 3.4 GB at the start, to 3.1 GB after the release build, to 2.8 GB after clippy.

`gpu_niceonly` is `#![cfg(any(feature = "cuda", feature = "cubecl"))]`, so a default-features build does not compile the test at all. I built with `--features cuda` instead. That feature only adds cudarc, which dlopens the driver at runtime and so needs no CUDA libraries to build. I used `--release` because CI's failing job runs that way.

```
nice -n 19 cargo test --locked --release -p nice_common --features cuda --lib -j 3 --no-run
# baseline (origin/main): 2m01s cold, binary copied to target/baseline-nice_common
# fix: 58s incremental
```

## Cause

The pipeline and `run_range_pipeline` both read the floor from the process-wide `FloorController` (a `OnceLock` static). With a mock sink, the dispatcher's only waits are on the MSD workers (cpu_wait), so when an interval ends during the test the controller raises the floor. CI (run 41219859643 attempt 1, sha 2a1caf27) logged `GPU MSD floor: 250000 → 270856 (cpu waited 33%, device waited 0%, step 1.083)`. Its left (pipeline) had 250000-wide ranges and its right (reference) 500000-wide ranges. I confirmed this with `gh run view --log-failed`.

## Fix

- `Shared` now carries an `Arc<FloorController>`. `msd_worker` and `Dispatcher` read and observe through it.
- I added two private constructors, `NiceonlyPipeline::start_with` and `run_range_pipeline_with`. The public `start` and `run_range_pipeline` pass in `floor_controller().clone()`, so production does not change.
- The static is now `OnceLock<Arc<FloorController>>`.
- The test uses `fixed_floor(TEST_FLOOR)`, a pinned controller of its own, for both forms. `TEST_FLOOR` is 4000, the floor `mixed_windows` already filtered at, and that literal is now the const.
- I added `assert_eq!((stats.floor, ref_stats.floor), (TEST_FLOOR, TEST_FLOOR))` and `assert!(!expected.is_empty())`.
- The doc comment explains the choice.

## Before the fix: full suite in parallel (baseline-parallel.log)

```
for i in 1..20: RUST_LOG=debug nice -n 19 target/baseline-nice_common --test-threads 8
```

1 of 20 runs failed (run 8). It hit the same assertion as CI on the same field-0 descriptors:

```
GPU MSD floor: 250000 → 294606 (cpu waited 71%, device waited 0%, step 1.178)
field 0: descriptors differ from the one-field form
  left: [(238000000, 250000, 68987977743), (238250000, 250000, 68987977743), ...
 right: [(238000000, 500000, 68987977743), (239000000, 500000, 68987977759), ...
```

Two other baseline attempts did not reproduce it:

- contention.log: the test pinned to one core with a nice-0 busy loop, 3 runs. All passed, because the pipeline phase at the 250k seed floor still finishes inside 500 ms.
- module-loop.log: the `gpu_niceonly::tests::` filter, 30 runs at 8 threads. All passed, for baseline and fix alike.

## After the fix

| what | runs | result | log |
|---|---|---|---|
| test alone (`--exact`), fixed tree before the commit | 20 | 20 ok (0.03–0.07 s) | fixed-alone.log |
| full lib suite, `--test-threads 8`, fixed tree before the commit | 20 | 20 ok (214 passed, about 8.5 s) | fixed-parallel.log |
| full lib suite, `--test-threads 8`, committed a7c13a2 rebuilt | 10 | 10 ok | commit-recheck.log |
| test alone, committed a7c13a2 rebuilt | 20 | 20 ok | commit-recheck.log |
| alone on one core with a nice-0 busy loop | 3 | 3 ok (2.4–2.7 s; the baseline took 1.0 s) | contention.log |

I checked that the committed file is byte-identical to the file tested before the commit (`cmp`).

## Forced provocation (moving-floor.log; temporary tests, never committed)

I added two throwaway tests to the committed tree and later removed them with `git checkout`. Both ran the same three-field equality check. A stepper thread forced `floor_controller()` intervals to elapse and called `observe` every 1 ms, going up and down between the clamps. Each test ran in its own process.

- With the shared controller (`floor_controller().clone()`, which is exactly what `start` and `run_range_pipeline` do, i.e. the original test): **3 of 5 failed**, with `field 0: 96 vs 88 ranges`, `field 1: 488 vs 459` and `field 2: 27 vs 49`. There were 25–31 floor steps during each check.
- With the pinned controllers (the new test): **5 of 5 passed**, with 37–50 floor steps during each check.
- Descriptor counts at floor 4000: field 0 had 3155, field 1 had 17439 and field 2 had 922, with 1 launch each.

## Lint

```
cargo fmt --all --check                                                     # clean
nice -n 19 cargo clippy --locked -p nice_common --all-targets --features cuda -j 3 -- -D warnings   # clean (clippy-cuda.log)
nice -n 19 cargo clippy --locked -p nice_common --all-targets -j 3 -- -D warnings                   # clean (module not compiled)
```

To check that clippy really lints the test module under `cuda`, I removed the `#[allow(clippy::cast_precision_loss)]` on `fixed_floor`. Clippy errored at gpu_niceonly.rs:1695, and I restored the attribute.

I did not run `--features gpu` clippy, which builds cubecl/wgpu, on ivory because of disk and build size. The CI lint job runs it.

## CHANGELOG

I left it out. The change only fixes a test, and the maintainer's own test-only commit cc1a4aa did not touch the CHANGELOG either.
