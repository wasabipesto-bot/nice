# MU260 brief: bring PR #260 up to date with main (the counter-array hazard), then release-readiness numbers (2026-11-16)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules); **`../T26/RESULTS.md` (task 2: how the open PR branches
were merged together on 2026-11-14 and how each conflict was resolved) and `../T26/REVIEW.md`
finding F4 (lines ≈ 100–130: exactly what the second of #251 / #260 to land must change)**;
`../T26B/REVIEW2.md` "The defect, exactly" (a compiler rule for kernels: with CubeCL's SPIR-V
compiler only the first of several atomic stores of one value in a basic block survives).

## What happened

Yesterday the maintainer merged #251 (GPU full check in base-b² limbs, with its `ran` words and
`ensure_checked`), #256, #262, #263 and #264. Upstream main is `0711b163`, CI green. PR #260
(fork branch `pr/top-slot-any-plane`, head `ec6a43a1`: the FD top kernel's append without a
lane-0 assumption, with its account words in the same `ran` array and `ensure_appended`) now
conflicts with main: CHANGELOG and ten regions of `common/src/cubecl_join.rs`. Both PRs extend
the `ran` array; #251's test-only "smallest take" word is hard-coded at `ran[STAGES_U32 + 3]`,
#260 puts `TOP_ACCOUNT` at `STAGES`: a careless merge makes every batch fail loudly or, worse,
lets one check read the other's word.

The tested resolution exists: fork branch **`exp/integration-1114` at `8bcee21`** is the old main
(`41b4b40`) + #251 + #255 + #256 + #259 + #260's fix merged together, with the `ran` words
resolved as F4 says, and it passed every suite on CUDA and lavapipe on 2026-11-14. #255 and
#259 are still open (they only touch the prefilter, `walk_pf_lean` and its plumbing).

## Task 1 (the must-have): #260 merged up, verified

1. In the worktree `~/projects/nice/.worktrees/t26-top-slot` (local branch `t26/top-slot` =
   `ec6a43a1` = the PR's head; clean), **merge `origin/main` with a merge commit** (never rebase,
   never force-push). Resolve `cubecl_join.rs` to the integration branch's resolution: every
   `ran` word named in one place, `TOP_ACCOUNT` after #251's words, #251's smallest-take word
   moved to its own named index, the compile-time assert that the words are disjoint and
   `RAN_WORDS` covers them, `ensure_ran` / `ensure_checked` / `ensure_appended` each reading
   only its own words. CHANGELOG: keep every line of main as it is and put #260's own line
   first in the Unreleased list.
2. **Mechanical check of the resolution:** `git diff <your merge> 8bcee21 -- common/src/cubecl_join.rs`
   must show only what #255 and #259 change (compare with `git diff origin/main fork/pr/join-prefilter-shift-pow2`
   and `… fork/pr/join-prefilter-popcount-spirv` for that file) and nothing in the `ran` words,
   the top kernels, the check kernel or the host checks. Explain every other hunk or remove it.
   Likewise `git diff origin/main <your merge>` must be #260's change and nothing else
   (compare with `git diff 41b4b405 f9a25017` on the same files).
3. **Verify:** `just lint` (CI's recipe, nothing narrower) and the host tests on ivory; on the
   box: the join's device suites on CUDA; on lavapipe with both compilers **from Mesa 26.0.8 in
   an Ubuntu 26.04 chroot, as CI runs it** (`../T26B/raw/ci/chroot_setup*.sh` shows how; test
   binaries built on the host run in the chroot), including #260's partly-filled-plane and
   lane-0-out tests and #251's partly-filled-plane tests in the same binary (they share the
   `ran` array now: a collision shows here); dense compares against the CPU join on CUDA at
   base 60 1e16, base 62 1e17 and base 64 1e17. Dump the SPIR-V module of the merged kernels
   and confirm no atomic operation of the source is missing (the comparison script is in
   `../T26B/review2-box/`).
4. **Push** the merge commit to fork branch `pr/top-slot-any-plane` (plain push: `git push fork
   t26/top-slot:pr/top-slot-any-plane`). Do not open, edit or comment on the PR. Write
   `MU260/RESULTS.md`: the resolution hunk by hunk, the mechanical checks' output, every run.

## Task 2 (after task 1, time-boxed to 75 minutes of box time): what a release would carry

The NVIDIA fleet still runs release v3.4.7 (build `8bd154b`), which yesterday measured ×3.13
slower than main `54d0aac` at base 62 on a power-capped RTX 3080. Main has since gained #251
and #256. On this box (RTX 3080, 300 W cap): v3.4.7 against upstream main `0711b163`, the real
client against a local stub API exactly as `../T28/RESULTS.md` §3 did it (reuse `../T28/raw/`:
`stub_api.py`, `hosts_block.sh`, the queue files; block the production hosts first and prove
it), three real base-62 fields of 1e17 from `../T28/raw/queue_timing.json`, interleaved, two
rounds: join `run_secs`, wall time, counts (exact equality for main against yesterday's main
counts on the same fields; v3.4.7 within the audit's bound). Then NiceMark's nice-only GPU
suite on both, two rounds each, **with its API address pointed at a closed local port** (it
pings the production API for a latency figure otherwise). Report: the ratio at base 62 at this
card's default power limit, NiceMark per scenario, and one paragraph "what a release from
`0711b163` contains since v3.4.7" from the CHANGELOG's Unreleased section (speed, the
soundness fixes, anything a fleet operator must know: new knobs, changed defaults), in
`MU260/RELEASE-NUMBERS.md`. No release is made, tagged or proposed by you.

## Rules

Your box is Vast instance **60886021** (RTX 3080 at 300 W, 24 threads; `python3 vast.py ssh 60886021`
from the program directory; ssh verified; wait for `/root/READY`; it destroys itself at about
10:45 UTC). Never `vast.py create` or `destroy`. One `CARGO_TARGET_DIR` per tree on the box.
ivory: `nice -n 19`, keep 5 GB of disk free, no GPU or release builds, writes only under
`MU260/` and the worktree named above. Push only the merge commit to the one fork branch; never
force-push, never delete a branch; if a push or any action is refused, report it and do not
work around it. Never push to `wasabipesto/nice`; no PR actions; no subagents. Never touch the
fleet, the server, `~/fleet-run`, demoux or mayalaran; **no contact with the production API from
the box**; never claim from or submit to production. Copy results to ivory early and often.
Hard stop **10:15 UTC**; task 1 must be complete and pushed before task 2 starts. Your final
message is a short report for the program's director: the merge's head and its checks first.
