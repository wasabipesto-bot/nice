# T2.4 brief: can today's GPU join lose a candidate without anyone noticing? (2026-11-13)

You are an independent auditor for the nice research program (repo `~/projects/nice` on this
machine, ivory; upstream `wasabipesto/nice` = git remote `origin`). The project searches for
"nice numbers": n whose square and cube together use every base-b digit exactly once. A search
result is "no nice number in this field", submitted once per field and never cross-checked, so
**a silently dropped candidate is the worst defect the project can have**. Two have been found
after the fact: a flush race in the join kernel (fixed in #222; it dropped 2–4 in 10,000
candidates on one device class for weeks) and an unsound filter combination in an older search
mode. Yesterday's audit of submissions (`T2/AUDIT.md`) found traces of the first on three more
device families. Nobody has audited the current code for what remains.

## Task

Audit upstream main (`a7a59c11`; also read the three open PR branches on the fork,
`pr/check-d`, `pr/join-prefilter-shift-pow2`, `pr/join-survivor-stage-512`, since they will
merge) for **every path by which a pair (top, bottom) that should reach the full check, or a
number that passes it, could be lost, truncated or miscounted without the host detecting it and
re-running.** Scope: the GPU overlap join end to end, kernel and host
(`common/src/cubecl_join.rs`, `join_plan.rs`, `overlap_join.rs`, the check kernel and
`join_check.rs` on `pr/check-d`), with the CPU join (`cpu_join.rs`, `cpu_check.rs`,
`cpu_top_fd.rs`) as the reference it is tested against, and the client path that turns a
field's result into a submission (`client/`), as far as a lost hit could hide there.

Work through at least these, and whatever else the code shows you:

1. **Every bounded buffer and counter:** the top records, the bucket and group tables, the
   entry lists, the shared survivor stage, the global survivor list, the check kernel's input
   and its hit list, the transposed copy, any 32-bit count or index that a large field could
   overflow. For each: the bound, what happens at the bound, how the host notices, and whether
   the re-run can itself overflow.
2. **Every concurrent access:** shared-memory arrays and atomics in `join_kernel`,
   `top_kernel`, `top_fd_kernel`, the bucket kernel and the check kernel. For each write, which
   barrier separates it from its readers; anything read and written in the same phase without
   an atomic; anything that relies on a device's scheduling (plane size 32 or 64, work-group
   order). The #222 race is the model of what to look for.
3. **Every filter that rejects:** the field certificate, the top certificates (ordinary and
   finite-difference, their carry bounds and the positions they skip), the residue classes, the
   AND, the walk's range clipping, the fixed-point prefilter (its error bound, at every base the
   join takes and at the field sizes in use), the check kernel. For each: is the rejection
   exact, where is the proof or test, and what input would be the first to break it (largest
   base, largest field, digits at the extremes, a block boundary, the first or last n of a
   field, a field at the end of a base's range).
4. **Every device or runtime failure that could look like an empty result:** a dispatch that
   did not run or ran partly (what `cube_done` / `ensure_ran` check and what they cannot see), a
   lost device, a buffer that failed to allocate, a read-back of the wrong size, a refused
   layout, the retry and split logic in `run_field`.
5. **The host's bookkeeping:** how slices, partitions and batches are enumerated and whether any
   range of n can fall between two of them or be skipped on a retry; how hits travel from the
   kernel to the submission.

For each item: the invariant in one sentence, where it is enforced (file and line), which test
covers it, and your verdict: sound by construction, sound and tested, sound but untested, or
**a gap**. For a gap, give the smallest concrete scenario you can construct (a host-side model or
a unit test on ivory is better than an argument) and what it would take to close it. Do not
fix anything.

## Method

Reading, plus your own small models and host tests (`nice -n 19 cargo test -p nice_common
--features cubecl <filter>` from a worktree `~/projects/nice/.worktrees/t2-soundness`, with
`CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` so the build is incremental;
ivory has about 7 GB of disk and no GPU or Vulkan driver, so no device runs). Prior findings
worth knowing, not to be trusted blindly: `../B64/REVIEW.md` (the base-64 finite-difference
review), `../PRP/REVIEW-stage.md` and `REVIEW-shift.md`, `T2/AUDIT.md` section 4.

## Deliver

`T2/SOUNDNESS.md`: a summary first (gaps by severity, or "none found" with what that rests on),
then the full table by the five headings above, then what you could not check without a
device. **If you find a path that can lose a candidate in production today, stop and hand back
at once with the evidence; do not wait for the rest of the audit.** No pushes, no PRs, no
subagents, no rented machines; never touch the fleet, the server, `~/fleet-run`, demoux or
mayalaran. Hard stop **12:30 UTC**; your final message is a short report for the program's
director.
