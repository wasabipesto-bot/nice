# N21 window plan: the walk-loop variants on the RX 9070 XT (demoux), 30 minutes

For whoever runs the window with only this file and `../N13/BRIEF.md` (the machine's rules: work only under
`W=/tmp/claude-exp-<date>-amd`, every build and run through `$W/run.sh`, no sudo, kill only your own PIDs and never
with a pattern, builds under `nice -n 19`, nothing pushed from demoux, copy results to ivory as you go). Background in
`RESULTS.md` next to this file. Scripts: `raw/scripts/window/` (tested end to end on the rented RTX 3080 box under CUDA
and under lavapipe, only `W`, `DEV` and the field sizes different; logs in `raw/box/dryrun*/`).

**What the window decides.** One binary (fork `exp/n21-walk-loop` at `2d3e10d3`, `env.sh`'s `COMMIT`), every
variant a value of `NICE_EXP_N21` (0 = today's main + #255 + #256). Mesa's compiler counts (RESULTS §4) predict, per
walked pair on this card: M (8, = candidate `exp/n21-popcount-test-wgpu` on this card) −8 ALU instructions, P+M (9,
both candidates) −10, and P+M+D (137) a walk 8 lower with the stage append moved to a second walk over the passing
pairs. On the RTX 3080 all three are 1–2 % slower (RESULTS §5), so the question is only whether this card gains what
its compiler's counts say. The window measures them at the card's operating point (≈ 3.15 GHz, ≈ 300 W) with the
counts checked.

## Before the window (on ivory, 2 minutes)

```sh
cd ~/projects/nice/scratchpad/2026-10-research-program/N21/raw
W=/tmp/claude-exp-<date>-amd          # the window's workspace, as its brief names it
scp -r scripts/window justin@demoux:$W/scripts
```

The workspace must already hold what N13's did (`run.sh` that sets `CARGO_HOME=$W/cargo-home`, PATH and the PID
registry; `cargo-home/` with the registry; `src/nice` = a clone of the fork). If `cargo-home` lacks a crate, `cargo`
fetches it into `$W/cargo-home` (allowed by N13's rules).

## Minute by minute

All on demoux as `$W/run.sh <command>`. Per-run seconds from N17 (b62 1e17 73.5 s + ~5 s warm-up; b64 1e17 at today's
main 135 s + ~5 s); build from N13/N17 (115–171 s at `-j 8`).

| clock | what | command | seconds |
|---|---|---|---|
| 0:00 | worktree E | `export W=...; $W/run.sh sh $W/scripts/setup_window.sh` | 30 |
| 0:01 | **start everything** (build, then the chains; `END_AT` = start + 27 min) | `W=$W END_AT=$(( $(date +%s) + 27*60 )) $W/run.sh sh $W/scripts/go_window.sh > $W/out/go.out 2>&1 &` | |
| 0:01–0:04 | build E (nothing timed meanwhile) | (go_window) | ~170 |
| 0:04–0:20 | **b62 1e17**, modes `$M62` (default `0 9 137 8`), 3 rounds, the order rotated each round | (go_window) | 12 × ~80 ≈ 960 |
| 0:20–0:29 | **b64 1e17**, modes `$M64` (default `0 9`), 2 rounds | (go_window) | 4 × ~140 ≈ 560 |
| 0:28 | `END_AT`: no run starts after it (b60 rounds only if time is left) | | |
| 0:29–0:30 | copy out, analyse, check no PID of `$W/pids` is alive, delete `$W/target-E $W/bin` | below | |

Copy and analyse (ivory):

```sh
rsync -a justin@demoux:$W/out/ raw/demoux/
python3 -I raw/scripts/window/analyze_window.py raw/demoux 3150 300
```

**Reading it.** Every row must say `ok` (clock within 3 %, power within 10 % of 3150 MHz / 300 W) and the counts
`identical` per field. The ratio printed per mode is base ÷ mode per round (> 1 = the variant is faster), then the
median. Expected from the instruction counts at about 0.5 % of a field per instruction per walked pair (N17's probe,
RESULTS §6) [E]: M ×1.02–1.04, P+M ×1.03–1.05 at b62, a little more at b64 (the prefilter's share is larger there). A variant within ±1 % of 1 in all three rounds is no gain on
this card.

**Decisions.** P+M (9) ≥ ×1.05 at b62 and b64 with M (8) alone ≥ ×1.03: open `exp/n21-popcount-test-wgpu` (and
`exp/n21-ffs-pop` stacked, if 9 beats 8 by ≥ 1 % in every round). P+M+D (137) above P+M in every round: D is worth a
branch (on wgpu only; it loses on CUDA). M below ×1.01: the instruction price does not hold for this change; close
the lead.

**Swaps if the plan must change.** `M62="0 9" R62="1 2 3 4"` buys a fourth round of the main comparison;
`M62="0 9 8 1"` measures P alone instead of D.

**Stopping early:** `touch $W/stop` ends the chain before its next run (a run is at most ~2.5 min). **Cleanup**: kill
only PIDs from `$W/pids` (parent before child); `rm -rf $W/target-E $W/bin` after the copy.
