# Experiments

One section per experiment, newest first. Each records: lead id, date, box (Vast id
and GPU, or host), commit(s) under test, exact commands, raw data path, the table,
and the one-line conclusion. Benchmark claims follow PROPOSAL.md §5: same box,
interleaved A/B, ≥3 rounds, median and spread per scenario, no scenario −2 %.

## T2.5 Realized gain of main a7a59c1 on demoux, from telemetry (2026-11-13, director, public API; `../2026-11-fresh-eyes/realized_1113.py`, `recent_niceonly_1113.json`, `demoux_launches_1112.json`)

`uv run --with numpy python realized_1113.py`. demoux, b60 1e16, two fields in flight: 8,232
non-empty fields on c0c357a (11-11 03:37 → 11-12 15:12 UTC) and 3,283 on a7a59c1 (from 11-12
17:20 UTC). Within a plan group (same launch count) join seconds against survivors is a line;
the builds' lines are compared at the group's pooled median survivors, bootstrap 95 %.

| launches per field | fields old / new (clean hours) | seconds old → new | gain |
|---|---|---|---|
| 1,350 | 3,831 / 808 | 12.87 → 12.52 | ×1.028 [1.025, 1.030] |
| 1,120 | 1,017 / 200 | 12.69 → 12.30 | ×1.031 [1.027, 1.035] |
| 1,170 | 781 / 168 | 12.90 → 12.48 | ×1.034 [1.030, 1.038] |
| 1,080 | 287 / 77 | 9.92 → 9.67 | ×1.026 [1.015, 1.037] |

**×1.029 weighted** (#250 on this card; #252–#254 do not act at b60 on a GPU). "Clean hours" = an
hour whose 1,350-launch fields have a 90th percentile of join seconds under 15 s: in seven hours
of 11-12 (local 15–18 and 20–22) the card was shared with another load and the join seconds
doubled (22–25 s), which makes the unfiltered comparison read ×0.843. **Rule for the future:
filter shared-card hours before reading a realized gain.**

## T2.3 Sampled exact re-verification of nice-only submissions by device and build, bases 58 and 60 (2026-11-12 15:41–21:46 UTC, agent; `T2/AUDIT.md`, `T2/raw/` (census, `sample.json`, queues, `compare.txt`, `cell_table.md`, `dup_rule.txt`, `pre222_only.txt`, `proof_hosts_block.txt`, `box/`, `box2/`); boxes 60374124 (went offline at 18:03, 2.68 h) and 60389955 (3.46 h), RTX 3080, ~$0.71 together)

Mechanism: the real client of each build, compiled from its commit, against a local stub of the
claim and submit endpoints; the production hosts mapped to 127.0.0.1 on each box and proven
unreachable before any client ran; the census from ivory by bounded id ranges. Validation: current
main reproduces demoux's counters exactly on 59/59 b58 and 149/149 b60 fields and the M4's on 20/20.

Census: b58 93,573 fields, all searched; b60 162,076 fields, 90.2 % searched; 11,473 submissions
disqualified (the M4 set). Counters (`survivors`, `checked`) are exact and repeatable only from
#236 on; older builds move stage overruns from one counter to the other run by run, so there
the audit compares the conserved combination survivors + checked ÷ (1 − pass rate) with a
tolerance that grows with the overrun (for 8bd154b / 9bde4a8 against main's exact counts; a loss
below ≈ 1e-5 of a heavily overrun field could hide there).

**Re-runs: 0 mismatches in 1,662 comparisons** (1,100 same old build, 328 exact, 234 against
main's counts). 95 % upper bound on a cell's per-field disagreement rate:

| | ≤ 2.1 % | ≤ 5.1 % | 9.5–14 % | weaker or not checked |
|---|---|---|---|---|
| b58, share of the range | 74.1 % | 22.0 % | 0.85 % (to 45 %) | 0.8 % (3 fields); M4 0.27 % not run; **Anvil 2.03 %: no telemetry, not checkable** |
| b60, share of the range | 46.0 % | 32.6 % | 14.3 % | 5.5 %; 9.8 % of the base not searched yet |

**Census finding (not a random sample): 3 of 11,087 same-build pairs of pre-#236 submissions
break the conserved quantity, all v3.4.6 (9a4f740) at b60, all with surplus checks:** field
206943130, GTX 1080, +5.4 M checks (3.3e-5 of the field's survivors); 206950836, TITAN Xp,
+2.35 M (2.8e-5); 206956667, RX 9070 XT, +9,990 (1.3e-6; that run also retried 16 partitions).
In each pair the other submission agrees with a same-build re-run on the 3080 (director's own
API lookups confirm the three pairs). Reading: the #222 flush race fired outside Apple at about
1.4e-4 per submission. Per #222 an event can also overwrite list entries, which counts cannot
show. **Fields with only a pre-#222 submission: 89,158 at b58 (95.3 % of the range) and 64,590
at b60 (39.9 %).** If an event loses as many entries as it duplicates, the expected lost share
of those bases' candidates is ≈ 1.4e-4 × 3e-5 ≈ 4e-9 [derived, assumption stated]. Nothing was
changed, re-queued or reported anywhere.

## PRP.1 The 512-entry survivor stage and the base-64 prefilter shifts as branches on main: exactness and CUDA regression (2026-11-12 17:13–20:45 UTC, agent; `PRP/RESULTS.md`, `PRP/PR-BODY-stage.md`, `PRP/PR-BODY-shift.md`, `PRP/raw/` (`ab_table.txt`, `nm_table.txt`, box logs, scripts); fork branches `pr/join-survivor-stage-512` 0d84d0a and `pr/join-prefilter-shift-pow2` 93a7ef6, each one commit on main a7a59c1; box 60383994, RTX 3080 at 320 W, 3.53 h, ~$0.42)

M = main, S = stage 512 / flush 256, F = shift form. Four rotated rounds, counts identical in
every run, each run started at ≤ 60 °C (the card throttles when runs are back to back: the first
A/B attempt was discarded for that), register variant recorded per process.

| field (main ÷ branch, median of 4) | S | F |
|---|---|---|
| b62 1e17 | ×1.000 | ×0.997 (same code as main: A/A) |
| b60 1e16 | ×0.998 | ×1.000 (A/A) |
| b64 1e17 (card in thermal slowdown on both sides) | ×0.997 | **×1.019** (1.012, 1.013, 1.024, 1.036) |
| b64 1e16 × 2 | ×1.000 | **×1.016** (1.016, 1.011, 1.017, 1.020) |
| NiceMark score, 4 rounds | ×0.999 (lowest scenario round 0.987) | ×1.002 (no b64 scenario: A/A) |

Exactness: dense compares against the CPU join pass (S: b60 1e16 48 partitions, b62 1e17 32; F:
b64 1e16 48, b64 1e17 32); CUDA device suite 7/7 for both (F's first run failed on a buffer
allocation while other jobs held the card's memory; alone 7/7); lavapipe 8/8 with naga and with
SPIR-V for S, F and M; host tests 247 / 248. **Stage overflow:** a throwaway build with a 16-entry
stage sends 124 M of 135 M checked pairs (b60) down the direct path and the counts still equal
the CPU join's; at 512 / 256 the direct path takes 93,908 pairs at b60, 0 at b62, 79 at b64.
**F at other bases:** the canonicalised CUDA source of all kernels at b58, b60, b62 is identical
to main's; the b64 join kernel differs in 12 lines (the multiplies became shifts). The CPU
join's prefilter was left alone (its base is a runtime value; a shift form there was 3.5 %
slower).

## N17.1 The RX 9070 XT at its operating point: profile by doubling, the tunings in three rounds, base 64 (2026-11-12 15:28–17:09 UTC, director, second demoux window, 101 of 120 minutes; `N16/raw/demoux/` (193 files), `N16/raw/demoux_analysis.txt`, scripts `N16/raw/scripts/go_dir1.sh`, `go_dir2.sh`, `go_dir3.sh`, `chain_geox.sh`, `modes.sh`; binaries: N16 = fork `exp/n16-join-base` 32e9e19, P = `exp/n20-mul-probe` f049415, M = main a7a59c1, D = `exp/n14-wgpu-dense-plan-v2` bb58878)

`python3 -I N16/raw/scripts/analyze.py N16/raw/demoux 3150 300`. Production's build path
(`--features gpu,cubecl-spirv`), production client stopped by the user, every run unprofiled,
99–100 % busy at 303–304 W and 3.03–3.19 GHz, counts exact in every exact mode. Base spread
within a chain 0.0–0.8 % (1.2 % in the first chain, whose first run was the fastest).

**Profile by doubling** (a part executed twice at full load; share = Δ seconds ÷ base):

| part | 9070 XT b62 1e17 (73.5 s) | RTX 3080 b62 | 9070 XT b64 1e17 (151.6 s) | RTX 3080 b64 |
|---|---|---|---|---|
| prefilter | **25.9 %** (0.68 ps per pair) | 15.9 % (0.35) | **30.4 %** | 20.8 % |
| check kernel (main's of 11-09) | **16.3 %** | 11.3 % | **17.5 %** | 11.0 % |
| AND | 11.1 % | 14.6 % | 10.5 % | 14.6 % |
| walk rounds | 6.1 % | 9.1 % | 8.0 % | 12.6 % |
| transposed copy | 0.9 % | 4.6 % | | |
| batch loads, entry-wave loads, barriers | −0.2 %, −0.5 %, +0.1 % | 1.4 %, 0.0 %, 0.1 % | | |

Removal, unprofiled, b60 1e16 (13.10 s; clocks 2.8–3.2 GHz in these 4–7 s runs): prefilter 27.6 %,
stage + check 19.3 %, AND 11.6 %, walk 5.6 %, entry waves and below 5.3 %; dispatch only 4.0 s.
The per-phase profile mode costs +17.9 % here (86 % busy). **Verdict: NVIDIA's profile with a
prefilter and a check that cost ≈ 2× per pair; the fixed per-batch parts are ≈ 1 %. N16's
premise is dead for good.**

**Tunings, three rotated rounds each** (tree E + switches; ÷ the round's own base):

| variant | b62 1e17 | b60 1e16 | b64 1e17 (1 round) | RTX 3080 (N16.1) |
|---|---|---|---|---|
| survivor stage 512 entries, flush at 256 (`sc512`) | ×1.055, 1.056, 1.060 → **×1.056** | ×1.057, 1.056, 1.056 → **×1.056** | ×1.062 (stage 256) | ×0.999 b60, ×0.994 b62 |
| denser plan (`vram`) | ×1.032, 1.035, 1.036 → ×1.035 | ×1.045, 1.047, 1.038 → ×1.045 | no-op on tree E (FD off there) | already on |
| stage 512 + `TOP_CAP` 128 + denser plan (`all3`) | ×1.111, 1.114, 1.123 → **×1.114** | ×1.134, 1.139, 1.139 → **×1.139** | ×1.080 (= stage + `TOP_CAP`) | — |

One-round screen at b60 (base 13.08 s): stage 512 / 256 / 128 ×1.063 / 1.048 / 1.054; `TOP_CAP`
128 ×1.054; stage 512 + `TOP_CAP` 128 ×1.085; stage 256 + denser plan ×1.103; work group 128 /
64 threads ×0.83 / ×0.64 (H2 dead); seconds = 11.83 + 0.87 ms × batches (1, 2, 4 partitions per
launch). b64 1e17 screen (base 150.33 s): stage 256 ×1.062, stage 512 + `TOP_CAP` 128 ×1.075.
**After the stage, `TOP_CAP` 128 adds only ×1.01–1.03 and needs a per-device value.**

**The denser plan behind its device rule, on today's main** (M a7a59c1 against D bb58878, one
round): the rule engages on RADV (625 against 1,350 batches at b60, 4,458 against 7,959 at b62,
3,944 against 7,076 at b64); **b60 ×1.053, b62 ×1.045, b64 ×1.004** (135.23 → 134.70 s).

**Base 64, the prefilter's two digits as shifts** (`pfsh`, exact identity at b = 2^6, binary P):
150.16 → 142.90 s, **×1.051**, counts identical (one round). Today's main at b64 1e17: 135.23 s
(tree E without #254: 150.2–151.6 s, so #254 is ×1.11–1.12 on this card).

**Multiply probe** (binary P, b62, one round; four extra operations per walked pair): additions
+5.7 %, two 32-bit low + two 32-bit high multiplies +6.9 %, the same with 24-bit-masked operands
+4.3 % (the driver's dump shows the two low multiplies became `v_mul_u32_u24`, the high ones stayed
32-bit). **Not resolved: the variants differ by less than a single round's layout noise; what the
probe does show is that eight or nine extra instructions in the walk loop cost 4–7 % of a
field on this card.**

## N16.1 A harness for the 9070 XT's profile; the RTX 3080 by doubling and by removal; what ACO generates (2026-11-12, agent; `N16/RESULTS.md`, `N16/WINDOW-PLAN.md`, `N16/raw/` (`sorted/` = the tables' logs, `scripts/`, `taskA.txt`, `taskC.txt`, `box/spv_dumps.tar.zst`); fork branches `exp/n16-join-base` 32e9e19 (from 44eee52) and `exp/n14-wgpu-dense-plan` 464be8b (on main 5b1d627); box 60317813, RTX 3080 at 280 W on a Ryzen 5 5600X, 3.59 h, $0.47; box 60315324 unusable, 0.44 h, $0.05)

`python3 -I N16/raw/scripts/analyze.py N16/raw/sorted` prints every row with clock, power, busy % and
counts (re-run by the director: tables reproduce; every row at 1,740–1,935 MHz and 277–280 W).

**The 9070 XT's profile from N13's logs, bounded** (`N16/raw/scripts/taskA.py`; J = differences of each
mode's own join timer, JS = the same scaled by the run's top phase; the truth lies between), b62 1e17:
base 7–13 % (0.20–0.38 ps per pair; 3080 0.26), AND 12–19 %, walk 5–6 %, **prefilter 15–28 %**,
survivor path 21–35 %, check 17 %, top 22 %. (N13.2's single figures are the JS end of each range.)

**RTX 3080 at 280 W, CUDA, unprofiled; "doubling" = the part executed twice at full load, counts
exact, cost = Δ seconds ÷ base** (b62 1e17 at 0.45, base 61.97 s, 2 rounds; b64 1e17 at 0.55, base
143.12 s, 2 rounds):

| part | b62 1e17 | b64 1e17 | by removal at b62 (unprofiled) | L51 (180 W, removal) |
|---|---|---|---|---|
| prefilter | 15.9 % | 20.8 % | walk + prefilter 28.4 % | 19.8 % |
| AND | 14.6 % | 14.6 % | 16.6 % | 14.9 % |
| check kernel | 11.3 % | 11.0 % | stage + check 12.2 % | 12.0 % |
| walk rounds | 9.1 % | 12.6 % | (above) | 9.2 % |
| transposed copy | 4.6 % | | | (base 10.9 %) |
| batch loads / entry-wave loads (cached second read: lower bounds) | 1.4 % / 0.0 % | | | |
| barriers (6 more per item and batch) | 0.1 % | | | |

The two instruments agree within 1–3 points, and with L51. **On the 3080 the clock stays or rises
in the light modes** (z 1,740, a 1,725, p 1,800 MHz against c's 1,740–1,770, all at 279 W): L51's
and B64's NVIDIA shares stand. Profiled mode costs +3.2 % there and keeps its clock.

**Launches on CUDA** (`NICE_EXP_HOSTACC`, `NICE_EXP_SLOTS`): seconds = 11.03 + 0.78 ms × batches at
b60 1e16 (7 runs), 59.6 + 0.84 ms × batches at b62 1e17 (4 runs). Every launch fence completes
inside `client.sync()` (0 of 2,615 pending); host time in `launch_batch` 0.92–1.00 ms per batch at
b62 (2.4–2.6 s, ≈ 4 % of the field, nearly all in CubeCL's flush), 0.2 ms at b60 and b64. Whether
that is GPU idle time is the agent's reading, not measured (busy reads 99 % at b62, 92 % at one
partition per launch): **estimate only, ≤ ×1.04 on NVIDIA.**

**Geometry and occupancy on CUDA (exact, b60 1e16 / b62 1e17):** `TOP_CAP` 128 +3.1–4.3 % / +3.5 %
slower; survivor stage 512 or 256 entries +0.1 % / +0.6 % (neutral); both +3.2 % / +2.4 %; work
group 128 +9–12 %, 64 +31–38 %; top-append ballot forms within ±1 %.

**What ACO (Mesa 25.2.7, null GFX1201 device, CubeCL's SPIR-V compiled with a small pipeline
program) generates for the join kernel:** wave64; 1,357 instructions; no spills, clamps or emulated
64-bit; 16 barriers (0 at a 64-thread work group); **18.9 KiB of LDS per work group, which caps
occupancy at 12 waves per SIMD (ACO's estimate)**; `TOP_CAP` 128 → 13.8 KiB, 18 waves; stage 512 →
14.8 KiB, 16; stage 256 → 12.8 KiB, 18; `TOP_CAP` 128 + stage 512 → 9.7 KiB, 24. The transposed
AND waits on four LDS loads per digit (latency-bound unless enough waves hide it). A walk round
with the prefilter is ≈ 113 instructions per entry slot (≈ 66 on NVIDIA). The FD top append's
scans already compile to a ballot. **Hypothesis this gives (not measured on the card): `TOP_CAP`
128's ×1.04–1.05 there is occupancy, so a smaller survivor stage, neutral on NVIDIA, should win
there too.**

**Task D** (`exp/n14-wgpu-dense-plan` 464be8b): the denser plan for a wgpu adapter reported as
`DiscreteGpu`, not a software rasterizer by name, budget ≤ 2 GiB. wgpu exposes no memory size, so
this is a class rule: it cannot tell a 4 GB discrete card from a 16 GB one. 11-case unit test,
fmt, clippy, 7 lavapipe device tests pass; on CUDA both binaries take the denser plan (A/A
×0.98–1.02).

**Validation of the harness:** dense compare against the CPU join for every exact mode on CUDA
(b60 1e16: 23 modes; b62 1e17: 15) and on lavapipe with the SPIR-V compiler (22 of 23; `wsync` is
not run by lavapipe and fails its dispatch check instead of miscounting). `go_window.sh` dry-run
twice on the box, the second from a fresh clone at the final head (builds 167 / 168 / 166 s at
`-j 8` on a 5600X); `END_AT` and the stop file tested.

## T2.2 Can production telemetry bound a per-launch cost on demoux? (2026-11-12, director, public API; `../2026-11-fresh-eyes/launch_regression.py`, `demoux_launches_1112.json` (6,567 demoux nice-only fields, 11-11 03:37 → 11-12 00:53 local, build c0c357a, b60 1e16, two fields in flight))

`uv run --with numpy python launch_regression.py`. 8.7 % of the fields are empty (0 launches,
1 ms). Non-empty: median join 12.15 s, 1,170 launches, 9.9 ms per launch; plans of 4, 5, 6, 7, 8
and 16 partitions per launch occur. `run_secs = a + α·survivors + γ·launches`: γ = 2.64 ± 0.04 ms
per launch (R² 0.975), which would be 28 % of a 1,350-launch field; but corr(survivors, launches)
= 0.85, the plan follows the field's density, and the per-group lines are not monotone in the
launch count (at 1.5e11 survivors: 10.9 s at 1,350 launches, 11.1–11.2 s at 1,120–1,170, 9.9 s at
1,080, 8.9 s at 450–720). **Verdict: an upper bound only (≤ 2.6 ms per launch); telemetry cannot
separate launch cost from FD seeds and field shape.** A forced partitions-per-launch sweep on the
card can (in the window harness).

## T4.1 The open PRs after #250's merge (2026-11-12, director; worktree `.worktrees/rebase-1112`, local branches `rb/*` (cherry-picks onto 5b1d627) and `mg/*` (merges))

#250 merged 01:57 UTC as 5b1d627, tree-identical to ee30303. Cherry-picks onto it: #251 and #254
clean, #252 changelog only, #253 clean on the new #252. `git diff` of each result against its
measured tree outside `CHANGELOG.md`: #251 and #254 identical; #252 and #253 differ by exactly
#250's diff (sha1 of the diff text equal to `git diff c0c357a 5b1d627`'s). The force-push of these
was refused, so each PR branch got a merge commit resolved to the cherry-pick's tree (`git diff
--quiet rb/X mg/X`): **#251 a70b012, #252 7269d61, #253 43b448b (merges the new #252), #254
f812a02**; plain pushes; all MERGEABLE; CI re-running at 05:56 UTC.

## N13.2 Correction to N13.1's profile: the ablation runs were at half clock (2026-11-12, director, yesterday's raw logs; `N13/raw/scripts/clock_check.py` → `N13/raw/clock_check.txt`)

`python3 N13/raw/scripts/clock_check.py N13/raw/demoux`. The `.gpu` samples (busy %, clock, power
every 5 s) of the profiled runs on the RX 9070 XT, medians per run, b62 1e17 at 0.45 (b60 1e16
pair in brackets where it differs):

| mode (profiled, `NICE_EXP_JOIN_ABL`) | clock | power | top phase | join phase | join ÷ field, as timed | join rescaled by the run's top phase |
|---|---|---|---|---|---|---|
| c, full | 3226 MHz | 294 W | 18.2 s | 43.3 s | 53.2 % | 53.2 % |
| p, no stage/check | 3141 | 244 | 18.5 | 42.8 | 52.5 % | 51.7 % |
| b, AND + walk | 1932 | 103 | 28.7 | 30.6 | 37.6 % | 23.9 % |
| a, AND only | 1599 | 95 | 30.9 | 25.8 | 31.7 % | 18.7 % |
| z, no AND | 1464 | 89 | 35.2 | 10.7 | 13.2 % | 6.8 % |

The card's clock follows its load: with the join's later parts off it ran at 45–60 % of its
clock and a third of its power, and the unchanged top phase took up to 1.93 × as long. N13.1
read that as a timer leak and took the join's parts from differences of whole-field totals
(a − z, b − a, p − b), i.e. from runs at different clocks. Of the 126 unprofiled runs (the PR
A/Bs and the retune) 125 sat at 99–100 % busy, 3.14–3.2 GHz, 304 W: **those numbers stand.** The
exception is the first naga run at b60 (69 % busy, 2.85 GHz, 212 W), so naga's ×1.00 at b60 is a
lower bound.

Corrected shares of the profiled field (rescaled by each run's top phase; rough, the bucket
phase does not scale by the same factor), b62 1e17 / b60 1e16, next to L51's RTX 3080:

| part | 9070 XT, corrected | bound that needs no rescaling | N13.1 said | RTX 3080 (L51) |
|---|---|---|---|---|
| join base | **6.8 % / 6.3 %** (0.20 / 0.19 ps per pair) | ≤ 13.2 % / 12.9 % (mode z's own join timer at half clock) | ≈ 36 % / 33 % | 10.9 % / 10.5 % (0.26 ps) |
| AND | 11.9 % / 11.5 % (0.35 ps per pair) | base + AND ≤ 31.7 % / 33.3 % | 13 % / 17 % | 14.9 % / 15.0 % |
| walk rounds | 5.2 % / 6.3 % | | 3 % / 0 % | 9.2 % / 9.0 % |
| **prefilter** | **27.8 % / 29.9 %** (≈ 21 ps per AND survivor) | walk + prefilter + stage ≥ 21.5 % / 22.3 % | 1 % / 5 % | 19.8 % / 23.5 % |
| stage | 1.5 % / 1.6 % | | | 1.1 % / 0.9 % |
| check (main's; mode c, full clock) | 17.0 % / 18.8 % (0.207 / 0.199 ns) | measured | same | 12.0 % / 14.4 % |
| top FD (mode c) | 22.4 % / 18.8 % | measured | same | 22.8 % / 18.4 % |

**Verdict: the 9070 XT's profile is NVIDIA's, with a dearer check and prefilter. "The join's
base is a third of the field at 4 × NVIDIA's cost per pair" and "the survivor path is nearly
free here" are both wrong** (N16's premise falls). What stands from N13.1: section A (the open
PRs), section C (the retune), the mode-c phase shares, the per-check and per-top-test costs.
Open: a profile of the join's parts on that card taken at its operating point (work added at
full load instead of removed), and whether L51's and B64's ablation shares on NVIDIA were taken
at full clock (today's agent checks on the box).

## N13.1 The open PRs, the profile and a retune on demoux's RX 9070 XT (2026-11-11 12:45–14:54 UTC, agent on the user's machine with the production client stopped; `N13/RESULTS.md`, `N13/raw/` (`demoux/`, `demoux-final/`, `scripts/`, `analysis.txt`))

Card at its 304 W cap; `cargo test --release -p nice_common --features gpu,cubecl-spirv` (reports
`wgpu<spirv>`, production's path). A/A noise 0.2 %; rounds within a tree 0.3–1.4 %; counts
identical in every run and exact against the CPU join on b60, b62 and b64 fields.

| field (3 interleaved rounds) | main → #250 | #250 → #251 | main → #251 | #250 → #254 |
|---|---|---|---|---|
| b62 1e17 at 0.45 | ×1.041 | ×1.127 | ×1.173 | |
| b62 1e17 at 0.55 (+ the empty 0.35) | ×1.040 | ×1.107 | ×1.150 | |
| b60 1e16 at 0.55 + 0.85 | ×1.031 | ×1.138 | ×1.178 | |
| b64 1e17 at 0.55 | | | | ×1.096 |
| b64 1e16 at 0.55 | | | | ×1.088 |

#250's denser plan is CUDA-only, so here only its cheaper stepped slot counts. Main's seconds per
field: b62 1e17 at 0.45 75.7 s (RTX 3080 at 300 W: 66.7 s); the card runs the join at ≈ 0.87–0.95 ×
that 3080.

**Superseded by N13.2 (2026-11-12): the join's parts below were taken from runs at half clock; the base and
survivor-path rows are wrong.** Shares as first reported (b62 1e17 / b60 1e16; the join's parts from whole-field totals per ablation mode):

| phase | 9070 XT | RTX 3080 (L51) |
|---|---|---|
| top certificates (FD) | 22 % / 19 % | 23 % / 18 % |
| join | 53 % / 56 % | 56 % / 59 % |
| · AND | 13 % / 17 % | 15 % / 15 % |
| · walk rounds + prefilter | 4 % / 5 % | 29 % / 33 % |
| · base (batch loads, transposed copy, entry waves) | ≈ 36 % / ≈ 33 % (derived) | 11 % / 11 % |
| check (main's kernel) | 17 % / 19 % | 12 % / 14 % |

Per operation: survivor path ≈ 0.11–0.15 ps per pair (3080: 0.67), join base ≈ 1.0 ps per pair
(0.26), check 0.20 ns (0.11), FD top test 0.14–0.15 ns (0.158).

Retune (b62 1e17 at 0.45 / b60 1e16 at 0.55):

| change | b62 | b60 | rounds |
|---|---|---|---|
| `TOP_CAP` 128 with `TRANSPOSE_MIN` 96 | ×1.039 | ×1.051 | 3 |
| CUDA's denser plan on this adapter (12 / 9 partitions per launch instead of 7 / 4; fits the 2 GiB budget) | ×1.039 | ×1.044 | 3 |
| both | ×1.078 | ×1.106 | 3 |
| `AND_GROUP` 8 · `TRANSPOSE_MIN` 128 | ×1.022 · ×1.018 | ×1.012 · ×1.022 | 3 |
| naga instead of SPIR-V | ×1.02 | ×1.00 | 2 |
| per-round plane barrier in the walk | ×1.00 | ×1.00 | 2 |
| wide u64 chunks | ×0.94 | ×0.93 | 2 |
| EPT 1 / 3 · `AND_GROUP` 2 · `TRANSPOSE_MIN` 256 · `TOP_CAP` 512 | ×0.96 / ×0.98 · ×0.96 · ×0.95 · ×0.87 | ×0.97 / ×0.98 · ×0.96 · ×0.98 · ×0.89 | 2 |

The driver reports 32–64-lane subgroups, so the one-ballot append is off here (not forced on).
**Conclusion: #251 is the big one on this card (×1.13–1.14; main → #251 ×1.17–1.18); #254 holds
at b64 (×1.09–1.10); two tunings are worth ×1.08–1.11 together; the join's base is a third of the
field here at four times NVIDIA's cost per pair and is the block to open next.**

## B64.1 First profile of base-64 fields; the walk's per-pair floor (2026-11-11, agent; `B64/RESULTS.md`, `B64/raw/` (`analysis.txt`, box logs, scripts); fork branch `exp/b64-profile` 44eee52; box 60171046, RTX 3080 at 300 W)

Base means over 10 fields at 0.05–0.95 of the range (seconds per admissible n; 3–4 rounds):

| | main c0c357a | stack a97e3d7 (#250 + #251) | stack over main |
|---|---|---|---|
| b64 1e17 | 6.46e-15 (82.0 s per field) | 6.16e-15 (78.2 s) | ×1.049 |
| b64 1e16 | 7.47e-15 (9.48 s) | 7.02e-15 (8.91 s) | ×1.064 |
| b62 1e17 (1 round) | 1.47e-14 (48.2 s) | 1.21e-14 (39.6 s) | ×1.22 |

Whole base on this card (derived): b64 2.96e7 s on the stack, b62 3.78e6 s: **b64 ≈ 7.8 × b62**.
3 of 10 b64 fields are empty at both sizes (2 of 10 at b62); an empty field costs ≈ 1.1 s with the
GPU idle. Shares of a b64 field on main: top certificates 17–18 % (the FD kernel is off at
power-of-two bases), join 67–68 % (base 12, AND 17, walk 13, prefilter + stage 25: the survivor
path is 38–40 %), check 11 % (≈ 6.5 % on the stack), setup + bucket + rest ≈ 4 %. b64 buckets hold
≈ 1,400–1,750 tops × 220–330 entries (b62: ≈ 470 × 330). No division survives at b64 (shifts and
masks); one `mul_hi` in the lean prefilter remains (1–2 %, estimate).

- **Field size:** the 1e16 tiles of a 1e17 field cost the same within ±1 % with identical counts;
  1e16 pays the idle second per empty field ten times as often: **insert b64 at 1e17, ≈ 3–4 %**.
- **Constants:** no retune moves b64 by ≥ 3 % (`TRANSPOSE_MIN` 128, `SURV_FLUSH` 768, `AND_GROUP` 8
  within ±2 %; EPT 1 or 3, `AND_GROUP` 2, `TOP_CAP` 128 lose 4–6 %; `TOP_CAP` 512 ×0.87 with spills).
- **The FD top kernel switched on at b64** (`TOP_FD_AT_POW2_BASES`, on the stack): **×1.141 /
  ×1.129 / ×1.125 on b64 1e17** (3 interleaved rounds), ×1.039 / ×1.067 / ×1.065 on 1e16; exact on
  the dense compare against the CPU join; top test 0.230 → 0.104 ns, top share 16.7 → 8.4 %,
  launches halve (the plan puts 11–13 partitions per launch instead of 5–7: #250's denser plan,
  CUDA only). The gate dates from FD round 1 ("measured slower").
- **Walk floor (N11):** it is the walk's round structure (a ~41-instruction round runs while any
  of 32 lanes has a bit left), ≈ 0.09 ps per pair; one walk over both entry slots ×1.00 at b62
  1e17, b60 1e16 and b64 1e16; without the per-round plane barrier ×0.88–0.90. **No small change
  reaches ×1.03: closed.**

Roadmap at b64 1e17: FD on ×1.13 (measured, one constant) · insert at 1e17 ×1.03–1.04 (server
config) · #251 ×1.05–1.06 (in review) · survivor path (38–43 % of the field) ≈ ×1.12 (estimate,
very large; L37's compaction lost) · binary stepping of the tops ≈ ×1.04–1.05 after FD
(instruction count, medium to large) · shift form of the walk's digit extraction ×1.01–1.02.

## T2.1 Who does the search, and what each deployed build did on demoux (2026-11-11, director, public telemetry; `../2026-11-fresh-eyes/demoux_history.py`, `demoux_history.json` (115,022 rows), `recent_niceonly.json`)

Nice-only fields submitted on 2026-11-09 and 11-10 (23,705 fields): **demoux (RX 9070 XT, wgpu on
Vulkan, main c0c357a) 81 %**, the fleet (NVIDIA, v3.4.7, ≈ 20 GPU-hours a day on 3060/4060-class
cards) 13 %, mayalaran (M4, main) 6 %. Median seconds per non-empty b60 1e16 field: demoux 11,
fleet RTX 4060 30, RTX 3060 74, M4 100–115.

Realized gain on demoux at each build switch (median seconds per non-empty b60 field, the last
1,500 fields before against the first 1,500 after, adjacent in the base; bootstrap 95 % interval):

| switch on demoux | what landed | realized | NVIDIA A/B at b60 (product of the PRs' own numbers) |
|---|---|---|---|
| 9a4f740 → c72e2c6 (10-28) | #203 and others | ×1.17 (400-field window) | — |
| c72e2c6 → 8c088a2 (10-29) | #215, #216 | ×1.14 (400-field window) | ×1.10–1.25, ×1.04–1.26 |
| 8c088a2 → 6f060a9 (11-03) | #235–#240 (with #222, #228) | **×2.11 [2.08, 2.14]** | ×1.80 |
| 6f060a9 → c0c357a (11-09) | #241, #246, #249 | **×1.17 [1.16, 1.18]** | ×1.37–1.39 |

v3.4.6 → main on demoux: 33.4 s → 11.6 s per field over the segments (×2.9; ×3.3 as the product of
the switches). **The last batch delivered less than half of its CUDA-measured gain on the card
that does 81 % of the work.** AMD cards cannot be rented on Vast and Vulkan does not start in Vast
containers (earlier notes), so the wgpu path can only be measured on demoux or after the fact
from telemetry.

Pace at the current mix (derived): b60 (80.7 %) ends in ≈ 3 days; b62 ≈ 2 months (≈ 53 days if the
fleet ran main); b64 ≈ 1.5 years.

## N1.C1 The CPU join at the transversal shape: exact prototype, counts, timing (2026-11-10, agent; `N1/cpu/RESULTS.md`, `N1/cpu/raw/` (run logs A–D, `analyze.py` summaries); fork branch `exp/n1-transversal-cpu` a32d78c from c0c357a; ivory, one EPYC-Rome vCPU, `nice -n 19`)

Change: experiment-only constructors (`JoinParams::supported_experiment`, `FieldSetup::new_experiment`,
`CpuJoin::new_experiment`), r³ mod b^(j+1) in `bot_dfs`, 256-bit r³ in `extend`, counters; +389/−11
in `overlap_join.rs`/`cpu_join.rs` plus a 567-line test module. `for_length` untouched. Exact: every
partition value of whole-base units at b10–b34 equals the reference `join_range` (survivor sets,
prefilter sets, hits), brute force to b30, 69 at b10; 30,000 random b40 units; 20 b54 and 6 b62
production-shape units (2.8e7 AND survivors, 1.0e6 prefilter survivors); the suite's 188 tests pass.

Counts per admissible n (measured; base mean of today's shape from 10 field locations):

| | b60 today / new | b62 today / new | b64 today / new |
|---|---|---|---|
| AND pairs | 1.05e-2 / 8.63e-3 | 6.7e-3 / 7.56e-3 | 3.5e-3 / 6.84e-3 |
| AND survivors | 3.8e-4 / 2.33e-5 | 2.5e-4 / 1.39e-5 | 1.5e-4 / 1.07e-5 |
| full checks | 2.4e-5 / 8.7e-7 | 1.5e-5 / 5.0e-7 | 9.6e-6 / 3.9e-7 |

My Monte Carlo: P_T and P_B within 3 %, pairs −5 % / −5 % / +20 %; its k 9 survivor column was
noise (8 and 2 events). Today's cost per admissible n varies ×2.7 between fields at b60; 2 of 10
sampled b62 fields and 4 of 10 at b64 are empty; the mid-base field is 22 % dearer than the mean at
b62. The bottom side is 8.0e15 residue *visits* per b62 base (95 ns exact, 44 ns affine on this
core), not 1.5e15; a unit of four partition digits with the fifth as the key shares one extension
across 62 values and removes it.

CPU seconds per admissible n, one thread (3 rounds, spread < 3 %):

| | b60 | b62 | b64 |
|---|---|---|---|
| today, mean of 10 fields | 2.25e-11 | 1.55e-11 | 6.81e-12 |
| (L − 4, 9, 5), affine extension | 7.62e-12 | 3.52e-12 | 3.62e-12 |
| (L − 4, 9, 4) + key digit (two-level) | 3.46e-12 | 2.65e-12 | ≈ 3.5e-12 (derived) |
| ratio, two-level vs today's mean | ×6.5 | ×5.9 | ≈ ×1.9 |

Mostly a cheaper AND, not fewer: 0.25–0.43 ns per AND against 1.0–1.15 ns (class lists of ~15,000
bottoms instead of ~300, 0.18 % of ANDs survive instead of 4.2 %). b64 is the weak base (twice
today's mean pairs: today's shape skips its empty fields and prunes by field).

**Director's re-projection of the GPU case** with these counts and a base-mean baseline (today
14.8 fs per admissible n at b62 on the 340 W card, 18.9 on the mid field; b64 ≈ 9.2 fs):

| chunk words | b62 | b62, walk floor removed (unmeasured) | b64 | b64, walk floor removed |
|---|---|---|---|---|
| u32 (portable) | ×2.45 | ×2.87 | ×1.76 | ×2.08 |
| u64, 4 chunks | ×2.90 | ×3.51 | ×2.10 | ×2.57 |
| u64, reverse orientation | ×3.18 | ×3.93 | ×2.32 | ×2.91 |

**Conclusion: on the CPU the new shape is measured at ×6 at b60/b62 and ≈ ×2 at b64; on GPUs it
projects at the ×3 bar at b62 (CUDA only) and under it at b64, where most of the remaining cost is.**

## N1.G1 Dense-phase cost per pair at other join shapes (2026-11-10, agent; `N1/gpu-tile/RESULTS.md`, `N1/gpu-tile/raw/` (`projection.txt`, `tables.txt`, `tsize.txt`, box logs, `n1_tile.rs`); fork branch `exp/n1-gpu-tile` c81875f; box 60024264, RTX 3080 at 340 W, 1.46 h, ~$0.18)

Calibration on real data (L51's profile tree 14f87cd, `join_kernel` byte-identical to c0c357a; b62
1e17 field at 7226266762397899821056, all 3,844 partitions, 3 interleaved rounds, no spill variant):
2.4655e13 AND pairs, 9.534e11 AND survivors (3.87 %), 5.80e10 full checks per field; dense phase
0.563 ps per pair (base 0.261 + AND 0.302); survivor path 17.4 ps per survivor (walk 5.6, prefilter
11.7); main unprofiled 61.93 s per field → 5.91e6 s per base on this card. (My estimates: pairs
−5 %, survivors +42 % on this field; my 0.8 ps / 36 ps were the 180 W box's.)

Synthetic tile harness (contiguous bottom lists; reproduces production's dense cost only to −19 %:
base −7 %, AND −30 %, the gap traced to buckets and remainders under 192 tops taking the per-top
AND at 0.85–0.97 ps per pair; projections scale base ×1.07 and AND ×1.43):

| tile (tops × entries) | orientation | chunk word | D_B 12 | D_B 18 | D_B 20 |
|---|---|---|---|---|---|
| 471 × 336 (today's mean) | today | u32 | 0.455 | 0.570 | 0.609 |
| 1,460 × 14,750 (f0 4, k 9) | today | u32 | 0.322 | 0.410 | 0.437 |
| 1,460 × 14,750 | today | u64, 4 chunks a pass | 0.272 | 0.323 | 0.339 |
| 1,460 × 14,750 | reverse | u32 | 0.400 | 0.410 | 0.407 |
| 1,460 × 14,750 | reverse | u64, 4 chunks a pass | 0.292 | 0.295 | 0.293 |
| 24 × 7,200 (k 10) | today / reverse | u32 | 1.11 / 3.39 | 1.11 / 3.39 | 1.11 / 3.40 |

(ps per pair, spreads ±1–3 %, counts identical across variants.) The AND part scales with the
entry's digits (17–18 fs per digit in u32, 10–14 in u64); the per-wave base does not and falls 2.4×
in the big tile, so 18 digits in the big tile cost no more than 12 in today's. u64 pays only with 4
chunks a pass. k 10's 24-top tiles cost ×2.7–11 the big tile's: dead.

Survivor path with the real walk and prefilter: 0.13–0.15 ps per pair + 14 ps × pass rate (fits
production to −1.4 % at 3.87 %). At the new 0.34 % it is 0.18 ps per pair = 54 ps per survivor:
survivors ÷ 10.8 buys the survivor path only ÷ 3.3. The floor is per-chunk machinery (ballots, the
flush decision and its barriers), not survivor work.

Whole-base b62 projection (central / uncalibrated harness; counts from NOTES §3; other overhead 2 %):

| shape | u32 | u64, 4 chunks | u64, reverse |
|---|---|---|---|
| f0 4, k 9 | ×2.56 / ×3.08 | ×3.01 / ×3.53 | ×3.20 / ×3.58 |
| f0 3, k 9, full FD top tests | ×2.81 / ×3.11 | ×3.19 / ×3.43 | ×3.05 / ×3.24 |
| f0 3, k 9, child certificates at 0.45 of a test (instruction estimate) | ×3.50 / ×3.97 | ×4.09 / ×4.51 | ×3.87 / ×4.19 |

New total at (f0 4, k 9, u32): dense 66 %, survivor path 22 %, everything else 12 %.
**Conclusion: at the user's ×3 bar, not over it. Portable u32 misses (×2.6–2.8); CUDA u64 clears
narrowly and inside the projection's own uncertainty; only f0 3 with cheap child certificates, an
unbuilt kernel, is clearly past it.**

## N5.1 Adversarial review of the no-shortcut argument (2026-11-10, agent, no hardware; `N5/REVIEW.md`, `N5/raw/` (`psj_mc.py`, `model.py`, `psj_floor.py`, `gap64.py` and outputs); ~25 CPU-seconds)

No hole that changes the exponent. Step 1 of the argument corrected: a pair with overlap o knows
2(L + o) digits. Prefix–suffix join model: flat floor ≈ 2e18 AND-units at b62, 1.6e19 at b64;
output-sensitive floor 3.4e17 / 1.6e18; information floor 4e10 / 5e11 (unreachable: list building).
The uniform-digit model holds within 10–20 % down to joint pass rates of 1e-6 (tops measured/model
0.87–0.94 at b62, bottoms 0.76–0.95). Lattice prescription ×3000–5000 worse than the join; partial
edge digits ≤ ×1.01 per base; cost per expected find at b150 ≥ 1e34 even with free lists and a
perfect join. One open engineering idea (digit-key indexed pairing, N10).

## L56.1 CPU seeded full check: PR branch (2026-11-09, agent; `L56/PR-RESULTS.md`, `L56/PR-BODY.md`, `L56/raw/`; `pr/cpu-join-seeded-check` 5c218b7 = one commit on L52's 1cce00d)

The check treats three digit sets as known: positions 0..k of n², n³ (the bottom's mask as
listed), positions k..k2 (the prefilter's four digits recomputed with the same `Fx::digits` /
`mid_values`), and the top's **pre-closure** common certificate digits (new `Cert::common`) only
where the seed flag is set (floor ≥ k2; every production survivor) — closure-forced digits are
never seeded (L47's warning). The middle digits come from design D's base-b² column form with its
own limb split (P split at b^10 with one 64-bit mul-high; `join_check` not imported since it lives
on the GPU stack; the PR's `Magic` uses the same construction and tests; merge proposed once both
land). **A/B vs 1cce00d (ivory Zen 2, 3 interleaved rounds; 1 / 4 threads):** b60 1e16 ×1.117
(1743 → 1560 ms) / ×1.139; b62 1e17 slice 0 ×1.136 (1693 → 1491 ms) / ×1.109; b58 1e15 ×1.168 /
×1.167; whole b60 1e14 ×1.090 / 1.069, b62 ×1.088 / 1.106, b64 ×1.119 / 1.110; counts identical in
every run. **NiceMark CPU 4 rounds ×1.155 (1091.0 → 1259.6; rounds 1.12–1.17).** perf (1 thread):
check share 14.8 → 4.9 % (b60), 16.1 → 4.7 % (b62); per check 119 → 36 ns / 133 → 34 ns; cycles
−8.6 / −12.7 %, IPC 2.85 → 3.12 / 2.79 → 3.17. On 4.28 M / 4.09 M recorded survivors: old 125.5 /
131.6 ns; column form with top digits 28.5 / 29.3 ns (×4.4–4.5); column form low digits only
38.2 / 41.0; L50's V3 form 50.3 / 50.8; digits converted before the verdict 9.6–9.8 → 1.8; 96 % of
checks decided within the first four middle digits. Tests: every checked survivor (test windows +
2 partitions of each PLAN field in CI; 4 partitions of each timed shape opt-in
`NICE_TEST_CPU_CHECK_REF`, 19.65 M survivors): seeds = true digits at exactly those positions and
disjoint, middle digits match position by position (count mode), distinct count =
`get_num_unique_digits`, repeat flag and verdict = `get_is_nice`; column digits vs malachite on
274,661 (n, shape) pairs at bases 3–64; 298,153 verdicts on near-nice / band-edge / adversarial n
incl. b10's 69; quotient exactness by closed-form bound + block checks in CI, exhaustive x < 2³¹
for 114 divisors opt-in (493 s); debug build with overflow checks passes; certificate parts vs
the reference and the stepped certificates; suite 196 + 22; `NICE_TEST_CPU_JOIN_REF=3`; whole b42;
fmt; clippy. (An out-of-line `Iterator::nth` from a clippy-driven `skip(1)` cost 0.7 % and was
fixed before the measured head.) → reviewer; held at the cap (4th held branch).

## L53.1 #249's top-layer sort off the device thread: third commit 80a103e (2026-11-09, agent; `L53/RESULTS.md`, `L53/raw/`; #249 head 80a103e; held branches rebased: `pr/top-fd-round2` 5d0c8cf, `pr/check-d` e28b79f)

On 87958fd `sorted_layer` ran at the top of `run_slice` inside `JoinDevice::new`, on the device
thread, after the previous slice's batches had all been read back → the GPU idled through 11
sorts per b62 1e17 field; the prep thread only computed the next slice's `sub_range`; slice 0's
sort was not in `plan_join` either. Fix: `sorted_layer` → `join_plan`; `plan_join` sorts slice 0
(the client already overlaps it with the previous field); the prep thread sorts later slices;
`JoinDevice::new` only uploads; residues step from the previous prefix by addition (99.8 % of
steps < b), u64 division only after larger gaps. Sort time (b62 1e17 field): 2.05 s standalone /
2.28 s in place → 1.02 s off the device thread (device thread keeps a 0.03–0.05 s copy of slice
0's layer, never waits); b60 1e16 0.37 / 0.41 → 0.18 s. **A/B (RTX 3080 at 150 W, E5-2630 v4):**
separate processes (3 rounds; 6 of 26 processes spilled and were re-run; clocks ±4 % between
processes): device time ×1.009 / ×1.023 / ×1.021 / ×1.023 (b62 1e17 / b60 / b62 1e16 / b64), wall
×1.006 / 1.016 / 1.007 / 1.019; **same process alternating old/new path (shared kernel image and
temperature): b62 1e17 ×1.022 (1.020–1.024), b60 ×1.016, b62 1e16 ×1.020, b64 (one slice) ×1.007.**
Below the ×1.03–1.04 estimate because this box's field is 103 s (150 W) and the sort 2.28 s; on
L51's box ≈ ×1.027 (estimate). Exact: new sort output and `goff` word-for-word = #249's on every
slice of four fields (30.6 M prefixes); every timed count; 1e14 COMPARE; dense; whole b42; parity;
certificate test; #249's sentinel FD-vs-top test (237,948,545 tops — this box cuts the b60 1e16
test field's slices differently from L46's 237,907,266; 87958fd gives the same here); host test
also on a reversed layer (21 fields, 582,884 buckets); lavapipe 8/8 ×2; lint 14/0; fmt/clippy ×3.
Rebases conflicted after all (round 2: `top_fd_runs` adjacent to the removed `sorted_layer` +
CHANGELOG; check-d: `check_counts` calls `JoinDevice::new`, which now takes the layer); both pass
unit tests, 1e14 COMPARE, parity (and check-d its count test). #249's body updated (three
commits) and a comment posted. Box 2.6 h.

## L54.1 / L55.1 Transposed-AND codegen and the register pin (2026-11-09, agent; `L54/RESULTS.md`, `L54/raw/` (box dumps, `analysis_*.txt`, `l55/`); branch `exp/join-and-codegen` 19702e1 = form 2 in PR form on d813aea, forms behind `NICE_EXP_AND_FORM` in d91447a)

SASS per digit in the AND loop (b62 = b60; identical across 5 shared layouts): d813aea **30**
(8 loads/ORs, 8 address, 11 bit iteration, 3 recomputed invariants); form 1 fold-only (index
masked with `& (TR_WORDS − 1)`, which gives NVRTC the no-wrap proof offline nvcc already assumes)
**24**; form 2 fold + walk the low mask word then the high **20**; form 3 form 2 with 4 shared arrays
per chunk group **19**; per (warp, 4-chunk group) 848 → 704 / 614 / 590 (−17 / −28 / −30 %). The
leaner bit loop (highest-bit / `trailing_zeros` / `clz` forms) costs the same as `BREV`+`FLO`+
`x&(x−1)` or more. **A/B vs d813aea (RTX 3080 at 130 W, 3 interleaved rounds):** form 1 ×1.009 /
×1.016 (b62 1e17 / b60 1e16); form 2 ×1.008 (0.963/1.012/1.008; ×1.012 without the cold-card
round) / ×1.018; form 3 ×1.016 / ×1.020; b62 1e16 ×1.010–1.018; b64 ×1.005–1.009. Cycle ratios
unusable (per-process clock means scatter ±6 % at 742–944 MHz on 5-s samples). Likely cause: at
130 W denser issue lowers the clock; a quarter to half of the predicted ~3.5 % of cycles shows in
wall time. **Record only: no form reaches ×1.03.** Register variants recorded: d813aea 46–48 with
the 40 + 24 B spill variant in 1 of 12 timed processes (re-run), 3 of 24 kernels in a 1e14 run;
forms 2/3 47–48, no spill in 48 kernels (even on the layout where d813aea spills; not
guaranteed). Exact: form 2's tree passes parity incl. b50/b54, the FD-vs-top test, certificate
test, dense fields, whole b42, 1e14 COMPARE (= L34's counts), lavapipe naga + SPIR-V 8/8, lint
14/0, fmt/clippy ×3 → **form 2 is a ready rider for a future join PR** (applies unchanged on
#249's head; one `use` line differs on #246). **L55 not feasible in CubeCL 0.10/0.11.3:** only
`__launch_bounds__(cube_dim)` is emitted, NVRTC options are hard-coded, `cuModuleLoadData` has no
JIT options, no PTX hook, `__maxnreg__` is rejected beside `__launch_bounds__`. Smallest upstream
patch: a `min_cubes_per_sm` kernel option plumbed like `cluster_dim` → `#[cube(launch_unchecked,
min_cubes_per_sm = 5)]` emits `__launch_bounds__(256, 5)`; 25 lines over 6 files
(`L54/raw/l55/cubecl-0.10-min-cubes-per-sm.patch`); sm_75 warns and ignores. **Root cause of the
1-in-7 lottery: CubeCL places shared arrays in `HashSet` order, randomised per process** → a
deterministic order would also remove that A/B noise. Box 2.5 h.

## L52.2 Two-pass scan: review fixes and the AVX-512 path executed on a Zen 5 host (2026-11-08; `L52/REVIEW.md`, `L52/PR-RESULTS.md` "Review follow-up", `L52/raw/avx512/`; head 1cce00d = one commit on #248)

Review (all seven planted bugs caught by the new test; portable + AVX2 correct by test, AVX-512
correct by reading only): fixes — AVX-512 taken only with `avx2` too (pass 1 uses a VEX
`vpbroadcastw`); the false "two pieces" coverage claim removed and a `piece` field (1024 outside
tests) lets `every_scan_finds_the_same_pairs` cross piece boundaries (suite also run once with
the constant at 9); `the_bit_tables_list_every_byte` over all 256 bytes; `debug_assert` on
`pass1`'s length contract; commit message/body corrections. Tests on ivory at 1cce00d: 190 + 22,
`NICE_TEST_CPU_JOIN_REF=3`, whole b42; fmt; clippy; sanity A/B ×1.21–1.29 (runtime piece length
costs nothing). **AVX-512 host: Vast 59703250, AMD Ryzen 9 9950X (Zen 5), ~15.4-core container
($0.43/h, 1.3 h):** avx512f + avx2 detected; the pass-1 test ran all three paths (84,860 bottoms
listed alike); the whole `cpu_join` suite (15), 190 + 22, `NICE_TEST_CPU_JOIN_REF=3`, whole b42
(same counts as ivory) all pass; three binaries (#248's old AVX-512 loop, the PR, the PR with
AVX-512 switched off) give identical counts everywhere (b60 1e14 1,326,103,590 / 84,383,498);
**speed over #248 on Zen 5: b60 1e16 ×1.232 (1 thread, 6 rounds) / ×1.225 (8 threads); b62 1e17
slice 0 ×1.238 / ×1.216** (beats the ×1.08–1.15 AVX-512 estimate; the new AVX-512 pass 1 is within
noise of the new AVX2 pass 1 there, ×0.95–1.04; box noise ±8 %). CI runners' AVX-512 support
still unknown. PR-ready, held at the cap.

## L52.1 CPU two-pass AND scan: PR branch (2026-11-08, agent; `L52/PR-RESULTS.md`, `L52/PR-BODY.md`, `L52/raw/`; `pr/cpu-join-two-pass-scan` cd661b0 = one commit on #248 7f5260b; worktree `.worktrees/l52-two-pass-scan`)

All three scan paths run two passes over pieces of ≤ 1024 bottoms: pass 1 makes a byte of pass
bits per 8 bottoms (`vptestnmq` / AVX2 compare + movemask / 8 scalar tests) and a shared `emit`
stores the set-bit positions as u16 indices from a 256-entry table, advancing by a 256-entry
count table (no branch on the bits; the last 0–7 bottoms stored always); pass 2 runs `survivor`
(`#[inline(always)]`) on the listed bottoms in original order; the full check stays out of line;
bounds-checked slice writes, no new `unsafe`, no knobs. New test
`the_first_pass_lists_the_same_bottoms_on_every_path` (114 class lengths ≤ 1024 at 0/1/40/100 %
passing + 1025–5120 through each path's dispatch). **A/B vs #248 (ivory Zen 2, 3 interleaved
rounds, loads ≤ 2; 1 / 4 threads):** b60 1e16 ×1.266 (2225 → 1758 ms) / ×1.260; b62 1e17 slice 0
×1.237 / ×1.237; b58 1e15 ×1.300 / ×1.316; whole b60 1e14 ×1.100 / ×1.104, b62 ×1.079 / ×1.083, b64
×1.162 / ×1.182; every production-shape round ×1.22–1.28. **NiceMark CPU 4 rounds ×1.261 (864.9 →
1091.0)**, rounds 1.22–1.28. perf (1 thread): branch misses 61.3 M → 25.3 M (b60) / 58.4 → 21.7 M
(b62); IPC 2.18 → 2.81; instructions +3–4 %; cycles −19–20 %. Exact: every run = #248's counts
(1e14 b60/b62/b64 incl.); tests 189 + 22; `NICE_TEST_CPU_JOIN_REF=3`; whole b42; the three-path
comparison incl. a b57 window with classes split into two pieces. **AVX-512 pass 1 compiled and
its assembly read (AVX-512F/AVX2 only) but never executed** (no AVX-512 host; CI runner CPU
unknown); the path is still selected on `avx512f` alone although pass 1 now uses an AVX2
instruction — detection should require avx2 too (reviewer). → reviewer; held at the cap.

## L51.1 Full stack d813aea profiled, ablated, retuned (2026-11-08, agent; `L51/RESULTS.md`, `L51/raw/` (logs, PTX-replay records, SASS, `analyze51.py`); branch `exp/l51-profile` 14f87cd)

RTX 3080 180 W on m139246 (L47's host too): d813aea = 79.10 s per b62 1e17 field, 15.85 s per b60
1e16 (L48.2's machine 73.4 s); exact counts throughout. **Phase split (b62 / b60):** FD top kernel
22.8 % (18.0 s) / 18.4 %; bucket 2.5 / 2.3; **join 55.9 % (44.2 s) / 59.0 %**; **check 12.0 % (9.5 s) /
14.4 %**; other 6.7 / 6.0 (**slice setup 4.8 / 4.5**). Profiled field 0.966× / 0.977× the unprofiled
in time (syncs let the card run 104 MHz faster at b62). **Join ablation (3 profiled rounds, % of
field):** base 10.9 / 10.5 (#249 took it from 15.9); **AND 14.9 / 15.0** (8.4 → 11.4 s; issue-bound by
instruction count); walk 9.2 / 9.0; prefilter 19.8 / 23.5; stage 1.1 / 0.9; the per-top AND
everywhere would cost ×1.14 / ×1.12. **Retune (2 interleaved rounds, each value its own kernel):**
EPT 1 ×0.949 / 0.948, EPT 3 ×0.939 / 0.951; TRANSPOSE_MIN 128 ×1.005 / 1.007, 256 ×0.985 / 0.984, 512
×0.873 / 0.908; AND_GROUP 2 ×0.946 / 0.953, 8 ×0.990 / 0.986 (4 cubes/SM); TOP_CAP 128 ×0.962 /
0.961, 512 ×0.935 / 0.945 (3 cubes/SM); FD cube 128 ×0.991 / 0.994, 512 ×0.994 / 0.998; stage once
per work item ×0.995 / 1.005; SURV_FLUSH 256 ×0.999 / 1.005, 768 ×0.996 / 1.008 → **no retune
reaches 3 %; defaults stay** (default scatter ~3 % within a block). **Two findings:** (1) **#249's
`sorted_layer` host counting sort runs inside the per-slice setup on the device thread with the
GPU idle: 2.55–2.84 s per b62 field (3.2–3.6 %), 0.44–0.46 s per b60 (2.8–2.9 %); ~7 u64 divisions
per prefix** → move into the overlapped field setup or do it in u32: ×1.03–1.04 / ×1.03 (host-only,
exact). (2) **~1 in 7 `join_kernel` compiles (5 of 32) picks a 40-register spilling variant worth
~3 % of the field (×0.968 / ×0.972 pinned)**; `.minnctapersm 5` or `.maxnreg 48` in the PTX gives 44
registers, no spill, ×0.992–1.003 of the normal 46–48-register code → ~0.4 % fleet-wide, 3 % for
affected processes; **A/B method: record each process's join-kernel variant (`ptxjit.py`) or pin
the compiled code** (every spill-variant process in this screen was re-run). **Re-pricing (no-go):**
L44 §3a fewer AND digits ×0.92–0.97; §3f digit-major LDS.128 ≤ 1 % (bank conflicts); L40 group walk
on the 41-instruction round 1.3–3.0 % / 2.2–4.0 % at best with its NiceMark loss and 4 cubes/SM;
COMPACT=2 ≤ 0.5 %. **AND codegen (go, no GPU needed):** the AND runs at ~2× its shared-memory floor,
52–60 % instruction overhead (7.8–9.0 % of the field in cycles); 8 of its 30 instructions per digit
are unfolded address arithmetic from CubeCL's index construction → folding ≈ 4.3 % of the field in
cycles (2.1–3.6 % time), with a leaner bit loop 3.0–5.1 %. **Ranked ≥ 3 %:** check kernel (L47,
done), `sorted_layer` off the device thread, AND codegen; below: the spill-variant fix (~0.4 %),
TRANSPOSE_MIN 128 (+0.5–0.7 %). Box 3.5 h.

## L47.1 Check kernel design D: built, exact, at the memory floor (2026-11-08, agent; `L47/RESULTS.md`, `L47/PR-BODY.md`, `L47/raw/`; `pr/check-d` 0f3332d = one commit on d813aea; knobs on `exp/check-d` 1187527c)

**Step 0 (old kernel, profiled, 2 rounds):** loads-only check (list entry + record words 0, 1, 6) =
3.36 s per b62 1e17 field / 0.76 s per b60 1e16 field = 0.745 TB/s = 98 % of the 3080's DRAM
bandwidth (< the 4.5 s build line); old kernel 8.79 / 2.13 s; cube sweep: 2048 cubes −3.7 / −3.8 %,
one exact wave (408) +2.8 / +1.6 % → the wave tail is ~4 %, not 6–16 %. **Kernel (driver JIT of
NVRTC PTX):** 39–40 registers in all 24 A/B processes (gate ≤ 48), no spills, no local, no shared;
330 instructions per warp-iteration on the b62 common path (gate ≤ ~360; +249 for the rest of n³
past the gate; b60 312, b64 306, b57 302); check 3.19 / 0.74 s = at the gather floor (×2.8 / ×2.9
vs the old kernel); gate width g = 8/10/12 flat ±2 % (memory-bound) → ships g = 10; one entry per
lane per take beat 4 and 8 by ~7 % (39 regs → 6 cubes/SM vs 5). **New device tests**
`cubecl_{,cuda_}check_counts_match_the_cpu`: per survivor the distinct-digit count, the gate
result and the digit mask vs the CPU (count mode) + every n rebuilt from its limbs (probe mode):
1,413,630 real list entries + 96,042 synthetic adversarial/random n over 26 field shapes, 3,599
past the gate; same totals on CUDA, lavapipe naga, lavapipe SPIR-V, and on the final head; host
tests for the new `join_check` module incl. an exhaustive check of all 114 divisors over every
x < 2³¹. **A/B vs d813aea (3 interleaved rounds):** b62 1e17 74.65 → 68.64 s **×1.088**
(1.077/1.086/1.107; cycles ×1.099; same median clock 1440 MHz at 179.6 W), **b60 1e16 15.20 →
13.52 s ×1.124** (1.137/1.105/1.124; ×1.140), b62 1e16 ×1.085, b64 ×1.070, 1e14 b57/60/62/64
×1.078/1.046/1.015/1.003; **NiceMark 6 rounds ×1.056** (1.050–1.066; b58 weak ×1.077, strong
×1.039, b60 ×1.060, b62 ×1.060). Exact: 1e14 COMPARE join = stride same counts; `check_all` incl.
b10's [69]; whole b42 417,789,835 / 16,879,877 join = stride = reference; dense fields; #249's
sentinel FD-vs-top test; certificate test; identical counts in every timed run and all 12
NiceMark runs; lint 14/0. The PR drops CI's `--require CheckKernel@57` (that requirement needs a
constant division in the kernel; the new kernel has no `/` or `%`). Final head 5be672c-equivalent
= timed tree + fmt/clippy/comments, re-verified. Next lever: the check is load-bound; carrying P in
the survivor list ≤ ~2 % of the field (not tried). Box 2 h. → reviewer; held at the PR cap (second
PR-ready branch on the GPU chain after FD round 2).

## L48.2 FD top kernel round 2 on #249: review fixes, wave64 gate, CUDA-scoped batches, combination A/B (2026-11-07, agent; `L48/REVIEW.md`, `L48/RESULTS.md` "Round 2", `L48/raw/r2/`; `pr/top-fd-round2` d813aea = one commit on #249's 87958fd; held at the PR cap)

Review (merge with small fixes; kernel changes exact by re-derivation + a host model): M1 the
ballot append keeps only 32 bits on CubeCL's C++ backends (wave64 CDNA via opt-in cubecl-hip
would miscount) → comptime `ballot = plane_size_max <= 32` from `client.properties().hardware`,
#249's `top_slot` uses the ballot's first word when on, the two plane scans otherwise (gate
forced off on CUDA: device test passes); M2 real memory rises to the budget at 1e16+ (b60 1e16
1.6 → 2.5 GiB; on wgpu the binding-limit budget would give 2.6 → 3.9 GiB even on small cards) →
`JoinLimits.vram_budget` set only by the CUDA runtime; `SURV_PER_PREFIX_VRAM = 1` only on CUDA and
only on fields the FD kernel certifies (`top_fd_runs`); wgpu, power-of-two bases and all slices
keep 2 (`SLICE_SURV_PER_PREFIX` gone); layout +31–64 % at 1e16+ on CUDA, stated; host tests pin
the gate, the plan (same slice cuts, more slots; b64 identical) and the two b20 windows that
re-form the carried c0 (P = 201 square, P = 231 cube — the only coverage of that path; timed
fields never cross a c0 change). L3 headroom halved (overflow above 2.0–2.1 survivors per prefix,
was 4.5–4.7; re-run path unchanged) documented. **Plan (10 GB, budget 2,469 MiB):** b62 1e17 11
slices identical, first-slice slots 5 → 11, 1,463 → 2,393 MiB, batches 6,439 → 3,288; b60 1e16 2
slices identical, slots 4 → 9, batches 1,350 → 625; no overflow re-runs. **A/B vs 87958fd (180 W,
3 interleaved rounds): b62 1e17 ×1.127 (1.123/1.108/1.127; 82.80 → 73.44 s; cycles ×1.140), b60
1e16 ×1.112 (1.136/1.108/1.112; 16.43 → 14.77 s), b62 1e16 ×1.129, b64 ×0.991–1.005 (#249's
kernels and plan exactly; scatter), 1e14 ×0.978–1.059 (same plans); NiceMark 6 rounds ×1.032
(b58 weak ×1.022, strong ×1.009 (lowest round ×0.972), b60 window ×1.052 still 2 slices with 5 →
10 a launch, b62 ×1.055).** Kernel alone: FD 0.2070 → 0.1371 ns per (prefix, slot) (−33.8 %) /
0.2061 → 0.1358 (−34.1 %); stepped slot −30.4 / −31.6 %. Registers 108 / 107 (#249: 112 / 108),
SASS 4,360 / 4,176, no spills, 2 blocks/SM; SPIR-V blocks 278–296. Exact on the combination:
#249's sentinel FD-vs-top test (423.1 M tops; pushed code 375.9 M; gate off too), parity,
certificate test, dense (b62 at 11 a launch, 0 re-runs), whole b42, 1e14 COMPARE, every timed
field; lavapipe naga + SPIR-V 8/8; lint 14/0; fmt/clippy ×3. Box 180 W, ~2 h.

## L48.1 FD top kernel round 2: ×1.082 at b62 1e17, PR-ready (2026-11-07, agent; `L48/RESULTS.md`, `L48/PR-BODY.md`, `L48/raw/` (box logs, scripts, patches, bundle); `pr/top-fd-round2` bedc658 = one commit on f3fb390; switchable `exp/top-fd-round2` f168b28, levels 1–7 and 103)

Box at **170 W** (default 320). Levels: 1 = L36.2's three trims, 2 = +ballot append (f3fb390's
append was `plane_sum` + `plane_exclusive_sum` + atomic + broadcast, not "one ballot + one atomic"
as L44 said; level 2: 7 SHFL → 2, +2 VOTE), 3 = +partial x mod b^c0 (**slower** than 2: SASS
4,936, SPIR-V blocks 355–391 > TopKernel at b64), 4 = +SURV_PER_PREFIX 1, 5 = +early-exit carries,
6 = 5 without 3, 7 = 4 without 3. **PR ships level 6** (trims + ballot + early-exit carries +
SURV_PER_PREFIX 1) **with a separate `SLICE_SURV_PER_PREFIX = 2`**: the first PR form also cut
slices and **failed the kill rule** (NiceMark b60 ×0.976 in all six rounds: its window went 2 → 1
slices, a wider slice prunes less at the field certificate, +2.6 % per partition); keeping slices
fixed it and the fields came out slightly faster. Registers/SASS (NVRTC→JIT = nvcc): base 110 /
3,888 (b62), PR 108 / 4,472; 0 spills, 2 blocks of 256 per SM at every level; SPIR-V blocks base
298–310 → PR 280–298. Kernel-alone ns per stepped slot (b62 / b60): L0 0.2045 / 0.2021; L1 0.1554 /
0.1537 (−24 %); L2 0.1454 / 0.1444 (−29 %); L6 0.1424 / 0.1493; base vs PR binary in production
batches: FD kernel 0.2424 → 0.1678 ns (−30.8 %) / 0.2447 → 0.1644 (−32.8 %). Screen vs L0 (b62 /
b60): L1 ×1.041 / 1.031; L2 ×1.047 / 1.043; L3 ×1.044 / 1.039; L4 ×1.063 / 1.059; L6 ≈ L4 + 0.6 %.
**A/B PR vs f3fb390 (3 interleaved rounds; NiceMark 6): b62 1e17 ×1.082 (1.076/1.083/1.086;
107.90 → 99.76 s; cycles ×1.111), b60 1e16 ×1.070 (1.068/1.075/1.070; 21.32 → 19.92 s; cycles
×1.054), b62 1e16 ×1.093 (×1.197), b64 ×0.997 neutral (FD off; plan 6 → 7 a launch), 1e14
×1.028/1.034/1.014; NiceMark ×1.029 (b58 weak ×1.018, strong ×1.036 (lowest round ×1.003), b60
×1.034, b62 ×1.033; NiceMark seeds every slot, so it sees only the ballot, the carry test and the
larger batches).** PR side 50–100 MHz slower at the cap on b62. Plans (10 GB, 2,560 MiB): b62 1e17
5 slots / 1,670 MiB / 6,439 batches → PR 9 / 2,457 / 4,009; b60 1e16 4 / 1,566 / 1,350 → 8 / 2,431 /
675; memory and binding bounds now bind first; measured 0.53 survivors per prefix and partition vs
1 assumed; no overflow re-runs. **Exact everywhere** (CUDA full list at levels 1–4 and both PR
forms; levels 5–7/103 the device test; every timed field; lavapipe naga + SPIR-V; lint 16/0;
fmt/clippy ×3). Conflicts with L46/#249 only in the append block (destination untouched → should
rebase cleanly). Box 3.3 h. **Held at the PR cap (5 open); reviewer launched.**

## L49.2 CPU fixed-point prefilter: review fixes and PR #248 (2026-11-07; `L49/REVIEW.md`, `L49/PR-RESULTS.md` "Review follow-up", `L49/raw/*-v2.txt`, `raw/m2/`; PR #248 head 7f5260b = one commit on #247 caef70e)

Review (tests run incl. FX exhaustive 6.63e11 triples, 306 s): merge with small fixes, no defect.
Fixes: `dm` dropped from `Top` (64 → 48 bytes; `const _: () = assert!(size_of::<Top>() == 48)`;
`prefilter_any` recomputes D from `top.p`) — the sort share back to #247's (1.39 % / 1.27 % vs 1.84 /
1.57 at 64 B); sanity A/B on the new head (4 threads, 4 rounds, two loaded rounds discarded):
b60 1e16 2642 → 2298 ms (×1.15), b62 1e17 slice 0 2474 → 2234 ms (×1.107), counts identical;
`survivor` share 21.9 / 22.8 % → 14.5 %. **M2: no test window with unseeded stepped tops can
exist** (every full block seeds: e² − a² ≥ b^(L+f0−1) → floor ≥ L + f0 ≥ k + 2; unseeded tops are
only clipped blocks < ~b/2 numbers at a field's end; search of every b20 4-digit window start
found none); the stepping test now asserts `full_floor ≥ k2` and the body states the coverage.
Dispatch `lean: mid == 2 && k > mid` with the matching assertion; docs/nits applied; title
"fixed-point". Tests 188 + 22, fmt, clippy, `NICE_TEST_CPU_JOIN_REF=3`, whole b42 all pass. **PR
#248 opened 09:00 UTC.** Open program PRs: #241, #246 (on #241), #247, #248 (on #247).

## L46.1 Static bucket order for the top layer: built, exact, ×1.158 at b62 1e17 (2026-11-07, agent; `L46/DESIGN.md`, `L46/RESULTS.md`, `L46/PR-BODY.md`, `L46/raw/`; branches `exp/join-static-buckets` b058bb7 (6 commits), PR-ready squash `pr/join-static-buckets` 318fdae (one commit on f3fb390), rider `exp/join-static-buckets-s15` 4b27507)

Design: a slot's top lands in bucket (key, (root − pc) mod (b−1)) with pc = (c0 + v) mod (b−1), c0 =
P0 mod (b−1) (b^p ≡ 1), so the slot only rotates the class; the host counting-sorts each slice's
top layer once by g = key·(b−1) + c0 and uploads `goff` (nb + 1 words); tlay words 2–3 carry g and
goff[g]; the top kernels append each kept top into its group's segment of `top_rec` with one
counter per (slot, group) (`top_slot` helper: one atomic per plane in `top_fd_kernel`, one per top
in `top_kernel`); a join work item w = slot·nb + bucket reads `nroots` segments g_r = (key,
(root_r − cls − v) mod (b−1)) with consecutive record loads (batches still fill 256 tops across
segment boundaries); **deleted: `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`, `work`,
`cursor`, the per-slot count and the per-kept-top `nroots` atomics; STAGES 6 → 4; layouts 11–29 %
smaller; slots/slices/batches unchanged.** `nroots` is comptime in the join (runtime loops → 60
registers or spills); a serial thread-0 scan places the segments (plane-size independent); the
work item's offsets/count/key live in shared memory. **Exact on the final tree** (= base and L38's
lists): parity incl. b50/b54 + b57 frontier; adapted FD-vs-top device test (per-(slot, group)
counts and segment records; 26 fields / 279 batches / 237.9 M tops); certificate test; dense
254,938,965 / 14,396,829 and 120,013,475 / 7,355,827; whole b42 417,789,835 / 16,879,877; 1e14
COMPARE; every timed field every round (b62 1e17 1,020,844,021,499 / 62,584,252,554 …); lavapipe
naga + SPIR-V 8/8; lint 14 shaders 0 flagged; fmt/clippy ×3. Registers (driver JIT of each
process's NVRTC PTX): join 46–48 spill-free in 30/37 processes incl. all 12 timed production
fields (the other 7, 1e14 and register samples: 40 + 8–32 B spills in per-item/per-wave code, no
slowdown); top_fd 108–112; top_kernel 80 → 97–103 no spills (no measurable cost); 5 cubes/SM.
**A/B vs f3fb390 (180 W RTX 3080 m139246, 3 interleaved rounds, equal clocks): b62 1e17 100.38 →
86.68 s ×1.158 (rounds 1.141/1.158/1.158; cycles ×1.174); b62 1e16 ×1.147; b60 1e16 19.675 →
17.049 ×1.154 (cycles ×1.150); b64 1e16 ×1.222; 1e14 b57/60/62/64 ×1.096/1.056/1.055/1.028;
NiceMark 6 rounds ×1.119 (1.103–1.138): b58 weak ×1.145, strong ×1.043, b60 ×1.153, b62 ×1.145.**
Beats L45's ×1.107 ceiling: scan + fill = 9.7 of the 13.7 s saved, the rest the FD kernel's lost
atomics (FD kernel alone ×1.054–1.060) and the join's consecutive record loads. **Rider (stage
checked once per top batch) vs this branch: b62 1e17 ×1.029, b62 1e16 ×1.024, b60 ×1.022, b64
×1.030, NiceMark (2 rounds) ×1.019; exact, lavapipe + lint pass; not in the PR branch yet.**
Conflicts with L48's level-2 append trim (same block; whichever lands second redoes it). Box
2.75 h. → reviewer agent on 318fdae + the rider.

## L49.1 CPU lean prefilter: PR branch (2026-11-07, agent; `L49/PR-RESULTS.md`, `L49/PR-BODY.md`, `L49/raw/`; branch `pr/cpu-join-lean-prefilter` d32f579 = one commit on #247 caef70e; worktree `.worktrees/pr-cpu-join-lean`)

`cpu_join.rs` +329/−41 (~200 lines tests): private `Fx` type (own constants) for the digits; `fresh4`
membership by shifts + six compares joined with `&` (branch-free; masks keep digit d at bit d —
x86 shifts need no reversal); `Top.seed` → gated `Top.gmask` + `Top.dh` (Top 48 → 64 B). The
fixed-point path is the only path for mid = 2 and k > mid (all production shapes); k ≤ mid (b10,
one b20 window) keeps the division form; old `prefilter` body, `smid`, `SmallDiv::rem` removed.
**A/B vs #247 (ivory Zen 2, 3 interleaved rounds, loads ≤ 2.0; 1 / 4 threads):** b60 1e16
partitions ×1.091 / ×1.076; b62 1e17 slice-0 partitions ×1.067 / ×1.106; whole b60 1e14 ×1.051 /
×1.056; b62 1e14 ×1.047 / ×1.064; b64 1e14 ×1.119 / ×1.109. **NiceMark CPU (4 rounds): 798.5 →
868.5 = ×1.088** (rounds 1.069–1.104): b58 weak ×1.097 (1 thread ×1.093), b58 strong ×1.053, b60
×1.113, b62 ×1.074. perf: `survivor` (range test + prefilter) 22.9 % of #247's join → 14.7–15.1 %
(×1.7 cheaper). Exact: every run = #247's counts (b60/b62/b64 1e14 fields; sampled production
partitions); whole b42; `NICE_TEST_CPU_JOIN_REF=3`; FX exhaustive over 6.63e11 triples (299 s on 4
threads). Tests in the PR: `fx_digits_match_the_division` (CI-sized, 4.46e8 triples),
`fx_digits_are_exact_everywhere` (opt-in `NICE_TEST_FX_EXHAUSTIVE=1`), `lean_membership_matches_
the_masks`, `lean_prefilter_matches_the_division_form` (1e6 pairs per base), `production_shapes_
take_the_fixed_point_prefilter`; stepped-vs-divided tops test now compares `dh`/`gmask`; 188 + 22
pass; fmt; default clippy. Caveats: Zen 2 only; RC's ×1.00 is the old L42 number. → reviewer.

## L45.1 Measurement session on #246: top-phase split, lean-join ablation, stage cadence, spills (2026-11-06, agent; `L45/RESULTS.md`, `L45/raw/` (logs, per-process kernel classification, SASS, CUDA, PTX; `analyze45.py`); branch `exp/join-l45-measure` 8a07c05 on f3fb390)

RTX 3080 180 W (m139250); unprofiled field 100.23 s (b62 1e17) / 19.63 s per field (b60 1e16);
every full-kernel run = the exact counts. **A. Top phase (3 profiled runs, medians):** FD kernel
25.23 s = 25.2 % (b60 4.12 s = 21.0 %); clipped launches 0.0 %; `top_scan_kernel` 1.06 s = 1.06 %
(0.21 s); **`top_fill_kernel` 8.63 s = 8.61 % (1.56 s = 7.96 %); scan + fill 9.7 % / 9.0 %** =
0.254 / 0.257 ns per kept top (L31's 0.22–0.26). Profiled vs unprofiled +0.6 % / +2.0 %; one empty
profile mark = 12 µs per batch. Check kernel 9.1 % / 11.3 % (L44 derived 9.5 / 11.4). **B. Lean-join
ablation (3 interleaved profiled rounds, % of field):** base 15.9 / 15.4; **AND 8.3 / 8.3 (not
L44's 1.1 %: #241's top record removed the latency that hid it)**; walk 6.4 / 7.0; prefilter 16.1 /
19.2; stage + flush 1.3 / 1.9; join 48.2 s / 10.2 s. Per-top AND everywhere (TMIN 2^30) costs
×1.094 / ×1.075 (#239 still pays). **Stage cadence (unprofiled A/B, 3 rounds vs every chunk):**
every 8 chunks ×1.022 b62 / ×1.020 b60; once per top batch ×1.020 / ×1.023 (rounds 1.018–1.033;
cycles ×1.03–1.05); every 4 chunks ≈ two thirds of that; all exact, the stage never fills even once
per batch (0 spilled pairs in 6 runs) → barrier waits are ~2.5 s of L44's 23 s unattributed, not
most. **Spills: none in production** — 100 runtime NVRTC→driver JIT compiles gave 47–48 registers,
no spills; L41's 40 + 28 B came from nvcc's offline compile. Pinned-image timing (3 rounds): nvcc's
spill build 1.7–2.9 % slower in the join (1.4–1.5 % of field) than nvcc's spill-free
`__launch_bounds__(256,5)` build; the runtime compile 3.4–3.5 % slower in the join (1.7 % of field)
than that — the gap is NVRTC's PTX, not the JIT; nvcc's PTX only wins with the 5-cube launch bound.
**Verdicts: item 1 (scan + fill < 5 %) not fired → L46 builds (ceiling ×1.107 / ×1.099 if scan +
fill vanish); item 5 no build** (cadence ~2 %, compile path ~1.7 %, spills 0) — once-per-batch
stage check is an exact rider for the next join PR; the AND at 8 % of the field says re-price
L44 §3a/§3f's AND ideas. Box 2.7 h.

## L42.3 CPU FD top certificates: review fixes, b64, PR #247 (2026-11-06, agent + director; `L42/REVIEW.md`, `L42/PR-RESULTS.md`, `L42/raw/pr/`; PR #247 head caef70e = one commit on main 6f060a9)

Review (independent, with tests run): merge with small fixes, no defect; the f64 carry screen's
error ~4e-12 vs margin 2⁻²⁰, 20.7 M adversarial boundary calls agree; step/word counts bounded at
the slice's last prefix. Fixes applied: the missing carry test
(`a_carry_runs_through_words_of_b_minus_1`; fails under both surviving mutations M1 ripple / M4
`cin`, passes on the branch; `L42/raw/pr/mutation-s1.txt`); rustdoc link, test-only derives,
private `MAX_STEPS`/`poww` accessor, `step_by(..max(1))` guard; body: 3e15 NiceMark window, #240's
×1.48–1.61, "413,250 kept; 243,907 seeded", round loads stated, overshoot path (steps once past P
then re-seeds; values below phi + h still fit). **b64 A/B vs main (3 rounds, loads ≤ 2.0): b64 1e16
partitions ×1.039 (1 thread) / ×1.068 (4); b64 1e14 whole field ×1.076 (359.0 → 333.7 s) / ×1.088
(96.1 → 88.3 s); counts identical (5,702,041,796 / 346,647,759).** b64 gains less than b60/b62
(×1.25–1.29): ~2.8× the survivors per partition and 9–10 % of prefixes seeding vs 2.3 % (not
profiled); the CPU takes the stepped path at b64 (unlike #240's GPU kernel) because `Base::cert`
divides by a runtime base at every base. Tests 184 + 22; `cargo doc` 7 warnings = main's 7. The
agent's permission guard refused the amend → two commits; the director squashed them (tree
identical) and opened **PR #247** at 10:25 UTC. Open program PRs: #241, #246 (on #241), #247.

## L41.1 Lean `walk_pf` (FX + MT + GM + RC): PR branch, ×1.086 at b62 1e17 (2026-11-06, agent; `L41/RESULTS.md`, `L41/PR-BODY.md`, `L41/raw/`; branch `pr/join-lean-prefilter` d672887 = one commit on 7832f89 (#241); prototype `exp/join-lean-pf` a150b49 (knob `NICE_EXP_JOIN_PF`), variant `exp/join-lean-pf-cwcopy` d5db28b)

Host tests: FX exhaustive over every (A, P, D) < b² at every base 10–64 = 6.63e11 triples, all
exact (190 s on 9 threads; ignored + `NICE_TEST_FX_EXHAUSTIVE=1` since CI runs ignored tests); in
CI: constants and `dh` vs exact ceilings for every D < b², the Δ < 2³² bound, digits for every
(P, D) at max A and every (A, D) at max P; MT vs the old four-mask test for every digit 4-tuple at
every base (2.1e8) + 1e7 random; end-to-end lean vs division form on 1e6 random pairs per base
(4.4 s release). SASS of the round before the stage at b62, predicted → actual: L0 71/71, L1 56/59,
L2 48/51, L3 45/47, L4 39/41 (ALU 45 → 35 → 28 → 24 → 21; b60 69 → 41, b64 64 → 43). MT as
specified did not shrink (NVVM split `(hit & 1)` on right shifts into four 64-bit compares →
level 2 at 60); fixed by holding every digit mask bit-reversed and testing the sign bit of
`hi32(seen << g)`, one funnel shift per digit. The residual +2 per level is a ptxas fallback (from
L1 on it stops proving convergence at the walk's vote/plane barrier: +3 issued per round; cause
not found). Registers 40 → 45 at b60/b62 (45–47 b64), ≤ 48, 5 cubes/SM kept; **some compiles of
the same kernel land on 40 registers with 28–44 B spills** (CubeCL's dynamic shared array hides the
5-cube limit, ptxas aims for 6; which compile spills depends on CubeCL's shared-array order per
process; spilled values are per work item/batch, never in the walk; A/B rounds agree to 0.1–0.6 %).
Exact (levels 3 and 4, timed binary and head): parity incl. b50/b54 + b57 frontier, #240's device
test, certificate test, dense fields, whole b42, 1e14 COMPARE, every screen/A/B field = the exact
counts; lavapipe naga + SPIR-V 8/8; lint 16/0 (JoinKernel b57 constant divisions 36 → 26); fmt,
clippy ×3. RC's clipped path covered by the CPU-reference small windows (a mutant without the range
test fails at b20 [58945,160000) and adds 26 / 5 survivors at b57 / b62 1e14). **Screen (2 rounds,
time / cycles):** L1 ×1.028 / 1.038 b62 1e17, ×1.037 / 1.063 b60; L2 ×1.055 / 1.077, ×1.076 /
1.087; L3 ×1.067 / 1.078, ×1.093 / 1.120; L4 ×1.075 / 1.097, ×1.111 / 1.143; plane-rounds
unchanged (+0.003–0.008 %). **A/B vs 7832f89 (180 W, 3 interleaved rounds): b62 1e17 ×1.086
(109.0 → 100.4 s; cycles ×1.103), b62 1e16 ×1.086 (×1.075), b60 1e16 ×1.122 (×1.126), b64 ×1.070
(×1.104), 1e14 ×1.027/1.017/1.006/0.997 (noise); NiceMark 6 rounds ×1.061 (rounds 1.056–1.063):
b58 weak ×1.070, b58 strong ×1.041 (lowest round ×1.007), b60 ×1.058, b62 ×1.068.** The leaner
round draws more power per cycle: the PR side ran 29–48 MHz slower at the cap (opposite of the
scoping's guess). Not taken: clip words copied to plain shared once per batch (×1.003 / ×1.012,
noise). Box 59373929 destroyed (~4.7 h). → reviewer agent before the PR.

## L42.2 CPU FD top certificates: PR branch (2026-11-06, agent; `L42/PR-RESULTS.md`, `L42/PR-BODY.md`, `L42/raw/pr/`; branch `pr/cpu-join-fd-tops` fba5431 = one commit on main 6f060a9; worktree `.worktrees/pr-cpu-join-fd`)

New `common/src/cpu_top_fd.rs`: five packed digit-array additions per step with trimmed word
counts (14 word adds per step at b60/b62 vs the prototype's 21); seed on a key's first prefix,
after a gap > 4h, or when a walk does not land on P; the seed converts P, P², P³ without a
hardware divide and builds the three difference arrays by shifts/additions; carry test = f64
screen + exact fallback; digit count from a bit-length table; kept tops step `pc`/`dm` by one (no
u128 division except at seeds). `CpuJoin::tops`: unclipped blocks always stepped; clipped blocks
and non-fitting fields keep `Base::cert`. No knobs. **A/B vs main on ivory (Zen 2, AVX2; 3
interleaved rounds, loads ≤ 2):** b60 1e16 partitions ×1.274 (1 thread) / ×1.289 (4); b62 1e17
slice-0 partitions ×1.264 / ×1.246; b60 1e14 whole field ×1.224 / ×1.224; b62 1e14 ×1.155 /
×1.163; counts identical every run (b60 1e14 1,326,103,590 / 84,383,498; b62 1e14 1,470,093,637 /
87,495,922). **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.186 (673.2 → 798.7)**;
b58 weak ×1.141 (1 thread ×1.142), b58 strong ×1.099, b60 weak ×1.336, b62 weak ×1.241. Exact:
new random-run test bases 10–64 (1,860,723 stepped blocks, 243,907 seeds, gaps/backward/clipped:
certificate, `pc`, `dm` = `Base::cert`); new production-field test b42–b64 (3,698,847 tops
identical in order); `check_partitions` now compares tops (windows + opt-in reference,
`NICE_TEST_CPU_JOIN_REF=3`/`16` pass); whole b42 417,789,835 / 16,879,877; `cargo test --release`
183 + 22; fmt; default clippy. → reviewer agent before the PR.

## L43.1 Per-wave base trims: ×1.017 at b62 1e17 → parked (2026-11-06, agent; `L43/RESULTS.md`, `L43/raw/`; branch `exp/join-wave-base` 0e1ba4e on 7832f89, bitmask `NICE_EXP_JOIN_WB`: 1 TT shuffle transpose, 16 TT2 cheaper transpose stage, 2 WH wave-load hoist, 4 AU fixed-trip AND loop, 8 PC `pc` from the bucket kernel)

Screen (one binary, 2 interleaved rounds; time ratio (cycles)): TT ×1.012 (1.026) b62 1e17 /
×1.012 b60; TT2 ×1.013 / ×1.013; WH ×1.015 / ×1.023; **AU ×0.995 / ×1.000** (the AND is bound by
shared loads; cutting ALU there loses ~30 MHz at the cap); **PC ×0.993 / ×0.994** (swaps 16 ALU
instructions for a dependent global load on the latency-bound wave-load chain); all four ×1.018 /
×1.022; **TT2 + WH ×1.023 / ×1.026**. A/B of TT2 + WH vs 7832f89 (180 W, 3 rounds, NiceMark 4):
**b62 1e17 ×1.017** (108.26 → 106.43 s; rounds 1.011/1.024/1.019; cycles ×1.016), b62 1e16 ×1.022,
**b60 ×1.019**, b64 ×1.059 (a b64 split: TT2 ×1.017, WH ×1.013, pair ×1.039 — not investigated),
1e14 ×1.000 / 0.978 / 1.010 (noise), NiceMark ×1.024 (lowest scenario b58 MSD-strong ×0.998).
Against L41's estimates: TT at the top of its 0–1.7 s range (−1.3 to −1.4 s); WH −1.6 s vs −0.4 s
from instruction count (the list→entry latency L39 suspected is real). **Parked: below the 3 %
kill line.** Exact with all four on (WB=31) and with WB=15: parity incl. b50/b54, #240's device
test (237.9 M tops), certificate test, dense b58/b62, whole b42, 1e14 COMPARE, every timed
field = L38's counts; lavapipe naga + SPIR-V 7/7 (TT falls back on 8-lane subgroups); lint 16/0;
fmt/clippy ×3. AU's invariant (every listed entry's mask has exactly 2k digits, key level or not)
holds by construction (§1). Registers: WB=0 40; 15/31 46; WH alone 47–48; AU 48; TT/TT2 40 +
12 B spills; **WB=19 40 + 8 B spills (the work-item index `w`)** — fails the no-spill gate as
written; AU fully unrolled took 64 registers (replaced). Direct SPIR-V JoinKernel 133–136 →
136–139 blocks. Box 2.9 h.

## L42.1 CPU join profile on ivory, and FD top certificates on the CPU (2026-11-06, agent; `L42/SCOPING.md`, `L42/raw/`; worktree `.worktrees/l42-cpu-join-prof`, scratch prototype `l42_fd.rs`, uncommitted)

Ivory = Zen 2 (EPYC Rome) VM, 4 vCPUs, AVX2 only (`scan_avx2`); ~25 idle CLI processes (load
0.5–1.2). Release build of `nice_client`, default features, no GPU deps: 2 min 09 s, 545 MB target.
Phase split (rdtsc counters on a scratch branch + `perf` + the pristine NiceMark run, score 665;
same within 0.3 points at 1 and 4 threads): **production shapes (b60 1e16, b62 1e16, b62 1e17
slices): top certificates 42–43 %, AND scan + survivors ~55 % (scan 28–29, prefilter 17–18, full
check 8–9), extend + lists ~1 %, sort ~1 %**; b60 1e14: 35 / 36 / 7+22 / 1; b62 1e14: 27 / 33 /
9+30 / 1. `Base::cert` + `divrem_w4` = 40.5 % of the join; 57 % of `Base::cert`'s samples sit on
two hardware `div`s in `digits_w` (per-digit `% b`, `/ b` with a runtime base). ~12 % of cycles are
branch mispredictions (survivor extraction, prefilter early exits). **FD top certificates:** `tops()`
visits a key's prefixes in ascending order within a partition → consecutive P differ by h = b³,
#240's five digit-array adds step in h; gaps ≤ 4 stepped, larger seed (2.3–4.7 % of slots).
Certificate alone ×1.6–1.8 vs `Base::cert`; **in place, whole partitions, interleaved 2 rounds: FD
×1.10–1.20 at production shapes (mean ×1.16) at 1 and 4 threads; FD + L41's lean prefilter
×1.23–1.29 (mean ×1.26).** Exact: FD cert = `Base::cert` on ~19 M slots (b60/62/64); whole b60 and
b62 1e14 fields with a per-slot self-check → identical survivor/checked counts; `cpu_join` tests,
the opt-in production-field reference test (b42–b64) and whole b42 (417,789,835 / 16,879,877) pass.
Point 4: the CPU join has #215's prune (`FieldSetup::fc`, `prune_bottoms`; cuts bottoms 43–65 %);
no transpose benefit (AND arithmetic 0.3 of ~2.3 cycles per AND; a bit-sliced version ≤ ~4 %);
the survivor prefilter is `walk_pf`'s arithmetic: FX+MT+GM port directly, ×1.05–1.08 alone, exact;
RC ×1.00 (drop). Caveat: Zen 3/4 (Anvil, demoux) divide faster → smaller share and gain there;
AVX-512 makes the scan cheaper → share back up. → PR agent launched (`L42/PR-BRIEF.md`).

## L40.1 Group walk over the AND group's 8 pass words: ×1.056 at b62 1e17 but b58 MSD-strong ×0.963 → parked (2026-11-05, agent; `L40/RESULTS.md`, `L40/raw/`; branch `pr/join-group-walk` f8a27cc = one commit on af21136 (#241) with a `#NNN` CHANGELOG line; variants `exp/join-group-walk-{p1,linear,f,h,h2,f2}`, counters `exp/join-rounds-base`, `exp/join-group-walk-rounds`)

Head kernel = H2 (first word picked before the walk). RTX 3080 at 150 W, 3 interleaved rounds vs
af21136: **b62 1e17 ×1.056** (1.058/1.054/1.058; clock-normalised ×1.120), b62 1e16 ×1.065
(×1.081), **b60 1e16 ×1.074** (×1.104), b64 ×1.050 (×1.059); **1e14 b57/60/62/64 ×0.955/0.970/
0.969/0.963**; NiceMark (6 rounds) ×1.030: MSD-weak b58 ×1.062, b60 ×1.045, b62 ×1.051, **MSD-strong
×0.963** → fails "no scenario < ×0.98". The PR side runs 40–60 MHz lower at the cap (more ALU work),
hence the higher clock-normalised ratios. Counters: rounds per group 23.97 → 15.48 (×0.65) at b62
1e17, 32.7 → 19–20 (×0.61) at b60; lane utilisation 24.9 → 38.5 % (23.5 → 38.5 %); less than the
predicted half because lanes are uneven (a plane runs 2.4× a lane's mean bits; Poisson would give
1.9×). Round body 139 SASS vs 110 (19 = the word pick, only when a lane needs a new word). The
residue test stays (clipped tops' ranges are invisible to the AND; it rejects a few pairs per field
at the edges). **Small batches (< 192 tops) save no rounds** (plane-rounds identical to the base at
b57/b62 1e14), so the extra body cost is pure loss there; variants: P (group walk everywhere) MSD-
strong ×0.959; F (base walk for small batches) 40 regs + 20 B spills, ×0.935; H (one chunk per pass)
×0.975 screen; H2 ×0.991 screen / ×0.963 A/B; F2 (L37's mode-2 loop for small batches) ×1.020
screen / ×0.964 over 6 A/B rounds, spills. MSD-strong swings ±4 % between sessions on one binary →
only A/B rounds count. Exact everywhere (parity incl. b50/b54, #240's device test, certificate test,
dense, b42, 1e14 COMPARE; lavapipe naga + SPIR-V 7 tests, no overflow; lint 16/0; fmt/clippy ×3;
P and F2 too). Registers 46–47, no spills (base 40); 5 cubes/SM (shared-bound). **Parked:** next
try = a higher gate for the group walk with MSD-strong measured over ≥ 6 rounds from the start, and
a SASS look at the work-item/wave code rather than the walk. Box 4.6 h.

## L39.1 One record per bottom entry: neutral, closed (2026-11-05, agent; `L39/RESULTS.md`, `L39/raw/`; branches on af21136: `pr/join-bottom-record` 08c9d90 (= F), `exp/join-bottom-record-r8` 746a1fc (E), `exp/join-bottom-record-r4` 72d1b85 (F), `exp/join-entry-sectors` c27c3ce (sector-count test))

E = 32-byte record per (slot, entry) with mask, q0, q1, r0 (+3 pad; `bp_r` leaves the join; +16 B
per slot-entry); F = 16-byte record (mask, q0, q1) beside `bp_r` (same bytes as before; r0 needs
18 bits and the 16 bytes have 10 free). **Sectors per entry measured on the production bucket
lists** (a warp's 32 lanes span ~1,000 class entries): base 2.50–2.54, E 1.00, F 1.71–1.73.
Screen E / F vs af21136 at b62 1e17 / b62 1e16 / b60 1e16: E ×0.982 / 0.999 / 0.995 (slightly
slower everywhere: doubled bytes), F ×0.997 / 1.015 / 1.004. **A/B of F vs af21136** (RTX 3080 at
its default 320 W, still `SW power cap` throttled; 3 interleaved rounds; both sides 1880–1892 MHz):
b62 1e17 ×0.997 (86.78 → 87.07 s), b62 1e16 ×1.004, b60 ×1.006, b64 ×1.003, 1e14 noise, NiceMark
×1.009 (no scenario < ×0.98). **Below the bar; closed.** Why: cutting the entry gather's sectors by
32 % (F) or 60 % (E) does not move field time, so in the full kernel the entry gather is not
sector-bound: the entry arrays are 9–14 MiB per launch and `bp_r` 0.4 MiB (the top arrays #241
fixed were ~250 MB each); L37's 10.5 s for "entry loads" came from a stripped kernel with an exposed
dependent load chain (list → entry) that the other cubes' AND/walk work hides in the full kernel.
**Lesson for the ablation method: a part's cost in a stripped kernel is an upper bound; latency-
bound parts shrink when the rest of the kernel is present.** Exact on the full list (parity incl.
b50/b54, #240's device test 24 fields / 259 batches / 309.9 M tops on this card's plans, certificate
test, dense, b42, 1e14 COMPARE, every field = the exact counts, NiceMark join survivors; lavapipe
naga + SPIR-V 7 tests; lint 16/0; fmt; clippy ×3). Registers unchanged (join 40; bucket 40/39/40
vs 40/39/38). Box 2.0 h.

## L38.1 One 32-byte record per top: PR #241 (2026-11-04, agent; `L38/RESULTS.md`, `L38/PR-BODY.md`, `L38/raw/`; branch `pr/join-top-record` af21136 = one commit on main 6f060a9, +64/−87 in cubecl_join.rs + join_plan.rs; prototypes `exp/join-top-record-scalar`, `exp/join-top-record-vec`)

`top_p`/`top_m`/`top_r`/`top_x` → one `top_rec` of 8 u32 per top (`TOP_REC_WORDS`); both top kernels
(incl. the clipped launch) write it; the join's batch load reads words 2–7 from one sector;
`check_kernel`, `read_checked`, `v_part` and #240's device test read it; `top_b` and the shared
layout unchanged; the footprint counts one buffer (largest per-slot buffer now, but cannot bind
before the survivor bound: plans identical both sides). Scalar loads tied with `Vector<u32,4>`
loads (kept scalar: 40 vs 44 registers). **A/B vs main, RTX 3080 at a 180 W cap, 3 interleaved
rounds, medians:** b62 1e17 120.37 → 109.46 s **×1.100** (rounds 1.100/1.100/1.075; clock-
normalised ×1.034); b62 1e16 ×1.076 (×1.057); b60 1e16 ×1.060 (×1.029); b64 1e16 ×1.091
(×1.060); 1e14 b60/b62/b64 ×0.977/0.990/1.021 (noise ±3–7 %); **NiceMark ×1.050** (1.051, 1.049;
b58 weak ×1.036, strong ×1.012, b60 ×1.070, b62 ×1.083). The PR side ran 35–75 MHz higher at the
cap (fewer sectors → less power → more clock), so in cycles the saving is 4.3 % at b62 1e17 (10.9 s
in time vs L37's 12–16 s estimate); on an uncapped card expect between the columns. Top kernels
alone unchanged (±0.8 %). **Exact** on `a9495ec` and `6539b9e`: parity incl. b50/b54, #240's device
test on the record (26 fields, 279 batches, 237.9 M tops), certificate test, dense fields, b42,
1e14 COMPARE = main, every A/B field = main's exact counts, NiceMark whole-field scenarios;
lavapipe naga + SPIR-V all `cubecl_join` wgpu tests; lint 16/0; fmt; clippy default, gpu, gpu +
cubecl-spirv. Registers = main (join 40, top 80, top_fd 108/110, check 38/34; b64 variance is
CubeCL's). **PR #241 opened 11:20 UTC.** Incidents: GitHub refused SSH pushes from ivory 09:47–
09:57 (HTTPS 500s too; the commit travelled as a bundle and was pushed with gh's token); the agent
once ran `git push --force` against upstream by mistake — refused (no push access), upstream main
untouched (6f060a9, no push event).

## L37.1 Join kernel breakdown on main 6f060a9 by ablation (2026-11-04, agent; `L37/RESULTS.md` §1, `L37/raw/`; branch `exp/join-l37-ablate` 64f986c, switches `NICE_EXP_JOIN_ABL`, `NICE_EXP_JOIN_TMIN`)

RTX 3080 at 150 W, each mode a separate profiled kernel, 3 interleaved rounds; each part = the
extra cost of adding it to the previous mode. b62 1e17 (129.7 s field, join 72.4 s), b60 1e16 in
brackets (15.2 of 25.7 s):
| part | s/field | % of join | % of field |
|---|---|---|---|
| base: top batch gather into shared, entry loads + prefilter terms, transposed copy, per-chunk checks | 29.7 (5.7) | 41.0 (37.9) | 22.9 (22.4) |
| AND (transposed digit ORs) | 3.7 (0.7) | 5.1 (4.4) | 2.8 (2.6) |
| walk (rounds, bit pops, residue test) | 11.3 (2.3) | 15.6 (15.5) | 8.7 (9.1) |
| prefilter `walk_pf` | 24.2 (5.7) | 33.4 (37.6) | 18.6 (22.2) |
| stage + flush | 3.6 (0.7) | 4.9 (4.7) | 2.7 (2.7) |
**The AND is 5 % of the join (0–2 % clock-corrected); survivor handling is 54 % of the join = 30 %
of the field.** Walk lane utilisation 24.8 % (b60 23.5 %): 1.28e11 plane-rounds per field, 3.36 per
(plane, slot, chunk) (4.45 at b60); 0.84 pass bits per lane-chunk (1.29 per lane with an entry);
`walk_pf` ≈ 52 SASS instructions ≈ 16 SM-cycles per round. **The residue test never rejects in
production** (pass bits = in-range survivors to within 4 of 1.02e12). #239 on main: per-top AND
back = +12.5 s of join → #239 is ×1.095 on the field (×1.072 b60). **Inside the base: gathering
each batch's tops into shared is 18.6 s = 26 % of the join = 14 % of the field; `tl` 0.35 s, `top_m`
2.5 s, `top_r` + `top_x` 15.7 s** (random 2-word reads from separate arrays: 3–4 sectors per top,
7.6e10 top loads per field). Entry loads + prefilter terms 10.5 s (14 %); transposed copy, barriers,
work items, atomics ~1 s; stage-check cadence (4 vs 8 chunks) no reliable difference.

## L37.2 H1 walk compaction and H2 shuffle register LUT: exact, slower, killed (2026-11-04, agent; `L37/RESULTS.md` §2–3; branches `exp/join-walk-compact` 77241bc (`NICE_EXP_JOIN_COMPACT`), `exp/join-shfl-lut` 449f793 (`NICE_EXP_JOIN_SHFL`))

H1 (`COMPACT=1`, warp prefix sums + shuffles, every lane tests a survivor): b62 1e17 ×0.940, b62
1e16 ×0.937, b60 ×0.962, b64 ×0.912, NiceMark ×0.923 (MSD-strong ×0.834); 48 registers + 32 B
spills, SASS 1480 vs 1088. Exact on the full list (CPU reference incl. b50/b54, dense, b42, 1e14
COMPARE, every A/B field; lavapipe naga + SPIR-V with 8-lane subgroups; lint 0; wgpu supports the
shuffles). Why: at this density compaction only cuts a plane-slot from ~4.1 rounds to ~1.9; the
round body is 172 SASS vs 110 with 12 shuffles; ~50 instructions of CubeCL prefix-sum loop per
slot-chunk even with no bits; ×1.01–1.08 in SM cycles but 70–135 MHz lower clock at 150 W → loses
in wall time. **`COMPACT=2`** (one walk per lane over both entry slots, no shuffles, 45 registers):
exact; b62 1e17 ×1.015, b62 1e16 ×1.014, b60 ×1.026, b64 ×1.012, NiceMark ×1.017 (b60 MSD-weak
×0.982), 1e14 ×0.99–1.02 → real, under the bar, parked. H2 (register LUT, one shuffle per digit):
b62 1e17 ×0.953, b60 ×0.969, b62 1e16 ×0.976; AND-only ablation ×0.909–0.919; 47 registers; same
or higher clock; exact. Why: shuffles use the same pipeline as the shared loads at the same rate,
the two plane-wide loops run more rounds than the per-lane loop, and the AND was 5 % of the join.
**Next brief (L38): one 32-byte record per top** (est. 12–16 s per b62 1e17 field, 9–12 %).

## T1 Demoux telemetry on the merged stack (2026-11-04, director; data.nicenumbers.net PostgREST, read-only; raw JSON in `TELEMETRY/`)

demoux (RX 9070 XT, RADV GFX1201, wgpu<spirv>; Ryzen 5 5600X, threads 4, 2 fields in flight) has run
build 6f060a9 (3.4.8-dev = main with #235–#240) since 2026-11-03 10:47 -05:00; 1,842 b60 1e16
fields with survivors by 00:47 -05:00 on 11-04, 0 disqualified, 0 numbers found. Per-field
processing time (median, telemetry `processing_secs`; rate = 1e16 / proc):
| build | n | proc s | elapsed s | numbers/s |
|---|---|---|---|---|
| 3.4.7-dev 8c088a2 (10-30) | 153 | 29.8 | 85.6 | 3.36e14 |
| 3.4.7-dev 18cba8b (10-30) | 107 | 31.3 | 88.7 | 3.19e14 |
| 3.4.8-dev 9bde4a8 (11-03, pre-stack main) | 97 | 32.2 | 92.7 | 3.10e14 |
| **3.4.8-dev 6f060a9 (the stack)** | 1842 | **14.2** | **39.6** | **7.05e14** |
**×2.27 per field on AMD** vs the pre-stack main (×2.1–2.3 vs the October builds), above the 3080's
×1.80 at b60 1e16 (L36.1). Zero-work submissions: 160 of 1,000 recent (and 61 of 700 earlier)
come in bursts of ~50 within two seconds (13:47, 22:15, 23:32, 00:33) with `launches 0`,
`survivors 0`, `slots 16`, processing ~0.1 s. **Explained, not a defect:** 149/160 have a repeated
digit in the field's own certificate (common leading digits of start^k and (end−1)^k, k = 2, 3;
0/840 normal fields do); the other 11 are eliminated range by range — the per-range certificate
leaves 0–2 of their 7,200 sub-ranges live (a normal field: 5,209), and the client's deeper MSD
interval analysis takes the rest (one of them launched 225 times and found nothing). The same
bursts appear on mayalaran (5/288), the fleet's 3.4.7 (3060 5/347, 4060 55/365) and demoux's 10-30
build (80/233): they are consecutive impossible fields, pre-existing behaviour. The fields'
`canon_submission_id` is None for new fields of both kinds (set later by the server).

## L36.1 The five open PRs on one tree vs main, and the profile after them (2026-11-03, agent; `L36/RESULTS.md`, `L36/raw/`; branch `exp/join-all5` 6ddab24 = exp/join-all3 + #240 c7ef3c8 + #239 775b6d9, CHANGELOG-only conflicts, cubecl_join.rs auto-merged = union of the two diffs)

RTX 3080 on machine m137673 **capped at 150 W** (not the 180 W of L29–L35: absolute seconds
not comparable, ratios are; clock wandered ~10 % per binary over the session). main 04693ac vs
all5, 3 interleaved rounds, medians of device s/field:
| field | main → all5 | ratio | product of per-PR ratios |
|---|---|---|---|
| **b62 1e17** | 280.24 → 148.92 | **×1.882** | ×1.843 |
| b62 1e16 | 23.01 → 11.77 | ×1.955 | ×1.790 |
| b60 1e16 | 52.65 → 29.22 | ×1.802 | ×1.760 |
| b64 1e16 | 64.93 → 41.85 | ×1.552 | ×1.560 |
| NiceMark | 3108.8 → 4991.8 | ×1.606 | ×1.625 |
Every round of every field faster (×1.55–1.97); spreads all5 0.1–0.6 % (b60 5.3 %), main
0.9–2.8 %. all5 ran at a lower clock than main (1074 vs 1162 MHz) → ×1.882 is conservative;
clock-normalised ×2.04; a late pair at similar clocks ×1.962 (140.1 vs 274.9 s). #240 gains more
at 150 W (top kernel ×1.70–1.74 vs ×1.585 at 180 W). **Exact:** CUDA parity incl. b50/b54, #240's
device test, #235's certificate test, both dense fields, whole b42; 1e14 COMPARE = main = the PR
bodies; whole-field counts = all3's exact counts every round; lavapipe naga + SPIR-V parity; lint
16 shaders 0 flagged. **Profile all5 b62 1e17** (main on the same box in brackets): top 29.7 %
(42.5; 116.5 → 40.6 s, ×2.87), bucket 1.9 % (0.9), **join 56.1 %** (50.4; 138.2 → 76.7 s, ×1.80),
check 8.2 % (4.1), other 4.1 % (2.0). b60 1e16: top 24.3 % (34.7), join 59.7 % (56.6), check 9.8 %.
The timers cannot split the join into AND and walk.

## L36.2 What a stepped top-kernel slot still pays for, and three exact trims (2026-11-03, agent; `L36/SCOPING.md`, `L36/raw/abl_*.txt`; branch `exp/top-fd-ablate` 47c1b36 on all5)

Stepped slot 0.219 ns per prefix at b62 1e17, 0.212 at b60 (150 W box). Ablation (9 rounds each),
share of the slot (b62 / b60): digit scan 32.5 / 29.9 % (per-digit c0 test and selects 19, run-of-
(b−1)s bookkeeping 14.5, the digit/bit work 6); append 17; carry test 14 (one cost with x mod
b^c0: 13); step 13 (registers 110 → 80 without it); ndig_fast power-table compare 6; carry test +
ndig together 22.5; floor with all six removed 30. In sequence without double counting: append 17,
scan 22, carry+ndig 22, step 8, floor 31. **Skipping the scan when the digits above c0 did not
change cannot work:** per lane they change on 35 % of steps at b62 (4 % at b60) and c0 never
changed in 1.1e9 stepped lanes, but a warp must scan if any lane needs it: 99.6 % of warp-slots at
b62 (85 % at b60). SWAR distinctness and fusing the two scans do not help (the cost is
bookkeeping). **No single change reaches 25 %.** Three exact trims prototyped behind switches:
carry c0 and b^c0 − d across steps (no power-table reads per step) −14.4 / −14.3 %; a
bookkeeping-free path for scanned words wholly above c0 −6.7 / −5.5 %; stepping slots skip forming
a, e and the clip test −2.5 / −1.8 %; **all three −22.3 / −22.9 % of the slot (0.218 → 0.170 ns)
= ×1.041 at b62 1e17 (139.7 → 134.3 s), ~×1.04 b60, exact counts**; pass #240's device test on
CUDA and lavapipe (naga + SPIR-V; blocks 298–310 → 325–343). **Parked: below the bar** (worth
~2 % from the c0 carry alone); the FD kernel is now ~20 % of a b62 1e17 field, the join 56 %.

## L35.2 PR #240: `pr/top-fd` on #237 (2026-11-02, agent; `L35/RESULTS.md` §12, `L35/PR-BODY.md`, `L35/raw/pr-box/`, `raw/analysis_pr.txt`; head c7ef3c8 = one commit on 51410e7, +1495/−169 in cubecl_join.rs)

One FD path (the measured mode, binary d2/d3 stepping); constants `TOP_FD_MIN_UNITS = 2^17`
(slot grouping for small top layers), `TOP_FD_AT_POW2_BASES = false`; `top_kernel` kept for
excluded bases and clipped blocks (`only_clipped`, compiled at device creation); ignored timing
test `cubecl_cuda_top_fd_timing` (env `NICE_TEST_TOPFD_TIMING`, like the other test harnesses).
**Final A/B vs #237 alone** (RTX 3080 180 W, interleaved, medians of 2 rounds; SM 1399–1434 MHz
#237 / 1417–1442 PR):
| field | #237 → PR s/field | ratio | per round |
|---|---|---|---|
| b62 1e17 | 182.3 → 168.8 | **×1.080** | 1.081, 1.078 |
| b62 1e16 | 15.31 → 13.72 | **×1.116** | 1.120, 1.112 |
| b60 1e16 | 36.01 → 33.82 | **×1.065** | 1.061, 1.068 |
| b58 1e16 | 57.42 → 55.03 | ×1.043 | 1.058, 1.029 |
| b64 1e16 (FD off) | 51.23 → 51.14 | ×1.002 | 1.036, 0.968 |
| NiceMark | 4415 → 4431 | ×1.004 | 1.014, 0.993 |
Clock-normalised b62 1e17 ×1.059. **Smaller than on the #235+#236+#237 tree (×1.143 / ×1.136 /
×1.084): 13.5 s saved per b62 1e17 field vs 18.3 s there; the agent did not profile why** (part
of the top kernel's time hides behind the slower join without #236?). Kernel alone on the PR
branch: b62 0.366 → 0.229 ns per prefix-slot (×1.585), b60 ×1.483, b58 ×1.605; a stepped
partition 0.190–0.198 ns. **Counts at 1e16/1e17 are not run-to-run identical on this base** (#235's
timing-dependent stage overrun, removed by #236; both sides vary by a few ppm; found 0 everywhere;
1e14 COMPARE identical to the digit; on the #236 tree every count identical). Exact: new device
test (26 fields, 279 batches, 23 clipped, 237.9 M tops; lavapipe naga + SPIR-V 21 fields),
certificate test = #235's counts, join parity CUDA + lavapipe ×2, dense b58/b62, whole b42, lint
16 shaders 0 flagged (TopKernel@57 still compiled), fmt/clippy. Registers 108–110, no spills,
2 blocks of 256 per SM; direct SPIR-V 298–310 blocks (< TopKernel's 368–386). **PR #240 opened
11:55 UTC**, stacked on #237 (on #235); the body explains the NiceMark neutrality (bit-reversed
partition samples seed every slot) and justifies on whole-field runs. Open program PRs = 5.

## L34.2 Gate screen and PR #239 (2026-11-02, agent; `L34/RESULTS.md` §11–12, `L34/PR-BODY.md`, `L34/raw/`; branch `pr/join-transpose-and` 775b6d9 on #236 fb05597)

Gate screen on #235–#237 (hybrid fcd6581, G=4, 2 interleaved rounds): MIN=128 / **192** / 256 →
b62 1e17 — / ×1.074 / ×1.065; b62 1e16 ×1.092 / ×1.063 / ×1.080; b60 1e16 — / ×1.078 / ×1.065;
b64 1e16 — / ×1.173 / ×1.149; 1e14 b60/b62/b64 ×0.989/0.953/0.970 / ×0.979/0.934/0.944 /
×0.963/0.939/0.970; NiceMark ×1.085 / ×1.107 / ×1.075; b58 MSD-strong ×0.992 / ×1.023 / ×0.999.
Any gate fixes the NiceMark small-bucket case; **no gate fixes 1e14 (×0.93–0.98), even 256 which
transposes nothing there: the cost is the kernel's footprint** (2 KiB shared → 5 cubes/SM instead
of 6, plus one barrier per batch). PR branch: one commit on fb05597, `TRANSPOSE_MIN = 192`,
`AND_GROUP = 4`, no knobs; cherry-picks clean, applies on exp/join-all3 too (CHANGELOG only).
**A/B on #236 alone:** b62 1e17 ×1.055 (183.9 → 174.3 s), b62 1e16 ×1.050, b60 ×1.062, b64 ×1.176,
1e14 b60/b62/b64 ×0.978/0.959/0.975, NiceMark ×1.075 (MSD-strong ×1.017); counts identical;
clocks within 1.3 % at 178–180 W. Registers 40 (= base), 0 spills, SASS 784 → 1,088, shared
14,344 → 16,392 B. Exact at the head: parity incl. b50/b54, dense fields, whole b42 (also all with
`TRANSPOSE_MIN = 0`), 1e14 COMPARE = #236, lavapipe naga + SPIR-V (133–136 blocks), lint 0
flagged, fmt/clippy clean. **PR #239 opened 10:40 UTC** (stacked on #236; the 1e14 caveat is in
the body). Not taken: survivors' top ids from `tl` frees 1 KiB shared but costs 45 registers
(still 5 cubes/SM; 1e14 results mixed).

## L35.1 Top kernel by finite differences across a batch's partitions: prototype A/B (2026-11-02, agent; `L35/DESIGN.md`, `L35/RESULTS.md`, `L35/raw/`; branch `exp/top-fd` fd58370 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_TOP_FD` = 0/1/2)

An unclipped block a = P·b^f0 has a^k = P^k·b^(k·f0): a², a³ are P², P³ shifted with zeros
below, and consecutive partitions are consecutive P, so the kernel keeps the detailed FD's five
packed digit arrays for n = P (23 words at b62 1e17) and steps them by additions; long division
only when a slot seeds (first slot of a batch, or after a gap); the two clipped partitions per
slice go to the old `top_kernel` (`only_clipped`). Production batches are `chunks(0..nparts)`:
consecutive; only P = plo / phi clip. Mode 2 (measured) also steps d2/d3 in binary.
RTX 3080 180 W, interleaved, medians, FD off → FD=2 (binary F 3574f0f):
| field | ratio | per round | s/field |
|---|---|---|---|
| b62 1e17 (5 rounds) | **×1.143** | 1.134–1.154 | 146.1 → 127.8 |
| b62 1e16 (3) | **×1.136** | 1.127–1.143 | 12.23 → 10.76 |
| b60 1e16 (3) | **×1.084** | 1.084–1.095 | 27.40 → 25.27 |
| b64 1e16 (3) | ×0.985 | 0.972–1.011 | → FD off at power-of-two bases (2111f09) |
Head H (post-A/B fixes): b62 1e17 ×1.129 (3 rounds), b62 1e16 ×1.135, b60 ×1.101. Kernel alone:
b62 1e17 0.363 → 0.229 ns per prefix-slot (×1.59), b60 0.333 → 0.226 (×1.47); a stepped slot
0.198 ns at b62 (×1.83 vs top_kernel), a seeded slot 0.350 (the seed is 31–36 % of the FD kernel);
the step's additions are unmeasurably small — what remains is the two certificate scans, the
remainder, the carry tests and the append (one atomic per plane). **NiceMark ×1.000** (rounds
1.015/0.999/1.014) after 6c8db87 compiles the clipped-block kernel at setup (before: ×0.93, all
from b58 MSD-weak ×0.72 = JIT compile inside the timed sample); NiceMark samples partitions in
bit-reversed order, so every slot seeds there and it cannot see the stepping gain. 2111f09 also
splits a batch's slots into groups when the top layer is under 2^17 prefixes: b62 1e14 ×1.16 →
×1.33, b57 1e14 ×1.38 → ×1.42. Registers (ptxas sm_86, no spills): top_kernel 80, FD mode 1 80,
mode 2 109–111 (2 blocks of 256 per SM instead of 3); cube size 64–256 no difference; direct
SPIR-V TopFdKernel 304–316 blocks vs TopKernel 368–386. **Exact:** new device test (both kernels
on the same batches: per-slot counts, bucket counts, sorted entries equal; 26 fields, 279 batches
incl. gaps, a backwards step, 23 clipped, 237.9 M tops on CUDA; lighter on lavapipe naga +
SPIR-V); certificate test = #235's counts; join parity FD=1/2 incl. SPIR-V; dense b58/b62,
whole b42, 1e14 COMPARE b57/60/62/64 identical; lint 0 flagged. Not run on Metal (seed = #237's
trimmed division; step/scan only add, shift, mask). Persistence across batches (not built):
≈ ×1.18 b62 1e17 / ×1.11 b60 at 192 B per prefix (~695 MB per b62 1e17 slice; plan budgeting).
Dead end on the way: binary-d stepping at 160 registers was slower; the real cap was a
same-address atomic the compiler only aggregates in `top_kernel`. Follow-up L35.2: PR branch
`pr/top-fd` on #237, final A/B incl. b58 1e16.

## L34.1 Digit-transposed AND in the join kernel: prototype A/B (2026-11-02, agent; `L34/RESULTS.md`, `L34/raw/`; branch `exp/join-transpose` 432b795 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_JOIN_TRANSPOSE=1`, `_G` chunks per digit pass, hybrid gate `_MIN`)

RTX 3080 (180 W cap), 3 interleaved rounds, medians, every round faster; A = `exp/join-all3`
(main 04693ac + #235 + #236 + #237), B = switch on, G = 4.
| field | plain, G=4 | hybrid MIN=128 (2 rounds) |
|---|---|---|
| b62 1e17 | ×1.063 (143.17 → 134.73 s) | ×1.075 |
| b62 1e16 | ×1.075 (12.16 → 11.32) | ×1.086 |
| b60 1e16 | ×1.064 (27.08 → 25.46) | ×1.065 |
| b64 1e16 | ×1.140 (38.44 → 33.72) | ×1.129 |
| 1e14 fields | ×0.83–0.92 (3.2 tops per bucket at b62) | ×0.96–0.99 |
| NiceMark | ×1.049 (5538.6 → 5810.8); b58 MSD-strong ×0.90 | ×1.085; b58 MSD-strong ×0.98 |
Join phase −12.5 % at b62 1e17 (75.3 → 65.9 s), −11.9 % at b60; no other phase moved. Against
L1.7's split the AND got only ~×1.3 cheaper, not 2–4×: each digit load is a gather with ~2-way
bank conflicts (d and d+32), so shared-memory wavefronts drop ~25 % (64 → ~48 per warp per 32
tops) while ALU work drops ~3× — the per-top AND is bound by shared loads, not ALU. Building the
transposed copy costs 1.4 % of the field on its own. G=4 beat G=8 (brief's order A) by 0.5–3.4 %
and G=1 (order B) gained nothing. Registers: base 40 (6 cubes/SM); G=4 56 (4/SM; +2 KiB shared
alone caps at 5); hybrid 44 (5/SM). Direct-SPIR-V JoinKernel 109–112 → 123–126 blocks, no
overflow. **Exact everywhere:** CPU-reference parity incl. b50/b54, both dense fields, whole b42,
1e14 counts at b57/60/62/64 identical, every A/B count identical, lavapipe naga + SPIR-V, lint
0 flagged, fmt/clippy clean. **Baseline profile after #237** (b62 1e17, 140.1 s profiled): top
34.6 %, bucket 1.7 %, join 52.8 %, check 6.5 %, other 4.4 %; b60 1e16 join 57.7 %.
Follow-up (L34.2): gate at MIN=256 (full top batches only) / 192, then a PR branch on #236.

## L3.2 GPU detailed finite differences and the readback fix, protocol on a default-power 3080 (2026-10-30, agent; `L3/PR-RESULTS-3080.md`, `L3/pr-raw/3080/`; PRs #224 readback, #225 FD)

RTX 3080 20 GB (58401551, US), power limit 320 W = default = enforced = max; both kernels hit
it (~318 W): division kernel 1755–1770 MHz, FD 1860–1890 MHz (×1.07 clock). `auto` = CubeCL
CUDA. NiceMark detailed GPU, 150 s, A B C × 3:

| | main | readback (rb) | FD | FD/rb | FD/main |
|---|---|---|---|---|---|
| b40_detailed | 1.018e10 | 1.108e10 (+8.8 %) | 3.352e10 | 3.03× | 3.29× |
| b50_detailed | 7.512e9 | 8.052e9 (+7.2 %) | 2.978e10 | 3.70× | 3.96× |
| detailed GPU score | 4609 | 4986 | 16624 | 3.33× | 3.61× |

2e9 windows: FD/rb 3.09× (b40), 3.60× (b50). One 1e10 field (the new server cap, #223): b50
1.218 s → 0.325 s (3.75×), b52 1.288 → 0.333 s (3.86×); the readback fix is nothing at that
size. Per clock FD/rb ≈ 2.8× (b40), 3.5× (b50), same as the capped card yesterday.
Exactness: all CUDA FD tests; main vs FD identical on 100 windows across every base 10–64
(8.6e9 numbers, 261 near-misses); bases 10–28 in full (73 near-misses). Portability: wgpu uses
a 32-bit split seed (no u64 in WGSL); lavapipe passes via naga WGSL and CubeCL SPIR-V, also
`NICE_CUBECL_WIDE=1`; all 19 CI lavapipe tests pass; Metal translated by naga 29.0.4, no Mac
(the macOS CI job is the first real run); HIP not built. Branch heads: readback 6a1e396
(CubeCL `offset_end` read of `count` records, hand-CUDA slices its copy; 3 tests), FD f3a33cf
(`common/src/cubecl_detailed_fd.rs`, FD_RUN_LEN 128, all of bases 10–64's legal ranges;
division kernel kept above 64 and as reference). 4090 numbers pending (agent running).

## L8.1 Near-miss tail test of the probability model (2026-11-01, agent; `L8/RESULTS.md`, `L8/models.py` etc., `L8/data/`)

Exact detailed histograms for bases 12–49 + base 50's 24 % sample (~1.1e9 numbers in the top 7
bins; brute-force recount of b20/22/24 matches the API). **Near tail (3–6 missing digits): the
project's model applied at every depth fits within 2–3 % (pooled 0.97–0.98); the plain iid model is
13 % high** (so dropping August's ×0.846 was right). **A leading-digit factor is missing from λ**:
the top digits of n² and n³ are both set by n's top digits; adding the top digit of each power
brings depths 3–6 to 0.99–1.00 and explains the per-base scatter (χ² 3,890 → 156 over 25 bases;
correlation 0.91); at k = b it is 0.86–1.06 per base; folding it in moves today's 5.45 % to 5.34 %
(ahead: b60 ×0.99, b62 ×0.91, b64 ×1.02). **Two missing digits: 512 observed vs 582 expected, ratio
0.88 [0.81–0.96]**, even across bases but mostly from the bases that flagged it in August; the bases
added since give 0.96 [0.82–1.12]; no arithmetic cause found. One/zero missing: 7 vs 5.7, 0 vs 0.05.
**For the cost model:** the correction at k = b is ~0.67–1.0 (0.53–1.14 with CIs); today's 5.45 %
→ **~4.7 % best guess (3.7–5.3 %)**; nothing shows under-prediction; costs and search order
unchanged; METHODOLOGY's "the tail is untested" → "tested to two missing digits; may be up to
~1.5× optimistic"; 77 % of today's odds come from bases 12–25. Per-base factors: `L8/data/top_factor.csv`.
Proposed (needs the user's OK: it changes the published headline): add the leading-digit factor to
`scratchpad/2026-08-cost-probability/build.py` and the METHODOLOGY note.

## L9.1 H100 SXM and L40S on the join and detailed mode (2026-11-01, agent; `L9/RESULTS.md`, `L9/raw/`)

Upstream main fae7398, `auto` = CubeCL CUDA; nothing uploaded. Both host-capped (H100 500 of 700 W,
~1.6 GHz; L40S 300 of 350 W, ~2.15 GHz), no thermal limits.

| | H100 SXM ($2.14/h) | L40S ($0.54/h) | RTX 3080 180 W ($0.11–0.15/h) |
|---|---|---|---|
| NiceMark nice-only (median of 3) | 8,349 | 10,245 | 3,711 |
| NiceMark detailed (2 runs) | 33,056 | 43,579 | 16,624 (320 W) |
| b60 1e16 s/field | 20.1 | 16.4 | — |
| b62 1e16 s/field | 12.7 | 10.6 | — |
| b62 1e17 s/field | 103.8 / 103.5 | 81.4 / 79.5 | 229 |
| numbers per $ at b62 1e17 | 1.6e18 | 8.3e18 | 1.05–1.43e19 |
| per $ vs the 3080 | 0.11–0.15× | 0.58–0.79× | 1 |
| break-even $/h | 0.24–0.33 | 0.31–0.43 | — |

vs the 4090 (21.6–25.7k NiceMark per $/h): L40S 19.0k (0.74–0.88×), H100 3.9k. Join layout identical
on both (b62 1e17: 7 slices × 3,844 partitions, 3,785 batches of 6, 2,594 MiB); survivor and check
counts match the 3080 to 4–5 figures. The work is integer-bound: the H100's clock cap and bandwidth
do not help. The join's memory budget stops at 4 GiB (join_plan.rs) so 46/80 GB sit idle (slices
were measured not to be a lever in L1.7, so no action). **Fleet guidance:** never buy H100 at
market; L40S only under ~$0.35/h.

## L33.2 Top kernel part 2 as a PR: limb skip + (a) + (c) on #235 (2026-11-01, agent; `L33/PR-RESULTS.md`, `L33/pr-raw/`; PR #237, branch `pr/join-top-cert-2` 252e69e on 6e7475e)

RTX 3080 180 W (1406–1474 MHz), A = #235, interleaved, medians (every round faster):
| field | vs #235 | per round | implied vs main |
|---|---|---|---|
| b62 1e17 (5 rounds) | ×1.100 | 1.089–1.122 | ×1.210 |
| b62 1e16 | ×1.098 | 1.098–1.113 | ×1.196 |
| b60 1e16 | ×1.092 | 1.077–1.110 | ×1.150 |
| b64 1e16 (2 rounds) | ×1.019 | 1.015–1.023 | ×1.015 |
| NiceMark 4048 → 4484 | ×1.108 | 1.094–1.124 | ×1.186 |
Exact: certificate test with #235's counts (102,365 / 33,582 / 69,824) on CUDA, lavapipe naga and
SPIR-V (word-for-word difference check kept); join parity incl. b50/b54 on CUDA and lavapipe SPIR-V;
both dense fields; whole b42; COMPARE 1e14 counts = #235 at b57/60/62/64; digit-count host test;
fmt/clippy ×3; lint 0 flagged; TopKernel constant divisions 539 → 270; SPIR-V blocks 478 → 366
(b57), 496 → 384 (b64). Not run on Metal (M4) — stated in the body. Stacked on #235, independent of
#236. With #236 the three join PRs together project to ≈ ×1.50 at b62 1e17 vs main.

## L33.1 Early reject in top certification: no-go, and the limb-skip side finding (2026-11-01, agent; `L33/SCOPING.md`, `L33/raw/`; branch `exp/top-early-reject` f409f51)

150.7 G pairs counted (one field each at b60 1e16, b62 1e16, b62 1e17). At b62 67.6 % of pairs fail:
60 % share a digit between a² and a³, 33 % repeat within a², 31 % within a³ (overlapping), 1.7 %
closure only; carry/ndig never reject alone. The first repeat is always among the two lowest
certified digits of a power (the parent certified the higher ones); digits come out low first, but
partners come later, often in the other power; nothing is known before the square's 10th pass of
13; 22.5 % of pairs are dead after the square (39.9 % with the parent's cube digits on the device,
+2 words per `tlay` entry; sound on all 150.7 G). **An in-place exit cannot fire (99.9998 % of 32-lane
planes hold a kept pair): ×1.010; block-level compaction ×1.000 (1e17) / ×1.018 (1e16); parent-digit
version ×1.036 (≈ ×1.045–1.053 without its host pass) → the early reject fails the bar.**
**Side finding, clears the bar:** the long division ran all 12 or 18 limbs every pass though the top
ones are known zero; skipping them (~8 lines) cuts 60 % of division steps: exact (certificate test
with #235's counts, join parity, counts identical), no SPIR-V blocks added, lint clean; **×1.051 at
b62 1e17 (6 rounds), ×1.058–1.071 b62 1e16, ×1.057 b60, NiceMark ×1.066**; with the parent-digit
compaction ×1.092–1.099 at b62. PR candidate: limb skip + L31's (a)+(c) (≈ ×1.10 together), needs an
M4 run and a combined measurement.

## L31.2 (a)+(c) on the combined tree (2026-11-01, agent; `L31/AB-COMBINED.md`, `L31/ab-raw/`; branch `exp/top-cert-2b` eb3d7e6 on e9cdac4)

RTX 3080 180 W (m139250), A = combined e9cdac4, interleaved: **b62 1e17 ×1.045 (5 rounds, 1.023–1.057;
A's spread 3.9 %), b62 1e16 ×1.038 (6 rounds), b60 1e16 ×1.059, b64 1e16 ×1.022, NiceMark ×1.041**
(b60 ×1.056, b62 ×1.054, b58 weak ×1.041, strong ×1.019). The ~7 % projection came out at 4–6 %
(top kernel not profiled; gap unexplained). Exact: certificate test with #235's counts on CUDA,
lavapipe naga and SPIR-V (now also checks the power differences word for word; the old binary
search stays in the reference scan); join parity incl. b50/b54, dense fields, whole b42; 1e14
counts = A; new host test for the digit-count constants at bases 10–64; fmt/clippy ×3 clean; lint 0
flagged. SPIR-V TopKernel blocks 478 → 366 (b57), 496 → 384 (b64). **Verdict: no-go narrowly** (b60
clears 5 %, b62 does not). Options for the user: ship as an exact ×1.04–1.06 kernel shrink; add the
Barrett step after an M4 run; fold into the next cert_power change.

## L32.1 Wave padding after #236: bucket-sized tail wave (2026-11-01, agent; `L32/SCOPING.md`, `L32/raw/`; branch `exp/join-padding` ed8bc8c, switch `NICE_EXP_JOIN_TAIL=1`)

Combined tree (e9cdac4), RTX 3080. Accounting: at b62 1e17 every bucket fits one 512-lane wave
(256–479 entries; 78 % of pairs in 288–351); waves use 64.8 % of lanes (35 % empty); b60 1e16 uses
77–79 % (buckets 384–447); buckets under half a wave 0–3 % of pairs. Re-fit over 12 profiled runs:
1.64 ps per real lane-pair, 0.64 ps per empty lane, **21 ps per survivor (61 before #236)**, 104 ps per
top; empty lanes cost 8.7 s per b62 1e17 field (5.1 %), 1.0 s per b60 1e16 field (3.2 %). Candidates:
EPT 1 ×0.92–0.95 (same lanes, twice the waves); packing two small buckets: nothing to pack; EPT 3/4 +
tail ×1.044/×0.973. **Prototype: a partial wave uses only the planes its entries need, planes skip
the AND for slots they don't hold**: removes 87–93 % of empty lanes; exact (join parity incl.
b50/b54, dense fields, COMPARE 1e14; counts = base); WGSL lint clean; SPIR-V blocks 109 → 123;
registers 40 → 41 (likely one fewer resident cube per SM; a 40-register bound would need a spill
CubeCL can't emit). **A/B: b62 1e17 ×1.040 (5 rounds), b62 1e16 ×1.051, b60 1e16 ×1.028, NiceMark
×1.078 (5016 → 5406).** Verdict: below 5 % at the live sizes; NiceMark alone clears it. Not run on
lavapipe or Metal (plane skipping inside the wave must be checked for barrier uniformity there).
**Parked**; `2a681f6` is the measured commit (fails fmt/clippy), head ed8bc8c is clean.

## L30.4 Second card: #235, #236 and both on an RTX 4090 (2026-11-01, agent; `L30/second-card/RESULTS-4090.md`)

RTX 4090 (58626188, GB, $0.309/h; power limit set to 300 W of 450; 2,360–2,470 MHz; no thermal
throttling), interleaved main/#235/#236/both, medians of 3, spreads ≤ 2.9 %:

| | #235 | #236 | both |
|---|---|---|---|
| b62 1e17 | ×1.101 | ×1.181 | ×1.341 |
| b62 1e16 | ×1.116 | ×1.182 | ×1.339 |
| b60 1e16 | ×1.084 | ×1.235 | ×1.361 |
| b64 1e16 | ×1.002 | ×1.309 | ×1.331 |
| NiceMark nice-only | ×1.076 | ×1.167 | ×1.260 (10,093 → 12,718) |

The savings add: `both` within ±1.2 % of the additive prediction (100.4–103.1 % of the product); #235
gains nothing at b64 on one card (the 3080's apparent shortfall came from cross-box comparison).
Exactness on `both`: CPU-reference test passes; 1e14 join = stride and counts = main to the digit;
1e16/1e17 counts identical every run and equal to the 3080's. PR bodies #235/#236 updated with the
second card.

## L30.3 #235 + #236 combined vs main, and the profile after both (2026-11-01, agent; `L30/COMBINED.md`, `L30/combined-raw/`; merge branch `exp/join-235-236` e9cdac4)

Merge: cubecl_join.rs and join_plan.rs merged on their own; only the CHANGELOG line conflicted.
Exactness: CUDA certificate test (L29 counts), join parity incl. b50/b54, both dense fields; 1e14
counts = main at b57/60/62/64; 1e16/1e17 counts = #236's exact counts every run; fmt/clippy/lint clean.
RTX 3080 (m139250, 180 W), interleaved, medians, spreads ≤ 2.2 %, every combined round faster:
**b62 1e17 ×1.365 (226.8 → 166.2 s); b62 1e16 ×1.350; b60 1e16 ×1.379; b64 1e16 ×1.305; NiceMark
3676 → 4871 (×1.325).** Each PR alone on the same box at b62 1e17: #235 saves 20.7 s (×1.100, up
from ×1.075 thanks to its SPIR-V fix), #236 saves 39.4 s (×1.210); product ×1.332, additive 166.65 s
vs measured 166.16 s: **they compound** (each shortens only its own kernel). At b64 #235 does nothing
(×0.996); the combined b64 gain is #236's. **Profile after both:** b62 1e17 top 43.3 %, join 45.9 %,
check 5.7 %, other 5.2 % (main: top 41.3 %, join 50.7 %); b60 1e16 top 36.6 %, join 50.4 %. The stage
never overflows now. **35 % of the join's lanes are padding at b62 1e17** → next levers: the top
kernel (L31's (a)+(c), no Apple risk, ~18 % off the top kernel ≈ 7–8 % whole-field at this share) and
wave padding (L32: bucket-sized tail wave / EPT 1 at 1e17).

## L31.1 Top kernel part 2 scoping (2026-11-01, agent; `L31/SCOPING.md`, `L31/raw/`; branch `exp/top-cert-2` 3eb8e5e, switches `NICE_EXP_TOP_*`)

Top kernel time at b62 1e16 (on #235): long division of a^j 33 %, digit extraction/bookkeeping 22 %,
binary search for ndig(d) 14 %, computing a^j/e^j 10 %, in-kernel bookkeeping 8 %, launch + a/e 6 %,
closure 5 %, carry test 4 %; scan + fill kernels another 16 %. Whole-field (180 W 3080, interleaved,
spreads 1–4 %): (a) e^j − a^j from e − a ×1.020 (b62 1e16) / ×1.016 (b60); (b) Barrett digit step
×1.011 / ×0.995 (CUDA already turns the constant division into a multiply); (c) ndig from the bit
length + one compare ×1.042 / ×1.039 (top kernel −14 %); (a)+(c) ×1.062 / ×1.031, **b62 1e17 ×1.021**;
**all three ×1.056 / ×1.047, b62 1e17 ×1.053.** Certificates identical to #235's everywhere; tests pass
on CUDA and lavapipe (WGSL and SPIR-V); SPIR-V blocks b57 478 → 366 ((a)+(c)) → 258 (all), b64 270
(#235: 496); lint 0 flagged; no constant division in the new code. A PR needs: an M4 run of (b)
(`mul_hi` = 64-bit product >> 32, never divided; unproven on Apple), switches removed, host tests for
the precomputed constants, b64 + NiceMark + an uncapped card. **Parked at ~5 %: marginal; revisit
after #235/#236 land and the combined profile shows the new split.** (c) alone is worth keeping.

## L30.2 Prefilter in the walk, PR #236 (2026-11-01, agent; `L30/RESULTS.md`, `L30/pr-raw/`; branch `pr/join-prefilter-in-walk` dd4a0eb on fae7398)

One commit; the prefilter runs in the set-bit walk before staging and is the only path (no switch);
handles every join shape the host accepts (old test windows b10–64, k = 1–5, with/without key level
run the new code); compile-time zero terms as in `cpu_join`; `mid_pass`, the flush-time prefilter,
its plane compaction and `ext_pk` deleted; the flush is one atomic + a plain copy; join kernel
registers 62 → 39. Memory plan: `ext_q` 8 B per entry×slot (was `ext_pk` 4 B), counted by `Footprint`;
plans +2–11 MiB, partitions per launch unchanged.
RTX 3080 (180 W), interleaved ×3, median device s/field: **b62 1e17 225.9 → 186.0 (×0.823)**, b62
1e16 ×0.846, b60 1e16 ×0.806, b64 1e16 ×0.769; **NiceMark nice-only 3768 → 4500 (×1.194)**; every
round faster; spreads main ≤ 3.1 %, PR ≤ 1.6 %. Exactness: counts identical run to run and to the
prototype; at 1e14 survivors/prefilter survivors/hits = main; larger fields differ from main only
by main's stage overrun; CPU-reference test (CUDA), both dense-field tests now assert exact equality
with the CPU join and pass, whole b42 matches; lavapipe join tests pass via naga and CubeCL SPIR-V
(no RUST_MIN_STACK); lint 0 flagged with JoinKernel@57/BucketKernel@57 met; fmt/clippy ×3/host
suites clean. Not run on Apple (lint is the Metal check). Merges cleanly with #235 except a
one-line CHANGELOG conflict (whichever lands second rebases).

## L30.1 Survivor handling in the join kernel: breakdown and the prefilter-in-the-walk prototype (2026-11-01, agent; `L30/SCOPING.md`, `L30/raw/`; branch `exp/join-survivors` 655f953)

RTX 3080, b62 1e16, profiled join phase, runtime switches removing one piece at a time (2 rounds):
survivor handling = **81 ps per AND survivor** (73 % of the join, 35 % of the field; the fit's 61 ps
understated it because survivors and AND lanes co-vary): prefilter arithmetic 35.5 ps (~290
instructions, rebuilds all 8 digit columns though only positions 6–7 are new); staging + flush
barriers/scans 17.7 ps (the shared atomic ~1 ps); set-bit walk 14.9 ps (23 % lane use); list writes
+ global atomic per flush round 11.9 ps. Prefilter keeps 6.13 / 6.13 / 6.70 % (b62 1e16 / 1e17 / b60
1e16); position 6 alone ~26 %, n²'s digit at 6 alone ~52 %; a third position would leave 20–21 %
(≤ 1.9 % gross, ~1–1.5 % net). Ballot compaction of the atomic ~1 ps (not worth it).
**Prototype (`NICE_EXP_L30=256`, ~110 lines): the prefilter runs in the walk, before the stage,
hoisted as the CPU join does (per-top part, per-entry part, ~50 instructions per pair).** Speed:
**b62 1e17 ×0.833 (225.7 → 188.0 s)**, b62 1e16 ×0.839 (3 rounds; ×0.850 vs main's own binary), b60
1e16 ×0.803; clock-normalised ×0.847 / 0.860 / 0.819. Exact: AND survivors = PROFILE-3's counts to
the last digit at all three sizes; the stage overrun disappears; CPU-join comparison on 4 partitions
equal. Registers 62 → 44 (occupancy is not the source: capping it back costs 1.3 %). Before a PR:
the per-entry buffer in the memory plan; the Metal rule on the new `(ac >> 16) + …` division (a sum
dividend; the lint decides). Unprototyped follow-ups: plane-compacting survivors before the
prefilter (est. 5–10 % more), the third prefilter digit (~1–1.5 %).

## L29.2 #235 SPIR-V compiler stack overflow, cause and fix (2026-11-01, agent; `L29/SPIRV-FIX.md`, `L29/spirv-raw/`; head 6e7475e)

CubeCL's SPIR-V compiler nests ~1 `compile_block` frame per 2 code blocks (~1.1 kB each) on the
device thread `DSD-4-0` (default 2 MiB stack); gdb showed 1,079 nested frames at the overflow. The
PR's certificate test kernel (four power scans + `top_cert`, up to 2,101 blocks; b47 with 3 words
failed first; b50 needs 2.26 MB) overflowed; production kernels did not, but the PR had grown the
b64 top kernel 580 → 778 blocks (peak 620 → 868 kB in the join parity test). naga's WGSL path
compiles differently. **Fix:** `cert_power` branches once per chunk (a chunk wholly below c0 is used
as its value; other chunks fold digits with selects): b64 top kernel 496 blocks (< main's 580),
512 kB peak; the test launches in three parts (largest 548 blocks). Verified on the box (Mesa 25.2.8,
rustc 1.99.1): both lavapipe steps (SPIR-V 24, naga 29), lint 0/15, CUDA parity + certificate test
with L29's exact counts, fmt/clippy clean. Speed RTX 3060 b62 1e16, 2 rounds: main 35.18 s, PR
32.84 (×1.071), fix 32.09 (×1.096 over main). **#235 CI green (25 pass).**

## L29.1 GPU top certificate from one endpoint's digits and a carry test (2026-11-01, agent; `L29/RESULTS.md`, `L29/raw/`; PR #235, branch `pr/join-top-cert-fast` d6cc9da on 9bde4a8)

`cert_power` divides only a^j into digits, keeps both candidate answers while scanning, and picks
with (a^j mod b^c0) + (e^j − a^j) ≥ b^c0; the remainder is built in 16-bit limbs from the digits
below c0 by compile-time-constant multiplies; the long division is #228's; no new division.
Exactness: new test `top_certificates_match_the_lockstep_scan_and_the_cpu` (wgpu + CUDA): 102,365
intervals, 33,582 kept, 69,824 powers taking the carry, word-for-word vs the old lockstep scan and
vs the CPU `Base::cert`/`cert_floor`; all existing join parity tests (b50/b54 windows, dense fields,
whole b42, join = stride), host 221; lint clean; WGSL lint 0 flagged (incl. the test kernel at bases
10–64). Certified-top counts = main at 1e16; survivors/checks = main to the last digit at 1e14 (at
1e16/1e17 they vary run to run on main too, via the stage overrun, by the same amount).
RTX 3080 host-capped 180 W, interleaved, medians of 3 (spreads ≤ 2.7 %, every PR round beat the main
round before it): **b62 1e17 229.3 → 213.3 s (×1.075); b62 1e16 ×1.089; b60 1e16 ×1.053; b64 1e16
×1.040**; NiceMark 3711 → 3976 (×1.071), scenarios ×1.049–1.106, none slower; 1e14 ×1.007–1.055 (2
rounds). Top kernel alone ×1.24 (b62), ×1.22 (b60), ×1.08 (b64: its chunk divisor 2^12 was already
a shift). Not done: e^j still computed in full (only e^j − a^j is needed); a limb-bounded division
variant was bit-identical with no clear gain (patch saved); AMD/Apple not run.

## L1.7 Join profile at b62 1e17 (the live size) on main 9bde4a8 (2026-11-01, agent; `L1/PROFILE-3.md`, `L1/profile3-raw/`; branch `rp/gpu-profile-3` bddf20f)

RTX 3080 10 GB **host-capped at 180 W** (1430–1510 MHz; absolute seconds ~1.22× PROFILE-2's card;
shares and the fit carry over). **b62 1e17: 223 s device per field = 7.28 µs per prefix, the same
as b62 1e16.** Profiled shares (probe excluded, +7.2 % overhead): top certification **37.8 %**, join
45.7 % (survivor handling 26 % of the field, real AND lanes 12 %, per-top chunk cost 4 %, padding
3 %), check 3–4 % unprofiled (7.9 % profiled), bucket 3.3 %, other 5.3 %. Stage-overrun extra
checks 0.014 % (1.1e-4 of survivors). Layout 11 slices, 6,439 batches of 5–8 partitions, 30.6M
prefixes; host setup 19 s CPU per field, overlapped except the first slice.
**Refit (1e16 + 1e17, 12 runs, rms 1.6 %):** join = 1.18 ps × real lane-pair + 0.49 ps × empty lane
+ 60.8 ps × AND survivor + 238 ps × top; fitted on 1e16 alone it predicts 1e17 within 4 %: **1e17
adds no new cost term.**
**Levers at b62 1e17:** (1) top certification: 12 % faster = 5 % win, 25 % = 10 %; it costs 0.77 ns
per (prefix, partition) and only 32 % of those pairs certify; (2) survivor handling: 18 % cheaper
per survivor (or 18 % fewer survivors) = 5 %; (3) AND lanes: 37 % per lane-pair = 5 %; nothing else
reaches 5 % (padding 3 %, per-top 4 %, per-check 2.4 %). **Batches/slices are not levers
(measured):** halving the survivor bound (38 % fewer batches) ×0.994; 11 → 4 slices ×0.991 (wider
slices prune 9.4 % less). Notes: the first unchecked b62 field has no top-layer prefixes (empty);
at b64 #228's top kernel reads ~12 % slower than clock-scaled (b64 not live; card confounded).

## L28.1 Two-word digit mask in the native FD kernel on wgpu (2026-11-01, agent; `L28/RESULTS.md`, `L28/raw/`; branch `pr/fd-u32-mask` 2b8d524, NOT opened)

`fd_mask_u32` moved from cubecl_web.rs into cubecl_detailed_fd.rs and shared; `fd_mask_sc` picks
u64 on CUDA/HIP and the u32 pair on wgpu (switched on `wide_chunk`); no divisions. RTX 3060:
CUDA 3 FD tests + 44-base sweep (132 windows, 9.6e8 numbers, 180 near misses) exact; lavapipe via
naga and via CubeCL SPIR-V: FD tests + browser FD tests + sweep exact; host 221; fmt/clippy clean;
WGSL lint 0 flagged; u64-naming lines in the native FD kernel's WGSL 135 → 32 at b40 (prologue,
seed word split, near-miss record remain); browser kernels' WGSL byte-identical to main.
**Speed:** CUDA PR vs main 0.992 / 1.001 / NiceMark 0.996 (unchanged). **The pair forced on CUDA is
24 % slower** (0.766 / 0.763), so CUDA/HIP keep u64. lavapipe PR 0.91–0.94× main on a noisy shared
host → Vulkan on native-u64 cards (AMD, NVIDIA-wgpu) may lose. **Apple M4 and AMD unmeasured.**
Decision: hold the branch; measure on the M4 and on AMD before opening; if AMD loses, gate the pair
to Metal adapters only (the wgpu backend enum is already read for the earlier Metal gate).

## L24.4 AMD parity for #233, run by the user (2026-10-31; `parity-demoux-1031.json`)

demoux, RX 9070 XT, LibreWolf (Firefox 155, wgpu → naga → Vulkan), `parity.html` served from
ivory (https://100.109.36.42:8443), build ae8b0bd, `gpu_build_info.detailed_kernel = "fd"`.
**199 windows, 25,471,443 numbers, 50 near misses, 0 differences, 23 s wall**; adapter present,
not a fallback (Firefox blanks vendor/architecture/description). Rate check: 2e8 at b40 in 0.117 s
= 1.71e9 n/s with Firefox's 16.7 ms timer steps (sanity floor only; the browser benchmark suite
on AMD is still unmeasured). The user noted LibreWolf now runs it without flags ("they must have
pushed some updates"). With this, #233 is exact on: lavapipe, SPIR-V, SwiftShader, M4 Chromium
(Tint → Metal), M4 native (naga → Metal), and AMD Firefox (naga → Vulkan).

## L24.3 Browser GPU detailed mode by finite differences (PR #233) (2026-10-31, agent; `L24/RESULTS-B.md`, `L24/raw-b/`; branch `pr/web-detailed-fd`, rebased onto main ba03322)

Exactness, 0 differences everywhere: native lavapipe (naga) `web_fd_matches_cpu_detailed` 430
windows (§3.3 list), `web_fd_seed_matches_cpu` 132/132 word for word, existing `web_kernel_*`
tests; CubeCL SPIR-V compiler: same five tests; CUDA FD suite + native lavapipe FD suite (native
kernel unchanged); host 221; fmt/clippy clean (default, gpu, gpu+spirv, wasm crate host and
wasm32 `--no-deps`); WGSL lint 122 shaders 0 flagged (FD kernel + seed probe at all 44 bases; no
u64; hot loop has no division); SwiftShader (CI image) `run.sh`, harness parity 199 + 13 windows,
seed probe 132/132, 78 run-shape runs; **M4 Chromium 151 headless no flags: parity 201 windows
(4.25e8 numbers, 50 near misses) + 440-window sweep, seed probe 132/132, 318 run-shape runs**; M4
native naga→MSL (Firefox's path): five tests pass, with the half-shift reproducer still failing
there as a live control.
**M4 speed (3 rounds, interleaved, spreads ≤0.4 %):** b40 6.59e8 → 4.40e9 (**6.7×**), b50 3.82e8 →
3.86e9 (**10.1×**), browser GPU NiceMark 265 → **2170 (8.2×)**. The browser now runs ~1.8× the native
wgpu FD kernel on the same M4 (guess: the native kernel's u64 mask is emulated on Apple; a u32 mask
there is a separate change = new lead). Run length stays 128 (64 is 3–5.5 % slower, 256 +0.7/+2.4 %).
Machine time 29 min wall (~15 min running). CI cost: +~85 s per lavapipe pass, +~140 s on SPIR-V.
**Coordination:** #231's lint `--require DetailedKernelU32@40/50` must gain `DetailedFdKernelU32@40/50`
(and keep one per-number call) once both are in; whichever lands second carries that edit.

## L24.2 Parity step, adapter check and WGSL lint (PR #231) and the CI flake (2026-10-31)

**PR #231** (`pr/browser-parity-step` 0f87771 on 2a1caf2): `web/search/parity.html` + `parity.js`
compare `process_chunk_gpu` vs `process_chunk_wasm` as raw JSON byte for byte and show adapter info;
the e2e drives the same page (CI: 13 windows, 9.3 s; `--parity hw`: 199 windows, 2.5e7 numbers);
a difference fails with the window and first differing field; a hung window fails and continues;
no adapter → `PARITY SKIPPED`; `--hw` requires a real non-fallback adapter matching
`--expect-vendor` and a warm 2e8 b40 call > 1e8 n/s. `scripts/wgsl-lint.py` + ignored test
`wgsl_dump_for_lint` (browser, detailed, stride, join kernels) in the lavapipe job: 8 s, 14 shaders,
0 flagged on main; flags the pre-#225/#228/#229 shaders and the reproducers. CI e2e 64 s vs 50–53 s
on main. M4 headless: `--hw --parity hw` passes in 26 s (199 windows, 50 near misses identical);
`--parity-random 10`: 639 windows identical; `--expect-vendor amd` fails as designed. Side note:
rootless podman on ivory leaves an empty `oom` file in the cwd; **upstream main has a tracked
`oom` at the repo root since #226** (same cause, the user's commit).
**CI flake diagnosed:** run 41219859643 attempt 1 (main 2a1caf27, NVRTC job) failed
`gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field` at
gpu_niceonly.rs:1730: left = 250000-wide descriptors, right = 500000-wide; the log shows the
adaptive MSD floor firing under load ("250000 → 270856, cpu waited 33 %"). The same test failed 3×
on the boxes under `--test-threads 8`, always passing alone (L25/L26). Timing-dependent test →
fix = pin the floor in the test (L27, agent running).

## L24.1 Headless WebGPU bring-up on the M4 and PR #230 (seed refactor) (2026-10-31, agents; `L24/BRINGUP-M4.md`, `L24/RESULTS-A.md`)

**Bring-up (22 min of Mac time):** Playwright 1.62 `channel: "chromium"` (Chrome for Testing 151),
macOS 26.3, over SSH, no GUI: adapter `apple`/`metal-3`, `isFallbackAdapter` false, warm 2e8 b40
call 6.56e8 n/s with **no flags**; `--enable-webgpu-developer-features` unmasks "Apple M4";
SwiftShader (CI pin) reports google/swiftshader, fallback true, 1.77e7 n/s. **Today's browser GPU
kernel is exact on Apple through Chrome's Tint:** 201 windows (§3.3 + both 2e8 benchmark windows),
4.25e8 numbers, 46 bases, 50 near misses, 0 differences; repeat identical; extra seeded sweep 440
windows 0 differences; CI subset on SwiftShader ~11 s. Rates: b40 6.58e8, b50 3.83e8, browser GPU
NiceMark 263–265. Harness: fork `exp/browser-gpu-harness` 5eeed09 (`wasm-client/e2e/hw/`).
**PR #230 (`pr/fd-seed-split16` 215952d):** `fd_seed_split16(nw: &Array<u32>, …)`; step helpers,
`fd_to_digits`, `NO_CARRY` pub(crate); CUDA/HIP branch untouched. 3080: fmt, 3 clippy runs, 220
lib tests, 3 CUDA tests (+ `NICE_CUBECL_WIDE=0` exercising the shared fn on the GPU); lavapipe seed
132/132 + FD/near-miss/detailed; **M4 seed 132/132 on Metal**, FD + near-miss pass; the half-shift
reproducer still fails there (control). WGSL: same code up to renaming at 14 bases + the seed
probe at 44 bases; only n's words go through an `array<u32, limbs>`. NiceMark split16 path
+0.2 % / −0.3 % (drift ~1 %). M4 34 min wall (~2 min compute).

## L26.1 Stride prefilter defensive fix (2026-10-31, agent; `L26/RESULTS.md`, `L26/raw/`; PR #229, branch `pr/metal-halfshift-prefilter`)

`candidate_check`'s low-digit prefilter (b ≤ 40 only). The #228 "top pair as one u32" construction
would, at two limbs (b33–40), divide `u32(n_lo >> 32)` = the u64 form of the bug (a compiler folds
the rebuilt halves back into the word; #228 escapes because its pair is a u32 sum). So each pass
divides the top pair as hi·Q + (hi·R + lo)/K with 2^16 = Q·K + R; every dividend is that sum or
`rem << 16 | limb` with a run-time remainder. Python model exact over ~3M cases, no overflow.
RTX 3060 (58548226, 1.08 h): lavapipe probe/cross-filter/`matches_cpu_niceonly`/`finds_69` pass;
CUDA `cubecl_cuda_matches_cpu_niceonly` + local CUDA copies of the probe and cross-filter tests
pass; 27-window sweep b28–40: 9,675 of 1,475,822 survivors = host mirror = main on both runtimes.
WGSL flagged sites main → fix: b30 6→0, b34 6→0, b40 6→0. Host 208/208, fmt/clippy clean. Not
M4-run (the paired form passes there today; the fix is defensive). Note: `matches_cpu_niceonly`
and `finds_69` barely touch the prefilter (none at b10/12/25; b40's 5e6 window launches nothing);
M4-CONFIRM's "b25 runs the prefilter" was wrong. Rebased onto main 7362e18 (CHANGELOG conflict).

## L25.2 M4 confirmation of #228 and the stride prefilter probe (2026-10-31, agent, 8 min of mayalaran; `L25/M4-CONFIRM.md`, `L25/raw/m4/`)

**#228 prediction confirmed (twice):** 472c9a0 + windows fails `cubecl_join_matches_the_cpu_reference`
at b50 with **0 join survivors vs the CPU's 934** (prefilter 0 vs 97); a per-window run shows b54
**0 vs 445** (0 vs 51); the other 18 windows agree. The branch (56b68bf) passes everything incl.
both windows, the b57 frontier field, tight/sliced/refused layouts; `join_sample_runs_partitions_
of_a_production_field` passes on both trees. The device loses every survivor → missed nice numbers
at b49–55 on a Mac without the fix. PR body + comment updated.
**Stride prefilter (cubecl_backend.rs:433–437), main:** `cubecl_prefilter_survivors_match_the_host_
mirror` passes twice at b30/34/40 (every lane width); `cubecl_matches_cpu_niceonly` (b10–80),
`cubecl_cross_filter_survivors_match_the_host_mirror`, `cubecl_niceonly_finds_69_in_base_10` pass.
So the paired `/`+`%` form still dodges the bug today; the fix is defensive (user: fix unless it
costs current work; it runs only at b ≤ 40, so it cannot).

## L25.1 Apple half-shift-divide audit of the GPU kernels (2026-10-31, agent; `L25/AUDIT.md`, `L25/raw/`; PR #228, branch `pr/metal-halfshift-top-kernel` 56b68bf on 472c9a0)

Source audit + WGSL dumps of 97 kernels on lavapipe (RTX 3060 box 58492432, $0.056/h, 1.17 h).
**One production kernel carries the pattern: the join's `top_kernel` (`cert_power`,
cubecl_join.rs:656–665)**: unrolled split16 division, first dividend each pass `x[top] >> 16` ÷ b^k;
28–64 flagged WGSL sites per base. Harmless at b40–44 and b57–64 (top limb of n², n³ is 0; b64's
divisor is a power of two); **wrong on Apple at b49–55** (the low-half model predicts 76–100 % wrong
digits) → lost join survivors → a nice number could be missed on a rescan/verification run on a Mac.
Stride prefilter (b ≤ 40 only) has the shape (6 sites) in a paired `/`+`%` form that passed the M4
probe in August (that August mul-sub failure was very likely this bug). Everything else is clean.
**Fix (ed972c7):** powers in 16-bit limbs, top limb pair divided first (the #225 construction);
no flagged sites in any of the 97 dumped kernels; `56b68bf` adds join windows with survivors at b50
(934/97) and b54 (445/51). CUDA 3/3 and lavapipe 3/3 on the branch and on main+windows; host 208;
lint clean. Throughput 0.997 (b58) / 0.984 (b62), inside main's 1.2 % / 2.4 % spread; survivor and
check counts identical over 3 × 1e14 fields per base. Not run on the M4 (needs a window): main +
windows expected to FAIL `cubecl_join_matches_the_cpu_reference`, the branch to pass.

## L23.1 Browser CPU detailed mode on finite differences (2026-10-31, agent; `L23/RESULTS.md`, `L23/raw/`, `L23/harness/`; PR #227, branch `pr/wasm-detailed-finite-diff` fe38c7e on #221's 7019653)

`process_chunk_wasm` → `process_range_detailed_fd` (2 files, 7 lines). Exactness: old wasm (d1ff798)
vs new, same `wasm-pack` command as CI, headless Chromium 151 (Playwright 1.62 image via rootless
podman on ivory): 141 windows, 36.4M numbers, raw JSON byte-identical (benchmark windows in three
chunkings, the 10M offline field, six windows per base 40–64, full ranges of bases 10–24 with 27
near misses, the e2e's b49 near miss above 2^53, 20M around the first b40 near miss). CI's e2e
`run.sh` passes locally; its CPU-vs-WebGPU histogram check agrees.
Speed (page suite, 60 s, 3 workers, interleaved ×3, M n/s): b40 3.564 → 36.571 (×10.3); b50 4.715
→ 31.127 (×6.6); b50_1t 1.782 → 8.776 (×4.9); NiceMark 246 → 1711 (×7.0); spreads ≤1.8 %. Per
number: wasm 683 → 58 ns (b40), 508 → 70 (b50), 655 → 72 (b60); native on the same box 266/43,
414/49, 541/50. The page + worker pool adds ~45–55 ms fixed per suite window (why `_1t` gains less).
Note: wasm32 clippy without `--no-deps` fails on a pre-existing lint at cubecl_web.rs:63 on main too
(CI never runs it); left alone.

## L3.7 Verification of the fixed FD branch on CUDA and lavapipe (2026-10-30, agent; `L3/verify/VERIFY-297a969.md`)

RTX 3080 (58428313, KR; host-capped at 150 W, 1545 MHz), 297a969: fmt, both lint clippy lines +
`--features gpu`, release build; 209 host tests; CUDA `cubecl_cuda_fd_matches_cpu_detailed` (every
window exact, FD = division = CPU on the benchmark windows, 73 near-misses), `..._matches_cpu_detailed`,
`..._reads_back_every_near_miss`, hand-CUDA `gpu_matches_cpu_detailed_small`; lavapipe all six wgpu
tests incl. `cubecl_fd_seed_matches_cpu` 132/132 windows; reproducer passes on llvmpipe. A
diagnostic build confirmed FD serves every b40/b50 window on CUDA and llvmpipe. Speed vs the
pre-fix PR (18cba8b), interleaved: 1.000× (b40), 0.999× (b50); absolute 2.86e10 / 2.50e10 at 150 W.
**#225 → single commit dbe2ab7 on main 9747e39 (tree = 297a969 + main's pool-size change), body
rewritten, marked ready for review, resolution comment posted.**

## L3.6 Root cause and fix on the M4 (2026-10-30, agent, 1 h 11 min of mayalaran; `L3/METAL-FIX.md`, `L3/metalfix/`; branch `pr/gpu-detailed-fd-metalfix` 297a969)

**Apple GPU compiler bug, confirmed with hand-written MSL (no wgpu/naga):** unsigned division or
remainder by a non-power-of-two constant is wrong when the dividend is a right shift by half the
width: `naga_div(x >> 16u, K)`, `(x >> 16u) % K`, `uint(ulong p >> 32) / K`. The unrolled split16
seed (`fd_to_digits`) made the first dividend of every chunk a bare `top_limb >> 16`, so n²'s (and
at some bases n³'s) digits were wrong from digit 0; limbs were exact. b23 is the same bug (at
K = 12167 a zero dividend returns 4), not a second fault. The per-number kernel is exact because
its long division is a runtime loop with a loop-carried remainder.
**Fix (af41956):** the wgpu seed in 16-bit limbs, u32 arithmetic only, each chunk's division
starting from the top two limbs as one u32 (no bare shift; one division fewer per chunk);
CUDA/HIP path, hot loop, mask and histogram unchanged. d9261a8: `fd_seed` + per-n seed test
`cubecl_fd_seed_matches_cpu` (1024 n at start/middle/end of all 44 bases, word for word) + the
minimal reproducer `metal_half_shift_div_repro` (ignored, `NICE_METAL_DIV_REPRO=1`). 297a969
reverts the gate.
**M4:** seed test failed before at b23, 25, 27–30, 49, 50, 52–55 and passes after; all FD/readback
tests pass; 220-window sweep of bases 10–64 (3.08e7 numbers, incl. run length 1) identical to the
CPU. Speed unchanged vs the PR: b40 2.435e9, b50 2.187e9, NiceMark 1216 (main 330): 3.00× / 4.54×.
Not done: CUDA/Vulkan re-run (verification agent), other Apple GPUs/macOS versions, Apple
Feedback report, **nice-only kernels not audited for the pattern (L25)**.

## L3.5 Metal gate for #225 and the desk root cause (2026-10-30, agent; `L3/METAL-ROOT-CAUSE.md`, `L3/pr-raw/gate/`)

Gate commit d8038d6 (head of `pr/gpu-detailed-fd`): the wgpu context records whether the adapter
backend is Metal (wgpu's backend enum, not the name); `DetailedKernel::for_device(base, metal)`
sends Metal to the per-number kernel; CUDA/HIP/Vulkan/DX12/GL keep FD; unit test
`detailed_kernel_by_device`. RTX 3080 box 58419619: fmt, all clippy lines, 210 lib tests, CUDA FD
tests and lavapipe FD tests pass with FD still serving; speed unchanged (b40 3.339e10 vs
3.331–3.467e10; score 16,591–16,614 vs 16,571–17,121).
**Root cause, modelled:** the seed's digit conversion computes `(x >> 16) / K` on the top word x
of n² and n³; if Apple's compiler divides the low 16 bits of x instead (the 16-bit form of the
2026-10-06 `hi(a·b)/K` miscompile), the model reproduces all 400 per-number results at b50 and
77 of 79 sweep windows exactly, including the base bands, the b32 exemption (power-of-two
divisor) and the passing windows inside failing bases. **b23 is not explained** (top words too
small). Artefacts for the Mac: `h2_repro.swift` (standalone Metal reproducer), `seed-dump-diag.patch`
(ignored test `zz_seed_dump_wgpu`, exact on CUDA and lavapipe). Cheapest fix: seed through the
per-number kernel's shared-memory long division (exact on the M4); never fold into one `x / K`.

## L3.4 #225 on Apple M4 (Metal): WRONG RESULTS (2026-10-30, agent, user-authorised 1 h; `L3/METAL-M4.md`, `L3/pr-raw/m4/`)

mayalaran: macOS 26.3 (25D125), M4, Rust 1.99.1; offline build (179 crates copied from ivory);
29 min of machine time, cleaned up. `auto` = CubeCL wgpu, "Apple M4 (Metal, wgpu<wgsl>)".
- `cubecl_fd_matches_cpu_detailed` FAILS (first b50 window; all b40 windows pass under every run
  shape); `cubecl_reads_back_every_near_miss` FAILS at b23; main's tests pass on the device.
- Per-base sweep: FD wrong at b23, b27–30, b49 (mid), b50, b52 (mid), b53–55; division exact in
  all 79 windows. Per n: 77 % wrong at b23 start, 87 % at b50; window histograms move only a few
  percent (the tests barely catch it).
- Every run length fails incl. 1 number per run → not stepping; seed, packing or mask build as
  compiled by Metal. Root cause unknown; prime suspect the Apple Metal compiler (cf. the
  2026-10-06 hi(a·b)/const miscompile seen via cubecl-metal). WGSL + naga MSL dumps saved.
- The CI "cubecl (Metal) on macOS" job (paravirtual GPU, #218) passed the same commit: it does
  not reproduce real-hardware Metal behaviour.
- Speed (3 rounds, spreads ≤0.3 %): b40 8.116e8 → 2.437e9 (3.00×); b50 4.812e8 → 2.183e9 (wrong
  kernel); NiceMark 329 → 1216. No thermal decline over 60 s reruns.
Action: #225 → draft + comment; gate FD off on Metal adapters pending the root cause.

## L3.3 Second card for #224/#225: RTX 4090 (2026-10-30, agent; `L3/AB-4090.md`, `L3/pr-raw/4090/`)

Vast RTX 4090 (58401579, CA, $0.374/h), not power-limited (480 W limit never reached) but
thermally limited (85–90 °C vs 83 °C target, fan 100 %, slowdown active in every snapshot);
clocks ~2.5–2.6 GHz main/rb, ~2.63 GHz FD. Trees main 46e4dc4 / rb 6a1e396 / fd f3a33cf.

| measurement | rb vs main (b40 / b50) | FD vs main |
|---|---|---|
| NiceMark detailed GPU, 6 interleaved rounds | 1.137 / 1.093 | 3.459 / 3.922 |
| NiceMark score (main 11,493) | 12,800 (×1.114) | 42,296 (×3.680) |
| 2e9 windows, 3 rounds | 1.023 / 1.007 | 3.022 / 3.634 |
| 1e10 fields, production path (`--repeat`, mock API, 3×8) | 0.997 / 0.995 | 3.061 / 3.767 |

FD vs rb per clock 2.87× / 3.31× (3080: 2.78× / 3.42×). An FD 1e10 field is ~0.11–0.12 s, so a
4090 needs ~9 claims/s. Exactness: all FD tests under CUDA; results identical across the three
trees on every window and on all 147 production submissions. wgpu FD test ran on llvmpipe only
(the NVIDIA Vulkan driver did not load in the container). Both PR bodies updated with these.

## L1.6 Partitions per launch + pruned buffer sizing, and the flush race (2026-10-30, agent; `L1/LAUNCH-RESULTS.md`, `L1/launch-raw/`; branches `pr/join-partitions-per-launch` c4ac700, `rp/join-flush-barrier` 61e6ba9 → PR #222, `rp/launch-with-barrier`)

RTX 3080 20 GB (58361499, 320 W = default), 10 GB layouts via test-only `NICE_TEST_JOIN_MAX_BUFFER`.
- **1e14, 10 GB budget, 3 rounds:** ×0.881 / 0.868 / 0.793 / 0.832 of main's time at b58/60/62/64
  (16 → 64 partitions per launch; 211–256 → 53–64 batches). 20 GB: ×0.899 / 0.868 / 0.787 / 0.826.
  Cap 64 beats "as many as fit" (105–177) by 1–4 %; a 16–177 sweep is fastest at 64 at every base.
- **1e16: neutral** (×0.992–1.011); 1e15 neutral with b58 1–2 % slower; NiceMark ×1.002
  (b58_msd_weak ×0.969 in 3 rounds, within that scenario's ±3 % noise here).
- **PARKED (director):** the live fields are 1e16 at b60 and **1e17 at b62** (data API
  `fields`, 2026-10-30), so a change that is neutral above 1e15 does not help production and
  does not move NiceMark. The "production size = 1e14" premise in the L1.5 brief came from a
  stale code comment ("Production fields at the frontier are 1e14"). Keep for small-field work.
- **The extra full checks are a race in `join_kernel`'s per-chunk flush decision**, not stage
  overruns: no barrier between the `s_cnt` load and the next chunk's appends, so a late plane
  can decide alone to flush and the cube's barriers pair at different call sites; stale list
  entries get fully checked and entries can be overwritten (survivors never checked). Frequent
  once cubes grid-stride (>16–19 partitions per launch); possible by the code in main's 1e16
  layouts. Instrumented: 12 of 50 base-runs at ≥64 per launch without the barrier showed a
  signature, 0 of 18 with it; 0 of 76 at 16–32. Fix = one `sync_cube()` after the load; cost
  within noise at 1e14 (×0.99–1.00), ≤ ~1.5 % at 1e16 unresolved. **PR #222.**

## L3.1 GPU detailed mode by finite differences, prototype (2026-10-30, agent; `L3/GPU-FD.md`, `L3/raw-fd/`; branch `exp/gpu-detailed-fd` e0c1b4c on the fork)

Vast RTX 3080 (58350503, KR, $0.108/h), **power-capped at 180 W** (default 340 W): the old
kernel ran ~1,425 MHz, FD ~1,690 MHz, so ~1.18× of the gain is clock; per clock FD is ~2.2×
(b40) / 2.7× (b50). 3 interleaved rounds, medians. Best variant v3: 128 numbers per thread,
high words of n²/n³ masked once per run (they change only on a rare carry; removes 14 of 50
masked digits at b50), one rare-carry branch per step.

| measure | b40 | b50 |
|---|---|---|
| benchmark harness, production host path | 2.60× (2.05e10 vs 7.88e9 n/s) | 3.22× (1.86e10 vs 5.78e9) |
| harness, both arms with the near-miss readback fix | 3.22× | 3.97× |
| 2e9-number window (mostly kernel) | 3.28× | 3.97–4.03× |

Run length flat within 3 % from 64 to 512 numbers per thread. Per-thread histogram was 5–7 %
slower than one shared atomic per number; a 2-digit lookup table within 2 % (both off).
Registers 96 (v1) → 48 (v3), no spills, 83 % occupancy; limited by integer instruction rate:
mask build ~4.5 instructions per digit = 55–60 % of the work, digit adds ~30 %.
Exactness: histogram and near-miss list equal the CPU's at every commit; test covers b40/b50
range start/end, 8 random windows, addend digit-gain windows, a window straddling the range
start (split across the two kernels), under 7 option sets, plus the full 2e8 benchmark windows
and every base 10–28 in full (73 near-misses). CUDA parity test, library tests, clippy clean.
**Side finding (independent of FD):** every call copied back the whole 20 MB near-miss buffer
(~1.7 ms over PCIe 3) even with zero misses; reading only what was written gives +5–8 % for
the current kernel and +30 % for FD. Worth its own small PR.
**Caveat for production:** at FD speed a 1e9-number detailed field is ~40 ms of GPU, so the
claim/submit round trip may dominate wall-clock; server-side detailed field size (BACKLOG 13)
becomes the limiter before the 3–4× shows in production throughput.

## L1.5 Join re-profile on main d1ff798 (prune + EPT 2 + closure + memory budget) (2026-10-30, agent; `L1/PROFILE-2.md`, `L1/profile2-raw/`; branch `rp/gpu-profile-2`)

Vast RTX 3080 **20 GB** (58350591, US, $0.149/h; 320 W cap = default; so the memory budget is
4 GiB and 1e16 layouts differ from 10 GB cards). Profiled with the probe readback excluded;
profiling adds 6–10 % at 1e14, ~0 at 1e16; unprofiled main matches within 1.5 %.

| | device s/field (b58/60/62/64) | top | bucket | join | check | other |
|---|---|---|---|---|---|---|
| 1e14 (20 fields) | 0.689 / 0.585 / 0.569 / 0.679 | 22/19/17/9 % | 11/14/16/14 % | 52/50/49/58 % | 6–7 % | 9–12 % |
| 1e16 (2 fields) | 46.3 / 33.9 / 14.6 / 42.9 | 30/34/41/15 % | ≤1 % | 62/57/51/77 % | 5–7 % | 1–3 % |

Refit at 1e16: 0.62 ps per padded lane-pair + 64 ps per AND survivor (rms 5.7 %, max 11 %,
over-predicts b64: empty lanes are cheaper than filled); + 406 ps per top → rms 2.9 %. At
1e14 the two-term fit fails (rms 33 %); + 15.6 ns per (partition, bucket) work item → rms
5.9 %. Each launch costs ~0.5 ms; **the 1e14 per-field fixed cost is 40–74 % of a field.**

**Levers ranked:** (1) more partitions per launch at 1e14: 16→32 gives ×0.92/0.90/0.83/0.87
of the time, 16→64 ×0.88/0.86/0.78/0.83 (b58/60/62/64); 32 fits 10 GB cards, 64 needs the
lists sized by the pruned slice (#215's deferred buffer sizing); one b64 run at 64 showed
0.4 % extra full checks, cause unknown, to be understood first. (2) survivor handling at
1e16: 25–59 % of device time. (3) top certification: 15–41 % (41 % at b62 1e16). (4) real
AND lanes at 1e16: 13–26 %. (5) wave padding: ~0 at 1e14 (EPT 1 costs ×1.08–1.10), 2–7 %
at 1e16, 9–15 % at b64. (6) bucket build 11–16 % at 1e14. (7) b60 stage overrun ~0.3 %.
(8) partitions per launch at 1e16: nothing.

## L2.2 Detailed finite differences through the client, NiceMark protocol (2026-10-30, agent; `L2/PR-RESULTS.md`, `L2/pr-raw/`; PR #221, branch `pr/detailed-finite-diff` 7019653)

Vast box 58350466: Xeon E5-2682 v4 (Broadwell), container quota 15.36 CPUs (`--threads 0`
→ 15), clocks uncapped. A = main d1ff798, B = branch (045797e, comment-only diff to
7019653), `nice_client detailed --benchmark --benchmark-secs 150`, A B A B A B.

| scenario | A (M n/s) | B | B/A |
|---|---|---|---|
| b40_detailed, 15 threads | 51.55 (−0.1/+0.9 %) | 287.95 (−0.2/+1.2 %) | **5.59×** |
| b50_detailed, 15 threads | 33.80 (−0.3/+0.1 %) | 271.09 (−0.0/+0.5 %) | **8.02×** |
| b50_detailed_1t | 2.22 | 15.23 | **6.85×** |
| detailed score | 1247 | 8424 | **6.76×** |

`--threads 1`: 5.57× / 8.12× / 6.80×, score 6.75×. `--threads 64` (4× oversubscribed,
cgroup throttled): 3.10× / 5.15×, score 4.80×; both trees slow, the new loop more. Pinned
per-number: b40 280→50 ns, b50 435→57, b60 560→58. Tests on the box: 180 passed, 5 ignored.
Production = the packed variant only (8 digits per 64-bit biased add); dispatch in common
(`process_range_detailed_fd`, bases 40–64 with a legal range except 63; others → division);
client's CPU chunk path calls it. Not run: GPU-feature clippy, WASM build (CI will).

## L1.4 Prune against new main on an RTX 4090, and the wave size (2026-10-29, agent; `L1/AB-4090.md`, `L1/pr-raw/4090/`)

Vast RTX 4090 (58197772, Poland, $0.375/h; **power-limited to 330 W**, so absolute times
are slow, ratios hold). A = upstream main 2709d3f (+ the two test-only harness commits);
B = `pr/field-cert-prune` 26a8b15 (rebased prune). 3 interleaved rounds, spreads ≤ 2.4 %.

| fields | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| prune vs main, 1e16 (2 per base) | ×1.097 | ×1.084 | ×1.112 | ×1.205 |
| prune vs main, **1e14 (production size, 20 per base)** | ×1.41 | ×1.50 | ×1.87 | ×1.79 |
| prune + EPT 2 vs main, 1e16 | ×1.19 | ×1.16 | ×1.26 | ×1.52 |
| prune + EPT 2 vs main, 1e14 | ×1.55 | ×1.55 | ×1.97 | ×2.08 |
| old pair on this card (85b5b4e base vs prune), 1e16 | ×1.14 | ×1.14 | ×1.37 | ×1.58 |

The 1e16 gains are below the 3080's day-1 numbers because new main carries #205's EPT 6 at
b62/b64 (a bad wave for pruned buckets) and #203/#206's own gains; the card is not the
cause (old pair reproduces the 3080). NiceMark (prune as pushed): 8086 → 9494 (×1.174);
b58 weak ×1.152, b58 strong ×1.330, b60 weak ×1.075, b62 weak ×1.126; all on the join.
**EPT with the prune: 2 < 3 < 4 < 6 in every round at every base**; 2 beats 4 by
×1.07–1.13 and 6 by ×1.15–1.27; at 1e14 EPT 1 is ~5 % better at b58 and tied elsewhere.
Exactness: `NICE_TEST_JOIN_COMPARE=1` 0 = 0 at every base; survivor and check counts identical
to the last digit across trees at 1e14; CUDA parity 3/3; CPU prune test passes; the 3080's
stage-overrun shift does not appear on new main. Bottoms removed: 55–77 % at 1e16, 72–86 %
at 1e14. Not done: the b64 1e16 dense test timed out at 300 s; NiceMark with EPT 2; EPT 1 at 1e16.

## L2.1 Detailed mode by finite differences, CPU prototype (2026-10-29, agent; `L2/RESULTS.md`, branch `rp/l2-finite-diff` on the fork: b003967 scalar, da9aaeb 8 digits per 64-bit add)

`common/src/detailed_fd.rs::process_range_detailed_fd`, same signature and output as
`process_range_detailed`; bases 40, 42–45, 47–50, 52–55, 57–60, 62, 64 (others fall back).
Not wired into the client. ivory, one thread pinned to core 3, the `b50_detailed_1t` window
(base-range start, 1,000,000 numbers), two passes of 3 interleaved rounds, median ns/number:

| base | old | scalar | × | 8 digits per add | × |
|---|---|---|---|---|---|
| 40 | 265 | 60 | 4.4 | 42 | 6.2–6.3 |
| 50 | 416–418 | 73–74 | 5.6–5.7 | 48–49 | 8.5–8.6 |
| 60 | 537–541 | 89 | 6.0–6.1 | 50–53 | 10.1–10.8 |

Old within ±1 %, new within ±2–5 %. Cycles per number at b50: old 1,390, scalar 244, packed 163.
Exactness: 11 tests, all pass for both variants: per-number equality with `get_num_unique_digits`
on 20 seeded 10k windows plus both range ends at b40/50/60 and b42/47/53/59/64; 7 windows per
base around every digit-gain point of n² and n³; b7 and b10 from n = 0; whole `FieldResults`
identical on the b40_detailed and b50_detailed windows; 27 near-misses identical over bases
10–24. Clippy clean, 179 lib tests pass.
Lessons: LLVM first compiled the digit carry as a mispredicted branch (17.5 misses per number,
only 1.6–2.2×); a branch-free select fixed it, and the GPU port must watch for the same. Packed
version profile: adds + bookkeeping 57 %, mask build 30 %, popcount + histogram 13 %. Production
builds target baseline x86-64, so `count_ones()` is a 17-instruction software popcount (both paths).
Next: wire into `client/src/main.rs` (~line 845) and run the 5 % protocol on b40_detailed,
b50_detailed, b50_detailed_1t (needs a box: ivory cannot build the client); then the GPU port
(each thread walks a run of ≥100 consecutive numbers with ~24 u32 of digit arrays in registers).

## L1.3 Field-certificate bottom prune, GPU A/B (2026-10-28, agent; `L1/PRUNE.md`, `L1/prune-raw/`)

Branches on the fork: `rp/field-cert-prune` (head 4670ffe; the prune is c1174c1, the rest
tests), `rp/field-cert-prune-base` (2d740d3 = 85b5b4e + the same harness, the A tree),
`rp/field-cert-prune-ept` (6e4e895, prune + EPT override). Vast RTX 3080 (58056651),
1e16 fields, 2 per base, the L1.2 starts, A B A B A B (3 rounds), median s/field (spread):

| base | main | prune | speed-up | bottoms removed |
|---|---|---|---|---|
| 58 | 69.36 (0.9 %) | 60.18 (1.1 %) | **1.153×** | 59.5 % |
| 60 | 45.26 (1.2 %) | 39.52 (1.2 %) | **1.145×** | 54.6 % |
| 62 | 26.98 (1.0 %) | 19.07 (0.6 %) | **1.415×** | 74.3 / 66.7 % |
| 64 | 83.42 (2.4 %) | 50.79 (0.6 %) | **1.643×** | 77.1 % |

NiceMark nice-only, 3 rounds, every scenario on the join in both trees: b58_msd_weak
+17.6 %, b58_msd_strong +32.5 %, b60_msd_weak +20.1 %, b62_msd_weak +43.9 %; score
2892 → 3705 (+28 %). Batches and slots identical (buffers still sized by the unpruned
count). At 1e14 production size the prune removes 73–86 %, so production gains are
probably larger (unmeasured).

Exactness on the box: CUDA kernel compiles; 194 host tests; `cubecl_cuda_join_matches_the_cpu_reference`,
the dense-field and whole-field CUDA tests, the CPU reference test, and the throughput
harness with `NICE_TEST_JOIN_COMPARE=1` (join = stride on 1e14 fields) all pass; clippy
`--features gpu -D warnings` clean. One behavioural ripple: the prune tree records 0.94× the
AND survivors and correspondingly more unfiltered prefilter survivors (2–2.5e-4 of
survivors), i.e. survivors that overflow the join kernel's staging area go to the check list
unfiltered, as on main but a little more often; +0.3–0.4 % full checks, and b64 crosses the
dense-field test's 1e-4 limit. Fix for the PR: flush every 16 tops or a larger stage.

**EPT sweep with the prune (`rp/field-cert-prune-ept`):** EPT 2 is best at every base:
×1.088 (b58, 1 round), ×1.053 (b60, 1 round), ×1.060 (b62, 2 rounds), ×1.139 (b64, 2
rounds) over EPT 4; EPT 1 worse than 2 everywhere. Prune + EPT 2 vs main at EPT 4:
**1.51× at b62, 1.91× at b64** (against the L1.2 numbers on the same machine, not
interleaved). So PR #205's EPT 6 and the EPT 5 note both give way to EPT 2 once the prune
is in; pruned buckets are 3–4× smaller, so the wave shrinks.

## L1.2 GPU join phase profile by base (2026-10-28, agent; `L1/GPU-RESULTS.md`, branch `rp/gpu-profile` on the fork)

Vast RTX 3080 (instance 58051111, $0.134/h), upstream 85b5b4e + `NICE_EXP_GPU_PROFILE=1`
(costs 3.9–6.3 % of device time; shares from profiled runs, seconds from unprofiled),
1e16 fields, 2 per base, CubeCL CUDA.

| base | roots | device s/field | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|
| 58 | 4 | 68.8 | 19.5 % | 3.8 % | 64.8 % | 4.7 % | 7.3 % |
| 60 | 2 | 45.2 | 23.3 % | 5.1 % | 55.8 % | 5.3 % | 10.5 % |
| 62 | 2 | 26.1 | 21.9 % | 7.2 % | 57.9 % | 3.6 % | 9.5 % |
| 64 | 8 | 83.1 | 7.1 % | 3.3 % | 82.6 % | 3.1 % | 3.9 % |

| base | µs/prefix | RX 9070 XT | AND survivors/prefix | prefilter survivors (= full checks) |
|---|---|---|---|---|
| 58 | 11.44 | 11.2 | 63.7k | 3.84k |
| 60 | 8.51 | 6.8–7.3 | 43.8k | 3.10k |
| 62 | 9.96 | 9.2–9.6 | 34.8k | 2.20k |
| 64 | 26.84 | 19.5 | 139.8k | 8.77k |

- Everything but the join kernel costs 4–5 µs per prefix at every base; tops per prefix
  1180–1300 everywhere. The join kernel carries the whole b64 jump (23.0 µs vs 6.1 at b62).
- Survivors per prefix = tops × roots × bucket occupancy (930–1210 at every base) × AND
  pass rate. b64/b62 survivors 4.02× = roots 8/2. b58/b60 1.45× (pass rate 1.41 % vs 1.81 %).
- **Join kernel cost model** (10 fields, four bases, max error 1.9 %): **0.58 ps per
  lane-pair, lanes padded to whole 1024-entry waves, plus 74 ps per AND survivor.** Wave
  padding is 1.07–1.10× at b58/b60 and 1.69–1.72× at b62/b64 (buckets of ~1200 spill into
  a second wave): ~18 % of b64 device time, 12 % of b62's.
- **Entries per thread (`NICE_EXP_JOIN_EPT`, 2 interleaved rounds, first field):** 5 gives
  ×1.12 (b62) and ×1.19 (b64) over 4; 6 (= PR #205) gives ×1.08 / ×1.13, matching #205's
  own 3080 numbers. So 5 beats #205 by 3.4 % / 5.4 % on this card. Needs a third round and
  other GPUs before it is a claim. The model fitted on EPT 4 predicts 5 and 6 within 0.6–3.4 %.
- L4: the check kernel is 3.1–5.3 % of device time (3.8–9.8 % of the join's), under the
  15 % kill criterion.
- Caveats: no hardware counters (`ncu` blocked on Vast); the b60 window used is denser
  (44k survivors/prefix vs ~26k on the 9070 XT's fields) so b60's µs/prefix reads high.

**What the prune should buy (director's estimate from the model, to be measured):** per prefix the
AND term is tops × roots × padded occupancy × 0.58 ps: b58 2.9 µs, b60 1.5, b62 2.8, b64 11.4;
the survivor term 4.7 / 3.2 / 2.6 / 10.3 µs. Pruning 73–86 % of bottoms (1e14 fields) cuts
the AND term by 2× at the current wave size (one wave instead of two) and by 3–7× with a
smaller wave, leaving survivors unchanged: 10–30 % of device time by base.

## L3.0 Detailed mode on the GPU (2026-10-28, agent; `L3/NOTES.md`)

RTX 3080, `auto` = CubeCL CUDA. b40_detailed 1.04e10 n/s, b50_detailed 7.8e9 (references
2.4e9 / 1.5e9 are for a weaker card). CPU 16 threads: b40 4.4e7, b50 2.86e7, one thread
1.87e6. GPU = 236–273× this CPU. `nvidia-smi dmon`: SM 98–99 %, memory controller 0 %.
Kernel: one thread per number; n², n³ in u32 limbs; digits peeled by long division by b⁵
in shared memory; OR into a mask, popcount, one shared atomic into the histogram. About
750 (b40) / 1,000 (b50) integer ops per number ≈ the card's integer throughput:
**compute-bound on the divisions.** The L2 finite-difference scheme (digit arrays updated by
addition) removes exactly those divisions, so L2 and L3 are one lead with a CPU prototype first.

## L1.1 CPU join counts by base (2026-10-28, agent; `L1/RESULTS.md`, branch `rp/l1-selectivity` a76984f on the fork)

Item 23's field per base plus a second field, 6 stratified partitions per field, ivory (EPYC
Rome) under `nice -n 19`, 3 threads; a second round reproduced counts exactly and stage
times within ±5 %. Ignored tests `cpu_join::selectivity::l1_selectivity`, `l1_probe_windows`.

| | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| roots | 4 | 2 | 2 | 8 |
| L / digits of n², n³ | 12 / 23, 35 | 12 / 24, 36 | 13 / 25, 37 | 13 / 26, 38 |
| bottoms per key list (per class) | 54.8k (961) | 54.9k (931) | 72.7k (1191) | 76.4k (1212) |
| ANDs per top | 3,844 | 1,863 | 2,383 | 9,702 |
| top popcount (n² + n³ known) | 15.7 (7.7 + 7.9) | 16.2 (8.1 + 8.2) | 17.3 (8.9 + 8.5) | 18.4 (9.6 + 8.9) |
| AND pass rate, measured / uniform model | 1.37 / 1.40 % | 1.64 / 1.42 % | 1.25 / 1.23 % | 1.06 / 1.06 % |
| AND survivors per top | 52.7 | 30.5 | 29.8 | 103 |
| full checks per top | 3.3 | 2.0 | 1.9 | 6.6 |
| CPU ms per prefix | 5.8 | 3.5–3.9 | 4.0–4.4 | 11.0–11.5 |
| RX 9070 XT µs per prefix (BACKLOG 68) | 11.2 | 7.0 | 9.4 | 19.5 |

- ANDs per top = roots × mean class size within 0.1 %: hypothesis A holds exactly.
- Pass rates follow the uniform model C(b−pc, 12)/C(b, 12); b64's tops know the most
  digits, so its pass rate is the lowest (0.85× b62). Net AND survivors per top: b64 3.5× b62.
- Tops per prefix (1.2–1.3k) and certificate cost (405–471 ns per prefix tried) are flat.
- Of the +7.6 ms per prefix from b60 to b64: 52 % survivor handling (range test, prefilter,
  dispatch, 32–41 ns each), 33 % the ANDs (0.22 ns each), 9 % full checks. ANDs are 13–17 %
  of a partition at b58–b62 and 26–27 % at b64. CPU scan shares match item 23's Zen 2 profile.
- CPU cost per prefix relative to b60: ×1.6 / 1 / ×1.15 / ×3.1; GPU: ×1.6 / 1 / ×1.33 / ×2.8.

**Lever counts (share of ANDs skipped).** Sub-bucketing by mask ∩ S: digits 0..s−1 skip
21–42 % (s = 4–8); the s most frequent top digits skip 56–81 %, but those digits are the
field's own certificate (4–7 leading digits of n², n³ every top knows). **Dropping bottoms
that share a digit with the field certificate skips 66 / 60 / 70 / 79 % of ANDs at
b58/60/62/64 with no bucketing.** CPU saving bound: 7–12 % at b58–b62, 20–23 % at b64
(only failing ANDs are skipped). GPU share unknown until the GPU profile lands.

## L1.0 Digit-sum class roots per base (2026-10-28, director, no hardware)

In the join each top probes one bottom bucket per root of x² + x³ ≡ b(b−1)/2 (mod b−1)
(overlap_join.rs module doc). The root count by base, from a 3-line enumeration:

| base | b−1 | roots | measured µs/prefix (RX 9070 XT, BACKLOG 68) | survivors per top-layer prefix |
|---|---|---|---|---|
| 58 | 57 = 3·19 | 4 | 11.2 | — |
| 60 | 59 prime | 2 | 6.8–7.3 | ~26k |
| 62 | 61 prime | 2 | 9.2–9.6 | 27–44k |
| 64 | 63 = 7·9 | 8 | 19.5 | 112–176k |

Roots for 40–97: 40:4 41:6 42:2 43:0 44:2 45:2 46:8 47:0 48:2 49:2 50:8 51:0 52:4 53:2
54:2 55:0 56:4 57:6 58:4 59:0 60:2 61:4 62:2 63:0 64:8 65:1 66:4 67:0 68:2 69:2 70:4
71:0 72:2 73:12 74:2 75:0 76:12 77:2 78:4 79:0 80:2 81:2 82:10 83:0 84:2 85:4 86:4
87:0 88:4 89:6 90:2 91:0 92:4 93:2 94:4 95:0 96:4 97:10. (Zero roots = residue-dead
bases, which the server never inserts; matches the known list.)

Reading: the b64 survivor count per prefix is ~4× b62's, exactly the roots ratio 8/2;
per-prefix time is ~2× because the tops phase does not scale with roots. b58 > b60
follows the same ordering (4 vs 2 roots). Hypothesis A of L1 is therefore the
explanation to beat; the CPU counting run (L1/RESULTS.md) checks it and sizes the
signature-bucketing lever.

