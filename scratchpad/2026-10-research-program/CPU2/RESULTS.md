# CPU2: fewer top tests in the CPU join by skipping failing runs (2026-11-14, ivory, CPU only)

Tags: **[M]** measured here, **[D]** derived from measured numbers, **[A]** assumed.

**Branches (fork, no PR):** `exp/cpu-top-skip` = `8f5fb0f6` + `d3630e30` (pushed 08:16 and 08:56 UTC, plain
pushes); **`exp/cpu-top-skip-squashed` = `e0bf513e`, the same tree as one commit on `41b4b405`** (the
reviewable form; I did not force-push). Formatted, `cargo clippy -p nice_common -p nice_client --all-targets
-- -D warnings` clean under 1.100.0, no CHANGELOG line. Timed: `d3630e30` (final, `new3`), `b86e4389` (the
first commit's `common/` code, `new2`), and a first version (`new`).

## 0. Answer

- **Top phase of the CPU join today** [M]: **45 % of a b62 1e17 partition, 39 % at b60 1e16, 19 % at b64
  1e17** (§1): far above the 8 % kill line. Inside it: seeding 5–9 %, stepping 6–16 %, certificates 9–21 % of
  the partition; the append is unmeasurably small.
- **Rule** (§2): a failing certificate's repeated pair `(j, i)`, `(j', i')` stays certified and equal for every
  later block whose `e^j < (⌊a^j/b^i⌋ + 1)·b^i` (both pairs); the first partition at which that can fail is
  bounded below in f64 with margins. Proved (§2), and tested: 1.4e8 blocks inside computed runs re-certified
  by `Base::cert_parts`, all failing; tops identical to the unskipped walk on 268 small-base field shapes
  exhaustively and on b57–b64 production-shape fields; the reference join on PLAN fields; counts identical in
  every timed run (§3, §5).
- **Gain on ivory** [M], 1 thread, contiguous partitions as a client thread runs them, 6 interleaved rounds,
  final code: **b60 1e16 ×1.132, b62 1e17 ×1.140 (every round ×1.130–1.145), b64 1e17 ×1.009 (rounds
  1.002–1.015)**; the earlier build `b86e4389`: ×1.127 / ×1.135 / ×1.005. Of that, `MAX_STEPS` 4 → 12 alone
  is ×1.015–1.02; spreads 1–3 %. In NiceMark's bit-reversed order the final code runs at the old speed
  (×1.02).
- **Kill criterion** ("gains less than ×1.05 on the whole field at b62 and at b64"): **b62 clears it with
  margin, b64 does not.** Read literally (kill only if both fail) it is not killed, so the branch is pushed;
  read as "must clear at each", b64 fails it. The director should decide; b64 is not helped (§5, §7).
  b60 (×1.13) also clears.
- **Two things a PR needs first** (§6): the client's rayon `map_init` scratch gave runs of 1–5 partitions
  at ≥ 8 threads, which would have made the change a *loss* there; the branch therefore keeps one scratch per
  worker thread in the client (probe: 91–99.9 % of a thread's partitions then follow a lower one) — that client
  path is not timed at production thread counts. And NiceMark's CPU join scenarios run partitions in
  bit-reversed order: the first commit made them ×0.80 at b62 (every partition paid the run analysis); the
  second works runs out only on dense walks, which measured ×1.02 there (no regression, and no skip gain:
  NiceMark cannot show this change).


## 1. Where the CPU join's time goes today [M]

Harness `raw/scripts/cpu2_prof.rs` + `raw/scripts/prof.rs` (scratch module inside `cpu_join`, not in the
branch; patch `raw/scripts/prof-scratch.patch`), on `41b4b405` (main). For each sampled partition: the whole
`run_partition` timed, then the partition's top phase alone in four modes: `tops()` as the join runs it;
`advance` only (seeds + steps, counted); `advance` + certificate (no `Top` built, nothing pushed); a seed at
every prefix (the seed's unit price). Seeding = seeds × unit price; stepping = advance − seeding;
certificate = (advance + cert) − advance; append = tops() − (advance + cert).

Sample: 3 fields per base at 10 %, 50 %, 90 % of the base range (b60 1e16, b62 1e17, b64 1e17); the first,
middle and last slice of each (b60 1e16 is one slice, b62 1e17 seven, b64 1e17 six); the first 3 partitions
of NiceMark's bit-reversed order (v = 0, 2048, 1024) in each. 1 thread per process, `nice -n 19`, two
processes at once (and for a few minutes my builds), so single values scatter by ±10 %; shares are ratios
inside one process. The b64 field at 50 % is empty (its field certificate fails: no tops at all), and so is
the last slice of the b64 field at 10 %.

| | b60 1e16 | **b62 1e17** | **b64 1e17** |
|---|---|---|---|
| partitions sampled (non-empty) | 9 | 27 | 15 (+9 of the empty field) |
| **top phase, share of the partition (time-weighted)** | **38.8 %** | **45.3 %** | **19.2 %** |
| range over partitions | 31.0–53.6 % | 40.4–51.2 % | 16.8–21.7 % |
| seeding / stepping / certificate / append | 5.5 / 15.1 / 19.6 / ≈0 | 8.9 / 16.2 / 21.4 / ≈0 | 5.0 / 6.1 / 8.6 / ≈0 |
| ns per top-layer prefix (one test) | 122–173 | 138–164 | 163–202 |
| one seed / one step / one certificate (ns) | ≈490 / ≈39 / 60–90 | ≈490 / ≈40 / 60–86 | ≈495 / ≈41 / 69–85 |
| steps / seeds per tested prefix | 1.39–1.40 / 0.017–0.080 | 1.31–1.40 / 0.042–0.080 | 1.32 / 0.085–0.095 |
| pairs passing | 0.32–0.36 | 0.32–0.33 | 0.31–0.32 |

(`raw/profile_b{60,62,64}.txt`, table `raw/profile_table.txt`, script `raw/scripts/profile_table.py`.) The
append is inside the noise (−5 to +2 %). **The top phase is far above the 8 % kill line at b62 and b64**, so
the work continues.

Structure (from the code, `cpu_join.rs` `run`/`tops`): the CPU join does **not** walk a prefix along the
partition axis. A partition is the unit of work; inside it, each key's top-layer prefixes are walked in
ascending order, `P = P0·b² + v` stepping by `h = b³` along the *prefix* axis (the FD state of `cpu_top_fd`).
Along that axis failures are independent (N6 §3, axis 2). The skip walk needs the partition axis, which is a
thread's sequence of partitions: the client runs `(0..partitions).into_par_iter()` (rayon splits contiguous
ascending ranges), so a thread that remembers, per prefix, the first partition at which it can pass again
gets the partition-axis skip without changing the loop order.

## 2. The skip rule, and why it is exact

**Setting.** A top test certifies the block `[a, e]`, `a = P·w`, `e = a + δ`, `w = b^f0`, `δ = w − 1`
(`Base::cert_parts(a, e, cap)`, `cap = k`); the CPU computes it from the FD digit arrays (`TopFdSetup::cert`,
already proved equal and tested). For each power `j ∈ {2, 3}` it reads the digits of `a^j` at positions
`from_j .. s_j` and fails on the first repeated digit (or, 2 % of failures, in the closure). Here
`c0_j = max(cap, ndig(e^j − a^j))` and `from_j = c0_j` without a carry, or the position above the d/d+1
digit with one. Equivalently **`from_j = max(c0_j, h_j)`**, `h_j` = the lowest position from which `a^j` and
`e^j` agree (no carry: they agree from `c0` up, so `h <= c0`; carry: they differ exactly on the run of `b − 1`
and the digit above it, so `h` is the position above that = `from`).

**Lemma.** Let a test fail on a repeat: certified positions `(j, i)` and `(j', i')` hold the same digit. Put
`X = ⌊a^j / b^i⌋` (= `⌊e^j / b^i⌋`, since `i >= from_j >= h_j`). Then **every** block `[a'', e'']` with
`a <= a'' <= e''` and `e''^j < (X + 1)·b^i`, and the same for `(j', i')`, fails too. Proof: `n ↦ n^j` is
increasing, so `X <= ⌊a''^j/b^i⌋ <= ⌊e''^j/b^i⌋ <= X`: the digits of `a''^j` from `i` up are `a^j`'s (so the
digit at `i` is the same), `a''^j` and `e''^j` agree from `i` up (`h'' <= i`), and `e''^j − a''^j < b^i` so
`ndig <= i` and `c0'' = max(cap, ndig) <= i` (`cap <= c0 <= from_j <= i`). Hence `i >= from''_j`: position
`i` is certified again, with the same digit; likewise `(j', i')`. The scan meets the repeat and returns
`None`. (Nothing about the closure or the scan order is used; a clipped block is such an interval too.)

**The run.** In the CPU join the blocks of one top-layer prefix in consecutive partitions are consecutive
blocks: `P = P0·b^p + v`, so partition `v + D` is `P + D`, `e(P + D) = e + D·w`. The first block that can pass
again is the smallest `D >= 1` with `(e + Dw)^j − e^j >= G`, `G = (X + 1)·b^i − e^j = b^i − (a^j mod b^i) −
(e^j − a^j) > 0`. Since `(e + Dw)^j − e^j <= j·(e + Dw)^(j−1)·Dw` (mean value theorem, `x^j` convex), for any
`S` every `D <= S` below `G / (j·(e + Sw)^(j−1)·w)` fails; with `S` = the partition count `b^p` (a run is never
asked about further) the run length `n = max(1, min(S, ⌈G / (j(e + Sw)^(j−1)w)⌉))` never exceeds the true one.
The code (`TopFdSetup::run_of`) evaluates it in f64 as a **lower bound only**: `(a^j mod b^i)/b^i` from the top
`m <= 4` digits of `a^j` below `i`, rounded up (`(r + 1)/b^m`, exact when fewer than 5 digits remain);
`(e^j − a^j)/b^i` from the exact binary `d_j` the FD state carries (relative error < 2^-50); `G/b^i` minus an
absolute margin 2^-40; `e + Sw` bounded by `(P + 1 + S)·w·(1 + 2^-40)`; the quotient times `(1 − 2^-40)`.
Every rounding is a few 2^-52 relative, far below the margins, so the computed `n` is `<=` the exact one; the
truncation to 4 digits costs at most `~b^-4` of a digit period (well under a partition at production shapes).
Of the repeated pairs it takes the first one met in a field-wide order of positions by how slowly they change
(`b^i / (j·a^(j−1)·w)`), which makes the faster digit of the pair as slow as possible; any repeated pair would
be exact, this only lengthens runs. A closure failure gives `n = 1` (no skip).

**In the join.** A thread keeps, per top-layer prefix, the first partition at which its block can pass
(`Scratch::next`, `u16`, saturating; a lower bound), set from the last failing test. It is read only for a
partition of the same join (a process-wide id per `CpuJoin`) that is later than the last one the thread ran:
then every partition in between, and the current one if below the entry, fails by the lemma, and the block is
neither stepped to nor certified. Any other order resets the entries to 0 (certify everything). Clipped blocks
(the slice's two end prefixes) are always certified and never set an entry. A skipped block is one today's test
fails, a passing block is never skipped, and the tops are pushed in the same order, so the tops, the join and
its counters are bit-identical.

## 3. Tests (first version of the code, best-pair runs, MAX_STEPS 4 then 12) [M]

`raw/tests-skip-full-v1.txt` (release, before the production test was trimmed to 600 partitions per field):

- `cpu_top_fd::a_failing_run_fails_at_every_block` (new): bases 7–64, 6 random fields per base (every block on
  the small ones, 300 random blocks on the large), `f0` 1.., `o` 1–2, span 1, b or b²: **334,914 failing blocks,
  142,224,583 blocks inside their runs each proved failing by `Base::cert_parts` (clipped or not), 0
  violations**; longest run 4,096 (the span cap), 127,054 runs of 1, 52,075 runs followed directly by a passing
  block (i.e. the bound is often tight).
- `cpu_join::the_skip_walk_finds_every_top_on_small_bases` (new): bases 10–36, up to three fields per band (whole
  band when small), every supported `(t, k, p)` with `p` 1–2 and at most 3e6 prefix-partitions: **268 field
  shapes, every partition in order, tops identical to certifying every block** (1,168,507 tops, 788,862 blocks
  not certified); 60 whole joins run partition by partition with one scratch vs a fresh scratch each: identical
  results.
- `cpu_join::the_skip_walk_finds_every_top_on_production_fields` (new): 1e14 fields at b57, b60, b62, b64
  (`PLAN_FIELDS`) and a third into the band at b57–b64 (b62's and b64's have no tops), **every partition in
  order and again with gaps (v mod 7 ≠ 3, v mod 11 ≠ 5): tops identical**; 0.60–0.64 of the layer's blocks
  not certified. (22 minutes; trimmed to the first 600 partitions for the branch.)
- `cpu_top_fd::stepped_certificates_equal_the_divided_ones` now compares `cert(..).ok()`.

## 4. Jumps, and what is left of the top phase [M]

The skip removes certificates, not steps: the FD state walks a key's prefixes along the prefix axis
(`h = b³`), so the steps between two certified prefixes are the same in number whether the prefixes between
them are certified or not. A skipped prefix's block is simply not visited; the next certified one is reached
by stepping (≈ 40 ns a step) or by a seed (≈ 490 ns, b60–b64 alike). A seed costs about 12 steps, and with
two thirds of the prefixes skipped the gaps grow (seeds went from 0.05 to 0.40 per certified prefix at
`MAX_STEPS` 4), so the reach before a seed was re-tuned (`raw/maxsteps-scan.txt`, top phase alone, ns per
top-layer prefix over 12 / 8 / 8 contiguous partitions, the first of them unskipped):

| MAX_STEPS | 4 | 8 | **12** | 16 | 24 | 32 |
|---|---|---|---|---|---|---|
| b62 1e17 s0 v0..12 | 129.1 | 113.3 | **108.2** | 110.3 | 112.3 | 113.8 |
| b64 1e17 (90 %) s0 v0..8 | 169.5 | 145.0 | **141.7** | 146.7 | | |
| b60 1e16 (50 %) v0..8 | 122.7 | 103.0 | **99.0** | 102.9 | | |

12 alone, without the skip, is worth ×1.015–1.02 (the `old12` binary below). A jump "by a multiply" (the
binomial update of the five digit arrays by `m` steps) needs four digit-array × scalar products; by count of
operations it would cost about two steps, so it would save at most ~1 step per certified prefix (estimated,
not built). At a power-of-two base the seed could be a bit unpack instead of divisions (b64: est. ≈ 100 ns
instead of 490): not built here, and it speeds up today's join too, so it is its own change (§7).

Steady state with the skip (b64 1e17 at 90 %, slice 0, partitions 1001–1007 after a full one; `cpu2_skipcount`):
of 4,997,077 top-layer prefixes a partition certifies 2.07 M (0.415; 1.575 M pass = 0.315) instead of all,
with 0.20 M seeds and 6.9 M steps; the top phase is ≈ 0.62 s instead of ≈ 0.87 s. Of the 0.62 s, steps are
≈ 0.28 s, seeds ≈ 0.10 s, certificates ≈ 0.16 s, the run analysis of the 0.5 M failing certificates ≈ 0.06
s. At b62 (s0, v0..24) the walk certifies 0.343 of the prefixes per partition in steady state (passes 0.319):
close to N6's floor (0.357 of today's tests incl. the first pass), and below N6's per-lane skip walk (0.384).

**The first partition a thread runs after a reset** certifies everything and also analyses every failure
(≈ 110–135 ns each), so its top phase costs ≈ 1.2–1.3 s instead of 0.87 s at b64 (b62: ≈ 1.12 vs 0.69 s). In
the client every rayon leaf range pays this once; NiceMark's and the L52 harness's bit-reversed partition
order pays it on **every** partition (no partition follows the last one the thread ran), i.e. a CPU join
benchmark run in that order gets slower, not faster (§6).

## 5. Timings: old against new on ivory [M]

Harness `raw/scripts/cpu2_ab.rs` (public API): set up one slice, run `count` **contiguous** partitions from
`v0` on one thread with one `Scratch`, as a thread of the client's pool runs them (so the first one of each run
is unskipped and pays the run analysis), print seconds, join survivors, checked survivors and hits. Script
`raw/scripts/run_ab2.sh` (and `run_ab.sh` for v1): every run `nice -n 19`, one at a time, rounds interleaved
with the binary order rotating per round, a load gate (1-min load ≤ 2) before each round; all 12 rounds OK
(loads 0.7–1.9 at round starts, no other process ≥ 20 % except one python3 at v1 round 3 and an ssh at 36 %).
Binaries: `old` = 41b4b405, `new2` = the branch commit `b86e4389`, `old12` = 41b4b405 with `MAX_STEPS` 12
only. **Counts identical in every run of every binary** (survivors / checked / hits below).

**Second build, `b86e4389` (`new2`; not the final code: the final code `d3630e30` is the §6 `ab3` table) (`raw/ab2-runs.txt`, `raw/ab2-summary.txt`; 07:18–07:50 UTC; 6 rounds; seconds per run):** *(relabelled 2026-11-14 afternoon, review finding L3; this table was headed "Final")*

| shape | partitions | old (6 rounds) | new (6 rounds) | speed-up, medians | minimums | per round | counts |
|---|---|---|---|---|---|---|---|
| b60 1e16 (1157209632114824200908) | 2400–2431 | 48.95 49.14 49.50 48.50 48.54 48.82 (med 48.89, spread 2.1 %) | 43.19 43.31 43.62 43.44 43.31 43.71 (med 43.38, 1.2 %) | **×1.127** | ×1.123 | 1.116–1.135 | 1,102,178,811 / 70,010,758 / [] |
| b62 1e17 s0 (4473066762334864396992) | 2400–2431 | 45.58 45.48 45.94 46.12 45.38 45.68 (med 45.63, 1.6 %) | 40.44 40.24 40.37 40.14 39.90 40.00 (med 40.19, 1.3 %) | **×1.135** | ×1.137 | 1.127–1.149 | 1,102,754,361 / 65,658,717 / [] |
| b64 1e17 s0 (71779931862957161709568) | 2400–2411 | 58.71 60.01 59.72 60.53 59.41 59.46 (med 59.59, 3.1 %) | 60.32 60.96 59.32 58.58 59.25 59.06 (med 59.28, 4.1 %) | **×1.005** | ×1.002 | 0.973–1.033 | 2,162,544,739 / 136,164,849 / [] |

**First version (`raw/ab-runs-v1.txt`, `raw/ab-summary-v1.txt`; 06:40–07:09; 6 rounds; MAX_STEPS 12, best-pair
runs, before passing `from` and the reciprocal table — the same skips, slightly dearer analysis):**

| shape | partitions | new vs old (medians / minimums / per-round range) | old12 vs old | new vs old12 (the skip alone) |
|---|---|---|---|---|
| b60 1e16 | 1000–1015 | ×1.085 / ×1.102 / 1.080–1.109 | ×1.018 | ×1.066 |
| b62 1e17 s0 | 1000–1015 | ×1.128 / ×1.139 / 1.107–1.150 | ×1.015 | ×1.111 |
| b64 1e17 s0 | 1000–1007 | ×1.031 / ×1.034 / 1.021–1.071 | ×1.023 | ×1.009 |

(old medians: b60 24.47 s, b62 22.85 s, b64 39.92 s; spreads ≤ 1.4 % / 1.2 % / 5.9 %; every value in the file.)

**b64, per partition** (`raw/probe-b64-v2400.txt`, `cpu2_abv`, two alternations): old 4.90–4.99 s and
5.08–5.25 s; new 5.46 / 5.47 s for the first (unskipped) partition, then 4.76–5.06 s. The steady-state saving
in place is ≈ 0.1 s a partition (≈ 2 %), against ≈ 0.25 s for the top phase measured alone (0.87 → 0.62 s):
the in-place saving is smaller than the isolated one at every base (b62: ≈ 0.17 s in place against ≈ 0.29 s
alone), which I did not explain (cache sharing with the join's per-key lists is my guess, not measured). The
first partition of a run costs ≈ +0.5 s, so a 12-partition run nets ≈ 0.

The machine was quiet enough to conclude for b60 and b62 (spreads 1–2 %, every round ×1.116 or more) and for
b64 that the gain is between −3 % and +3 % (per-round range), i.e. no measurable gain.

## 6. How partitions reach a thread: the client and the benchmarks [M]

The skip pays only on a partition that follows, on the same `Scratch`, a lower partition of the same join.

- **The client as it was** (`process_field_join`: `(0..parts).into_par_iter().map_init(Scratch::default, ..)`)
  gives a fresh `Scratch` to every rayon job. A probe with the same pattern and sleeping 1 ms items
  (`raw/scripts/cpu2_rayon_leaves.rs`, `raw/rayon-runs.txt`, 3,844 items, two repeats) found contiguous runs
  of mean length 384 (2 threads), 21–92 (4), 4–6 (8), 2.0–2.4 (16), 1.2 (32), 1.0–1.1 (64): rayon splits
  down to single partitions on many threads. There the change would have been a loss.
- **The branch keeps one `Scratch` per worker thread** (a `thread_local!` in `client/src/main.rs`): in the
  same probe 3,494–3,842 of 3,844 items (91–99.9 %) then follow a lower partition on their thread, and
  3,070–3,842 (80–99.9 %) follow their immediate predecessor (64 → 2 threads). That path itself is **not timed**
  here (it needs ≥ 8 busy threads; ivory allows 2): the A/B harness models one thread's contiguous sequence.
- **Out-of-order callers.** NiceMark (`client/src/bench.rs`) and the L52/L56 harness run partitions in
  bit-reversed order (`sample_order`), so no partition follows a nearby lower one. With the first commit
  (`8f5fb0f6`) every partition there paid the run analysis: b62 1e17 s0, 6 partitions, two alternations
  (`raw/bitreversed-order.txt`): old 1444 / 1455 ms a partition, new 1845 / 1803 ms, **×0.80**. The second
  commit (`d3630e30`) works the runs out only when the thread's previous partition of the join is at most 8
  below (`RUN_GAP`), so such orders run at the old cost (measured below), and a contiguous run gives up the
  skip on its second partition (its first now certifies everything without analysing, the second analyses).
  NiceMark still cannot show the gain the client gets; its CPU join scenarios would need contiguous ranges
  per worker to measure this change.

**Final code (`d3630e30`, `raw/ab3-runs.txt`, `raw/ab3-summary.txt`; 08:23–08:55 UTC, 6 rounds, all OK,
same harness, shapes and partitions as the table above; `new3`):**

| shape | old (6 rounds) | new (6 rounds) | speed-up, medians | minimums | per round | counts |
|---|---|---|---|---|---|---|
| b60 1e16, 2400–2431 | 48.54 48.79 49.62 49.73 49.53 49.19 (med 49.36, 2.4 %) | 43.39 43.18 43.80 44.49 43.48 43.75 (med 43.62, 3.0 %) | **×1.132** | ×1.124 | 1.118–1.139 | identical |
| b62 1e17 s0, 2400–2431 | 45.70 45.84 45.94 46.24 46.41 46.22 (med 46.08, 1.6 %) | 40.43 40.12 40.11 40.52 41.03 40.38 (med 40.41, 2.3 %) | **×1.140** | ×1.139 | 1.130–1.145 | identical |
| b64 1e17 s0, 2400–2411 | 59.51 59.86 60.23 60.12 59.11 59.67 (med 59.77, 1.9 %) | 59.12 59.01 59.32 59.52 58.67 59.53 (med 59.22, 1.5 %) | **×1.009** | ×1.008 | 1.002–1.015 | identical |

**Bit-reversed order** (the L52/L56 harness `l52_ab`, NiceMark's `sample_order`, b62 1e17 s0, 6 partitions, 1
thread, two alternations; `raw/bitreversed-order.txt`): old 1444 / 1455 / 1461 / 1474 ms a partition; first
commit 1845 / 1803 (**×0.80**); final 1417 / 1448 (×1.02, the `MAX_STEPS` part). Counts identical.

## 3b. Tests on the final code [M]

`raw/unit-tests-v2.txt`: `cargo test --release -p nice_common -p nice_client -- --test-threads=2` on
`d3630e30`: **201 + 22 passed, 8 ignored** (41b4b405 has 196 + 22 per L56 plus later tests; the branch adds 4:
`a_failing_run_fails_at_every_block`, `the_skip_walk_finds_every_top_on_small_bases`,
`the_skip_walk_finds_every_top_on_production_fields`, opt-in `the_skip_walk_finds_every_top_on_the_timed_shapes`).
The skip-walk helper now alternates runs on and off (`v % 5 != 2`) so walks with partitions that set no runs
are covered too. On the first commit (same rule; `raw/unit-tests.txt`, `raw/unit-tests-new.txt`,
`raw/unit-tests-prodref.txt`): the full suite passed (201 + 22); the opt-in timed-shape test
(`NICE_TEST_CPU_SKIP_PROD=24`): b60 1e16, b62 1e17 s0, b64 1e17 s0, partitions 0–23, the middle 24 and the last 24,
tops identical (e.g. b62: 36.3 M tops, 71.7 M blocks not certified per 24 partitions); the reference join on
3 partitions of each PLAN field (`NICE_TEST_CPU_JOIN_REF=3`, which runs one scratch through ascending
partitions, i.e. with the skip): identical survivors, prefilter survivors and hits; the first-600-partition
production test: b57–b64, 0.60–0.64 of the layer's blocks not certified. `cargo fmt --all --check` clean;
`cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings` clean (`raw/clippy.txt`), rustc
1.100.0.

## 7. Verdict, and what I could not determine

**Verdict.** Exact (proved; tested exhaustively on small bases and on real fields b57–b64; counts identical
in every timed run). On one thread over contiguous partitions it is **×1.13–1.14 at b60 1e16 and b62 1e17**
— above the ×1.05 bar for a simple change (it is a medium one: +~600 lines incl. ~300 of tests) — and
**×1.01 at b64 1e17**, i.e. nothing. Against the kill criterion as written ("less than ×1.05 … at b62 and at
b64") it is not killed because b62 clears; if the director reads it as "must clear at each", b64 fails it.
I pushed the branch on the literal reading and flag the choice here. b62 is the base the server runs next.

Why b64 gains nothing: the top phase is 19 % there, not 45 %; the walk certifies 0.415 of the blocks (b62:
0.343; more short runs from fast digits), and what remains of the top phase is stepping and seeding (≈ 0.38 of
0.62 s), which the skip does not remove; in place the steady saving is ≈ 0.1 s of a 4.9 s partition.

**Not determined:**
- The client with ≥ 8 threads (the per-thread scratch) is not timed: ivory allows 2 threads. The rayon probe
  says 91–99.9 % of partitions follow a lower one on their thread, 80–99.9 % their predecessor, so I expect
  the one-thread numbers to carry, minus up to ~1/run-length of the gain; not measured.
- Why the in-place saving is ≈ 60 % of the isolated one (b62 0.17 vs 0.29 s, b64 0.1 vs 0.25 s).
- Whole fields: every number is a contiguous run of 12–32 partitions from one field per base (one slice);
  the top share varies 31–54 % across fields (§1), so the gain will vary with it (b60 field at 10 % of the
  band had a 51–54 % top share).
- GPU and other machines: not involved. The skip uses only the partition order of one thread.
- Not built: a jump by multiply (est. ≈ 2 steps' cost), a power-of-two seed for b64 (bit unpacking instead of
  divisions; est. 490 → ≈ 100 ns; it also speeds up today's join, so it is its own change; an unmeasured
  draft is `raw/scripts/pow2-seed-experiment-unmeasured.patch`), a cheaper run analysis (≈ 110 ns per
  failing certificate now), NiceMark changes to measure contiguous runs.

## 8. Files

- `CPU2/RESULTS.md` (this file).
- Profile: `raw/profile_b{60,62,64}.txt`, `raw/profile_table.txt`; scripts `raw/scripts/profile.sh`,
  `profile_table.py`, `cpu2_prof.rs`, `prof.rs` (scratch module, not in the branch), `prof-scratch.patch`.
- Skip counts and tuning: `raw/maxsteps-scan.txt`, `raw/probe-b64-v2400.txt`; scripts `cpu2_skipcount.rs`,
  `cpu2_carried.rs`, `cpu2_abv.rs`.
- A/B: `raw/ab-runs-v1.txt` + `ab-summary-v1.txt` (first version, with `old12`), `raw/ab2-runs.txt` +
  `ab2-summary.txt` (`b86e4389`), `raw/ab3-runs.txt` + `ab3-summary.txt` (final); `raw/bitreversed-order.txt`;
  scripts `run_ab.sh`, `run_ab2.sh`, `ab_table.py`, `cpu2_ab.rs`; binaries `raw/bin/{old,old12,new,new2,new3}`.
- Client order: `raw/rayon-runs.txt`, `raw/scripts/cpu2_rayon_leaves.rs`.
- Tests: `raw/tests-skip-full-v1.txt` (full-span production walk, 22 min), `raw/unit-tests.txt`,
  `unit-tests-new.txt`, `unit-tests-prodref.txt`, `unit-tests-v2.txt`, `raw/clippy.txt`.
- Patches of intermediate states: `raw/scripts/wip-skip-v1.patch`, `wip-full-before-clean.patch`.
- Worktree `~/projects/nice/.worktrees/cpu-top-skip` on `exp/cpu-top-skip` (`d3630e30`), clean.
