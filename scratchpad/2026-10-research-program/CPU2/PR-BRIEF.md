# CPU2 PR brief: make the CPU skip walk ready to open, and measure it as clients run it (2026-11-14)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
The maintainer has asked for this branch to be opened as a PR. An earlier engineer wrote it this
morning and an independent reviewer found it sound; you finish it. Read first, in this order:
`../README.md` (rails, PR rules); `RESULTS.md` (all of it: the rule, its proof, the measurements,
and §0's and §6's two caveats); `REVIEW.md` (findings M1, L1, L2, L3 and "What I could not
verify") and the reviewer's harness under `review/`; the branch itself,
`git diff origin/main fork/exp/cpu-top-skip-squashed` (one commit `e0bf513e` on main `41b4b405`,
600 lines in `common/src/cpu_join.rs`, `common/src/cpu_top_fd.rs`, `client/src/main.rs`); and
two merged CPU PRs for the expected form of a body: `../L52/PR-RESULTS.md`, `../L56/PR-RESULTS.md`
and their bodies (`gh pr view 248 --repo wasabipesto/nice`, `gh pr view 253 --repo wasabipesto/nice`).

## What is missing

1. **M1: free the per-thread join state when a field ends.** The branch moved the join's
   `Scratch` into a `thread_local!` so a worker's runs survive between partitions; it is never
   freed (about 10 MB a thread for the `next` array at production shapes, plus the other
   buffers, for the life of the process, through later stride-walk fields too). Free it when the
   field's join ends (the reviewer suggests `rayon::broadcast(|_| JOIN_SCRATCH.take())` after
   the slice loop: check which pool the join's workers actually belong to and that the
   broadcast reaches exactly those threads; make sure an early return or an error path frees
   too). State the per-thread cost in the module docs.
2. **L1: one helper for the first certified position**, used by both `cert` and `run`, so the
   skip rule cannot drift from the certificate it relies on. This touches the hot path: it must
   not cost speed (see the measurements) and the proofs in the docs must still read correctly.
3. **L2: tests of the carried state** across joins, out of order, on retries and at the
   `RUN_GAP` edge, in the branch (port the idea of `review/cmp_*.rs`; they must fail on a mutant
   that forgets to reset the state: show that they do).
4. **The measurement this morning's work says is missing: the real client at production thread
   counts.** The gain was measured with a harness on one thread (×1.140 at b62 1e17, ×1.132 at
   b60 1e16, ×1.009 at b64 1e17) and the client path (one scratch per worker thread instead of
   rayon's `map_init`) was only probed, never timed. On the rented box (44 hardware threads,
   below): main against the branch, the real `nice_client` binary in the CPU configuration a
   CPU-only client runs (find from `client/src/main.rs` and the benchmark code how to run a
   given field offline, without the server: the benchmark's field option or the test hooks the
   earlier CPU PRs used; never claim from or submit to the production API), all threads and
   also 8 threads, interleaved, at least three rounds each, at b62 1e17 and b60 1e16 (whole
   fields if a field fits in about ten minutes, otherwise the same fixed sample of slices in
   both binaries: say exactly what was run), and one round at b64 1e17. Counts and hits
   identical. Peak resident memory of both binaries at each thread count (`/usr/bin/time -v`),
   and resident memory after the join ends (to show M1 frees it). Then **NiceMark's CPU
   scenarios, four rounds**, main against the branch: the maintainer's bar is no scenario below
   ×0.98.
5. **The verdict against the bar:** a measured ≥ ×1.10 for a change of this size at production
   shapes (b62 is where the search goes next; b64 gains nothing and the body must say so). If
   the real client at 44 threads gains less than ×1.05 at b62, **stop, do not prepare a PR, and
   write up why** (how often a worker's next partition follows its previous one, and what would
   fix it).

## Deliver

- Branch **`pr/cpu-join-top-skip`** on the fork: **one commit on `origin/main`** (`41b4b405`;
  re-check that main has not moved) containing the reviewed change plus 1–3, with a one-line
  CHANGELOG entry in the file's style under the unreleased section, ending in the placeholder
  `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))` (the maintainer wants changelog lines
  short and user-facing: one sentence, the numbers belong in the PR body). `cargo fmt --all --check`,
  `cargo clippy --workspace --all-targets -- -D warnings` and `cargo test -p nice_common` clean
  under the pinned toolchain (Rust 1.100.0).
- Also push the same work as separate commits on top of `e0bf513e` to a branch
  `exp/cpu-top-skip-fixes` so the reviewer can read the delta from the reviewed commit; the two
  branches must have the same tree (say so, with the tree ids).
- `CPU2/PR-BODY.md`, at most 700 words plus tables: what, why, how the rule is sound (short;
  the code's docs carry the proof), exactness evidence, measurements (state the machine, the
  thread counts, rounds and spreads; what was measured with the harness and what with the
  client), memory, what NiceMark shows and why it cannot show the gain, "Not in this PR". It
  must say that no GPU code path changes. No mention of the research program, this directory,
  agents, reviewers' files or model names; last line
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- `CPU2/PR-RESULTS.md`: every table with every round, the commands, tree ids, what you changed
  for M1/L1/L2 and how you tested each, mutant runs; raw logs and scripts under `CPU2/raw-pr/`.
  Mark every number measured, derived or assumed. Relabel `RESULTS.md` §5's table (L3).

## The box and the rules

The instance id comes in the message that carries this brief; `python3 vast.py ssh <id>` (run
from the program directory) prints the ssh command; wait for `/root/READY` (`/root/FAILED`:
clone the fork yourself). It has 44 hardware threads and a GPU you do not need. Build there in
release mode, one `CARGO_TARGET_DIR` per tree; copy results to ivory early and often and commit
locally often (an outage yesterday cut agents off mid-run). Never `vast.py create` or `destroy`.
On ivory: writes only under `CPU2/` and a worktree `~/projects/nice/.worktrees/cpu-join-top-skip-pr`;
`nice -n 19`; check `df -h /` first and keep 3 GB free (use
`CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` for clippy and tests: it is
warm for 1.100.0; no release builds on ivory); `/tmp` is a small tmpfs. Push only to the fork,
only the two new branch names; **never force-push, never delete a branch; if a push is refused,
report it and do not ask anyone to do it for you**. Never push to `wasabipesto/nice`; do not
open, comment on or edit any pull request; no subagents. Never touch the fleet, the server,
`~/fleet-run`, demoux or mayalaran; the production API is not to be contacted from the box at
all. Hard stop **19:40 UTC** (the box destroys itself at about 20:10 UTC): write up what you have; an unfinished NiceMark round is fine if you
say so, an unverified exactness claim is not. Your final message is a short report for the
program's director: the verdict against the bar first.
