# L2 PR: detailed mode by finite differences, branch + protocol (2026-10-30)

Branch `pr/detailed-finite-diff` on `fork` (wasabipesto-bot/nice), one commit on
upstream main d1ff798: **7019653** "Detailed mode: digit arrays by finite
differences instead of division". The box measured **045797e**; 045797e → 7019653
changes comments only (module doc wording, one private intra-doc link), verified by
`git diff 045797e 7019653` having no non-comment lines. PR body: `PR-BODY.md`
(not opened). Raw logs: `pr-raw/`.

## What changed from the prototype (rp/l2-finite-diff, b003967 + da9aaeb)

- Scalar (digit-serial) variant removed: `add_digits`, `ripple`, the byte-wise
  `add_assign`/`add_small` and the `SWAR` const parameter are gone; the word-parallel
  adds are now `add_assign`/`add_small`. No test needed the scalar path.
- Dispatch: `fd_kernel(base) -> Option<fn(&FieldSize) -> FieldResults>` (private)
  holds the base match (40, 42–45, 47–50, 52–55, 57–60, 62, 64, i.e. the bases
  `get_num_unique_digits` specialises); `pub fn process_range_detailed_fd` calls it
  or falls back to `process_range_detailed`. One place, in common.
- Client: `client/src/main.rs` CPU chunk path in `process_field_sync` calls
  `process_range_detailed_fd` (the only client change, plus the import). Fields,
  `--validate` and `--benchmark` all go through `process_field_sync`.
  `process_range_detailed` is untouched (reference for tests, GPU small-range
  fallback, WASM client).
- Tests: the prototype's exactness tests kept (single variant now); the
  small-base full-range test trimmed to bases 10–24 (the 25–29 calls were already
  skipped by its 5 M size guard) and asserts exactly 27 near-misses; new
  `dispatch_uses_finite_differences_where_supported` (b40, b50 → new loop; every
  base 40–64 with a range except 63 → new loop; b10 → division, equal results);
  `fd_timing` (ignored) simplified to division vs finite differences, env knobs
  dropped.
- Module doc rewritten (scheme in one paragraph), comments on the branch-free carry
  (`add_word`, `add_assign`, `fix_len`), CHANGELOG one sentence.
- Diff vs main: 4 files, +556 −2 (`common/src/detailed_fd.rs` 551 lines, of which
  lines 313–551 are tests).

Lint/test on ivory: `cargo fmt --all` clean; `cargo clippy -p nice_common -p
nice_client --all-targets -- -D warnings` clean (default features; the CI's gpu +
cubecl-spirv clippy pass was not run here, but the only client change is the
CPU-path call and an import that has no GPU-gated use); debug
`cargo test -p nice_common --lib detailed_fd`: 11 passed, 1 ignored, 13.5 s.

## Box

Vast instance 58350466 `nice-research-l2-cpu` (RTX 3080, unused), `ssh -p 39252 root@ssh1.vast.ai`.
`pr-raw/box-info.txt`:

- Intel Xeon E5-2682 v4 @ 2.50 GHz (Broadwell-EP), 2 sockets × 16 cores × 2 HT = 64 logical CPUs, 2 NUMA nodes, 125 GB RAM, Ubuntu 24.04.
- `nproc` = 64, but cgroup `cpu.max` = `1536000 100000` → **15.36 CPUs** quota.
  The client's own `available_parallelism` (used by `--threads 0`, and reported as
  `cpu_threads_available`) = **15**.
- Clocks: governor schedutil, `scaling_max_freq` 3000000 (= max turbo), `intel_pstate/no_turbo` 0 → **no cap**. Idle cores sit at 1.2 GHz; busy cores sampled at 2.9–3.0 GHz (`pr-raw/clock.log`, every 15 s through the protocol).
- Host load from other tenants: load average 3–5 before the runs.
- Rust 1.99.1 (repo pin), release profile, default features.

**Thread count.** The brief said `--threads <nproc>`; nproc = 64 is four times the
CPU quota. I ran the protocol at **15** (= quota, = what `--threads 0` gives) as
the primary, and repeated the full A B A B A B at **64** as well. Throttling,
from `cpu.stat` in `clock.log`:

| phase | nr_throttled | throttled_usec |
|---|---|---|
| t15, 6 runs (04:58:58–05:13:10) | 68 → 88 | 2,259,191 → 2,266,766 (7.6 ms) |
| t64, 6 runs (05:13:10–05:27:40) | 88 → 5377 | 2,266,766 → 22,090,863,294 (≈22,089 s summed over threads) |
| t1, 2 runs | 5377 → 5377 | unchanged |

## Commands

### Branch (ivory)

```sh
cd /home/claude/projects/nice && git fetch -q origin main && git fetch -q fork
git worktree add .worktrees/pr-detailed-fd origin/main -b pr/detailed-finite-diff
cd .worktrees/pr-detailed-fd
git cherry-pick b003967 da9aaeb        # prototype, then reworked (see "What changed" above)
cargo fmt --all
nice -n 19 cargo clippy -p nice_common -p nice_client --all-targets -j 3 -- -D warnings   # clean
nice -n 19 cargo test -p nice_common -j 3 --lib detailed_fd -- --test-threads 3          # debug: 11 passed, 1 ignored, 13.5 s
git reset --soft origin/main && git commit      # one commit
git push -u fork pr/detailed-finite-diff
# measured as 045797e; then comment-only edits, git commit --amend, re-ran clippy + module tests,
git push --force-with-lease=pr/detailed-finite-diff:045797e fork pr/detailed-finite-diff   # 7019653
```

### Box

```sh
python3 scratchpad/2026-10-research-program/vast.py list    # 58350466 nice-research-l2-cpu
ssh -p 39252 root@ssh1.vast.ai
source ~/.cargo/env; cd /root/nice
git fetch https://github.com/wasabipesto/nice.git main      # d1ff798
git worktree add /root/main d1ff798
git fetch origin pr/detailed-finite-diff && git worktree add /root/pr FETCH_HEAD   # 045797e
(cd /root/main && cargo build --release -p nice_client)     # 2m28s
(cd /root/pr   && cargo build --release -p nice_client)     # 2m15s
/root/run_protocol.sh     # pr-raw/run_protocol.sh: A B A B A B at --threads 15, then at 64, then --threads 1 once each
# each run:
/root/<tree>/target/release/nice_client detailed --benchmark --benchmark-secs 150 --threads <T> --benchmark-json
/root/run_tests.sh        # pr-raw/run_tests.sh, on /root/pr (045797e):
cargo test --release -p nice_common --no-fail-fast                                  # 2m00s incl. build
taskset -c 2 cargo test --release -p nice_common --lib detailed_fd::tests::fd_timing -- --ignored --nocapture --test-threads 1   # twice
python3 pr-raw/summarize.py > pr-raw/summary.txt    # locally, from the copied JSON
```

Each benchmark JSON (`pr-raw/t{15,64}-r{1,2,3}-{A,B}.json`, `pr-raw/t1-{A,B}.json`)
carries `build_sha` (A d1ff798, B 045797e), per-scenario rate, window, repetitions,
timed seconds, warm-up; stderr in the `.err` files. Each scenario got 50 s of the
150 s budget (45 s timed). Windows: multi-thread scenarios 2 M × threads (30 M at
15, 128 M at 64), `b50_detailed_1t` 1 M.

## Results

Rates in M numbers/s, spread = (min/median − 1, max/median − 1).


### --threads 15: 3 rounds

A = d1ff798, B = 045797e

| scenario | threads | A rounds (M/s) | A median | A spread | B rounds (M/s) | B median | B spread | B/A |
|---|---|---|---|---|---|---|---|---|
| b40_detailed | 15 | 51.49 52.02 51.55 | 51.55 | -0.1/+0.9 % | 287.95 287.38 291.51 | 287.95 | -0.2/+1.2 % | **5.59x** |
| b50_detailed | 15 | 33.84 33.71 33.80 | 33.80 | -0.3/+0.1 % | 272.39 271.04 271.09 | 271.09 | -0.0/+0.5 % | **8.02x** |
| b50_detailed_1t | 1 | 2.22 2.24 2.21 | 2.22 | -0.8/+0.6 % | 15.24 15.19 15.23 | 15.23 | -0.2/+0.1 % | **6.85x** |
| score |  | 1247 1252 1244 | 1247 | -0.3/+0.4 % | 8424 8396 8444 | 8424 | -0.3/+0.2 % | **6.76x** |

  A b40_detailed: threads 15, window 30000000, repetitions 78 (last round), timed 45.4 s
  B b40_detailed: threads 15, window 30000000, repetitions 438 (last round), timed 45.1 s
  A b50_detailed: threads 15, window 30000000, repetitions 51 (last round), timed 45.3 s
  B b50_detailed: threads 15, window 30000000, repetitions 407 (last round), timed 45.0 s
  A b50_detailed_1t: threads 1, window 1000000, repetitions 100 (last round), timed 45.3 s
  B b50_detailed_1t: threads 1, window 1000000, repetitions 686 (last round), timed 45.0 s

### --threads 64: 3 rounds

A = d1ff798, B = 045797e

| scenario | threads | A rounds (M/s) | A median | A spread | B rounds (M/s) | B median | B spread | B/A |
|---|---|---|---|---|---|---|---|---|
| b40_detailed | 64 | 41.95 42.98 41.40 | 41.95 | -1.3/+2.4 % | 129.81 130.09 129.91 | 129.91 | -0.1/+0.1 % | **3.10x** |
| b50_detailed | 64 | 24.39 24.28 24.34 | 24.34 | -0.3/+0.2 % | 126.46 125.15 125.45 | 125.45 | -0.2/+0.8 % | **5.15x** |
| b50_detailed_1t | 1 | 2.21 2.21 2.24 | 2.21 | -0.3/+1.0 % | 15.30 15.35 15.18 | 15.30 | -0.8/+0.3 % | **6.91x** |
| score |  | 1042 1048 1041 | 1042 | -0.2/+0.6 % | 5009 5000 4983 | 5000 | -0.3/+0.2 % | **4.80x** |

  A b40_detailed: threads 64, window 128000000, repetitions 15 (last round), timed 46.4 s
  B b40_detailed: threads 64, window 128000000, repetitions 46 (last round), timed 45.3 s
  A b50_detailed: threads 64, window 128000000, repetitions 9 (last round), timed 47.3 s
  B b50_detailed: threads 64, window 128000000, repetitions 45 (last round), timed 45.9 s
  A b50_detailed_1t: threads 1, window 1000000, repetitions 101 (last round), timed 45.2 s
  B b50_detailed_1t: threads 1, window 1000000, repetitions 684 (last round), timed 45.1 s

### --threads 1: 1 rounds

A = d1ff798, B = 045797e

| scenario | threads | A rounds (M/s) | A median | A spread | B rounds (M/s) | B median | B spread | B/A |
|---|---|---|---|---|---|---|---|---|
| b40_detailed | 1 | 3.56 | 3.56 | +0.0/+0.0 % | 19.82 | 19.82 | +0.0/+0.0 % | **5.57x** |
| b50_detailed | 1 | 2.29 | 2.29 | +0.0/+0.0 % | 18.60 | 18.60 | +0.0/+0.0 % | **8.12x** |
| b50_detailed_1t | 1 | 2.23 | 2.23 | +0.0/+0.0 % | 15.18 | 15.18 | +0.0/+0.0 % | **6.80x** |
| score |  | 209 | 209 | +0.0/+0.0 % | 1409 | 1409 | +0.0/+0.0 % | **6.75x** |

  A b40_detailed: threads 1, window 2000000, repetitions 81 (last round), timed 45.5 s
  B b40_detailed: threads 1, window 2000000, repetitions 446 (last round), timed 45.0 s
  A b50_detailed: threads 1, window 2000000, repetitions 52 (last round), timed 45.4 s
  B b50_detailed: threads 1, window 2000000, repetitions 419 (last round), timed 45.1 s
  A b50_detailed_1t: threads 1, window 1000000, repetitions 101 (last round), timed 45.3 s
  B b50_detailed_1t: threads 1, window 1000000, repetitions 684 (last round), timed 45.0 s

Merge bar (no scenario regresses > 2 %): met at every thread count; every
scenario is 3.1–8.1× faster.

### Per number (`fd_timing`, pinned to CPU 2, 1 M numbers at each base's range start, 3 interleaved rounds, ns/number)

```
TIMING b40: division [287.13 281.74 277.09] med 281.74 | finite differences [52.14 50.20 50.21] med 50.21 | 5.61x
TIMING b50: division [430.60 434.41 432.00] med 432.00 | finite differences [56.97 58.55 56.74] med 56.97 | 7.58x
TIMING b60: division [550.75 550.42 561.72] med 550.75 | finite differences [56.99 57.23 57.26] med 57.23 | 9.62x
TIMING b40: division [279.48 280.89 275.96] med 279.48 | finite differences [50.10 52.46 50.53] med 50.53 | 5.53x
TIMING b50: division [440.73 432.84 438.66] med 438.66 | finite differences [57.30 56.90 58.03] med 57.30 | 7.65x
TIMING b60: division [557.18 569.34 571.11] med 569.34 | finite differences [59.34 58.95 59.50] med 59.34 | 9.59x
```

Round spreads within −2.1/+3.8 % of the medians. Compared with ivory's Zen 2
(prototype, fd-words): b40 6.2–6.3×, b50 8.5–8.6×, b60 10.1–10.8×; on this
Broadwell 5.5–5.6×, 7.6–7.7×, 9.6×. Absolute: division 280/435/560 ns here vs
265/416/540 on ivory; finite differences 50/57/58 here vs 42/48/50.

### Notes

- `b50_detailed_1t` vs pinned timing of the same window: B 65.7 ns/number in the
  scenario vs 57.1 pinned; A 450 vs 435. So the scenario costs 9–15 ms more per
  1 M-number repetition than the loop alone, on both trees (it builds a fresh
  one-thread rayon pool per window; I did not verify that this is the cost). This
  is why the 1t ratio (6.85×) sits below both the pinned ratio (7.6×) and
  b50_detailed at `--threads 1` (8.12×, 2 M window). Not this PR's concern.
- At `--threads 15`, b50_detailed scales 17.8× its 1-thread `b50_detailed_1t`
  rate on B and 15.2× on A; b50_detailed at `--threads 1` (2 M window) is 18.60
  (B) / 2.29 (A), so per-thread scaling at 15 threads is 14.6× (B) and 14.8× (A)
  of that: about the same scaling for both loops at the quota.
- At 64 threads, both trees lose (A b40 −19 %, B b40 −55 % vs 15 threads): the
  cgroup throttles throughout and the threads run two to a physical core. The
  higher-IPC new loop loses more (hypothesis: less to gain from SMT; not measured
  with counters here, no perf on the box).

## Tests on the box (045797e)

`pr-raw/test-pr-common.log`: lib **180 passed, 0 failed, 5 ignored** in 4.88 s
(release, 64 visible CPUs); the 3 DB integration test files have 0 tests at default
features; doc-tests 0. The 5 ignored: 3 `cpu_join` opt-in, `overlap_join::cert_is_sound_on_real_tops`
(minutes), and `fd_timing` (run separately above, both passes exit 0, which
includes its `FieldResults` equality assert on every timed window).

## Not done

- The CI's GPU-feature clippy pass (`--features nice_client/gpu,nice_client/cubecl-spirv`) and the browser/WASM build were not run (no code they compile changed beyond the client's CPU branch and an import).
- PR head 7019653 was not rebuilt on the box (comment-only diff from the measured 045797e).
- The 1t per-repetition overhead cause is not verified.
