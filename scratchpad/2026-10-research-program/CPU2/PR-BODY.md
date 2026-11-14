## What

The CPU overlap join tests every top-layer prefix's block in every partition. A prefix's blocks in consecutive partitions are consecutive blocks, so a test that fails on two equal certified digits keeps failing until one of them can change. Now a failing test says for how many partitions, and a thread running a join's partitions in ascending order skips the prefix until then.

- `TopFdSetup::cert` returns `Err(n)`: this block and the prefix's next `n − 1` fail (`run`, `run_of`).
- `CpuJoin::run` keeps per prefix the first partition whose block can pass (`Scratch::next`) and skips the prefix before it. The state carries over only to a later partition of the same join (`Scratch::enter`); anything else clears it. Runs are worked out only while a thread's partitions are at most 8 apart.
- The FD state walks up to 12 steps before seeding (was 4): skipped prefixes leave longer gaps.
- The client keeps one join scratch per worker thread, not per rayon job (rayon splits down to single partitions, but each thread runs its own mostly ascending), freed when the field's join ends.

No GPU code path changes.

## Why

The top phase was 45 % of a b62 1e17 partition, 39 % at b60 1e16, 19 % at b64 1e17 (1 thread); two thirds of its tests fail.

## Why it is exact

Proof in `cpu_top_fd`'s module docs. If certified positions `(j, i)` and `(j', i')` of a failing test hold equal digits, put `X = ⌊a^j/b^i⌋`: every later block with `e'^j < (X + 1)·b^i` (and likewise for `j'`) certifies both positions again with the same digits, and fails. The count of such blocks is a lower bound (mean value theorem; f64 with relative margins of 2^-40). Certificate and run take the first certified position from one helper. Only failing blocks are skipped; the tops and everything after them are unchanged.

## Exactness evidence

- `a_failing_run_fails_at_every_block`: bases 7–64, random fields: every block inside a computed run re-certified by `Base::cert_parts` fails (one full run: 142 M blocks).
- `the_skip_walk_finds_every_top_on_small_bases` (268 field shapes) and `…_on_production_fields` (b57–b64): tops identical to certifying every block.
- New, `the_carried_state_survives_any_order_of_joins_and_partitions`: joins interleaved on shared thread scratches, out of order, with retries, steps back and gaps; tops and `run_partition` against no carried state. It fails on three mutants of the carry rule (never reset, carry backwards, ignore the join id) that the ascending tests miss.
- Outside this PR: the run bound against big-integer arithmetic on 9 M adversarial cases (never above the exact run); main against this branch under disorderly schedules on 567 joins at b10–b34 and 50 production-shape fields at b44–b64: identical tops, survivors, checked counts and hits.
- Every timed run below: identical survivors, checked counts and hits.

## Measurements

The real `nice_client` (release, CPU only), main against this branch, on a rented 2× Xeon E5-2696 v4 container with a 42-CPU quota (`--threads 0` = 42), fed one field by a local stand-in for the claim API; a measurement-only hook (identical in both) restricts slices or partitions and prints the join's run time (timed; setup excluded) and memory. Interleaved, order alternating per round; medians.

| work | threads | main, s (rounds) | this PR, s (rounds) | speed-up | per round |
|---|---|---|---|---|---|
| **b62 1e17**, slice 0 of 7, all 3844 partitions | 42 | **204.4** (205.4, 204.4, 204.1) | **185.0** (184.7, 185.7, 185.0) | **×1.105** | 1.112, 1.101, 1.103 |
| **b60 1e16**, whole field, 3600 partitions | 42 | **207.2** (207.3, 207.2, 207.2) | **191.7** (191.7, 192.0, 191.4) | **×1.081** | 1.081, 1.079, 1.082 |
| b62 1e17, slice 0, partitions 0–1023 | 8 | **241.3** (249.8, 240.0, 241.3) | **213.5** (214.6, 213.5, 210.1) | **×1.130** | 1.164, 1.124, 1.148 |
| b60 1e16, partitions 0–1023 | 8 | **262.1** (261.8, 264.2, 262.1) | **237.5** (237.5, 237.2, 238.4) | **×1.104** | 1.102, 1.114, 1.099 |
| b64 1e17, slice 0 of 6, all 4096 partitions | 42 | 816.6 (1 round) | 806.3 | ×1.013 | |

Spreads 0.0–0.7 % (42 threads), 0.5–4.0 % (8). Field starts: 4473066762334864396992 (b62), 1157209632114824200908 (b60), 71779931862957161709568 (b64).

A one-thread harness (EPYC-Rome VM, 32 contiguous partitions of these slices) measured ×1.140 (b62), ×1.132 (b60), ×1.009 (b64); why the client keeps less at 42 threads I did not investigate.

**b64 gains nothing**: its top phase is 19 %, and what the skip leaves of it is stepping and seeding.

## Memory

Each worker thread holds 2 bytes per top-layer prefix while a join runs: 10.8 MB at b62 1e17, 8.6 MB at b60 1e16, at most 32 MiB. Peak resident memory:

| work | threads | main | this PR |
|---|---|---|---|
| b62 1e17 slice 0 | 42 | 360 MiB | 706 MiB |
| b60 1e16 | 42 | 382–389 MiB | 745 MiB |
| b64 1e17 slice 0 | 42 | 374 MiB | 743 MiB |
| b62 / b60, 1024 partitions | 8 | 229 / 243 MiB | 262 / 275 MiB |

About +350 MiB at 42 threads, freed when the join ends: resident just after, 196 MiB against main's 242 MiB (b62), and 577 MiB without the free.

## NiceMark

CPU nice-only, all 42 threads, 150 s, 4 interleaved rounds (medians):

| | main | this PR | ratio | per round |
|---|---|---|---|---|
| score | 6094.5 | 6115.2 | ×1.003 | 0.997, 1.004, 1.010, 1.003 |
| b58_msd_weak | 2.284e13 | 2.268e13 | ×0.993 | 0.973, 0.992, 1.022, 0.992 |
| b58_msd_weak_1t | 7.349e11 | 7.352e11 | ×1.000 | 0.997, 1.010, 0.999, 0.999 |
| b58_msd_strong | 1.304e14 | 1.313e14 | ×1.007 | 1.004, 1.000, 1.013, 1.008 |
| b60_msd_weak | 5.567e13 | 5.654e13 | ×1.016 | 1.012, 1.014, 1.017, 1.020 |
| b62_msd_weak | 6.050e13 | 6.039e13 | ×0.998 | 1.000, 1.004, 0.999, 0.994 |

No change, as expected: NiceMark runs partitions in bit-reversed order with a scratch per job, so nothing is skipped.

## Not in this PR

- Anything for b64; a power-of-two seed (bit unpacking instead of divisions) would help it and today's join alike.
- NiceMark scenarios that hand each worker contiguous partitions, which could show this change.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
