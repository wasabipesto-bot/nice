# Scheduled task

- Name: nice research daily cycle (director v2)
- Schedule: `CRON_TZ=America/Indiana/Indianapolis 41 0 * * *`
- Fires into: session_014g2dyZ4dAhZFch4nmKWPyZ ("Daily autonomous nice research migration"; the director since 2026-11-09)
- Trigger id: trig_011koSFKmVf7EAYuAGy2h4mU (created 2026-11-09T21:03Z; first run 2026-11-10T05:41Z)
- Inspect: `list_triggers` / `get_trigger`. `update_trigger` cannot repoint a task at another
  session: after a rotation, create a new task from the new session and disable the old one.

## Previous task

- trig_012YG24kD3dwPtQAheLqir5F ("nice research daily cycle", into session_014g2dyXVFTNJDzdmrqg4TdX),
  2026-10-28 → 2026-11-09, **disabled** 2026-11-09T21:03Z at the director change (not deleted).

## Prompt

Rewritten 2026-11-10T15:13Z (the user's PR bar, autonomy guidance, base 64 as the cost driver). The
current text is what `get_trigger trig_011koSFKmVf7EAYuAGy2h4mU` returns; in short: reconcile
(Vast, PRs and their CI and comments, the user's messages); work the tracks of the journal head;
rails as in README; PRs one discrete change each at ≥ ×1.05 (simple) to ≥ ×1.10 (very large) or a
defect fix, reviewed first, at most 5 open; record and sync; a ~300-word report.
