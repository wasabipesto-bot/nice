# N1 GPU brief: what a pair costs in the dense phase at other join shapes (2026-11-10)

You are an engineer on the nice research program (repo `~/projects/nice`, upstream
`wasabipesto/nice`, fork `wasabipesto-bot/nice`). Read first, in this order:
`~/projects/nice/scratchpad/2026-11-fresh-eyes/NOTES.md` (§3), the module docs at the top of
`common/src/overlap_join.rs` and `common/src/cubecl_join.rs` on upstream main (c0c357a), and
`../../L51/RESULTS.md` + `../../L34/RESULTS.md` (how the transposed AND works and what it costs).

## The question

The overlap join runs at one fixed shape: top blocks of b^3 numbers (f0 = 3), bottoms of k = 6
digits (masks of 12 output digits), 2 partition digits, fields that are ranges of n. A different
organisation ("transversal": work units keyed by the shared middle digits, every list built once
per base) would allow k = 9 (masks of 18 digits) with f0 = 4 or 3. Per admissible n at b62 it has
the same number of AND pairs as today (≈ 8e-3; 4.3e-3 at f0 3) but 7–15× fewer AND survivors,
60× fewer top tests at f0 4, and a tenth of the full checks. Whether that is worth a redesign
depends on one thing nobody has measured: **what the dense phase (everything the join kernel
does before a survivor is extracted: loading a batch of tops, transposing it, loading entries,
the AND itself) costs per (top, bottom) pair when the entry mask has 18 or 20 digits instead of
12, in the new tile shape, with 32-bit and with 64-bit chunk words.** In the transposed AND an
entry's pass mask over a chunk of 32 tops is the complement of the OR of one shared word per digit
of the entry, so the AND-only part should scale with the digit count; the per-wave base may not.

The decision rule the director applies to your numbers: the redesign is dropped for GPUs unless
some variant projects to **≥ ×3 on a whole b62 base** against today's main. Today's shares at
b62 1e17 on a 3080 (L51): join base 11 %, AND 15 %, walk 9 %, prefilter 20 %, stage 1 %, top FD
23 %, check 12 %, slice setup 5 %. So the dense phase's cost per pair decides it.

## What to build and measure

Box: instance **60024264** (`nice-research-n1-tile`, RTX 3080, 6 h TTL from ~06:00 UTC).
From `~/projects/nice/scratchpad/2026-10-research-program`: `python3 vast.py ssh 60024264`
prints the ssh command; wait for `/root/READY`. `/root/nice` is a clone of the fork with remote
`upstream` fetched; base your work on `upstream/main` (c0c357a). Branch `exp/n1-gpu-tile`, pushed
to the fork only (HTTPS remote of the fork works for pushing from ivory; from the box, bring
results back with scp/rsync instead). All GPU builds and runs happen on the box
(`--features gpu,cubecl-cuda`, backend cubecl-cuda, which is what the fleet runs).

1. **Calibration at today's shape (do this first).** On real data: b62, the 1e17 field starting
   at 3226266762397899821056 + 40000·10^17 (any mid-base field will do; say which), a sample of
   ≥ 64 partitions through `run_slices`. Get, with the kernel's own profile timers/ablations as
   L51 did or with counters you add: AND pairs tested, AND survivors, seconds in the dense phase
   and in survivor handling → **ps per pair (base and AND separately if you can) and ps per AND
   survivor**. The director's estimate to check: ≈ 2.6e13 pairs, 6.7e11 survivors per 1e17
   field; ≈ 0.8 ps per pair for base + AND; ≈ 36 ps per survivor.
2. **A tile harness**: a test-only kernel (or a comptime mode of `join_kernel`) that runs the
   dense phase on synthetic tiles whose masks are random digit sets of the right sizes, with the
   survivor path reduced to counting (popcount of the pass masks) so that the pair cost is what
   is timed. Parameters:
   - digits per bottom entry D_B ∈ {12, 18, 20}; digits per top D_T ∈ {17, 15} (tops have a
     variable count in production; use the fixed mean and say so);
   - tile shapes (tops per bucket × entries per bucket): today's ≈ 2,000 × 350, the new
     ≈ 1,460 × 14,750 (f0 4, k 9, per residue-class pair of one partition value), and
     ≈ 24 × 7,200 (a k 10 variant);
   - chunk words u32 (today, portable) and u64 (CUDA only: 64 tops per chunk);
   - orientation: tops transposed and entries in registers (today), and the reverse (bottoms
     transposed in chunks, each top ORs one word per digit of its own mask).
   **The harness must reproduce step 1's dense-phase cost per pair at today's shape
   (D_B 12, 2,000 × 350, u32, today's orientation) within 20 %.** If it cannot, say so plainly
   and report why (L39's lesson: a stripped kernel can expose a load chain that the full kernel
   hides, and then its numbers are upper bounds, not costs). Report ratios between variants
   inside the harness as the primary result, absolute ps per pair as secondary.
3. **Survivor handling at the new density**: with pass rates of 2.5 % (today) and 0.33 % (new)
   of pairs, what does the walk cost per survivor and per pair (most pass masks are zero at
   0.33 %)? Use the real walk if it can be driven from the harness, otherwise reason from
   instruction counts and say which.
4. Optional, only if 1–3 are done with ≥ 1 h left: the cost of certifying the 62 children of a
   certified top (f0 4 → f0 3) when only the new digits below the parent's certificate are
   computed, against a full FD step (0.21 ns): an instruction-count estimate is enough.

Rounds: ≥ 3 per configuration, interleaved, same process where possible (the join kernel has a
1-in-7 spilling compile variant; record each process's variant or alternate inside one process,
as L51/L53 did). Note the card's power cap and clock (`nvidia-smi -q -d POWER,CLOCK`).

## Deliver

`N1/gpu-tile/RESULTS.md` in this directory: the calibration numbers; the table of ps per pair by
(D_B, shape, word width, orientation) with spreads; survivor-path numbers; a projection of whole-
base b62 time for (f0 4, k 9) and (f0 3, k 9), u32 and u64, using these per-admissible-n counts
(admissible n per b62 base = 3.13e20; today's total ≈ 95,430 fields × your measured seconds per
field): pairs 8.0e-3 / 4.3e-3, AND survivors 2.7e-5 / 1.3e-5, prefilter pass ≈ 6 %, top tests
1.4e14 (f0 4) / 5e15 (f0 3) per base at 0.21 ns, bottoms 1.5e15 cheap extensions; and your own
judgement of what the model misses. Raw logs and scripts under `N1/gpu-tile/raw/`. State every
number's provenance (measured on the box / derived / assumed).

## Rules

Vast only through the instance above: never `vast.py create` or `destroy` (the director destroys
the box). ivory writes only under `N1/gpu-tile/` and your worktree
(`~/projects/nice/.worktrees/n1-gpu-tile`); `df -h /` before any ivory build (9.5 GB free; prefer
building on the box). Never push to `wasabipesto/nice`; no PRs; no subagents. Never touch the
fleet, the server, `~/fleet-run`, demoux or mayalaran. Hard stop 11:00 UTC: write up what you have.
