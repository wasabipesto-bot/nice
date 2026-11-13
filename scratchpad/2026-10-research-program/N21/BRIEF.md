# N21 brief: a leaner walk and prefilter loop in the GPU join (2026-11-13)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules), `../EXPERIMENTS.md` entries **N17.1**, **N16.1**
and **PRP.1** (yesterday's measurements, the source of the numbers below), `../N16/RESULTS.md`
section C and `../N16/raw/taskC.txt` with `../N16/raw/scripts/taskC*` (how the AMD compiler's
output for the join kernel was obtained without the card), `../L51/RESULTS.md` (NVIDIA's SASS of
the walk and the register caveat), `../PRP/RESULTS.md` (how CUDA A/Bs were run on a card that
throttles), and in `common/src/cubecl_join.rs` on upstream main: the module docs, the walk in
`join_kernel` (from `while plane_any(x != 0u32)`), `walk_pf_lean` and its doc comment.

## Why

After the AND, each thread walks the set bits of its 32-top chunk: per round every lane that has
a bit pops it, runs the fixed-point middle-digit prefilter on that pair (`walk_pf_lean`), and
stages the pair if it passes. Measured by running each part twice at full load:

| share of a field | RX 9070 XT, b62 1e17 | RTX 3080 | RX 9070 XT, b64 1e17 | RTX 3080 |
|---|---|---|---|---|
| prefilter | 25.9 % | 15.9 % | 30.4 % | 20.8 % |
| walk rounds (vote, pop, no prefilter) | 6.1 % | 9.1 % | 8.0 % | 12.6 % |

The RX 9070 XT (wgpu on Vulkan, CubeCL's SPIR-V compiler) does about 81 % of the search and
NVIDIA 13 %, and base 64 is where most of the remaining cost is. On the AMD card a probe that
added a chain of four operations (eight or nine instructions) per walked pair cost 4–7 % of a
b62 field, whatever the operations were: **every instruction in this loop is worth roughly half
a percent of a field there.** Mesa's compiler emits about 113 instructions per walk round and
entry slot for it (49 vector, 62 scalar exec-mask bookkeeping, 8 shared-memory loads) against
about 66 on NVIDIA; the prefilter block itself is 52 instructions with four 32-bit low and four
32-bit high multiplies. Two open PRs touch the area and should be assumed merged: #255 (at base
64 the digits are taken by shifts; branch `pr/join-prefilter-shift-pow2`) and #256 (the shared
survivor stage is 512 entries; branch `pr/join-survivor-stage-512`).

## Task

Find exact reformulations of the walk loop and the prefilter that execute fewer instructions
per walked pair, measure them, and deliver the best as candidate branches. Ideas to start from
(verify each against the code; add your own):

1. **Digits at b60/b62:** one high multiply by b² gives both digits of a fraction as a number
   below b²; splitting it (multiply by a small constant and shift, or compare against it) may
   be cheaper than a second high multiply plus a low multiply. Check the exactness proof in the
   doc comment still holds for the form you choose.
2. **The membership test:** `seen` is a 64-bit mask shifted left by each of the four digits and
   sign-tested. On both vendors a 64-bit shift by a variable amount is several 32-bit
   instructions. A word select and a 32-bit shift, a table in registers, or a different
   encoding of the masks may do the same test in fewer.
3. **The six distinctness compares** of the four digits.
4. **Shared-memory loads per walked pair** (`t_dm`, `t_glo`, `t_ghi`, then `t_id` on a pass):
   packing, ordering, or reading them once per round for the lanes that popped.
5. **The round itself:** the vote (`plane_any`), the pop, the stage append (`s_cnt.fetch_add`),
   and whether two bits per round, or a compaction of the popped pairs before the prefilter,
   pays (an earlier "group walk" lost at small batches on NVIDIA: see L40 in the ledger's history
   if you go there).
6. **Base 64:** with #255 the digits are shifts; what is left in the block there, and can the
   two products `p·dh` share work.

Each variant: a comptime switch on an experiment branch **`exp/n21-walk-loop`** (new, from
upstream main with #255's and #256's commits merged in; say exactly what the base is), default =
today's code, so one binary measures every variant.

**Exactness is not optional.** For each variant: an argument for why it is exact (for every input
the kernel can see, not only sampled ones), a host test, the dense compare against the CPU join
on CUDA (`NICE_TEST_JOIN_DENSE*`, `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`) at
b60 1e16, b62 1e17 and b64 1e17, and the wgpu device tests on lavapipe with both compilers.

**Measure:**
- CUDA on the box: each variant against the default, same binary, interleaved, at least three
  rounds, b62 1e17, b60 1e16, b64 1e17 (starts in `../N16/raw/scripts/env.sh`); counts identical;
  clock, power and register variant per run; start every timed run with the card cool (PRP did
  ≤ 60 °C) and never build while timing.
- For RDNA4 without the card: build Mesa's RADV as `../N16/raw/scripts/taskC_build_mesa.sh` does,
  dump CubeCL's SPIR-V for each variant and compile it for GFX1201; report instructions per walk
  round and entry slot (vector, scalar, shared-memory, multiplies) for the default and each
  variant. State the predicted gain on that card as an estimate from the price above, clearly
  labelled.

## Deliver

`N21/RESULTS.md`: the loop as it is (what each instruction group does, on SASS and on ACO), every
variant with its exactness argument, CUDA table and ACO counts, a ranking, and what you would
PR. The best one or two variants as **separate one-commit candidate branches** on upstream main
(`exp/n21-<name>`, no changelog line, no PR), each a discrete change. A 30-minute plan to time
them on the RX 9070 XT (`N21/WINDOW-PLAN.md`, scripts adapted from `../N16/raw/scripts/`, tested on
the box under CUDA and lavapipe). Raw logs and scripts under `N21/raw/`. Mark every number
measured, derived or assumed.

**Kill criterion:** if no exact variant removes at least 8 instructions per walk round on ACO's
count or gains at least ×1.03 on CUDA at b62 or b64, say so, write up what the loop costs and
why it resists, and stop.

## The box and the rules

The instance id comes in the message that carries this brief; `python3 vast.py ssh <id>` (from
the program directory) prints the ssh command; wait for `/root/READY` (`/root/FAILED`: clone the
fork yourself). One `CARGO_TARGET_DIR` per tree. Never `vast.py create` or `destroy`. ivory
writes only under `N21/` and a worktree `~/projects/nice/.worktrees/n21-walk-loop`; no GPU builds
on ivory (7 GB free; `/tmp` is a small tmpfs). Push only to the fork, only new branch names and
new commits on them; never force-push, never delete a branch; if a push is refused, report it.
Never push to `wasabipesto/nice`; no PRs; no subagents. Never touch the fleet, the server,
`~/fleet-run`, demoux or mayalaran. Copy results to ivory as you go. Hard stop **12:15 UTC**.
