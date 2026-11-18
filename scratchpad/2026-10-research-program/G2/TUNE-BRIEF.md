# G2 port: offline tuning before the window (brief, 2026-11-18 08:15 UTC)

You are an engineer continuing someone else's throwaway prototype. Work alone (do not start subagents), on this
machine only (ivory). Hard stop **12:30 UTC**; write your results file before that, even if unfinished.

## Context in five lines

- "nice" searches for numbers n whose square and cube together use every digit of base b once. Today's search
  is an "overlap join" on the GPU. G2 is a redesign of that join; a hand-written CUDA benchmark (v10) measured
  ×5.1 against today's code at base 64 on an RTX 3080, and its CubeCL port (the portable version: CubeCL compiles
  the same Rust kernel to CUDA, to WGSL and to SPIR-V) measured ×3.9 there.
- The card that matters is an RX 9070 XT (RDNA4, Mesa RADV, the SPIR-V runtime, 64-lane planes): it does about
  86 % of the search. Nobody has run the port on it. An offline model from Mesa's ACO compiler output predicts
  ×4.4 (×3.3–5.6) against a stop line of ×4.0. The owner has not yet granted the 45-minute window in which this
  is measured. No GPU can be rented today.
- Your job: use the hours before that window to make the port faster **where it can be shown offline**, so that
  the one measurement on the card is taken with the best build.

Read first, in this order (all under `~/projects/nice/scratchpad/2026-10-research-program/G2/`):
`PORT-NOTES.md` (living notes of the port: state, build, lavapipe and ACO tooling, RDNA4 pricing, pitfalls),
`BENCH.md` sections "CubeCL port on CUDA" and "CubeCL port after fixes", `WINDOW-PLAN.md`. The design itself is
in `RESULTS.md` and `PROPOSAL.md` if you need it. Code: worktree `~/projects/nice/.worktrees/g2-cubecl`, local
branch `g2-cubecl-local` (head `9ff100e6`), file `common/examples/g2_cubecl.rs`. Hand CUDA: `bench/g2bench.cu`.

## Part A (first, and most of your time): the RDNA4 path

The ACO pricing (`PORT-NOTES.md`, "RDNA4 pricing") says the 3b step is 1.95 of the kernel's 3.06 ms bound and
names what costs there. In order:

1. **Precomputed slice byte offsets in the probe table**: the address is 3 VALU per digit (`v_bfe`,
   `v_lshl_add`, `v_lshlrev`); precomputed offsets would make it 2. Predicted about −16 % of the step.
2. **Shared memory (LDS) down to ≤ 21 KB**, so that 12 waves per SIMD fit instead of 8 (the notes name two
   routes: u16 pending indices via shared `fetch_or`, a smaller probe table; 8-chunk rounds with 8-lane groups).
3. Whatever else the ACO listing of the 3b loop shows once 1 and 2 are in (64-bit operations emitted as pairs,
   `s_delay_alu` and waits are a quarter of the stream, the 20 unrolled trailing-zero counts in probe setup).

For every change: (a) ACO instruction counts for GFX1201 before and after, per wave-iteration of the loops, with
the same scripts as the notes (`aco/aco.sh`, `aco/loops.py`, `port/model_rdna4.py`); (b) **exactness on
lavapipe** (container `localhost/lvp26`, Mesa 26.0.8) on both staged super-units, whole super-units, with the
SPIR-V build, at plane widths 8 and 16, GPU prep on: survivor sets, counts, 0 kernel errors, as the notes
describe; (c) a line in your results table. A change that is not exact is reverted, not parked half-working.
Each kept change is its own ordinary commit on `g2-cubecl-local` (never amend, rebase or force; never push).

**Stop rule for part A:** if by 10:30 UTC nothing has removed at least 8 % of the 3b step's VALU count or
reached 12 waves, write that down and move to part B.

## Part B (second): why the port is ×1.34 slower than hand CUDA on NVIDIA

Measured on one RTX 3080, same session: bottom side with probes off 1.75 ms (port) against 0.63 ms (v10);
preparation 0.70 against 0.42 ms; full kernel 6.0 against 4.54 ms. And one unexplained effect: the same top
digits copied in from a precomputed table (`--tdig 1`) instead of made in the cube cost +2.8 ms with identical
table contents. The generated CUDA of several builds is in `port/raw/cuda_box2/cuda_src/`.

- Read the generated CUDA of the bottom side (phase 1) against v10's source and say, concretely, what the port
  executes that v10 does not (emulated 64-bit, bounds checks, shared-memory traffic, loops that did not unroll,
  divisions, register pressure).
- If NVIDIA's compiler pieces install from PyPI without a GPU (`nvidia-cuda-nvrtc-cu12`, `nvidia-cuda-nvcc-cu12`;
  use `uv`, a throwaway venv under the worktree, **at most 1 GB**, and remove it when done), compile both to PTX
  (SASS too if a disassembler is available) and compare instruction counts of that loop. If they do not install
  in 20 minutes, drop this and work from the sources.
- Apply source-level changes in the Rust kernel only where the generated code visibly improves, keep them exact
  on lavapipe, and mark the expected gain as **predicted, not timed**.

## Rules

- ivory only. No rented machines, no ssh to any other host, no production API, no pushes, no pull requests.
  Nothing outside `~/projects/nice/.worktrees/g2-cubecl` and the `G2/` directory of the scratchpad is written.
- `nice -n 19` and `-j 2` for builds. Run `df -h /` before every build: the disk has 9 GB free; stop and report
  if it drops under 5 GB. `/tmp` is a 3.8 GB tmpfs: do not build there.
- If a container named in the notes (`g2mesa`) is gone or stopped, restart or rebuild it as the notes describe;
  do not remove other containers, images or volumes.
- Label every number: measured (ACO or PTX count, lavapipe exactness), or predicted (time). No timing claims
  from lavapipe.

## Deliverables

1. `G2/TUNE-RESULTS.md`: a table (change, counts before → after, waves per SIMD, exact on lavapipe yes/no,
   predicted effect on the card and on CUDA, commit), the new model prediction for the card with its band, what
   you tried and dropped, and what remains.
2. `PORT-NOTES.md` "Where it stands" updated; `WINDOW-PLAN.md` updated if the build to time in the window, or
   its variants, changed; the bundle `port/g2-cubecl-local.bundle` re-created if you committed.
3. A final report to me of at most 40 lines: the table, the new prediction, anything that surprised you.
