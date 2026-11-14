# CPU2 PR review: `pr/cpu-join-top-skip` (`3ba5766a`), the changes since `e0bf513e`, the measurements, the body

Reviewer: independent (not involved in writing the change), 2026-11-14, 18:46–19:30 UTC, on ivory, CPU
only, `nice -n 19`, at most two threads. Worktrees `.worktrees/review-cpu2-pr` (detached at `3ba5766a`;
the harness hooks were applied for one build, then reverted: clean) and `.worktrees/review-cpu2-pr-mut`
(mutants, reverted: clean); both removed at the end. Nothing was committed, pushed, opened or commented on.
My files: `CPU2/review-pr/` (harness adapter, outputs under `out/`, mutants under `mut/`).

## Verdict

**Open after two one-line body edits (B1, B2); no code change is required.** The changelog's `#NNN`
must be filled in once the PR has a number (B3), which is the normal flow.

- L1, M1, L2 and the changelog line are correct. The new helper (`first_certified`) gives exactly what both
  older copies gave, for every input. On the final tree, this morning's harness gives byte-identical
  output to main's (the big-integer run-bound check, and main against the branch on small bases,
  production shapes and the hunted fields).
- **M1, the question you most wanted answered: no.** A worker thread cannot run the broadcast closure
  (`JOIN_SCRATCH.take()`) while it holds that thread-local's `RefCell` borrow, and nothing can clear a
  scratch in the middle of a partition. Reasons and a demonstration are below. If it ever did happen, the
  result would be a panic ("already borrowed"), or an abort if the process was already unwinding. It
  would never be a wrong result.
- **The bar.** The evidence meets ×1.10 at exactly one point: b62 1e17, slice 0 of 7, ×1.105. That is
  three tight rounds (1.101–1.112) on one machine. b60 1e16 (a whole field) gains ×1.081, which is
  below the bar. b64 gains ×1.013, which is nothing. NiceMark's lowest scenario is ×0.993 (bar ×0.98:
  met). So the change is **borderline against the ×1.10 bar, not clearly over it**. The body reports
  all of this honestly, and whether that is enough is the maintainer's call. In exchange the client
  holds about 8.5 MB more per worker thread while a join runs (+350 MiB peak at 42 threads), and frees
  it afterwards.

## Findings

No high or medium findings.

### B1 (low, body): the mutant sentence claims more than was run

`PR-BODY.md` line 24: "It fails on three mutants of the carry rule … that the ascending tests miss." The
author ran only one ascending test against those three mutants
(`the_skip_walk_finds_every_top_on_small_bases`; `raw-pr/box/tests-mutant-*.txt`). I made two more mutants
(below). Both fail the new test and pass `…_on_small_bases`, `…_on_production_fields`,
`…_on_the_timed_shapes`, `a_field_in_slices_finds_what_it_finds_whole` and
`cpu_join_agrees_with_the_stride_path_on_whole_windows`. Replacement sentence:

> It fails on five mutants of the carry rule (never reset; carry to any earlier partition, or to the one just before; ignore the join id, or match joins by their prefix count) that `the_skip_walk_finds_every_top_on_small_bases` passes.

### B2 (low, body): one memory figure is not the median

`PR-BODY.md` line 55, row "b62 / b60, 1024 partitions": "262 / 275 MiB". The branch's b62 peaks were
262, 261 and 261 (`raw-pr/ab-summary.txt`), so the median is 261. The other memory figures match.
Replacement cell: `261 / 275 MiB`.

### B3 (process): the changelog's PR number

`CHANGELOG.md:5` links `#NNN`, so it needs a follow-up commit once the PR exists. Otherwise the line is
accurate, one sentence and user-facing.

### I1 (informational, doc): `FreeJoinScratch`'s doc says fields run outside any pool

`client/src/main.rs:877-880`: "fields are processed on a blocking thread outside it". That is true for
the claim loop. NiceMark's `run_window` (`client/src/bench.rs:756-763`), though, calls
`process_field_sync` inside a one-thread pool's `install`. That path reaches `process_field_join` if a
window passes `slices_for`. If it does, the partitions and the broadcast both go to that one-thread pool
(`rayon::broadcast` uses the current pool), so behaviour is right either way. `PR-RESULTS.md` §2's "NiceMark
does not call `process_field_join`" holds for its join scenarios, which use `bench.rs`'s own `map_init`
loop. It is not structurally true of the window scenarios. No change needed. If the doc is touched, it
could say "the pool the caller is in (the client's global pool, or NiceMark's one-thread pool)".

### I2 (cosmetic)

The guard's doc breaks a line in mid-sentence (`main.rs:875-877`, "…production shapes) are held only /
while a field's join runs…"). The re-wrapped module-doc line `cpu_top_fd.rs:40` is about 100 columns.
`cargo fmt --check` passes, so these are optional.

### Process item for the director (not about the PR)

`PR-RESULTS.md` §8 records that the author's NiceMark runs sent 80 `GET /ping` to the production API.
The author reported it. The body does not mention it, and should not.

## Answers to the brief's questions

### 1. Same tree, one commit, main unmoved

`fork/pr/cpu-join-top-skip` = `3ba5766a` and `fork/exp/cpu-top-skip-fixes` = `e2fe1f5a` have the same tree,
**`e953808b99608561c56856a7eb4147b00fb4758e`**. `git log origin/main..3ba5766a` is the one commit, and its
merge base is `41b4b405`. After `git fetch origin`, `origin/main` is still `41b4b405`: main has not moved. The PR
diff against main touches `CHANGELOG.md`, `client/src/main.rs`, `common/src/cpu_join.rs` and
`common/src/cpu_top_fd.rs` only.

### 2. L1 (`4ae3a956`): `first_certified`

`common/src/cpu_top_fd.rs:611-628`. It is used by `cert` (`:647-650`) and by `run`'s `failed == 0` branch (`:686-689`).

- **Against `cert`'s old copy.** The old code did `c0 >= sp → continue` with `from[jj]` left at its
  initial value. That initial value is `self.s2`/`self.s3`, which is exactly the `sp` of that power, and
  `doms[jj]` was left at 0. The new helper returns `(sp, 0)`, and the scan loop `while pos < sp` then does
  nothing. Without a carry, both give `(c0, 0)`. With a carry, both skip `b − 1` digits through the same
  closure `at`, then take `g = at(pos)`, `dom = digit_range_mask(g, g+1)` and `from = pos + 1`. `top` is
  the same `(b − 1) as u8`. Nothing else in `cert` changed. The early return on a repeat, the closure, the
  `Cert` fields and `Err(1)` without `runs` are textually the same apart from the helper call. So the set
  of passing tops cannot change.
- **Against `run`'s old copy.** The old code was `from[1] = sp`; if `c0 < sp`, then `pos = c0`, and with a
  carry it ran `while pos >= z && digit(x, pos − z) == top { pos += 1 }; pos += 1`. For `pos < z`,
  `at(pos)` is 0 and `top = b − 1 >= 1`, so `at(pos) == top` is false exactly when `pos >= z` is false
  there. The two loops stop at the same position, and both return `pos + 1`. A zero top digit falls into
  the same case (`0 != top`). The only difference is that `run` now discards the mask.
- `carry` and `ndig` are called with the same arguments as before, and `Scratch::enter` is the old
  inline rule moved as is (`cpu_join.rs:173-185` against the deleted lines of `run`).
- **Re-run on the final tree** (`3ba5766a` plus the morning's harness modules, attached by `#[path]`; the
  branch adapter now calls `Scratch::enter` itself instead of a copy of the rule:
  `review-pr/cmp_final.rs`). These ran on one release test binary (`review-pr/bin/test-final`), at most
  two at a time:
  - Big-integer check of the run bound (`review_exact_run_bound_and_adversarial_runs`, bases 7–64, 40
    trials): **7,980 setups, 29.9 M `run_of` evaluations, 8.97 M at certified positions, 0 above the exact
    run, 6.74 M equal to it; 7.37 M failing certificates; 657 M later blocks inside runs re-certified by
    `cert_parts`, all failing.** The output is identical, line for line, to this morning's on
    `e0bf513e` (`review-pr/out/exact-7-64.txt`).
  - Main against the branch under disorderly schedules (`review_cmp_small`, `…_production`,
    `…_production_hunt`; same seeds, defaults, window 12). Final-tree sha256 values:
    small `69cc1ac8…`, production `8090f0e9…`, hunt `d8c5af03…`. **All three equal main's outputs**
    (`review/out/SHA256SUMS`; main `41b4b405` is unchanged since they were made). To confirm that the
    stored main output is reproducible, I re-ran main's small comparison with this morning's main binary:
    `69cc1ac8…` again. This covers 567 joins and 276,077 partition events at b10–b34; 37 production-shape
    fields at b44–b64 (3,132 events, 774 M skip-eligible entries); and 13 hunted fields with tops at
    b58–b64 (1e15 and 1e17; 1,017 events, 470 M skip-eligible entries). The emulated partition and skip
    counts equal this morning's.
  - **The body's "Outside this PR" bullet is supported on the final tree as written:** "9 M adversarial
    cases (never above the exact run)" (8.97 M), "567 joins at b10–b34", "50 production-shape fields at
    b44–b64" (37 + 13), and "identical tops, survivors, checked counts and hits". Two caveats belong in the
    review, not necessarily in the body. The production comparisons cover windows of partitions (start,
    middle and end of the first and last slices), not whole fields. And no compared field holds a nice
    number, so "identical hits" is vacuous: the tops hashes and the survivor and checked counts carry the
    claim.

### 3. M1 (`92960cd1`): `FreeJoinScratch`

`client/src/main.rs:863-887` (thread-local and guard), `:906` (`let _free`), `:931-941` (partitions).
Rayon sources read: `rayon-core-1.13.0` (the version in `Cargo.lock`), `src/broadcast/mod.rs`,
`src/registry.rs`, `src/latch.rs`.

- **Which pool.** The claim loop runs fields through `begin_field` → `spawn_blocking` →
  `process_field_sync` → `process_field_join`, on a tokio blocking thread, which is not a rayon worker. So
  `into_par_iter` injects into the global pool (built by `build_global` in `main`). `rayon::broadcast`
  calls `broadcast_in(op, &Registry::current())`, and from a non-worker thread that is the same global
  registry. It queues one job on each worker's broadcast queue and waits on a blocking `CountLatch`. In
  NiceMark's single-thread window path the caller is the one-thread pool's worker. Then the partitions
  and the broadcast both use that pool, and the caller runs its own broadcast job in `wait_until`. It
  holds no borrow at that point (`Drop` runs in `process_field_join`'s frame, never inside a partition).
  No deadlock is possible in either case. Every pool thread gets its broadcast job as soon as it is idle,
  and after the `reduce` returns no thread is waiting on anything the caller holds.
- **Can a worker run `take()` while it holds the borrow?** A worker runs a broadcast job only when it looks
  for work. Broadcast jobs sit in a per-worker queue read by `take_local_job` (`registry.rs:749`). That is
  called only from the worker's main loop and from `wait_until_cold` (`:780`), and `wait_until` is reached
  only from inside a rayon call (`join`, `scope`, iterator splitting, `install`, latches). Under the
  borrow the thread runs only `join.run_partition(v, scratch)` (`main.rs:934`). That code is
  `nice_common`, which has **no rayon dependency** (`cargo tree -p nice_common -e normal` lists no rayon;
  the only threads in `common` are `run_all`'s `std::thread::scope`, which `run_partition` does not use).
  `progress.tick()` is outside the borrow. So a thread holding the borrow never yields to rayon, and it
  cannot steal the broadcast job, or another partition. **It cannot happen.**
  - Probe (`/tmp/claude-1000/…/scratchpad/bcast`, rayon 1.11 / rayon-core 1.13, a two-thread pool, two
    CPUs): the client's pattern with 3 OS threads ending 900 "fields" concurrently on one pool ran with
    no panic. The same code with one `rayon::join` under the borrow panicked at once with "RefCell already
    borrowed", both from stolen partitions and once from the broadcast's `take()`. So the hazard is real
    only if someone later adds a rayon call inside `run_partition`. That would break the per-thread
    scratch itself, which `e0bf513e` already introduced, not only the guard. A one-line comment on
    `JOIN_SCRATCH` ("no rayon calls under this borrow") would protect it. That is optional.
- **Two fields' joins on one pool at once?** Not in the client today. `begin_field(...).await` is serial,
  `field_lookahead` is non-zero only for `cli.gpu && Niceonly && repeat`, and with `cli.gpu` set
  `process_field_sync` never reaches the CPU join (`main.rs:731`). NiceMark runs its scenarios one after
  another. Even if two joins did overlap, one field's `take()` reaches each thread only between
  partitions, because of the argument above. The other join's next partition on that thread then finds
  `last == None` and clears and rebuilds `next` (`cpu_join.rs:173-181`). That is the "first use" path,
  which is sound (the state is a fact about the join, keyed by its id). It costs only lost skips.
  **A clear in the middle of a partition is impossible.**
- **Exit paths.** There are three: a normal return (`:958`); the `CpuJoin::new` error `return None`
  (`:918`; it costs a broadcast before the stride walk, which is negligible); and a panic that unwinds from
  `reduce`. In the panic case, rayon's `join` waits for both halves before it resumes the panic, so no
  partition of this join is still running, and the panicking thread's `RefMut` was released while it
  unwound. A panic inside `Drop` while unwinding would abort the process. The only ways that could
  happen are `take()` finding the cell borrowed (impossible, as above) or allocation failure (an abort
  anyway). Also, a field panic already ends the client: `spawn_blocking(...).await.expect("Processing task panicked")`.
  The drop order is fine too: `_free` is declared after `tel`, `hits` and `field_progress`, so it drops first.
- **Effect, measured by the author.** RSS right after the join is 196 MiB with M1 and 577 MiB without it,
  at b62 with 42 threads (`raw-pr/box/r{1,2}-b62s0-42rev-*.err`). I checked the raw `MEASURE` lines.

### 4. L2 (`95ef18da`): the new test

`cpu_join.rs:1744-1907`. It does what it says. Several joins (two fields per base, up to two shapes
each, from 8 bases) share 3 thread scratches. Their partitions come in rayon-like chunks of 1–24
partitions dealt to random threads. Some chunks are reversed (steps back by one, many times over),
some partitions are retried (duplicated), some chunk starts repeat the previous partition, and gaps of
1–30 are cut out (251 events beyond `RUN_GAP`, 6,774 within it). Neighbouring chunks are swapped, and
the joins' queues are interleaved. Every event checks two things: the carried tops (through
`Scratch::enter`, the code `run` uses) against `all_tops`, and `run_partition` with the long-lived
scratch against a fresh one. Coverage is asserted.

My own mutants of `Scratch::enter` (`review-pr/mut/`, release, final tree; each run with the new test
and five older tests):

| mutant | change | new test | older tests (`…skip_walk…small_bases`, `…production_fields`, `…timed_shapes`, `a_field_in_slices…`, `…stride_path_on_whole_windows`) |
|---|---|---|---|
| `stepback1` | carries to the partition just before the last (`last <= v + 1`) | **FAILED** (b20 join 1 thread 0 partition 10: a passing top at p = 4410 skipped) | all ok |
| `lenid` | matches joins by prefix count instead of id (`self.next.len() == len`) | **FAILED** (b23 join 3 thread 0 partition 37: tops missing) | all ok |
| `retry` (control) | carries into a retry of the same partition (`last <= v`) | ok | all ok |

The control is expected to pass. Every entry `> v` that a retry of `v` meets was written at a partition
`<= v` from a failing certificate whose run covers `v`, so skipping on it is sound. This mutant is
equivalent, not missed. In the same way, `RUN_GAP` only decides whether runs are worked out (a run is a
fact about the join), so no mutant of it can be unsound and no test can be expected to catch one. The
test does exercise both sides of the edge. Together with the author's three (`reset`, `back`, `id`; I
read the diffs and logs), that makes five unsound mutants, all caught by the new test and all passed by the
ascending small-base test.

### 5. Measurements and body

- **Every number in the body was checked against the raw data.** I recomputed `ab-summary.txt`'s medians
  and ratios by hand from its per-run lines, and spot-checked those lines against the raw `.err`
  `MEASURE` lines and `time -v` (`r2-b62s0-42-{br,main}.err`: `run_secs` 185.70 and 204.38, peak 723196
  and 369764 kB, which are 706 and 361 MiB). The results:
  - b62 42 threads: 204.38/185.04 = ×1.105. b60 42: 207.20/191.65 = ×1.081. b62 8: ×1.130. b60 8: ×1.104.
    b64: 816.60/806.27 = ×1.013. The per-round ratios and the spreads match.
  - The claim files give the field starts: 4473066762334864396992 + 1e17, 1157209632114824200908 + 1e16,
    and 71779931862957161709568 + 1e17.
  - The counts are identical in every run.
  - NiceMark: I recomputed every median and per-round ratio from the 8 JSON files (`scenarios[].rate`,
    `score`), and they match the body exactly.
  - Memory: all figures match except B2. The per-thread arrays (5,392,026 and 4,308,426 prefixes) are from
    `raw/profile_b6{2,0}.txt`.
  - "45 % / 39 % / 19 %" and "two thirds fail" are from `RESULTS.md` §0/§1 ("pairs passing 0.32–0.36").
- **The hook** (`raw-pr/scripts/measure_hook.py`) does three things, each with an assert that its
  anchor occurs exactly once: it narrows `slices` by `NICE_MEASURE_SLICES`, it limits the
  `into_par_iter` range to `0..min(N, partitions)`, and it prints `VmRSS`/`VmHWM` and the join's
  telemetry after `process_field_join` returns, which is after the guard has run. The same script was
  applied to both trees, the field and the order are the same, and setup is excluded in both. The timed
  branch binary is `f317581a`. It differs from `3ba5766a` only inside `mod tests` (hunks at lines
  1832–1906) and in the changelog, so **the timed code is the commit's code**, and the comparison is fair.
- **What "slice 0 of 7" leaves unmeasured.** It leaves out b62's slices 1–6, whose top density can
  differ (this morning's review found many production fields with no tops at all). It also leaves out
  the other b60 and b62 fields, the whole b64 field, other CPUs (AVX-512, EPYC at full thread count),
  more than 42 threads, and every partition past 1023 in the 8-thread rows. The body labels each figure:
  "slice 0 of 7", "partitions 0–1023", and "1 round" for b64. b64 is stated ("b64 gains nothing"), the
  memory cost is stated (per thread, peak, and freed after), and "No GPU code path changes" is true.
  `TopFdSetup` and `CpuJoin` are `pub(crate)`/`common`-internal, and the only references in GPU files
  (`cubecl_join.rs`) are doc comments.
- **No mentions it must not make.** The body has no program directory, agent, reviewer file or model
  name. The footer is the standard tool attribution.

### 6. Anything else in `git diff e0bf513e e2fe1f5a`

I found nothing else. `Scratch::enter` is private and is reached only through `run` and the test. Its
docs describe the reset cases correctly. The `next` docs now state the memory per thread and that a
caller keeping a scratch per thread should drop it. `bench.rs` still uses `map_init` with a fresh
scratch per job, so it carries no state and needs no free.

## What I ran (all on ivory, release unless noted, final tree `3ba5766a`)

- `cargo fmt --all --check`: clean. `cargo clippy --workspace --all-targets -j 1 -- -D warnings` after
  touching the three changed sources: clean (nice_common recompiled; the only output is
  `nice-wasm-client`'s existing unused-`web-sys` manifest warning). Files: `review-pr/out/{fmt,clippy}.txt`.
- The whole `nice_common` lib suite, single-threaded, from the final-tree test binary, with my four
  review tests skipped: **202 passed, 0 failed, 8 ignored** (`review-pr/out/tests-final-full.txt`).
  `cargo test -p nice_client` (debug): 22 passed (`tests-client.txt`).
- The harness re-run above (exact check 3 min, small 1 min, production 30 min, hunt 14 min) and the
  mutants (3 builds plus the 6 tests each, about 3 min each).
- The rayon broadcast probe (`/tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad/bcast/src/main.rs`; `taskset -c 0,1`).

## What I could not verify

- I re-timed nothing. ivory has two threads, and the A/B is the author's single box. I checked the
  numbers against the raw logs, not by reproducing them.
- No whole production field, and no field with a nice number, went through both main and the branch. I
  did not run the opt-in production tests (`NICE_TEST_CPU_SKIP_PROD`, `NICE_TEST_CPU_JOIN_REF`).
- The client's RSS at 128 threads is unmeasured. Extrapolated from about 8.5–11 MB a thread, it is
  about +1.1–1.4 GB at the production shapes.
- Whether any NiceMark window scenario actually reaches `process_field_join` (I1). It is harmless either way.
