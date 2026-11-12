# N16 window plan: the join's corrected profile on the RX 9070 XT (demoux), at most 90 minutes

For whoever runs the window with only this file and `../N13/BRIEF.md` (the machine's rules: work only under
`W=/tmp/claude-exp-<date>-amd`, every build and run through `$W/run.sh`, no sudo, kill only your own PIDs and never
with a pattern, builds under `nice -n 19`, nothing pushed from demoux, copy results to ivory as you go). Background,
the switches and the RTX 3080 column are in `RESULTS.md` next to this file; the scripts are `raw/scripts/` (every one
run end to end on the rented RTX 3080 box, under CUDA and under lavapipe, with only `W` and `DEV` different).

**What the window decides.** N13's ablation profile on this card was taken while the card dropped to 1.5–1.9 GHz
and ~90–100 W in the light modes (RESULTS §A), so its "base = a third of the field" does not stand. The window
measures the join by **doubling** one part at a time (the part executed twice, counts unchanged), with the card at
least as loaded as in production (3.1–3.2 GHz, 304 W), and checks every run's clock and watts. Then the survivor
path and top switches, the shared-memory occupancy and geometry variants that the RDNA4 compiler dump points at
(RESULTS §C: the join's work group is LDS-bound at 12 waves per SIMD), the launch accounting, and Task D's binary.

**How the scripts were tested [M]:** on the rented RTX 3080 box: (1) `dryrun_window.sh` = a fresh workspace with a
clone of the fork from GitHub, a stand-in `run.sh`, `setup_window.sh`, then `go_window.sh` with `DEV=cuda`, 1e14
fields and shortened lists: every build (242–246 s each from scratch at `-j 4` beside a lavapipe job) and every chain
ran, and the analysis parsed it; repeated at the end from a fresh clone with the final branch head 32e9e19 and `-j 8`
on an idle 5600X: N16 / M / D built in 167 / 168 / 166 s, every chain ran (`raw/box_dryrun/`); the `END_AT` and `$W/stop` guards were triggered on purpose and
stopped the chains; (2) the same chains at full size under CUDA (`go_box.sh`, `go_box2.sh`, `go_box3.sh`: the NVIDIA
column of RESULTS §B); (3) under lavapipe, the wgpu path with CubeCL's SPIR-V compiler (`go_lavapipe.sh`: every chain
with shortened lists at 1e13, then the dense compare of every exact mode). On demoux only `W`, `DEV=wgpu` (the default)
and the AMD sysfs sampler differ; the sampler is N13's `wrun.sh` code (which ran there for 140 runs), with the clock
parsed to a plain number.

## Before the window (on ivory, 2 minutes)

```sh
cd ~/projects/nice/scratchpad/2026-10-research-program/N16/raw
W=/tmp/claude-exp-<date>-amd          # the window's workspace, as its brief names it
scp -r scripts justin@demoux:$W/scripts
```

The workspace must already hold what N13's did (`run.sh` that sets `CARGO_HOME=$W/cargo-home`, PATH and the PID
registry; `cargo-home/` with the registry; `src/nice` = a clone of the fork with remote `upstream` fetched). If
`cargo-home` lacks a crate, `cargo` fetches it into `$W/cargo-home` (allowed by N13's rules).

## Minute by minute

All commands on demoux, as `$W/run.sh <command>` (it registers the PID). Times are for this card: per-run seconds
from N13's runs (b62 1e17 at 0.45: 74–76 s of fields + ~5 s warm-up and kernel compile; b64 1e17 at 0.55: 137–150 s +
~5 s; b60 1e16 at 0.55: 13 s + ~4 s), a doubling adds 0–17 % (the RTX 3080's, RESULTS §B); builds from N13's logs
(`../N13/raw/demoux/builds.out`: 171 s for the first tree, 115–139 s for each later one, `-j 8` under `nice -n 19`; the
RTX 3080 box, a Ryzen 5 5600X like demoux's, built N16 / M / D from scratch in 167 / 168 / 166 s at `-j 8`).

| clock | what | command | seconds | must? |
|---|---|---|---|---|
| 0:00 | workspace, worktrees N16 / M / D | `export W=...; $W/run.sh sh $W/scripts/setup_window.sh` | 60 | yes |
| 0:01 | **start everything**: the N16 build, then the chains in priority order, each run guarded by `$W/stop` and by `END_AT` (= start + 84 min) | `W=$W $W/run.sh sh $W/scripts/go_window.sh > $W/out/go.out 2>&1 &` | | yes |
| 0:01–0:04 | build N16 (nothing timed meanwhile) | (go_window) | ~170 | **yes** |
| 0:04–0:19 | **MUST 1**: b62 1e17 doubling: `info d_pf d_walk d_and d_check c2 d_copy d_load d_wave d_bar c3` (11 runs, 3 base) | `chain_must.sh` (ROUND=1) | 11 × ~82 ≈ 900 | **yes** |
| 0:19–0:36 | **MUST 2**: b64 1e17 doubling: `c d_pf d_walk d_and d_check c2` (6 runs, 2 base) | (same chain) | 6 × ~165 ≈ 990 | **yes** |
| 0:36–0:45 | **checkpoint** (while the next chain runs): copy `out/` to ivory, run the analysis, read the clock column and the shares | ivory: `rsync -a justin@demoux:$W/out/ raw/demoux/`; `python3 -I raw/scripts/analyze.py raw/demoux 3150 300` | | **yes** |
| 0:36–0:45 | survivor path and tops at b62 (`c wsync bal2 c2`: the walk's plane barrier; the FD append's two-word ballot — its scans are the card's default, and the one-word ballot would drop lanes 32–63 of a wave64), then the removal modes UNPROFILED at b60 (`c r_p r_b r_a r_z r_s8 r_s7 r_s6 r_s5 c2 prof_c`), each with its clock | `chain_surv.sh` (names `sv-…`) | 4 × 80 + 11 × 17 ≈ 510 | no |
| 0:45–0:51 | occupancy, geometry, launches at b60: `c tc128 sc512 sc256 tcsc wg128 wg64 wg128tc wg128e4 wg64tc c2 vram tcvram s4 s2 s1 c_nohost c3` | `chain_geo.sh` (names `ge-…`) | 18 × ~17 (s1 ~25) ≈ 330 | no |
| 0:51–0:57 | build M (main 5b1d627) and D (exp/n14-wgpu-dense-plan); nothing timed meanwhile | (go_window) | ~2 × 170 | no |
| 0:57–1:07 | Task D: M against D, b62 1e17 and b60 1e16, 3 rounds alternating | `chain_D.sh` (names `DM-…`, `DD-…`) | 6 × 80 + 6 × 17 ≈ 580 | no |
| 1:07–1:22 | MUST round 2 at b62 (reversed order; b64 skipped) | `chain_must.sh` ROUND=2 L64= | 11 × ~82 ≈ 900 | no |
| 1:24 | `END_AT`: no run starts after it; the running one ends by ~1:27 | | | |
| 1:24–1:30 | copy `out/` to ivory; check that no PID of `$W/pids` is alive; delete `$W/target-*` and `$W/bin` | `rsync`; the registry | | yes |

**The must-haves are in the first 45 minutes:** the N16 build, the b62 and b64 doubling rounds with 3 + 2 base runs
(done by ~0:36), and the clock check at the checkpoint. If the builds run long, touch nothing: `END_AT` keeps the end at 90 minutes, and the chains
are in priority order, so what is cut is the second round and Task D.

**Stopping early:** `touch $W/stop` ends the current chain before its next run (each run is at most ~3 min).
Everything after the checkpoint is optional. To skip a chain, edit `go_window.sh` before starting it, not while it runs.

**What to look at, at the checkpoint (0:36–0:45):**
1. Every row of `analyze.py` must say `ok` in the point column (clock within 3 % and power within 10 % of 3150 MHz /
   300 W) and `exact` in the counts column. A doubling run that is OFF-POINT is repeated at the end (add it to the
   second round's list); a base run that is OFF-POINT makes the round's ratios unusable.
2. The base runs' spread (printed) must be ≤ 1 %; yesterday's A/A pair was 0.2 %.
3. Read the decision table below against the "% base" column.

## Decision table (what each outcome means, what confirms it, what the fix is)

"Share" = the doubling run's extra time ÷ the base run's time at b62 1e17 (and b64 1e17). The RTX 3080's shares are
in RESULTS §B.2 (280 W; b62 1e17 / b64 1e17): prefilter 15.9 / 20.8 %, AND 14.6 / 14.6 %, check 11.3 / 11.0 %, walk
9.1 / 12.6 %; at b62 transposed copy 4.6 %, batch loads 1.4 %, barriers 0.1 %, entry waves 0.0 %. Removal on the 3080
agreed within 1–3 points. A doubling measures the marginal cost of one more copy of the part (its instructions
and its shared-memory traffic; its global loads mostly hit cache the second time), so for memory-bound parts it is a
lower bound.

| outcome on the 9070 XT | means | confirm with (already in the plan) | fix | estimated gain on this card |
|---|---|---|---|---|
| **d_pf + d_walk ≥ 30 %** (3080: 25 % at b62, 33 % at b64; the clock-corrected N13 profile: 21–35 %) | the per-pair prefilter and the walk's rounds are the card's biggest block; RDNA's wave64 makes each walk round wait for the slowest of 64 lanes, not 32 | `wsync` (plane barrier per round) and EPT in N13 (EPT 1 −4 %); the RTX 3080's walk share (9 %) | a walk that compacts the AND's bits across the plane before the prefilter (L40's group walk, rejected on NVIDIA for its small-batch loss, ≥ 3 % there), or wave32 for the join (RADV picks wave64; CubeCL cannot request a subgroup size today) | ×1.05–1.15 if the walk's share halves [E] |
| **d_and ≈ 15 %** (as on NVIDIA, 14.6 %) | the AND is issue-bound here too | AND_GROUP 8 (N13: +1–2 %) | L51's AND codegen item (fold the index arithmetic, leaner bit iteration) | ×1.02–1.05 [E, L51 §4] |
| **d_check ≥ 15 %** (3080: 11 %) | the check is expensive here (N13: 0.20 ns against 0.11) | — | #251 (measured ×1.13–1.14 on this card in N13) | ×1.13 [M, N13] |
| **d_copy ≥ 5 %** (3080: 4.6 %) or **tc128 / sc512 / tcsc win ≥ 3 % at b60** (3080: +0.1 % to −4 %) | shared-memory footprint and occupancy: the join's cube uses 18.5 KiB of LDS, which caps it at 12 waves per SIMD on GFX12 (ACO's own estimate, RESULTS §C); TOP_CAP 128 → 13.5 KiB / 18 waves, stage 512 → 14.5 KiB / 16, both → 9.5 KiB / 24 | `geo` chain at b60; then `MODES="c tc128 sc512 tcsc c2" sh chain_geo62.sh` at b62 if time remains | a per-device TOP_CAP and stage size for RDNA (or smaller shared arrays generally: the stage is 8 KiB of the 18.5) | N13 measured TOP_CAP 128 ×1.04–1.05 [M]; sc512 / tcsc unknown [the window measures it] |
| **d_bar ≥ 3 %** (3080: 0.1 %) | barriers across four wave64s are dear | `wg64` (ACO removes every barrier at 64 threads, §C) — but wg64 also cuts occupancy to 4 waves (LDS per wave ×4) | fewer barriers per batch (merge the header's three; once-per-item stage check) | ≤ the measured d_bar share |
| **d_load / d_wave large** (≥ 5 %) | global-load latency of the batch and entry loads (the second copy hits cache, so the true cost is larger) | removal modes r_s6/r_s7/r_s8 unprofiled, if their clock held | prefetch the next batch's records during the AND (double-buffer the batch) | ≤ the share [E] |
| **slope of seconds against batches large** (s1/s2/s4 at b60; 3080: 0.78 ms per batch; `HOSTACC` encode or wait ≫ 0 per batch; on CUDA the fence is synchronous: 0 pending) | per-launch cost (encode + submit + fence on wgpu/RADV) | `vram` and `tcvram` (fewer launches); the HOSTACC line of every run | the denser plan on wgpu (Task D's branch, N13 ×1.04); fewer, larger launches | ≤ slope × launches saved |
| **`HOSTACC`: create + launch per batch ≫ 0.1 ms, or busy < 97 %** (on lavapipe the host blocks in the flush for the whole field and every fence is pending, so on wgpu `flush_s` ≈ GPU time; create and launch are the host's own cost) | host-side launch cost on RADV is not hidden | `s1`/`s2`/`s4` slope against create + launch per batch | the denser plan (fewer launches and seeds); reuse the per-batch buffers | ≤ (create + launch) × batches saved |
| **every doubling share small and even** | no single hot spot; the gap to NVIDIA is clock-for-clock throughput | — | nothing local; per-device tunings only (TOP_CAP 128, denser plan) | ×1.08–1.11 [M, N13 tc128 + vram] |
| **a removal mode stays at 3.1 GHz unprofiled** | removal is usable on this card when unprofiled; compare it with the doubling | `chain_surv` b60 removal rows | — | — |
| **Task D: D faster than M by ≥ 3 % at both fields, counts the same** | the denser plan's gain holds in a binary with the rule | — | open Task D's branch as a PR | ×1.04 [M, N13] |

## Files the window produces

`$W/out/`: `<chain-><mode>_<b62|b64|b60>_r<round>.log` (harness output with the `HOSTACC` and, for `info`,
`EXP_INFO` / `EXP_PLANE` lines) and `.gpu` (busy %, clock, power every 2 s); the chain prefix is empty for the
must chain, `sv-` for chain_surv, `ge-` for chain_geo, `DM-` / `DD-` for Task D (main / D); `build_*.log`,
`builds.out`, `trees.txt`, `go.out`. Copy to `N16/raw/demoux/` on ivory; `python3 -I raw/scripts/analyze.py
raw/demoux 3150 300` prints one table per (chain, field) with that chain's own base runs, the HOSTACC lines, the
launch fit, Task D's ratios and the device lines (its ps-per-pair column assumes the window's b62 and b60 fields).

**Cleanup** (N13's rules): kill only PIDs from `$W/pids` (parent before child), never by pattern; `rm -rf $W/target-*
$W/bin` after the copy; the watchdog removes the rest.
