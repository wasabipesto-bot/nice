# Review: `pr/join-survivor-stage-512` (0d84d0a2 on a7a59c11)

Reviewer: independent, 2026-11-12. Worktree: `~/projects/nice/.worktrees/review-stage` (detached at 0d84d0a2).

## Verdict

**Open after the listed fixes.** None of them is about correctness. The change is sound by construction for every
device, base and field shape, and no other code depended on the old values. What needs fixing is wording: the doc
comment's NVIDIA sentence is broader than the evidence (finding 1), and a few figures and phrases in the body are loose
(findings 2-5).

## Findings, most severe first

### 1. Doc comment: "On NVIDIA … the size does not matter" is true of the RTX 3080, not of NVIDIA in general (minor, doc)

`common/src/cubecl_join.rs:107-108`. Only an RTX 3080 (sm_86) was measured. Occupancy arithmetic for the lean shape
(the declared shared memory is 18,556 B = 18.1 KiB with 1,024 entries and 14,460 B = 14.1 KiB with 512, matching the
body's CUDA figures; 48 registers × 256 threads → 5 blocks per SM by registers on every arch below):

| arch | shared/SM | thread cap (blocks of 256) | blocks by smem, 1,024 → 512 | binding limit before → after |
|---|---|---|---|---|
| sm_75 (Turing: T4, RTX 20xx, GTX 16xx) | 64 KiB | 4 | **3 → 4** | **shared memory (3)** → threads (4) |
| sm_86 / sm_89 | 100 KiB (+1 KiB/block) | 6 | 5 → 6 | registers **and** shared memory tie at 5 → registers (5) |
| sm_70 / sm_80 / sm_90 | ≥ 96 KiB | 8 | ≥ 5 → ≥ 6 | registers (5) |

So on Turing the kernel is bound by its shared memory, and this change probably *raises* its occupancy by a third
there. That is a likely gain, not a risk, but it makes the comment's flat "on NVIDIA … the size does not matter"
wrong. Also, on sm_86 the old stage tied with the registers rather than being slack, so "bound by its registers, not
its shared memory" only holds after the change. Suggested wording: "On an RTX 3080 (sm_86) its registers allow 5
cubes per SM with either size, and the size did not measure." Optionally add that Turing's 64 KiB SM is
shared-memory-bound and was not measured.

### 2. Doc comment states ACO's occupancy estimate as a fact about the card (minor, doc)

`cubecl_join.rs:105-107`: "on AMD's RDNA4 the cube's 18.9 KiB with 1,024 entries limits how many cubes run at once,
and the 4 KiB less of 512 raises that by a third". The source (EXPERIMENTS N17.1) is ACO's static estimate, made with
Mesa 25.2.7 on a null GFX1201 device (12 → 16 waves per SIMD). The card was not profiled for occupancy, and the body
says so ("that is the reading of the compiler's output"). The measured ×1.056 fits the estimate but does not prove it.
The 18.9 KiB is ACO's figure; the declared arrays come to 18.1 KiB, and the difference is presumably allocation
granularity or compiler-added LDS. Suggest "Mesa's compiler puts the cube's 18.9 KiB … at 12 waves per SIMD and 512
entries at 16" or similar, so the comment does not assert a hardware measurement that was not made.

### 3. Body: operating-point ranges quote runs that are not this comparison (nit, body)

- RX 9070 XT, "3.03–3.19 GHz, 303–304 W": the 3.03 GHz comes from the `all3` b62 runs, which the analysis marks
  OFF-POINT. The base (`c`) and `sc512` runs are **3,083–3,168 MHz, 302–304 W** (`N16/raw/demoux_analysis.txt`
  lines 1-16, 32-47). Fix to "3.08–3.17 GHz, 302–304 W". Note also that `sc512` ran 50-80 MHz *below* the base runs
  and was still ×1.056 faster, which makes the result more convincing, not less.
- RTX 3080, b62 "288–307 W" and b60 "317–319 W": 307 W (b62 F r2) and 317 W (b60 F r1) are runs of tree F, the
  sibling branch. M and S alone give **b62 288–302 W, b60 318–319 W** (`PRP/raw/ab_table.txt`).

### 4. Body: "How many pairs go direct depends on how the device schedules the work groups" (nit, body)

That is not quite right. `s_cnt` is per cube. The flush check sits at fixed points (after each batch of tops, behind
barriers). Work items are assigned to cubes deterministically (`w += CUBE_COUNT_X`, `join_cubes = min(nwork, 65535)`,
`cubecl_join.rs:3659`). So the *number* past a full stage, `max(0, count_before + batch_passes − SURV_SH_CAP)` per
batch, is fixed by the batch plan; only *which* pairs take the direct path depends on scheduling. The next sentence,
"the RX 9070 XT's runs below had identical counts in every round", reads as though it were evidence about the direct
path, but those are hit and survivor counts, which are identical by construction, and the direct path was not counted
on the AMD card. Suggest: "How many pairs go direct is fixed by the batch plan, which differs by device; it was
counted on the RTX 3080 only."

### 5. Body: the experiment tree's difference could be named (nit, body)

The body says the AMD gain was measured "in a tree whose other stages are not exactly today's main". That is fair. I
checked it: tree E's `join_kernel` (32e9e19) differs from main's only in turning the constants into comptime
parameters plus experiment hooks that compile away at the defaults (diff of the two `join_kernel` bodies). Its shared
arrays are identical, and its flush is also checked once per batch of tops. The rest of tree E sits at #240 with FD
off at b64 and without #250/#254, so on main the join is a *larger* share of field time. The gain should therefore
transfer at about the same size, or slightly larger. One sentence would cover it: "the join kernel is today's;
the top-certification stage is older and slower".

### 6. Optional hardening: assert the constants' relation (nit, code)

Nothing enforces `0 < SURV_FLUSH <= SURV_SH_CAP`. Correctness does not depend on it, since a flush level above the cap
would only send more pairs direct, but the comment ("half the stage") states it. `const _: () = assert!(SURV_FLUSH > 0
&& SURV_FLUSH <= SURV_SH_CAP);` would document it, at no cost.

### Changelog line

"Speed up the GPU overlap join on AMD cards by halving the shared-memory stage … so that more of its work groups run
at once." It is in the file's style. Two things outrun the evidence: only one RDNA4 card was measured, and "more work
groups run at once" is the compiler's estimate, not a measurement. Acceptable as is. "on AMD's RDNA4 cards" would be
more exact.

## Soundness: what I checked in the code

Every reader of the two constants (`grep`, whole repo): only `cubecl_join.rs`.
- `:557-558`: `s_t`, `s_r` sized `SURV_SH_CAP`.
- `:972-985` (walk): `at = s_cnt.fetch_add(1)`. When `at < SURV_SH_CAP` the pair is staged at `at`. Otherwise it takes
  its own `surv_count.fetch_add(1)` and is written when `g < surv_cap`. Every pair takes exactly one of the two paths.
- `:1012-1027` (per-batch flush): `sc` is read between two barriers, so it is uniform and no append can race it, and
  the flush runs when `sc >= SURV_FLUSH`.
- `:3069-3100` (`flush_survivors`): `n = min(sc, SURV_SH_CAP)`, which is exactly the slots `0..n` that were written.
  It reserves `n` with one atomic, copies them, and resets `s_cnt`.
- `:1036-1048`: the final flush.

When a batch overruns the stage between flush checks (up to 256 tops × the bucket's entries), the overrun pairs are
counted once each in `surv_count` (direct) and the staged ones once (flush `n`). Nothing is dropped, and nothing is
counted twice. Overflow of the *global* list is independent of the stage: `check_kernel` clamps to `surv_cap`, and
the host (`read_counts` / `run_field` re-runs) compares `surv_count` against `surv_cap`. `join_plan.rs`'s `SURV_CAP`
(1<<24) and `SURV_CAP_RETRY` (1<<26) do not reference the stage. No CPU reference, other kernel, assertion or buffer
size uses either constant.

Independent model (`stage_sim.py` in my scratchpad): it simulates the walk/flush protocol with random batch sizes
(0…5,000 pairs per batch, random order), list caps above, equal to and below the total, and stages 512/256, 1024/512
and 16/8, over 9,000 cases. In every case the global count equals the pairs produced; with room, the list holds every
pair exactly once; with overflow, it holds `cap` distinct pairs. **ok.**

## What I verified, and how

- Diff (`git diff origin/main...fork/pr/join-survivor-stage-512`): two constants, their doc comments and one
  CHANGELOG line, nothing else. That matches the commit message and the body.
- `cargo fmt --all --check`: clean.
- `nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings` (toolchain 1.99.1 pin):
  clean.
- `nice -n 19 cargo test -p nice_common --features cubecl`: **233 passed, 0 failed, 34 ignored** (the device tests).
  The body's 247 is with `gpu,cubecl-spirv`, so that is a different feature set and the difference is not a
  discrepancy.
- Body numbers I recomputed from the raw logs, all of which match:
  - RX 9070 XT `sc512` per-round ratios b60 1.057/1.056/1.056 and b62 1.055/1.056/1.060 (from the
    `demoux_analysis.txt` seconds).
  - RTX 3080 per-round ratios and the mean-of-middle-two medians for b62, b60 and b64 1e17 (`ab_table.txt`).
  - NiceMark medians 9,948 / 9,916, ×0.999, and the per-scenario medians and minima (`nm_table.txt`).
  - T16/T512 direct-path counts (RESULTS "Stage overflow").
  - The 1,024/512 "0 at b60 and b62" claim (L51 §3.4 and L45, earlier kernel, as the body says).
  - The b60 one-round screen and the b64 stage-256 ×1.062 (EXPERIMENTS N17.1).
- The body mentions no program, directories, agents or model names; the only "Claude" is the required footer.

## What I could not verify

- Any GPU run, including the lavapipe tests. The brief rules out GPU-backend builds here.
- ACO's LDS and wave figures (18.9 KiB, 12 → 16 waves). I took them from N17.1; my own count of the declared arrays
  is 18.1 / 14.1 KiB.
- Whether RADV actually runs the kernel in wave32 or wave64 on the card, and so which limit binds there.
- The effect on unmeasured devices: Turing (probably a gain, finding 1), RDNA2/3, Intel, Apple.
- Direct-path traffic on the AMD card's batch plan. It was counted only on CUDA's plan.
