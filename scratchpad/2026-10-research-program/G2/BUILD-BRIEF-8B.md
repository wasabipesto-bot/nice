# The middle-out join, step 8B: carry the review's changes back into the cleaned branch (brief, 2026-11-19 18:00 UTC)

You are an engineer. Work alone (do not start subagents). **Hard stop 21:40 UTC; the box destroys itself at
about 21:55 UTC. Bundle commits to ivory after every piece.**

## Where things stand

The middle-out join (a redesigned nice-only GPU join for the "nice" project) lives on the fork branch
**`dev/mo-clean`**, head `5a048669`, worktree `~/projects/nice/.worktrees/midout-clean` on ivory. Its maintainer
has put every pull request from this work **on hold** and is about to read that branch with a design document
and a process map (`~/projects/nice/scratchpad/2026-11-midout-design/`: read its `DESIGN.md` first, it is the
fastest way in; §9 lists what is known to be wrong on the branch). **No pull request is opened by anyone.**

This afternoon the first two pull requests (the field coordinate; the exact CPU reference) were cut from that
branch, independently reviewed with mutation testing, and fixed. Those fixes exist only on the two cut branches:

- `pr/midout-field-coordinate` (`c6d9164a`; same tree as worktree `~/projects/nice/.worktrees/pr-midout-coord`)
- `pr/midout-cpu-ref` (`da7f25c3`; same tree as worktree `~/projects/nice/.worktrees/pr-midout-cpu`)

so the branch the maintainer will read is behind its own review. Read, under
`~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's decision and the
rules: all apply), **`PR12-NOTES.md` §2 and §6 ("Carry back to `dev/mo-clean`": your list)**,
`PR12-REVIEW.md` (why each change exists), `CLEAN-NOTES.md` (the state of the cleaned tree, the three test
tiers and how each is run, what the box needs: `build6c/box/` has the scripts).

## Your job, in this order, each piece its own ordinary commit that leaves every tier passing

**A. The carry-back.** After it, `common/src/midout/coord.rs`, `cpu.rs`, `arith.rs`, `mask.rs` on `dev/mo-clean`
are the cut branches' files plus **only** what the rest of the branch still needs and the cut left out, and you
list that difference line by line in your notes:

1. `Coord`'s fields private with getters; every use in `gpu.rs`, `gpu_wide.rs`, `audit.rs`, `route.rs`,
   `wire.rs`, the examples and the client changed to match.
2. The three independent tests, `prefilter_digits` / `prefilter_direct`, the per-base split of the whole-base
   test, the fixed brute-force test (it counted `checked` with the reference's own prefilter).
3. `Counts` field docs and the counter wording; the per-file lint allowances instead of the module-wide list.
4. The coordinate's documentation true for the default: on this branch `coord.rs:21–24` still gives the older
   (4, 9, 6) renumbering under "Base 64" while the default is (4, 8, 5).
5. **What must stay that the cut removed:** the older coordinate (4, 9, 6) and the coordinates of bases 65 and
   68–70 (the wide path and its tests use them; whether the older one is dropped is the maintainer's open
   decision, so it stays, documented as "also known"), `Mask::low64`, `Shape::label`, the box-only staged test.
   Choose the smallest API that serves both (the cut's `coord_digits` / `is_known` extended, not two parallel
   sets of names) and say what you chose.

**B. Three stale comments:** `gpu.rs:281` names `tdig_kernel` (now `tdigz2_kernel`); `route.rs` gives the
base-65 CPU slice as "about 70 s against 55 s" where the measurements are 70–93 s against a 55–56 s field (state
the range and that the sampled check is therefore off at base 65); anything else you meet that is false.

**C. The client route refuses an Apple Metal device.** The join has never run on Metal; the decisions document
given to the maintainer says the hidden client flag refuses it until someone has checked it on Apple hardware,
and today `client/src/midout_route.rs:164–186` accepts any wgpu device. Find how production tells Metal from
other backends (`grep -rn "Metal" common/src client/src`), refuse with one plain sentence, and unit-test the
predicate (no Apple machine is available: say that the refusal itself is untested on one).

**D. If, and only if, it is a small and safe reordering:** install the route's panic hook before the device
context is created (today it is installed after, so a runtime-thread panic during context creation is seen only
by the execution checks). If it is not small, leave it and say why.

**E. Verify at the new head, on the box:** `just lint`; production's whole suite; tier (a) (ordinary tests) in
release and debug with their times; tier (b) on lavapipe through both compilers (WGSL and SPIR-V); the card
tier on CUDA (slice parity, both fault tests, wide parity); and one timing, five warm base-64 fields at the
new head against `5a048669` in the same session, alternating (this morning: 1.627 fs per admissible n on this
host): the carry-back must cost neither exactness nor speed. Kernels should not change at all: if any kernel's
generated CUDA source differs between the two heads, stop and find out why.

**F. Then make the maintainer's reading material match the new head** (on ivory, after the push; this is the
only place outside the repository you write, apart from your notes):
`cd ~/projects/nice/scratchpad/2026-11-midout-design && python3 tools/check_refs.py interactive/midout-map.html`
checks every file:line in the map against the branch; fix each `BAD` line number in the map's node array (the
README there says how), run `python3 tools/print_inline_refs.py DESIGN.md` and fix the inline `file:line`
references in `DESIGN.md`, and replace `5a048669` by the new head where either names the head its references
were checked against (not where a measurement names the commit it was taken at). **Change no other wording
there**: list for me what in `DESIGN.md` §9 and §10 is now out of date (items you fixed, file sizes) and I edit
it. Do not re-render screenshots.

**G. A separate, small question about production (not the middle-out work; reproduce or refute, do not fix).**
The reviewer of the cut branches reported that production's stride table panics for bases with no valid residue
(19, 23, 27; possibly 15), around `common/src/stride_filter.rs:165` on upstream main (`origin/main`, `974d7194`).
In a scratch clone of upstream main on the box: is it true, for which bases, with what message, and **which
user-reachable commands hit it** (a client subcommand with `--base`, the benchmark, an API-issued field: say
whether the server can ever issue such a base)? Write a failing test in the scratch clone only (no branch, no
push) and report the facts in a short section of your notes.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here (4 cores, 4.6 GB of disk free).
- **One rented box, which I rented and logged in to for you:** the ssh line is at the end of this brief.
  Install the toolchain (the repository pins it), `just`, lavapipe (`mesa-vulkan-drivers`, `vulkan-tools`),
  `spirv-tools`; **map the production hosts to 127.0.0.1 and ::1 with the proof saved before any client binary
  runs** (`build6c/box/hosts_block.sh`); nothing ever claims from or submits to the production API. Never
  create or destroy instances; never use another machine (in particular never the maintainer's machines).
  Leave the box running and idle.
- Branch `dev/mo-clean`, worktree `~/projects/nice/.worktrees/midout-clean`: ordinary commits only (never
  amend, rebase or force; no merge commits with a default message); every commit message has a body saying
  what and why in plain words, with no reference to notes, steps, reviews by name, agents or models; trailer
  exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Bundle to ivory after every piece;
  `git push -u fork dev/mo-clean` from ivory. **No pull request, nothing to upstream, the two cut branches are
  not touched.** One target directory per clone on the box; verify a binary by its build string before timing.

## Deliverables (by 21:40 UTC)

1. `dev/mo-clean` on ivory and the fork, everything passing at its head.
2. `G2/CARRYBACK-NOTES.md`: per piece A–G what was done and the proof; the line-by-line difference that remains
   between the branch's four shared files and the cut branches', with the reason for each; tier results and
   times; the timing; the list for `DESIGN.md` §9 and §10; the answer to G.
3. Raw logs under `G2/build8b/`.
4. A final report to me of at most 25 lines.

## The box

    ssh -p 26994 root@ssh5.vast.ai

Vast instance 61490977: RTX 3080 (10 GB) capped at 240 W by its host, 16 threads visible with a CPU quota of
about 5, 31 GB of memory, 40 GB of disk, a fresh Ubuntu image with CUDA devel (nothing of ours is on it yet:
the earlier box is gone, so the toolchain, `just`, lavapipe and the clones are yours to set up; allow 20–25
minutes). ivory's ssh key is accepted; I logged in at 17:58 UTC. It destroys itself at about 21:55 UTC.
