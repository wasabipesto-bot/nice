# The middle-out join, step 2A: the cost around the kernel (brief, 2026-11-18 19:05 UTC)

You are an engineer on the second step of a build. Work alone (do not start subagents). **Hard stop
23:45 UTC.**

## Where things stand

Read first, on ivory: `~/projects/nice/scratchpad/2026-10-research-program/G2/BUILD-BRIEF-1.md` (what the owner
decided and the rules: all of its rules apply to you unchanged) and then `G2/BUILD-NOTES.md` in full (the state
after day one, written three hours ago by the engineer before you). Code: branch `dev/middle-out-join`, head
`7ba982c7`, worktree `~/projects/nice/.worktrees/midout` on ivory, `common/src/midout/`.

Day one produced an exact end-to-end path for base-64 fields on an RTX 3080: **1.752 fs per admissible n against
main's 6.615 fs in the same session, ×3.78.** The kernel and its preparation cost what the prototype measured
(6.1 ms per slice). The shortfall against the prototype's ×4.6 is the work around the kernel, which earlier
measurements assumed at 0.115 fs and which costs 0.45 fs: tops 0.46 ms, record expansion 0.92–0.98 ms, the
unprefiltered full check 0.57 ms per slice.

## Your job: pieces B, A and C of BUILD-NOTES §7, in that order

- **B, the expansion** (records → checkable entries): the largest new overhead. The notes list three routes.
- **A, a prefilter before the check**: production's middle-digit prefilter as a pass on the survivor list (or
  folded into the expansion), so that `checked` takes production's meaning; mirrored in the CPU reference.
- **C, a top hierarchy across a field**: certificates at coarser levels once per field or per 64 slices, the
  per-slice level only under a valid parent.

For every piece: exact first (the CPU mirror equals the device on the test slices; whole-field counts equal
before and after where the piece does not change a counter's meaning, and equal to the CPU reference where it
does), one ordinary commit per piece with its tests, then its cost per slice by the same cumulative-stop
method the notes used. If a piece does not pay, say so and leave it out: do not keep code that is neutral.

**Target:** at least ×4.4 end to end on this box against same-session main, with the per-piece table showing
where it came from. Re-run main's ten fields once at the end for the ratio (they take 14 minutes; the box's
earlier value was 6.615 fs). The same ten middle-out fields as day one, so numbers compare.

**Not yours tonight:** masks wider than 64 bits (another engineer is building that on another box, on branch
`dev/mo-wide`: keep your changes inside the existing functions where you can, and do not rename or move the
pieces of `gpu.rs` you do not need to touch, so the two branches merge), the client route, the main kernel's
internals (piece D), lavapipe at 16 lanes.

## Your machines

- **ivory**: reading, git and notes only; do not build here.
- **The day-one box, still running and idle, handed to you for this task:**

      ssh -p 14628 root@ssh3.vast.ai

  Vast instance 61286074: RTX 3080 capped at 240 W, 16 threads visible but a 5.12-CPU quota, 31 GB memory. The
  day-one engineer's build tree, toolchain, staged slices and scripts are on it (`BUILD-NOTES.md` and
  `G2/build1/box/` say where); production hosts are already blocked there (proof in `G2/build1/raw/`): check the
  block still holds before any client binary runs. It destroys itself about 06:40 UTC. Leave it running and
  idle at the end.
- Commits go on `dev/middle-out-join` (you are its only writer tonight): ordinary commits, never amend, rebase
  or force; trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle from the box to
  ivory, then `git push fork dev/middle-out-join` from ivory. No pull request, nothing to upstream.

## Deliverables (by 23:45 UTC)

1. The commits on ivory and on the fork branch; `cargo fmt` and clippy clean as before; production's tests
   still pass.
2. `G2/BUILD-NOTES.md` updated: section 1 ("where it stands") rewritten for the new state, the per-slice cost
   table before and after, the new number, the test inventory, and section 7 revised (what is done, what the
   next most valuable piece is now, with your estimate of its worth).
3. Raw logs under `G2/build2a/`.
4. A final report to me of at most 30 lines: the ratio and the session it was taken in; what each piece gave;
   what you dropped; exactness evidence; the next piece you would do and why.
