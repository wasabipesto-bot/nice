# Sharing shared-memory loads between neighbouring probes in the pairing kernel: a microbenchmark that decides (brief, 2026-11-22 05:55 UTC)

You are a GPU engineer. Work alone (do not start subagents). **Hard stop 10:15 UTC; the box destroys itself at
about 10:45 UTC.** A measurement task on a scratch branch: no production code changes, no pull request.

## Background

The "nice" project's redesigned GPU join (the "middle-out join", fork branch `dev/mo-clean`, head `10ddbf17`)
spends 60 % of a slice in its pairing kernel, and most of that in the word loop ("phase 3b"): each listed probe
(a top with about 17 certified digits) ORs its 17 digit words over each lane's chunk of 64 children; the words
live in shared memory. **Read first**, under `~/projects/nice/scratchpad/2026-10-research-program/`:
`CW/RESULTS.md` in full (yesterday's microbenchmark of this loop: it is the starting point for everything
here, including the tools, the dumps of real slices, the ablation that gives phase 3b's share of the kernel,
the offline compile for the RX 9070 XT and the two models of that card) and `CEIL/RESULTS.md` section "Q4"
(exact counts for sharing ORs between probes: ×1.26 in summed ORs with a trie order, ×1.13–1.17 once the lanes
of a wave run in lockstep). The design in plain words: `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md`
§2, §5, §6.5–6.6, §6.13.

Yesterday's finding that matters: **the word loop is bound by shared-memory bandwidth on the RTX 3080** (wider
words cut instructions by 30–45 % and gained only ×1.17), and probably on the RX 9070 XT. So the lever is
fewer loads, not fewer instructions. Consecutive probes of a job share digits (tops close in value share their
leading digits of n² and n³): if the listed probes of a round are ordered so that neighbours share a prefix of
their digit lists in one fixed digit order, the OR of the shared prefix can be kept in registers and only the
remaining digits loaded.

## The question

**How much of the word loop's time, and of the whole main kernel's, does sharing loads between neighbouring
probes save, on an RTX 3080 (measured) and on the RX 9070 XT (offline compile; both card models of
`CW/RESULTS.md`, the issue-bound one and the one with the shared-memory limit), with counts exact?**

## What to build (continue the scratch branch `exp/mo-word-width`, head `6f7559d1`, worktree `~/projects/nice/.worktrees/mo-word-width`)

1. **Orders and counts first, on the CPU** (the dump tool exists): for the real slices used yesterday, the
   number of digit loads per listed (probe, round) under: today's order; probes of a job sorted by their digit
   list in a fixed digit order (try: by digit position in the certificate from the most significant down; by
   digit value frequency); with one shared prefix level (the previous probe's first k digits, k chosen per
   probe as the common prefix length, capped at 4, 8, 12, 17) and with a small stack (2 or 3 saved partial ORs).
   The probe order is free per job, but the listing is per round and all 16 lanes of a round share it: count
   what survives that. Report loads per visit against 17.
2. **Kernels**: the width-64 word loop of yesterday's microbenchmark with (a) one saved partial OR, (b) the
   small stack if (a) leaves a clear gain on the table and registers allow. Variable trip counts: the lanes of
   one round share the probe sequence, but a 64-lane plane holds several rounds, so decide how the planes'
   streams stay in step (pad, or let lanes idle) and count the idle lane slots. The record test and store as
   in the real kernel. **Counts (non-zero words, survivor bits) must equal the dump's for every job; no timing
   for a kernel whose counts differ.**
3. **Timing on the RTX 3080** as yesterday (shuffled interleaving with the plain width-64 loop, clock and power
   logged, in cycles if the clock moves): ps per pair, ms per slice of phase 3b, and with yesterday's measured
   share of phase 3b in the main kernel (re-measure it if this box differs) the whole main kernel's gain.
4. **Offline for the RX 9070 XT** as yesterday (SPIR-V at a plane width of 64 from the box, the driver's
   compiler in the `g2mesa` container on ivory): VALU cycles and shared-memory operations per wave-iteration,
   registers (the kernel must stay at 120 or fewer and 12 waves per SIMD: say what the real `g2_kernel` would
   have with the extra accumulators), and the predicted word-loop and main-kernel times under both models.
5. **The verdict against the rule written in advance:** if the whole main kernel gains less than ×1.08 by the
   RTX 3080's measurement **and** by the shared-memory-limited prediction for the RX 9070 XT, the idea is
   dropped. Otherwise say what building it into `g2_kernel` takes (the probe order per job in the tops stage,
   the per-probe prefix length, phase 3a's listing, the execution checks) and its risks. A clear "no" with
   numbers is a full result.

## Machines and rules

- **ivory** (this machine): reading, git, notes, and shader compilation in the existing `g2mesa` container
  only; no project builds here.
- **One rented box, which I rented and logged in to for you:** `ssh -p 37180 root@ssh7.vast.ai` (Vast
  61919190: RTX 3080 10 GB at a 350 W limit, 12 threads, **15 GB of memory** (one slice's dump at a time),
  40 GB of disk, a fresh Ubuntu image with CUDA devel; nothing of ours is on it). You should not need a client
  binary; if one runs, map the production hosts to 127.0.0.1 and ::1 first and save the proof. Nothing ever
  contacts the production API. Never create or destroy instances; never use another machine, in particular
  never the maintainer's machines. Leave the box idle.
- Branch `exp/mo-word-width`: ordinary commits (never amend, rebase or force), trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory and `git push -u fork
  exp/mo-word-width` from ivory. Never commit to `dev/mo-clean`. No pull request; nothing to upstream.
- Long runs under `nohup` with logs, polled; foreground `sleep` on ivory is blocked. Copy raw results to ivory
  as you go. If the tooling denies something, do not work around it: note it and report it.

## Deliverables (by 10:15 UTC)

1. `PS/RESULTS.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): the verdict first; loads per
   visit by order and scheme (counts); the table by kernel variant (ps per pair and phase-3b ms on the 3080;
   cycles, shared-memory operations, registers and waves per SIMD offline; predicted ms on the RX 9070 XT under
   both models); the whole main kernel's gain on each card; exactness evidence; what building it in would
   take; what you could not finish. Every number marked measured (command, raw file) or predicted.
2. Raw output under `PS/raw/`, scripts under `PS/box/`.
3. A final report to me of at most 20 lines.
