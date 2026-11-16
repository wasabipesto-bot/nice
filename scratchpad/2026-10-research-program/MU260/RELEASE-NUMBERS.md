# MU260 task 2: what a release from upstream main `0711b163` would carry, against v3.4.7 (2026-11-16)

No release was made, tagged or proposed. Box: Vast 60886021, RTX 3080 (10 GB), **power limit 300 W** as rented
(nvidia-smi: limit 300 W, card default 340 W, max 375 W; I did not change it), 24 threads. Builds on the box from exact
commits, own worktree and target dir each, `cargo build --release -p nice_client --features gpu,cubecl-cuda`
(`t2/build2.sh`, `t2/builds.txt`): **v3.4.7 = `8bd154bc`** (rustc 1.99.1, its pinned toolchain) md5 d6f3af10;
**main = `0711b163`** (rustc 1.100.0) md5 dbdc834a. Both clean trees.

**Production isolation.** `t2/proof_hosts_block.txt`: `api.`, `data.`, `www.nicenumbers.net` and `nicenumbers.net`
mapped to 127.0.0.1 and ::1 in the box's `/etc/hosts` at 06:04 UTC, before any client was built or run (curl exit 7
for each, github.com 200); re-checked at 06:51 just before the chain. `run_queue.sh` (T28's) refuses to start if a
production host answers or the block is missing; every client got `--api-base http://127.0.0.1:8200` (the stub) and
NiceMark `--api-base http://127.0.0.1:9` (closed: curl exit 7). Nothing claimed from or submitted to production.

## Answer

- **Base 62, real fields, at this card's 300 W limit: v3.4.7 takes ×3.25 the join time of main `0711b163`**
  (geomean of 6 pairs, range ×3.20–×3.31; whole-field wall ×3.17, range ×3.11–×3.24). Main: 49.8 s join /
  51.6 s wall per b62 1e17 field; v3.4.7: 161.6 s / 163.3 s. Yesterday's T28 figure at a 150 W cap against
  `54d0aac4` was ×3.13 (run) / ×3.08 (wall); today's main adds #251 and #256, and the card ran at 289–297 W and
  1.83–1.86 GHz in every run of both builds (62 °C max). The card's own default limit is 340 W; the box is rented
  at 300 W and I did not change it, so "default" here means the box as rented, without T28's extra 150 W cap.
- **Counts:** main equals yesterday's main (`54d0aac4`, T28 `raw/box`) exactly on all 3 fields, both rounds
  (survivors, checked, nice list: 6 of 6 equal). v3.4.7 inside T28's overrun bound in 6 of 6 (its counters are
  timing dependent by design, #222 without #236). No nice number on any field.
- **NiceMark nice-only GPU** (`--gpu --benchmark --benchmark-secs 150 --benchmark-json`, API base
  `http://127.0.0.1:9`, closed: all 10 `/ping` samples per run `null`, `median_ms: null`): **score ×2.28**
  (v3.4.7 4622 → main 10559, medians of 2 rounds); per scenario main/v3.4.7: b58 msd-weak ×2.53, b58 msd-strong
  ×1.48, b60 msd-weak ×2.76, b62 msd-weak ×2.65. (Scores are against each version's own pinned reference rates, so
  compare the per-scenario rates, not only the score.) Main's NiceMark b62 ratio (×2.65) is below the real-field ratio
  (×3.25): NiceMark samples a 1e16 window for a fixed share of seconds, real fields are 1e17 end to end.

## Timing runs (`t2/chain2.sh`, table `t2/timing2.py` → `t2/timing2.txt`)

Three real base-62 1e17 fields from T28's `queue_timing.json` (207072517, 207072868, 207072999; T28's f1, f2, f4),
one client process per (build, field), `niceonly --gpu --threads 8 --telemetry --repeat` against T28's stub
(`stub_api.py`, 127.0.0.1:8200), builds alternated per field (round 1: v3.4.7 first on fields 0 and 2, main first on
1; round 2 reversed), 06:56–07:18 UTC. Wall = stub claim → stub receipt of the submission. Power / clock = mean of
2 s `nvidia-smi` samples with utilisation > 50 % (`t2/box/gpu.csv`). "counts": main = exact equality with yesterday's
main on the same field; v3.4.7 = T28's bound (x = T − survivors, |d| = |checked − P − x(1 − p)| ≤ 5√(x p(1 − p)) + 2 +
0.06 p(1 − p) x, T, P = main's counts).

| field | round | build (telemetry sha) | join run_secs | setup_secs | wall s | survivors | checked | nice | slots | mean W | mean SM MHz | max °C | counts |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 207072517 | 1 | 0711b163 (0711b163) | 53.3 | 17.4 | 55.4 | 863,401,151,773 | 51,300,460,796 | 0 | 12 | 289 | 1846 | 62 | equal |
| 207072517 | 1 | 8bd154bc (8bd154bc) | 171.6 | 17.0 | 173.4 | 863,400,798,763 | 51,300,792,637 | 0 | 6 | 294 | 1852 | 62 | x=353010, |d|=194 ≤ 1888 |
| 207072517 | 2 | 0711b163 (0711b163) | 52.8 | 17.4 | 54.9 | 863,401,151,773 | 51,300,460,796 | 0 | 12 | 295 | 1856 | 62 | equal |
| 207072517 | 2 | 8bd154bc (8bd154bc) | 168.9 | 16.9 | 170.8 | 863,400,806,505 | 51,300,785,160 | 0 | 6 | 296 | 1855 | 62 | x=345268, |d|=389 ≤ 1854 |
| 207072868 | 1 | 0711b163 (0711b163) | 50.1 | 17.1 | 52.1 | 780,224,058,985 | 46,355,547,549 | 0 | 12 | 296 | 1859 | 62 | equal |
| 207072868 | 1 | 8bd154bc (8bd154bc) | 160.3 | 16.4 | 162.2 | 780,224,050,346 | 46,355,555,705 | 0 | 6 | 296 | 1854 | 62 | x=8639, |d|=30 ≤ 141 |
| 207072868 | 2 | 0711b163 (0711b163) | 49.3 | 16.9 | 51.3 | 780,224,058,985 | 46,355,547,549 | 0 | 12 | 296 | 1835 | 62 | equal |
| 207072868 | 2 | 8bd154bc (8bd154bc) | 160.6 | 16.4 | 162.5 | 780,224,051,387 | 46,355,554,707 | 0 | 6 | 297 | 1855 | 62 | x=7598, |d|=11 ≤ 131 |
| 207072999 | 1 | 0711b163 (0711b163) | 46.5 | 16.7 | 47.8 | 710,206,564,304 | 42,183,717,957 | 0 | 16 | 293 | 1832 | 62 | equal |
| 207072999 | 1 | 8bd154bc (8bd154bc) | 153.8 | 17.3 | 155.0 | 710,206,564,086 | 42,183,718,159 | 0 | 9 | 294 | 1853 | 62 | x=218, |d|=3 ≤ 20 |
| 207072999 | 2 | 0711b163 (0711b163) | 46.7 | 16.7 | 48.0 | 710,206,564,304 | 42,183,717,957 | 0 | 16 | 296 | 1847 | 62 | equal |
| 207072999 | 2 | 8bd154bc (8bd154bc) | 154.4 | 16.1 | 155.7 | 710,206,564,192 | 42,183,718,061 | 0 | 9 | 294 | 1853 | 62 | x=112, |d|=1 ≤ 15 |

f0 (207072517) round 1: v3.4.7/main run 3.216, wall 3.133
f0 (207072517) round 2: v3.4.7/main run 3.198, wall 3.112
f1 (207072868) round 1: v3.4.7/main run 3.202, wall 3.114
f1 (207072868) round 2: v3.4.7/main run 3.257, wall 3.167
f2 (207072999) round 1: v3.4.7/main run 3.307, wall 3.240
f2 (207072999) round 2: v3.4.7/main run 3.310, wall 3.243
geomean over 6 pairs: run ×3.248 (range 3.198-3.310), wall ×3.168 (range 3.112-3.243)
0711b163: mean run 49.8 s, mean wall 51.6 s, power 289-296 W, SM 1832-1859 MHz
8bd154bc: mean run 161.6 s, mean wall 163.3 s, power 294-297 W, SM 1852-1855 MHz

## NiceMark (`t2/box/nm-r*-*.json`, table `t2/nm_table2.py` → `t2/nm_table.txt`)

Two rounds each, interleaved (r1: main, v3.4.7; r2: v3.4.7, main), 07:18–07:21 UTC; each run took ≈ 40 s (the GPU
sweep's four scenarios do not use the 150 s budget). Columns: v3.4.7 median (rounds), main median (rounds),
main / v3.4.7 by medians, per round.

| scenario | v3.4.7 `8bd154bc` | main `0711b163` | main / v3.4.7 | per round |
|---|---|---|---|---|
| score | 4622.4 (4658.7, 4586.0) | 10558.5 (10507.5, 10609.5) | **×2.284** | 2.255, 2.313 |
| b58_msd_weak | 2.013e+14 (2.039e+14, 1.988e+14) | 5.083e+14 (5.047e+14, 5.12e+14) | **×2.525** | 2.476, 2.576 |
| b58_msd_strong | 1.194e+15 (1.217e+15, 1.171e+15) | 1.763e+15 (1.739e+15, 1.788e+15) | **×1.477** | 1.429, 1.527 |
| b60_msd_weak | 4.007e+14 (4.004e+14, 4.011e+14) | 1.106e+15 (1.106e+15, 1.106e+15) | **×2.760** | 2.762, 2.758 |
| b62_msd_weak | 5.073e+14 (5.074e+14, 5.073e+14) | 1.342e+15 (1.344e+15, 1.339e+15) | **×2.645** | 2.649, 2.640 |

Counts (runs that sampled the same partitions must agree): main's two rounds agree exactly on b58 msd-weak
(33,590,315,220 / 1,894,592,860) and b58 msd-strong; v3.4.7's b58 msd-weak differs between its own rounds and from
main by 158 / 163 survivors (33,590,315,062 and …057; checked +148 / +151), its known timing-dependent overrun
counting (#222), the same kind as in the timing runs. b58 msd-strong agrees across all four runs (4,027,773,430 /
226,773,299). b60/b62 sampled different partition counts per run (the sample is time-budgeted), so they are not
comparable for counts.

## What a release from `0711b163` contains since v3.4.7 (from the CHANGELOG's Unreleased section)

**Speed:** the GPU overlap join is ≈ ×3.2 faster per real base-62 field on NVIDIA (above): lighter top certificates
stepped by finite differences through a batch's partitions, carrying their bounds between partitions and (CUDA) up to
twice as many partitions per launch (#235, #237, #240, #250, #254), the middle-digit prefilter run in the walk in a
division-free fixed-point form (#236, #246), a transposed top batch for the entry test (#239), one 32-byte record per
top (#241), a static bucket order with the sort overlapped with device work (#249), the full check in base-b² limbs
from the top's record (#251) and a 512-entry survivor stage for RDNA4 (#256); the CPU overlap join gains its own set
(#247, #248, #252, #253, #262). **Soundness:** the GPU stride walk no longer assumes full subgroups or a lane 0 and
fails the field if a survivor queue checks fewer survivors than it queued (#263); the join's full check now fails the
field if it checked a different number of listed entries, or a different index sum, than the join listed (#251);
#260 (the top stage's append without a lane-0 assumption, with its account) is **not** in `0711b163` — it is the open
PR merged up in this task. **API side** (needs a server deploy, not a client update): statement timeout of 30 s and a
wider `Next` cursor window (#238), and the nice-only queue no longer hands out a field twice when consumed slowly
(#264). **For a fleet operator:** no new client flags or environment knobs and no changed defaults since v3.4.7 (the
client's `main.rs` diff is a thread-local join scratch buffer only; new `NICE_*` variables are test-only); a device
that mis-executes the new checks' kernels now fails its field loudly ("the check kernel checked N of the M survivors…",
"…survivor queue…") instead of submitting, so a rise in failed fields after deploy points at a device, not the server;
the release builds with rustc 1.100.0 (bumped from 1.99.1, #258), and the GPU image job must run on `ubuntu-24.04`
runners (#261: it fails on `ubuntu-latest`, glibc of the base image). v3.4.7's reported counts differ run to run
within the overrun bound; main's are exact, so operators comparing resubmissions should expect exact repeats from now
on.

## Files

`t2/` scripts (`build2.sh`, `chain2.sh`, `run_queue.sh`, `stub_api.py` from T28, `hosts_block.sh` from T28,
`timing2.py`, `nm_table2.py`), `t2/proof_hosts_block.txt`, `t2/box/` (`builds.txt`, `runs.log`, `gpu.csv`,
`out_T*.jsonl` = every submission body the clients sent the stub, `client_*.log`, `stub_*.log`, `nm-r*-*.json` /
`.stderr`, `hosts_in_bins.txt`: the only nicenumbers host string in either binary is `api.nicenumbers.net`, the default
API base, overridden in every run). Box time for task 2: 06:51–07:21 UTC (30 min of the 75-minute box).
