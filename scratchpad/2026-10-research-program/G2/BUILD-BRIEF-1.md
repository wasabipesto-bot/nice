# The middle-out join, day one: a basic, exact, end-to-end implementation (brief, 2026-11-18 16:45 UTC)

You are the lead engineer for the first day of a build. Work alone (do not start subagents). **Hard stop
22:30 UTC**: by then the notes are written and your commits are on ivory, whatever state the work is in.

## What was decided, and by whom

The project's owner wrote today: *"I'm in favor of building this redesigned join."* Their conditions, which
shape everything below:

- *"I appreciate the simplicity of the current field structure and that we aren't pigeonholed into a specific
  search implementation. I want to ensure that this new field structure won't prevent us from being able to
  incorporate a significant amount of optimizations."*
- *"My expectation is that you would spend a day on the basic implementations then a few more days optimizing
  it before review and merge. This would allow you to re-architecture the join or field structures before
  locking in schema changes."*

So: **no server code, no schema, no API change, no pull request now.** The join is built in the client's
library on a development branch and runs against a local work list. The field structure stays soft until the
join has been optimised. Working name: **the middle-out join** (the owner may rename it; keep the name in few
places). A unit of its work, all n sharing digits 4–8, is a **slice** (the documents call it a "super-unit").

## What exists

"nice" searches for n whose square and cube together use every digit of base b once. Production's GPU search
is the "overlap join" (`common/src/cubecl_join.rs`, CPU form `overlap_join.rs`). The redesign ("G2" in the
documents) pairs certified top prefixes with certified bottoms inside slices keyed by the middle digits they
share. It exists as one CubeCL example file, proven exact and measured today:

- RX 9070 XT (the card that does 86 % of the search): ×4.73 against main by a synchronised protocol, ×5.14–5.48
  pipelined; RTX 3080: ×4.61 against main; exact at 8, 16, 32 and 64 lanes.
- Exact counts say the design carries to bases 65–70 (masks wider than 64 bits; nothing there has run on a GPU).

Read, in this order, under `~/projects/nice/scratchpad/2026-10-research-program/G2/` on ivory:
`RESULTS.md` (the design and why), `PROPOSAL.md` §1–2 and §5–6 (work unit, coordinate, client work,
verification), `PORT-NOTES.md` (the port: structure, options, CubeCL 0.10 pitfalls: read the pitfalls twice),
`WINDOW-RESULTS.md` (what the card showed today: preparation, pipelining, uploads), `bases/RESULTS.md` (above
64, the padded coordinate, shapes per base). Code: `~/projects/nice/.worktrees/g2-cubecl`
(`common/examples/g2_cubecl.rs`, head `1313018a`), the CPU prototypes `proto/` and `bases/proto/` (u128 masks,
exact above 64), production's `common/src/overlap_join.rs`, `cubecl_join.rs`, `cubecl_backend.rs`.

## Your machines

- **ivory** (this machine): for reading, git and notes only. Its disk is nearly full (under 5 GB): **do not
  build on ivory.**
- **One rented box, which I rented and logged in to for you:** see the ssh line at the end of this brief
  (RTX 3080, Ubuntu 24.04, CUDA 12.8 devel image). It destroys itself about 06:30 UTC tomorrow. Build and test
  there. Install what you need (rustup with the repo's pinned toolchain, `mesa-vulkan-drivers` and
  `vulkan-tools` for lavapipe). Before any client binary runs there, map the production hosts to 127.0.0.1
  and ::1 and save the proof (`G2/bench/box/` and `../T28/raw/hosts_block.sh` show how). Nothing ever claims
  from or submits to the production API, from anywhere.
- Code moves between the box and ivory by `git bundle` (the box has no GitHub credentials and gets none). On
  ivory: a worktree `~/projects/nice/.worktrees/midout` on a new branch **`dev/middle-out-join`** from upstream
  main (`origin/main`). Ordinary commits only; never amend, rebase or force. Commit trailer exactly:
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. At the end, from ivory, `git push -u fork
  dev/middle-out-join` (the fork `wasabipesto-bot/nice` only; never upstream; **no pull request**).

## Day-one target

A library-level implementation that searches a field of the new kind end to end and exactly, with tests, at
base 64. In order of priority:

1. **A work-unit interface that does not leak the join.** A field is `(base, v_start, v_size)` in a per-base
   coordinate v; the map n ↔ v is a small, documented, tested piece of code (base 64's bit renumbering from
   `PROPOSAL.md` §2; write it so the padded coordinate of other bases from `bases/RESULTS.md` §5 fits the same
   interface, and include base 65's if time allows). **Nothing outside the join may know its shape (f0, k),
   its slice key, its chunking or its kernels.** A field fixes only the few most central digits (6–8 at base
   64) and is much coarser than a slice, so that the join may later change shape without changing fields.
   Write down, in the notes, exactly which future changes of the join a field of this kind permits and which
   it would forbid: the owner asked.
2. **A CPU reference of the middle-out join for a field**, from the prototypes: returns the nice numbers found
   and two exact, device-independent counters (define them; say how they relate to production's `survivors`
   and `checked`). Tests: whole small bases against brute force (every b mod 5 class, odd bases, the known
   nice number 69 in base 10), and real base-64 slices against the staged references.
3. **The GPU path** (CubeCL, one source for CUDA and for Vulkan/SPIR-V): the example's preparation and main
   kernel moved into the library; the tops of a slice and the full check of its survivor records produced by
   production's existing machinery where it can be reused (say plainly what day one does on the CPU instead);
   a field driver that queues slices without synchronising per slice, reuses buffers and keeps per-slice input
   on the card where it can. Parity tests: GPU field results equal the CPU reference, on the box's card
   (CUDA) and on lavapipe with the SPIR-V compiler at small sizes.
4. **One honest number**: whole base-64 fields end to end through the library path on the box (tops and
   survivor checks included: the measurements so far only assumed them at 0.085–0.115 fs), against
   production's client on same-session base-64 fields. Label it with the box and its power cap.
5. Masks: structure the code so widths above 64 bits are a type parameter or a second path, but do not build
   the wide path today.

If the whole target does not fit in the day, the order above is the order of sacrifice from the bottom:
exactness and the interface before speed. A partial GPU path that is exact beats a fast one that is not.

## Rules

- One discrete concern per commit; tests with the code. Run `cargo fmt` and clippy under the repo's pinned
  toolchain on what you touch before the last commit (the repo's `just lint` is the standard at review).
- Do not change production code paths' behaviour: the new join is additive and unreachable from the default
  client today.
- No new dependency without saying why in the notes.
- Every number you report is labelled measured (where, power cap, session) or estimated.
- If the box misbehaves (ssh down for 10 minutes, card throttled or shared), stop and report; never create or
  destroy instances and never use another machine.
- Leave the box running at the end, idle, with nothing of yours executing; I decide what happens to it.

## Deliverables (by 22:30 UTC)

1. Branch `dev/middle-out-join` on ivory and on the fork, with the day's commits.
2. `G2/BUILD-NOTES.md` on ivory: where it stands (first section, kept current), the interface and what it
   permits and forbids, design decisions and their reasons, what was reused from production and what was
   written new, test inventory with results, the number from item 4, and **a work breakdown for the next
   days as independent pieces** (each with its files, its interface to the others, its test, and whether it
   needs a GPU), so that several engineers can work in parallel tomorrow.
3. A final report to me of at most 40 lines: what runs end to end and exactly; what does not yet; the number;
   the three biggest risks you now see; anything in the design documents that turned out wrong.

## The box

    ssh -p 14628 root@ssh3.vast.ai

Vast instance 61286074: RTX 3080 capped at 240 W by its host (it cannot be raised), 16 threads, 31 GB of memory,
48 GB of disk, Ubuntu 24.04, image nvidia/cuda:12.8.1-devel-ubuntu24.04 (nvcc present). ivory's ssh key is
accepted; I logged in at 16:42 UTC. This host ran the same kind of work this morning without trouble. It
destroys itself at about 06:40 UTC tomorrow.

A build trap seen on this very host this morning: two worktrees building into one cargo target directory can
hand you the other worktree's binary (cargo "finished" in a fraction of a second). Give each worktree or commit
you compare its own target directory, and check a binary by a string only it contains.
