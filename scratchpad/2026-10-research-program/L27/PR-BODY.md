# Pin the MSD floor in the threaded-pipeline test

`gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field` fails now and then when it runs alongside other tests. It always passes on its own. This PR makes it deterministic.

## What the test checks

It pushes three base-40 windows through `NiceonlyPipeline` with two fields open at once and a mock sink. It checks that results come back in push order and that the sink sees the right open/launch/close order. It then runs each window through the one-field form (`run_range_pipeline`) and asserts that the pipeline gave the sink exactly the same range descriptors for each field.

## Why it depended on timing

The pipeline and the one-field form both read the MSD floor from the one process-wide `FloorController`, and that controller steers. The floor sets where the MSD recursion stops, so it sets where descriptors are cut.

With a mock device, `launch` never blocks. The dispatcher's only waits are on the MSD workers, and the controller treats that as a starved device: it raises the floor when an adjustment interval (500 ms) ends. Run alone, the test is over long before the first interval ends. Alongside the other tests that share the controller, or on a loaded host, a step can land between the pipeline run and the reference run, or during one of them. The two forms then cut the same numbers at different boundaries.

That is the failure in the `Test GPU host code (cuda feature, NVRTC)` job on 2a1caf2 (run 41219859643, attempt 1):

```
GPU MSD floor: 250000 → 270856 (cpu waited 33%, device waited 0%, step 1.083)
panicked at common/src/gpu_niceonly.rs:1730:13:
field 0: descriptors differ from the one-field form
  left: [(238000000, 250000, 68987977743), (238250000, 250000, 68987977743), ...
 right: [(238000000, 500000, 68987977743), (239000000, 500000, 68987977759), ...
```

The pipeline (left) cut 250 000-wide ranges at the seed floor of 250 000. The reference (right) ran after the step to 270 856 and kept 500 000-wide ranges.

## The fix

- A pipeline now gets its floor controller when it starts. The new private constructors are `NiceonlyPipeline::start_with` and `run_range_pipeline_with`. The workers read the floor from that controller, and the dispatcher reports its waits to it, instead of calling the global directly.
- `NiceonlyPipeline::start` and `run_range_pipeline` keep their signatures and pass in the process-wide controller. Production behaviour does not change.
- The test gives each form its own controller, pinned at 4000. That is the floor `mixed_windows` uses to pick its windows, so the windows are mixed at the floor the test runs at. At 4000 the three fields have 3 155, 17 439 and 922 descriptors, many more than at the default floor, so the comparison covers more ranges.
- The test also asserts that both forms report that floor and that each field had descriptors, so the equality check can't pass on two empty lists.
- Everything else in the test is unchanged: push order, the open/close order, two fields open at once, and descriptor equality, now at one fixed floor. The doc comment explains why the floor is pinned.

Pinning with `NICE_GPU_MSD_FLOOR` would not work in a test. The variable is read once, when the global controller is first created, and it would pin every other test in the process too.

## Evidence

Run with `cargo test --release -p nice_common --features cuda --lib` on a 4-core x86-64 Linux host, under `nice -n 19`:

| | runs | failed |
|---|---|---|
| before, full lib suite, `--test-threads 8` | 20 | 1 (same assertion and same left/right descriptors as CI; floor `250000 → 294606`, cpu waited 71%) |
| after, full lib suite, `--test-threads 8` | 30 | 0 |
| after, the test alone | 40 | 0 |

To make the original failure happen on demand, I added a throwaway test (not in this PR). It runs the same equality check while a second thread keeps stepping the process-wide floor up and down:

| | runs | failed |
|---|---|---|
| shared controller (what the test did before) | 5 | 3 (`field 0: 96 vs 88 ranges`, `field 1: 488 vs 459`, `field 2: 27 vs 49`) |
| pinned controllers (this PR) | 5 | 0, with 37–50 floor steps during each check |

`cargo fmt --all --check` and `cargo clippy -p nice_common --all-targets --features cuda -- -D warnings` are clean. The module only compiles under `cuda` or `cubecl`. I did not run the `--features gpu` clippy locally (it also builds cubecl); CI's lint job covers it.

No CHANGELOG entry, since this only fixes a test.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
