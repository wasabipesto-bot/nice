# The middle-out join, step 9W: the wide path's check, expansion and shared memory (brief, 2026-11-20 06:20 UTC)

You are an engineer. Work alone (do not start subagents). **Hard stop 11:35 UTC; the box destroys itself at
about 11:55 UTC. Bundle commits to ivory after every piece.**

## Where things stand

The middle-out join (a redesigned nice-only GPU join for the "nice" project) lives on the fork branch
**`dev/mo-clean`**, head `c2152084`, worktree `~/projects/nice/.worktrees/midout-clean` on ivory (this machine).
Its maintainer has every pull request from this work **on hold** while they read the design; work on the
branch continues. **Read first:** `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` (the fastest way
in; §4 on the execution checks, §6.7–6.9 and §9 matter most for you), then, under
`~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's decision and rules: all
apply), `BUILD-NOTES-WIDE.md` and `BUILD-NOTES.md` §11 and §14 (the wide path's history and measurements),
`CLEAN-NOTES.md` (test tiers, how the box is set up: `build6c/box/`), `CARRYBACK-NOTES.md` §4 (yesterday's
verification of this head).

The **wide path** (`common/src/midout/gpu_wide.rs`: two-word masks, digits by division) is the only GPU route
for bases above 64: base 65 is exact and costs 3.47 fs per admissible n on an RTX 3080 (×2.17 of base 64) and
3.1 fs on the RX 9070 XT, the card that does most of the search (×3.2 of base 64 there). Three things are known
to be wrong with it. Do them in this order; each piece is its own ordinary commit that leaves every tier passing.

## A. The sampled CPU check does not fit base 65 (a soundness gap: do this first)

At base 64 one random slice per field is recomputed on the CPU and compared n for n; it is the only thing that
sees a kernel that does all its work and computes wrongly. At base 65 it is switched off, because the CPU slice
takes 70–93 s on one thread against a 55–56 s field (`route.rs`, `gpu_wide.rs`). Make it fit:

- Make the CPU reference's slice search run on several threads (the jobs or the parents of a slice are
  independent; `rayon` is already a dependency of `nice_common`: check). The result must be identical to the
  single-threaded one in every count and in the survivor list's order, or the comparison must not depend on
  order: prove which, and test it (a slice at a small base and one real base-65 slice, both thread counts).
- Measure the base-65 CPU slice on this box (a quota of about 5 CPUs) with 1, 2, 4 and all threads, and the
  base-64 one. The maintainer's machine has more cores, but assume no more than this box.
- If it fits inside a field with margin (CPU slice ≤ 0.8 of the field time on this box), switch the sampled
  check on at base 65 in the route and say so in the code where it was explained as off. If it does not fit,
  do not switch it on: report the times and what would be needed (for example a check that finishes during the
  next field, with the submission held until it has).
- The thread count must not starve the device thread: measure base-65 and base-64 field time with the check
  running against without (five warm fields each, alternating); a slowdown of more than 1 % at base 64 is not
  acceptable (cap the threads, lower their priority, or say it cannot be had).

## B. Where the wide expansion spends its time

The wide expansion takes about 3.3–3.6 ms per slice where the narrow one takes 1.1 ms on the same card, and it
is **not** the prefilter (3.64 ms without it against 3.37 ms with it). Find where it goes, by measurement
(timing stops, ablation builds behind the test-only features, the generated CUDA): the divisions that extract
digits, the two-word masks, the record walk, the child-list reads, the write of the survivor list, the launch
shape. Then remove what can be removed without changing what the kernel returns. Report the time per part even
if nothing can be removed. Target: under 2 ms; anything measured is a result.

## C. The wide main kernel's shared memory on the RX 9070 XT (prepared offline)

On that card the narrow main kernel runs 12 waves per SIMD; the wide one's shared memory is about 3 KB over the
threshold for that, which is the leading explanation for base 65 being ×3.2 of base 64 there and only ×2.17 on
NVIDIA. `G2/BUILD-NOTES.md` §12 and `G2/WINDOW-PLAN-2.md` describe the model and how the kernels were compiled
for that card offline (SPIR-V dumped on a box, the driver's compiler run in a container on ivory: the container
`g2mesa` exists there, stopped; start it only to compile shaders, never to build the project). Find the 3 KB
(a smaller probe window with more instances, packing, a narrower per-digit table for 65 digit values), keep
every count identical, show the kernel under the threshold by the same offline method, and show no slowdown on
the RTX 3080 (five warm base-65 fields, alternating with the head before your change). It cannot be timed on
the RX 9070 XT today: say plainly that the gain there is a prediction and give the prediction with its range.
If the offline method cannot be reproduced within 40 minutes, stop this piece and report why.

## For every commit

`just lint`; production's suite; the ordinary tests; the device tests on lavapipe through both compilers (WGSL
and SPIR-V); on the card: slice parity at base 64 and base 65, the narrow and the wide fault tests; and at the
end one timing of base 64 (five warm fields, alternating with `c2152084`: nothing here may cost base 64 more
than 1 %) and of base 65 (same, to show what was gained). Exactness is not negotiable: a change that alters any
count is reverted.

Afterwards, on ivory: `cd ~/projects/nice/scratchpad/2026-11-midout-design && python3 tools/check_refs.py
interactive/midout-map.html`; fix each `BAD` line number in the map (its README says how) and the inline
`file:line` references in `DESIGN.md` (`tools/print_inline_refs.py`), replace the head they name by the new
head where they name the head their references were checked against, and change no other wording: list for me
what in `DESIGN.md` is now out of date.

## Machines and rules

- **ivory**: reading, git, notes and shader compilation in the existing container only; no project builds
  here (4 cores, 4.5 GB of disk free).
- **One rented box, which I rented and logged in to for you:** the ssh line is at the end of this brief.
  Install the toolchain (the repository pins it), `just`, lavapipe (`mesa-vulkan-drivers`, `vulkan-tools`),
  `spirv-tools`; **map the production hosts to 127.0.0.1 and ::1 with the proof saved before any client binary
  runs** (`G2/build6c/box/hosts_block.sh`); nothing ever claims from or submits to the production API. Never
  create or destroy instances; never use another machine, in particular never the maintainer's machines.
  Leave the box running and idle.
- Branch `dev/mo-clean`, worktree `~/projects/nice/.worktrees/midout-clean`: ordinary commits only (never amend,
  rebase or force; no merge commits with a default message); every commit message has a body saying what and
  why in plain words; subject and body carry no reference to notes, steps, reviews, agents or models; trailer
  exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Bundle to ivory after every piece;
  `git push -u fork dev/mo-clean` from ivory. **No pull request, nothing to upstream.** One target directory
  per clone on the box; verify a binary by its build string or checksum before timing.
- Another engineer is working today on a scratch branch `exp/mo-ceiling` (a counting study, another box): do
  not touch it; nobody else commits to `dev/mo-clean` today.

## Deliverables (by 11:35 UTC)

1. `dev/mo-clean` on ivory and the fork, every tier passing at its head.
2. `G2/WIDE2-NOTES.md`: per piece what was done and the proof; the thread-count table; the expansion's time by
   part before and after; the shared-memory accounting and the offline compile result; tier results; both
   timings; what in `DESIGN.md` is out of date; what is left.
3. Raw logs under `G2/build9w/`.
4. A final report to me of at most 25 lines.

## The box

    ssh -p 36712 root@ssh4.vast.ai

Vast instance 61587396: RTX 3080 (10 GB) capped at 240 W by its host, 16 threads visible with a CPU quota of
about 5, 31 GB of memory, 40 GB of disk, a fresh Ubuntu 24.04 image with CUDA 12.8 devel (nothing of ours is on
it: allow 20–25 minutes for the toolchain, `just`, lavapipe and the clones). ivory's ssh key is accepted; I
logged in at 06:02 UTC. It destroys itself at about 12:00 UTC.
