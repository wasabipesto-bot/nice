# Scheduled task

- Name: nice research daily cycle
- Schedule: `CRON_TZ=America/Indiana/Indianapolis 41 0 * * *`
- Fires into: session_014g2dyXVFTNJDzdmrqg4TdX (nice research director)
- Trigger id: trig_012YG24kD3dwPtQAheLqir5F (created 2026-10-28T03:50Z; first run 2026-10-28T04:41Z)
- Inspect: `list_triggers` / `get_trigger`; repoint after rotation with `update_trigger` (persistent_session_id).

## Prompt

See the text recorded below; it is what the routine sends each day.

```
Daily cycle of the nice research program. You are the director. Design: ~/projects/nice/scratchpad/2026-10-research-program/PROPOSAL.md; operating notes: README.md in that directory. Posture today: heavy (up to ~5 h of director time, at most 12 subagents, Opus or Sonnet only, no subagent may spawn subagents).

1. Reconcile: `python3 vast.py reconcile` (TTL and orphan sweep, invoices, credit); `gh pr list --repo wasabipesto/nice` for program PRs and their CI; read anything the user wrote in this session since the last report; if a day was missed, say so in the report.
2. Read the last two JOURNAL.md entries and LEDGER.md. Choose at most two active leads by expected gain ÷ cost. Write the kill criterion before starting anything new. A closed lead may be reopened only with a written reason for what the earlier verdict missed.
3. Execute. Vast only through `vast.py create` (label prefix, TTL, $30/month cap, $10 credit floor). CPU work on ivory under `nice -n 19`; check `df -h /` first; /tmp is a 3.8 GB tmpfs. Code in worktrees under .worktrees/. demoux or mayalaran only after asking the user, and only when genuinely helpful. Never touch the live fleet, the server, its data, deploys, merges, or upstream main (PROPOSAL §6).
4. Record: a dated JOURNAL.md entry, LEDGER.md status and verdicts, EXPERIMENTS.md numbers with commands and data paths; then `./sync.sh "<summary>"`.
5. Report: write REPORTS/YYYY-MM-DD.md with the sections: What moved; Numbers; Verdicts; PRs (opened, ready for review; cap 5 open, 2–3 if large; merge bar PROPOSAL §5); Spend (Vast month-to-date and today; subagents used today); Questions for you (numbered, non-blocking); Tomorrow. Send the report as your reply, about 400 words plus tables. Only a blocking problem goes to ntfy (topic in README.md once the user gives it); otherwise pick another lead and continue.

If an experiment needs hours, create a one-shot reminder into this session (send_later) saying what to collect, and end the turn; the reminder continues the same day and still ends with the report. End the turn once the report is sent; do not run past about 5 h of director time.
```
