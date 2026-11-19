# The middle-out join, step 3A: accounts that prove the work ran (brief, 2026-11-19 01:30 UTC)

You are an engineer on the third step of a build. Work alone (do not start subagents). **Hard stop
05:15 UTC.**

## Why this step comes before any more speed

"nice" is an exhaustive search whose normal result is "nothing found". An independent audit of the new join's
trunk finished an hour ago: `~/projects/nice/scratchpad/2026-10-research-program/G2/AUDIT-MO.md`. Read it in
full first; it is your specification. Its verdict in two sentences: the device equalled the CPU reference on
all 1,073 slices tried and no loss path was found for correct kernels on a healthy card; **but every account
the host checks is satisfied by all-zero counters, so a launch that did nothing returns "0 survivors" as a
success**, reproduced twice (a failed device allocation; `MIDOUT_STOP` left in the environment), and shown by
fault injection for a dropped main kernel, dropped tops, a dropped probe, a dropped parent and an over-strict
prefilter. Tonight the same class of failure was shown to reach production's stride path
(`G2/build2e/ALLOC-FAILURE.md`).

Also read: `G2/BUILD-BRIEF-1.md` (the owner's decision and the rules: all apply to you), `G2/BUILD-NOTES.md`
(the trunk's state), and on branch `dev/mo-wide` the job-instance account the wide path already has (`C_JOBS`,
commit `fb6962ea`), which is the model for one of yours.

## Your job

On the trunk `dev/middle-out-join` (head `91ac0761`; you are its only writer tonight):

1. **Merge `dev/mo-audit` into the trunk** (an ordinary merge commit): it carries the auditor's parity sweep,
   tops scan, fault-injection switches and tests, which are your acceptance tests.
2. **Positive evidence of execution for every stage**, compared by the host with what it queued, as the table
   in AUDIT-MO §4.1 lists: cubes or job instances that reached their end per kernel per batch; tops placed;
   rows written; a "slice done" word written on the device, from which the host counts slices; and the
   conservation laws of §1.3: total probes run = 8 × the slice's tops; children counted independently in the
   preparation = children the main kernel saw. All-zero counters must no longer pass for a slice that has work.
   Mind slice 0 and its like: some slices genuinely have no survivors or no tops; the account is "what ran
   equals what was queued", never "something was found".
3. **`MIDOUT_STOP` out of the library path** (a test-only or example-only switch if it is still needed).
4. **The guards of AUDIT-MO §3**: the 16-bit pending parent index, the 20-bit top index, the per-batch bound of
   the child-list write, plane-width checks in the kernels that lack one, nice numbers checked to lie in the
   field, the slice count that compares a host counter with itself.
5. **A sampled CPU check hook in the field driver**: one random slice per field recomputed by the CPU
   reference on a host thread while the card works, compared on survivors, checked and the prefiltered list;
   selectable by the caller, on in the benchmark example. It is the only check that sees a kernel that computes
   wrongly; say what it costs.
6. **Acceptance:** every fault switch of the audit that passed silently now fails loudly, each asserted by a
   test (`F_SKIP_MAIN`, `F_SKIP_TOPS`, `F_DROP_PROBE`, `F_DROP_PARENT`, and `F_PF_DROP` through the sampled
   check), the two reproductions of §1.1 and §1.2 fail loudly, the parity tests and a 100-slice subset of the
   sweep still pass, production's tests pass, fmt and clippy are clean. On CUDA on the box and on lavapipe at
   8 lanes through SPIR-V. Then the cost: per-slice time before and after and the ten-field number against
   tonight's 1.647 fs (main on this box is 6.615 fs; no need to re-run it).

Kernel traps to respect (all real in this codebase): on the SPIR-V compiler several atomic *stores of one
value* in a basic block are merged into one (use atomic adds, or distinct values); a `loop` with two `break`s
and a read after it compiles to invalid SPIR-V; planes may run partly filled on Vulkan and lane 0 may not
exist (count per lane that runs). `G2/PORT-NOTES.md` has the list.

Order of sacrifice if the night is short: items 1, 2, 3 and their acceptance tests first; then 4; then 5.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, handed to you for this task** (the auditor just left it idle):

      ssh -p 14628 root@ssh3.vast.ai

  Vast instance 61286074: RTX 3080 capped at 240 W, 16 threads visible with a 5.12-CPU quota, 31 GB memory;
  trees, toolchain, lavapipe, staged slices, the sweep's data and scripts are on it (`G2/audit1/`,
  `G2/build2a/box/`). Production hosts are mapped to 127.0.0.1 and ::1: check before any client binary runs;
  nothing ever claims from or submits to the production API. **It destroys itself at about 06:40 UTC: your
  commits must be on ivory well before that.** Leave it running and idle. Never create or destroy instances;
  never use another machine.
- Ordinary commits on `dev/middle-out-join` (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory; `git push fork
  dev/middle-out-join` from ivory. No pull request, nothing to upstream. One target directory per worktree.
- Do not touch `gpu_wide.rs` (it is on another branch) and do not restructure `gpu.rs` beyond what the accounts
  need: the wide kernels will have the same accounts ported to them afterwards.

## Deliverables (by 05:15 UTC)

1. The commits on ivory and the fork.
2. `G2/BUILD-NOTES.md` updated: section 1 for the new state; a new section "Accounts": for every stage, what
   it returns and what the host compares it with; the table of fault switches before and after; what is still
   visible only to the sampled CPU check or to nothing; the cost.
3. Raw logs under `G2/build3a/`.
4. A final report to me of at most 30 lines: which faults are now loud and which are not; the two
   reproductions; cost per slice and the ten-field number; what remains from the audit; anything the audit got
   wrong.
