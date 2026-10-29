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
2. Read the last two journal entries and the ledger; pick at most two active leads.
3. Execute under the posture (heavy: ~5 h director time, ≤12 subagents on Opus/Sonnet,
   no nested agents). Vast only via `vast.py create`. CPU work on ivory under
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

## Channels

- Daily report: this session's reply.
- Urgent / blocking only: `curl -s -H "Title: nice research" -d "<what and what is needed>" https://ntfy.sh/wasabipesto-claude`
  (public topic, no secrets). Never routine progress.
- Questions: numbered in the report; the user answers in the session.

## Rotation

When context passes ~60 % or after 4 weeks: write a handover entry in the journal,
create a new session, and point the routine's `persistent_session_id` at it
(`update_trigger`). Record the new id in `ROUTINE.md`.
