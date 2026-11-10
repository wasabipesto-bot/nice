# nice research program: operating notes

Design: `PROPOSAL.md` (approved 2026-10-28). State of record is this directory; the
director session can be replaced from it at any time.

## Files

- `LEDGER.md` leads, status, kill criteria, closed list
- `JOURNAL.md` dated entries, newest first
- `EXPERIMENTS.md` numbers, commands, data paths
- `REPORTS/YYYY-MM-DD.md` the daily report, also sent as the session reply
- `vast.py` budget-guarded Vast rentals; `vast-ledger.csv` its ledger
- `sync.sh` snapshot this directory into the `research-program` branch on the fork
- `ROUTINE.md` the scheduled task's prompt and id

## Daily cycle (the routine fires 00:41 America/Indiana/Indianapolis)

1. `python3 vast.py reconcile`; `gh pr list --repo wasabipesto/nice`; read the user's
   replies since the last report.
2. Read the journal head (the current plan) and the Tracks table at the top of the ledger.
   Since the director change on 2026-11-09 the day is organised by tracks (T1 the join's
   macro shape, T2 integrity, T3 theory, T4 delivery), not by three kernel leads; every lead is
   priced as $/base at the frontier, and kernel trims under ×1.10 are parked, not PR'd. The
   operation model is `../2026-11-fresh-eyes/NOTES.md`.
3. Execute: few, fully briefed subagents on Opus (implementation, review) or Sonnet (surveys),
   a reviewer agent on every PR branch, no nested agents. Vast only via `vast.py create`. CPU work on ivory under
   `nice -n 19`; `df -h /` first (ivory has filled before; `/tmp` is a 3.8 GB tmpfs).
   Code in worktrees under `.worktrees/`; beware shared target-dir collisions between
   same-version worktrees (`cargo clean -p nice_common -p nice_client` before compared
   builds).
4. Record: journal, ledger, experiments; `./sync.sh "<summary>"`.
5. Report, then end the turn. Long waits: a one-shot reminder into this session.

## PRs

Open immediately once the 5 % protocol and exactness pass; the report lists them. Bodies:
what, why, soundness, measurements, exactness, short "Not in this PR"; no mention of the
program, the scratchpad or fork-only write-ups; no reference re-pinning (ops does it).

## Rails (PROPOSAL §6)

Never without asking: live fleet (config, crontab, `~/fleet-run`), server, schema,
data corrections, deploys, merges, upstream `main`, destructive git, spend above the
cap, rentals below the credit floor, the user's machines.

## Working without the user (2026-11-10)

The user checks in when they can and may miss several days. Decide inside the rails without
asking; keep questions rare and never blocking; reports short enough to skim after a gap.
Standing order: keep looking at high-level strategies; if none pan out, continue with
optimisations. Kernel work is opened as a PR chain only when its combined measured gain is
≥ ×1.5 (or it fixes a defect). A server rearchitecture is not wanted (N1 parked). Write-ups and
outreach belong to other agents: note such items in the report only.

## Channels

- Daily report: this session's reply.
- Urgent / blocking only: `curl -s -H "Title: nice research" -d "<what and what is needed>" https://ntfy.sh/wasabipesto-claude`
  (public topic, no secrets). Never routine progress.
- Questions: numbered in the report; the user answers in the session.

## Rotation

When context passes ~60 % or after 4 weeks: write a handover entry in the journal, start a
new session, create a new scheduled task from it (`update_trigger` cannot repoint a task at
another session) and disable the old one. Record both ids in `ROUTINE.md`. Done once, on
2026-11-09, at the user's request.
