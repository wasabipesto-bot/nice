# The local coordinator of the middle-out route under failure: a chaos harness, invariants, fixes (brief, 2026-11-24 05:55 UTC)

You are an engineer who breaks distributed bookkeeping for a living. Work alone (do not start subagents), on
this machine only (ivory), **Python and reading only: no Rust builds, no rented machines.** **Hard stop
10:30 UTC.**

## Why

The "nice" project searches exhaustively for numbers with a rare digit property; a result is "this base holds
none", so a field that is recorded as searched but was not, or lost, silently voids a base. A redesigned GPU
search join (the "middle-out join", fork branch `dev/mo-clean`, head `eb9ef776`, worktree
`~/projects/nice/.worktrees/midout-clean`) cannot use the project's server yet (no server change is approved).
The one way to run it for real is a **local coordinator**: `scripts/midout_coordinator.py` (164 lines, standard
library, HTTP on 127.0.0.1, state in two append-only files) and a client route
(`client/src/midout_route.rs`, behind a hidden flag `--midout-coordinator URL`). If the maintainer says yes,
that coordinator would hand out and record the 262,144 fields of base 64 over about two months on one machine.
It has been run for a dozen fields with one client. **Nobody has tried to break it.** Read first:
`~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §6.11 and §9, then
`~/projects/nice/scratchpad/2026-10-research-program/G2/BUILD-NOTES-CLIENT.md`, then both files above and
`common/src/midout/wire.rs` (the claim and submit shapes).

## Your job

1. **Write the invariants down first** (in your notes, before any test): what must hold of the state files and
   of the HTTP behaviour at every moment and after any crash. At least: every field of the work list is, at
   the end, accepted exactly once or still open, never lost; a field is not handed out while a live claim on
   it exists (except by the documented `--reissue-after`); a submission is accepted only for a claim this
   coordinator issued, once per field, with the route marker; an accepted submission is on disk before the
   client is told "accepted" (what does the script do: flush? fsync?); after a kill at any point the files are
   readable and the restart reconstructs exactly the state that was acknowledged; a submission whose body
   disagrees with its claim (other base, other range) is refused; nothing an ordinary client can send makes a
   field look searched. Add what you find missing.
2. **A chaos harness** (`scripts/` is not the place: put it under your notes directory, it is a test tool):
   fake clients in Python speaking the real wire format (take the body of a real submission from
   `G2/build4f/` or the client code), run against the real coordinator script as a subprocess: many clients at
   once; random think times; clients that die between claim and submit; duplicate, late, reordered and
   cross-claim submissions; malformed and oversized bodies; `SIGKILL` of the coordinator at random moments,
   including mid-write (also simulate a torn last line and a full disk by truncating the state files at every
   byte offset of their last record), then restart; restarts with a changed work list; two coordinators
   pointed at one state directory by mistake; `--reissue-after` races (the first client submits after the
   field was reissued). Thousands of randomized runs with seeds, each checked against the invariants from the
   state files and from what clients were told. Every failure reduced to a smallest reproducing script.
3. **Fix what breaks**, in `scripts/midout_coordinator.py` on `dev/mo-clean` (ordinary commits, one per
   defect, each with the reproducing test's description in the message body; the harness itself stays in the
   notes directory): keep it standard-library and short; durability by `flush` + `os.fsync` where an
   acknowledgement depends on it; a lock file against two instances; refusal with a clear message over
   silent repair, except for a torn last line, which must be handled as "not acknowledged". Do not redesign.
4. **What the client does on its side** (by reading `client/src/midout_route.rs`, since nothing may be built
   here): on a refused submission, a lost reply, a coordinator that is down or restarts mid-field, a claim that
   was reissued under it: say for each what happens and whether a searched field can end up unrecorded or an
   unsearched one recorded. List code changes you would make there, with file and line; do not make them.
5. **An audit tool** (`scripts/midout_audit.py`, standard library, on the branch): reads a work list and a
   state directory and prints: fields accepted, open, claimed-and-stale; any field accepted more than once or
   with a submission that does not match its claim; whether the accepted fields cover the work list; the
   list of nice numbers reported; exit status non-zero unless everything is accepted exactly once. It must
   agree with the harness's own checker on every randomized run.

## Rules

- ivory only; `nice -n 19` for the harness; `df -h /` first (4.4 GB free: keep state directories small and
  under the session scratch directory you are given or `/tmp` sparingly: it is a 3.8 GB tmpfs); ports on
  127.0.0.1 only, chosen free; kill every process you start (find them by PID you recorded, never by
  `pkill -f` with a pattern in the same command line).
- Branch `dev/mo-clean`, worktree `~/projects/nice/.worktrees/midout-clean` (nobody else commits there today):
  ordinary commits only (never amend, rebase or force); plain messages with no reference to notes, agents or
  models; trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`;
  `git push -u fork dev/mo-clean`. **No pull request; nothing to the upstream remote `origin`.** Python only:
  `python3 -m py_compile` and the repository's lint for scripts if it has one (check the justfile); you cannot
  run `just lint` here (it builds Rust): say so.
- Never contact the production API; the coordinator and the fake clients speak to 127.0.0.1 only.
- If the tooling denies something, do not work around it: note it and report it.

## Deliverables (by 10:30 UTC)

1. `~/projects/nice/scratchpad/2026-10-research-program/COORD/RESULTS.md`: the invariants; the harness (what it
   does, how many runs, seeds); every defect found with its smallest reproduction, severity (could a field be
   lost or falsely recorded?) and fix commit; what still fails or was not tested (real power loss, a remote
   coordinator, the real client); the client-side reading; how to run the audit tool.
2. The harness under `COORD/harness/`, the commits on `dev/mo-clean` (coordinator fixes, the audit tool).
3. A final report to me of at most 20 lines.
