# The review's fixes for the base-65 branch, an independent count for the top hierarchy, and the merge (brief, 2026-11-27 09:20 UTC)

You are a GPU engineer (Rust, CubeCL kernels). Work alone (do not start subagents). **Hard stop for card work
13:00 UTC; report by 13:30 UTC** (check `date -u`).

## Where things stand

The "nice" project's redesigned search join (the middle-out join) has a wide device path for bases 65–70
(`common/src/midout/gpu_wide.rs`) and a narrow one for base 64 (`gpu.rs`). A result is the statement that a range
holds no solution: **a kernel that silently loses a candidate is the one unforgivable failure**, and every stage
therefore keeps "accounts" (counts read back and checked by the host) and each field is compared on one sampled
slice with the CPU.

- Fork branch **`dev/mo-wide-b65`** (`a7ea3890`, three commits on `0b6e22e1`): a compact tops list and shared
  parent lists on the wide path; base 65 is 6–7 % faster on an RTX 3060. Its author's write-up:
  `B65/LEVERS-RESULTS.md`. An independent review: **`B65/LEVERS-REVIEW.md`** ("merge with fixes"; read it in full:
  it is your work list). Both under `~/projects/nice/scratchpad/2026-10-research-program/` on ivory (this
  machine); paths below are relative to that directory unless they start with `~`.
- The main development branch **`dev/mo-mode`** has moved to `c16d48e9` since that branch was cut: it gained
  dump tests that put the middle-out kernels through the project's WGSL lint in CI (`LINT/NOTES.md`:
  `wgsl_dump_for_lint` in `gpu.rs` and `gpu_wide.rs`, `scripts/wgsl-lint.py`, the `--require` lists in
  `.github/workflows/gpu-parity.yml`).

## The job, in this order (small named commits; each compiling and exact)

Work on a new branch **`dev/mo-wide-b65b`**: start from `dev/mo-mode` `c16d48e9` and bring in `dev/mo-wide-b65`
with a **merge commit** (no rebase of pushed commits; resolve conflicts in `gpu_wide.rs`'s test module by keeping
both sides). Pushes to `fork` only; never to `origin`, `dev/mo-mode` or `dev/mo-wide-b65`; never force-push or
amend a pushed commit; commit trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no
mention of assistants, agents, reviews by agents or a research program in commits or comments. No pull request.

1. **Review finding 2:** read back the compact list's own count (`tstat[2]`) and require it to equal `tstat[0]`.
2. **Review finding 1:** a test that checks the **shared** parent path against an independent reference n for n:
   the brute-force small-base test through the field path with sharing on (fields holding several slices per key,
   so that the lists are really built and used; mind finding 5's note that `build_anc` requires a non-empty list
   per key, which small bases may violate: make an empty list legal if it is, or choose bases where it cannot
   happen, and say which), or the narrow path's `MIDOUT_SHARE8` case ported to the wide slice test; and assert in
   the sharing test that the lists were used, not only built.
3. **Review finding 3:** a fault confined to the shared lists that keeps the list's own counts consistent, and a
   test that the sampled check's field-run comparison catches it.
4. **Review finding 4, the important one. An independent count for every ballot append that has none.** The
   review found that `wtops5` (the top hierarchy's parent list, unchanged by the branch) appends by ballot with no
   plane check and no count independent of the ballot, so on a driver that leaves a plane's lanes split after a
   branch a valid prefix could be dropped with consistent counts; it suspects the base-64 path's `tops5` and
   names `whist`'s certified count. **Audit every ballot append in `gpu.rs` and `gpu_wide.rs`** (list them in your
   notes: kernel, what it appends, which account proves the count independently of the ballot, or none) and give
   each one that lacks it an independent count that the host checks (the review suggests a per-lane count summed
   outside the ballot; follow whatever form the other kernels of these files already use), with a fault in the
   fault tests that shows the new account is loud. Kernels must stay exact and the cost small: measure it.
5. **The lint's dump:** the wide dump test and the workflow's `--require`/`--require-present` lists must cover the
   new and changed kernels (`wanc_kernel`, the new `wtops1`/`wtops2`/`wtdigz` forms, whatever step 4 touches),
   at forced plane widths 32 and 64 as the others are.
6. Review finding 5, as far as cheap: the compile-only path at forced width 64 should include `build_anc`; an
   out-of-memory test through the field path if it is small. Bases 66–70 are out of scope today (say so).
7. Review finding 6 (minor items): fix what is one line; list the rest.

## Verification

- **eventeo** (RTX 3060; rules as before: `README.md` "Machines the program may use", the memory entry
  `~/.claude/projects/-home-claude/memory/reference_eventeo_host.md`; wake it with `~/.local/bin/wake-eventeo`,
  source `~/research/scripts/env.sh` (and `env_vulkan.sh`) in every script, never the production API, kill only by
  recorded PID, `bash -l ~/research/scripts/off_if_idle.sh` at the end and confirm from ivory that ssh is gone;
  yesterday's and today's scripts are in `B65/scripts/` and on the machine under `~/research/`): all wide tests
  and the narrow tests through CUDA and through Vulkan (direct SPIR-V); every existing fault message unchanged;
  counts of base-65 fields 13731 and 77777 and of a base-64 field equal to `B65/runs/levers/`'s; timing of base 65
  and base 64 (narrow and wide) before and after step 4, alternating, card utilisation and power beside it: **the
  independent counts may cost at most 1 % of a field; if more, say what it costs and why, and keep them.**
- **The M4** (`ssh justin@mayalaran`; write only inside `~/claude`; `~/claude/scripts/env.sh`; `build_mo.sh
  BRANCH TAG` and `wide_tests.sh TAG RUN` exist there): the wide tests through Metal on the final head.
- **The fork's CI on the final head** (`gh workflow run "GPU Device Parity" -R wasabipesto-bot/nice --ref
  dev/mo-wide-b65b` and `"Rust Cross-Platform Build, Test, and Release"`): lavapipe with the lint step and the
  forced-width tests, Metal, `just lint`, the whole matrix. If macOS jobs are cancelled for lack of runners,
  re-run them (`gh run rerun <id> --failed`).

## Deliverables (by 13:30 UTC)

- `dev/mo-wide-b65b` on the fork with the CI results on its head.
- `B65/FIXES-NOTES.md`: per review finding what was done and how it was verified; **the audit table of ballot
  appends**; the cost of the new counts; what the tests ran on; what is not done; energy; confirmation that
  eventeo is off and nothing runs on the M4.
- A final report to me of at most 20 lines. If the tooling denies something or a machine does not answer, do not
  work around it: stop and report.
