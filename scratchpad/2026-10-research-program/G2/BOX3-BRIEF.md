# G2 tuned port on a rented RTX 3080: exactness at 32 lanes and timing (brief, 2026-11-18 13:00 UTC)

You are an engineer on the "nice" number search. Work alone (do not start subagents). You have this machine
(ivory) and **one rented box that I rented and logged in to for you**:

    ssh -p 28064 root@ssh6.vast.ai        (Vast instance 61250912, RTX 3080, 16 threads, 24 GB disk, image nvidia/cuda:12.8.1-devel-ubuntu24.04)

Its host caps the card at **240 W** (it cannot be raised from inside). I accepted that: it is why every ratio
you report must come from this one session, and why your fs numbers will sit above yesterday's (taken at 300 W).

It destroys itself at about 15:55 UTC. **Hard stop 15:30 UTC**: by then results are copied back to ivory and
your results section is written. You never create or destroy instances; I do.

## Context

G2 is a redesign of the search's GPU join. A hand-written CUDA benchmark (kernel "v10", `bench/g2bench.cu`)
measured 1.12 fs per admissible n at base 64 against 6.35–6.40 fs for today's main, on RTX 3080s. The portable
CubeCL port of the same kernel (`common/examples/g2_cubecl.rs` in the worktree
`~/projects/nice/.worktrees/g2-cubecl`, local branch `g2-cubecl-local`, never pushed) measured 1.499 fs
yesterday at head `9ff100e6`. Today it was tuned **offline**, eleven commits to head `4170a781`: instruction
counts fell, every commit is exact on lavapipe at plane widths 8 and 16, and nothing was timed. The tuned
build's 32-lane path has never run on hardware. You run it.

Read first (all under `~/projects/nice/scratchpad/2026-10-research-program/G2/`): `PORT-NOTES.md` (state,
build, options, pitfalls), `TUNE-RESULTS.md` (what changed today and what is predicted), `BENCH.md` sections
"CubeCL port on CUDA" and "CubeCL port after fixes" (yesterday's two box sessions: the procedure, the
protocol, the numbers to beat), and the scripts and logs they left in `port/raw/cuda_box/` and
`port/raw/cuda_box2/` and `bench/box/`. Reuse those scripts; do not reinvent the protocol.

## What to measure, in this order

1. **Exactness at W = 32 on the card, tuned head `4170a781`, CUDA runtime**: both staged super-units
   (`bench/su64_712012851`, `bench/su64_391856203`), whole, GPU prep on, variant A (`--tdig 0`) and variant D
   (`--tdig 1`): survivor sets equal to the prototype's, counts equal to the CPU reference, records, order,
   class segments and top digits, 0 kernel errors. Also `--fill 1024` if it is not the default at W = 32, and
   `--prep2 0` once. If anything is not exact: stop timing that variant, find the first commit of the eleven
   that breaks at W = 32 (the binaries can be built per commit), and report; do not patch around it.
2. **Timing, one session, card idle before each binary, at least four rotated rounds**: hand CUDA v10;
   the pre-tuning port (`9ff100e6`, "P"); the tuned port A; the tuned port D. Per-launch medians of the
   components as yesterday (preparation, probes off, full kernel) and end to end in fs per admissible n.
   Record the card's power limit, its power draw and clock during the runs (`nvidia-smi` at 100 ms, one
   sampler, killed afterwards), and the build of each binary.
3. **Today's main on this box, same session** (upstream main `7e0113fc`, the production client against the
   local stub, the same base-64 field(s) and harness as `BENCH.md` used), so the ratio is same-box,
   same-session. If time is short, this comes before extra rounds of step 2.
4. If time remains: for the largest remaining gap between the tuned port and v10, one sentence on where it
   is (components), nothing more. No tuning on the box today beyond a one-line fix needed to run.

## Rules

- **Before any client binary runs on the box, production hosts are blocked there** (map them to 127.0.0.1 and
  ::1 as `bench/box/` and `../T28/raw/hosts_block.sh` do) and the block is proven (curl refused) with the proof
  saved. The client talks only to the local stub. Nothing ever claims from or submits to production, from the
  box or from ivory. NiceMark, if used at all, points at a closed local port.
- No git push from anywhere, no pull requests. The box gets the code by bundle
  (`port/g2-cubecl-local.bundle`, prerequisite upstream main `7e0113fc`, which the box may fetch from GitHub).
- On ivory: `nice -n 19`, `-j 2`, check `df -h /` before any build (stop under 5 GB free), nothing in `/tmp`.
  Another agent is using ivory's CPUs for a counting job: build on the box, not on ivory, wherever you can.
- Never amend, rebase or force anything in git. Do not commit on `g2-cubecl-local` unless a one-line fix is
  needed to run; if so, an ordinary commit, and say so.
- Every number is labelled with the box, the power limit and the session. Timings from different sessions are
  not mixed in one ratio without saying so.
- If the box misbehaves (ssh drops for more than 10 minutes, the card is shared or throttled below its 240 W cap), stop and tell me; do not look for another machine.

## Deliverables

1. `BENCH.md`: a new section "Tuned port on CUDA (2026-11-18, Vast 61250912, 240 W)" with the exactness result, the
   timing table (v10, P, A, D: components and end to end, per round and median), main on this box, and the
   ratios against main for each.
2. `PORT-NOTES.md` "Where it stands" updated. Raw logs, scripts and build logs under `port/raw/cuda_box3/`.
3. A final report to me of at most 30 lines: exact or not at W = 32; the table; the ratios; whether today's
   offline predictions (TUNE-RESULTS: 1.25–1.45 fs, ×1.1–1.3 of v10, D no longer slower than A) held; anything
   that surprised you.
