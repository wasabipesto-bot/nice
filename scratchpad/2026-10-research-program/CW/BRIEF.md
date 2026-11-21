# Wider words per lane in the pairing kernel: a microbenchmark that decides (brief, 2026-11-21 06:00 UTC)

You are a GPU engineer. Work alone (do not start subagents). **Hard stop 11:25 UTC; the box destroys itself at
about 11:55 UTC.** A measurement task on a scratch branch: no production code changes, no pull request.

## Background

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a base
exactly once. Its redesigned GPU join (the "middle-out join") lives on the fork branch `dev/mo-clean`, head
`10ddbf17`, worktree `~/projects/nice/.worktrees/midout-clean` on ivory (this machine). **Read first:**
`~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §1, §2, §5, §6.5–6.7, §6.13 and its "Terms"; then
the main kernel in `common/src/midout/gpu.rs` (`g2_kernel`: its phase list is in its documentation; phases 3a
and 3b are the ones that matter here); then, under `~/projects/nice/scratchpad/2026-10-research-program/`:
`CEIL/RESULTS.md` ("Verdict", Q1's table, Q5, and "What I would build first") and `G2/BUILD-NOTES.md` §12.1–12.3
(how kernels are compiled offline for the RX 9070 XT, and the model of that card).

The pairing ("main") kernel is 60 % of a slice on the RX 9070 XT, the card that does most of the search. Per
job, about 472 probes (tops, each with about 17 certified digits) meet about 8,400 children in chunks of 64: a
chunk is one 64-bit word per digit value, a probe ORs its 17 digit words, and a non-zero result word is a
record. A lane holds a chunk; rounds are 16 chunks (1,024 children); phase 3a lists, per round, the probes that
at least one chunk of the round keeps after the common-mask skip; phase 3b runs every listed probe over the
round's 16 lanes. Yesterday's exact counts (`CEIL/RESULTS.md`): the lanes are 60.5 % busy; 91 % of kept visits
produce a zero word; no other order or skip test helps (best ×1.18). **One lever moves the number of lane
slots: the width of a lane's word.** With 128 or 256 children per chunk and rounds of 1,024 children unchanged,
lane slots fall to 0.503 and 0.254 of today's at the same bytes read (kept fraction 0.552 / 0.626, busy 0.678 /
0.767, records unchanged). Whether that is ×1.0 or up to ×2 / ×3.9 of kernel time depends on what a slot costs:
if a slot is bound by shared-memory loads, a slot with twice the words costs twice; if by the instructions
around the loads (loop control, probe decode, addresses, the record test and store), much less. The offline
compile of today's kernel for the RX 9070 XT shows the word loop at 171 VALU cycles and 39 LDS operations per
wave-iteration, and that card's model is issue-bound (it predicted the measured slice within 3 %).

## The question

**What does phase 3b cost per pair at 64, 128 and 256 children per lane word, on an RTX 3080 (measured) and on
the RX 9070 XT (offline cycle counts and the card's model), and what would the whole main kernel gain?**

## What to build (scratch branch `exp/mo-word-width` from `10ddbf17`, worktree `~/projects/nice/.worktrees/mo-word-width`)

A microbenchmark, not a rewrite of the join:

1. **Real inputs.** From the CPU reference (and the CEIL instrument on branch `exp/mo-ceiling`, head `52120649`,
   which already walks jobs, chunks, rounds and probe listings exactly as the kernel does), dump for a few real
   base-64 slices (712012851 and two others) what phase 3b consumes: per job the children's digit words in
   today's order, the probes' digit lists, and the per-round probe listings; for widths 128 and 256 the same
   with chunks of that width (children order unchanged, rounds of 1,024 children unchanged, the common-mask
   skip and the listing recomputed for that width). The expected number of non-zero words and of survivors per
   job comes from the same dump.
2. **Three kernels that do phase 3b's work and nothing else**, written in the project's kernel language
   (CubeCL, as `g2_kernel` is), as close to the real phase 3b as you can make them (take its code; keep its
   memory layout: words in shared memory per round, probe digits as the kernel stores them, the unrolled 17
   ORs, the record test, and a store of each non-zero word with the same ballot or append the kernel uses):
   width 64 (must match the real kernel's structure; show how you checked that, for example by comparing its
   generated code for the loop with `g2_kernel`'s), width 128 (two u64 or four u32 per digit word, your choice,
   say why; try both if cheap), width 256. Output per job: the count of non-zero words and the survivor count,
   **which must equal the dump's for every job**: no timing is reported for a kernel whose counts differ.
3. **Timing on the RTX 3080** (CUDA, the default backend): whole slices' worth of jobs per launch pattern as
   the real kernel launches them, many repetitions, the three widths interleaved, the card's clock and power
   logged; ps per pair and ms per slice for phase 3b alone. Also time the real main kernel on the same slices
   (the existing timing stops) so that phase 3b's share of it is known, and say how you separated phases 1, 2,
   3a and 4 from 3b (ablation or stops).
4. **Offline for the RX 9070 XT**: dump the three kernels' SPIR-V at a plane width of 64 on the box (the
   project's direct SPIR-V compiler path, feature `cubecl-spirv`), compile them with the driver's compiler in
   the container `g2mesa` on ivory (start it only for this; `G2/BUILD-NOTES.md` §12.1 and `G2/build4s/box/`,
   `G2/build9w/box/` have the scripts used before) and report per kernel: VALU cycles and LDS operations per
   wave-iteration of the word loop, registers, shared memory, waves per SIMD, spills. With the card's model
   (`G2/build4s/model_4s.py`: issue-bound, wave64 as two passes on a SIMD32, efficiency 0.77) give the predicted
   phase-3b time per slice for each width, and the main kernel's.
5. **The verdict against the rule written in advance:** if the whole main kernel gains less than ×1.15 at the
   best width by both the 3080's measurement and the offline prediction for the RX 9070 XT, the idea is
   dropped; if either shows ×1.15 or more, say what building it into `g2_kernel` would take (phase 1's chunk
   layout, the transpose, the records' format when a word is 128 or 256 bits, the expansion's read of them,
   the execution checks), what it would do to registers and waves per SIMD on the RX 9070 XT, and what the
   risks are. Report what you find; a clear "no" with numbers is a full result.

If the microbenchmark shows something else that matters more (for example that the record store, not the ORs,
bounds the slot), measure it and say so.

## Machines and rules

- **ivory**: reading, git, notes, and shader compilation in the existing `g2mesa` container only; no project
  builds here (4 cores, 4.5 GB of disk free).
- **One rented box, which I rented and logged in to for you:** the ssh line is at the end of this brief.
  Install the toolchain (the repository pins it), `spirv-tools`, and lavapipe (`mesa-vulkan-drivers`,
  `vulkan-tools`) if you use it for a functional check of the SPIR-V path. **Map the production hosts to
  127.0.0.1 and ::1 before any client binary runs** (`G2/build6c/box/hosts_block.sh`; you should not need a
  client binary at all); nothing ever contacts the production API. Never create or destroy instances; never
  use another machine, in particular never the maintainer's machines. Leave the box running and idle.
- Branch `exp/mo-word-width`: ordinary commits (never amend, rebase or force), trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory and `git push -u fork
  exp/mo-word-width` from ivory as the archive. Never commit to `dev/mo-clean`. No pull request; nothing to
  upstream.
- Long runs under `nohup` with logs, polled; foreground `sleep` on ivory is blocked (wait with a background
  `until …; do sleep N; done` loop). Copy raw results to ivory as you go.

## Deliverables (by 11:25 UTC)

1. `CW/RESULTS.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): the verdict first; the table
   (width × {ps per pair on the 3080, ms per slice of phase 3b, VALU cycles and LDS operations per
   wave-iteration, registers, waves per SIMD, predicted ms on the RX 9070 XT}); phase 3b's share of the main
   kernel on each card; every number marked measured (command, raw file) or predicted; the exactness evidence
   (counts equal per job); what building it in would take; what you could not finish.
2. Raw output under `CW/raw/`, scripts under `CW/box/`.
3. A final report to me of at most 20 lines.

## The box

    ssh -p 21860 root@ssh3.vast.ai

Vast instance 61761289: RTX 3080 (10 GB) at its 320 W default limit (not capped: log the clock and power with
every timing), 32 threads visible with a CPU quota of about 10, 46 GB of memory, 40 GB of disk, a fresh Ubuntu
image with CUDA devel (nothing of ours is on it: allow 20 minutes for the toolchain and the clone from
`https://github.com/wasabipesto-bot/nice.git`). ivory's ssh key is accepted; I logged in at 05:58 UTC. It
destroys itself at about 11:55 UTC.
