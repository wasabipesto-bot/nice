# The middle-out join, step 2E: masks wider than 64 bits, bases 65 and up (brief, 2026-11-18 19:10 UTC)

You are an engineer on the second step of a build. Work alone (do not start subagents). **Hard stop
00:30 UTC** (tonight, after midnight).

## Why this piece

The project's owner approved building the middle-out join today, and said what decides its value for them:
*"If this is a 5x improvement for all further work then I'm much more interested than a b64-specific
optimization."* After base 64 come bases 65, 68, 69 and 70, where a digit mask no longer fits in 64 bits.
Production has no join there at all (it falls back to a path hundreds of times slower). A CPU study today
showed by exact counts that the middle-out design carries to those bases; **nothing above base 64 has run on
a GPU.** You make it run, exactly, and take the first number.

## Where things stand

Read first, on ivory under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the
owner's decision and the rules: all of its rules apply to you unchanged), `BUILD-NOTES.md` in full (the state
after day one; piece E of its §7 is yours), `bases/RESULTS.md` (the study above 64: shapes per base, what
widens, the padded coordinate, probe counts per block at bases 68 and 69, how to stage a real base-65 slice
with the prototype), `PORT-NOTES.md` (the CubeCL 0.10 pitfalls: read them twice). Code: branch
`dev/middle-out-join` at `7ba982c7`, `common/src/midout/` (`gpu.rs` is the device path for base 64, `cpu.rs`
the CPU reference, which already runs with `u128` masks, `coord.rs` the field coordinate, with base 65's
padded form tested).

## Your job

1. **The device path for masks wider than 64 bits**, bases 65–70: child and common masks in two words, digits
   by division instead of shifts, 7-bit digit fields, more slice rows per chunk, the coordinate's padded form.
   Bases up to 64 must keep today's 64-bit path and its speed: width is a compile-time or per-base choice, not
   a tax on base 64. Whether that is a second file or a width parameter in `gpu.rs` is your call; say why.
2. **Exact first.** The device equals the CPU reference (`u128`) on real base-65 slices, survivor sets n for n
   and every count; a staged prototype slice at base 65 as an independent reference; and the wide path forced
   on at small bases and at base 64 against the references that already exist there (so the wide code is
   tested where brute force and the narrow path can check it). On the box's card (CUDA) and on lavapipe
   (SPIR-V) at 8 lanes.
3. **The first numbers**, on whole fields, end to end, labelled with the box and its power cap:
   - base 65: fs per admissible n, against the study's prediction for it and against base 64 on the same box
     in the same session through the same library path (day one measured base 64 at 1.752 fs on another box);
   - base 64 through the wide path against base 64 through the narrow path: what width itself costs;
   - base 68 if time allows (n has 14 digits there; the study says a block has 3.5k–6.3k probes against the
     576-probe table, so the table must be tiled: day one's "second job instance" is the mechanism to extend).
4. Card-years for base 65 from your measured number (admissible n at base 65 is ×0.905 of base 64's
   4.83e21), stated as a measurement on one RTX 3080 at this box's power cap.

Order of sacrifice if the night is short: exactness at base 65 before any number; base 65 before base 68.

**Not yours tonight:** the cost around the kernel (expansion, prefilter, top hierarchy): another engineer is
changing exactly those parts of `gpu.rs` on the trunk branch tonight. Keep your changes out of those functions
where you can, and do not rename or move code you do not need to touch, so the branches merge.

## Your machines and branch

- **ivory**: reading, git and notes only; do not build here (disk nearly full).
- **One rented box, which I rented and logged in to for you:** the ssh line at the end of this brief. Set it
  up as `BUILD-NOTES.md` and `G2/build1/box/` describe (toolchain, lavapipe, **production hosts mapped to
  127.0.0.1 and ::1 with the proof saved before any client binary runs**). It destroys itself about
  06:00 UTC. Leave it running and idle at the end.
- **Your branch is `dev/mo-wide`**, created from `7ba982c7`, with its own worktree
  `~/projects/nice/.worktrees/midout-wide` on ivory. Ordinary commits, never amend, rebase or force; trailer
  exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle from the box to ivory, then
  `git push -u fork dev/mo-wide` from ivory. Do not write to `dev/middle-out-join`. No pull request, nothing
  to upstream.

## Deliverables (by 00:30 UTC)

1. The commits on ivory and on the fork branch; `cargo fmt` and clippy clean; production's tests and day one's
   tests still pass.
2. `G2/BUILD-NOTES-WIDE.md`: where it stands, the design choice for width and why, what widened and what each
   widening costs, the test inventory with results, the numbers of item 3 with their raw logs
   (`G2/build2e/`), what is not proven, and what merging with the trunk will need.
3. A final report to me of at most 30 lines: exact or not at base 65 (and how checked); the base-65 number and
   what it means in card-years; what width costs at base 64; base 68's state; surprises.

## The box

    ssh -p 28120 root@ssh6.vast.ai

Vast instance 61303619: RTX 3080 with 20 GB, power limit 320 W (uncapped), 64 threads, 251 GB of memory, 48 GB
of disk, Ubuntu 24.04, image nvidia/cuda:12.8.1-devel-ubuntu24.04 (nvcc present). ivory's ssh key is accepted;
I logged in at 18:54 UTC. It destroys itself at about 06:00 UTC.

A build trap seen on these boxes: two worktrees building into one cargo target directory can hand you the
other worktree's binary. One target directory per worktree or commit you compare, and check a binary by a
string only it contains.
