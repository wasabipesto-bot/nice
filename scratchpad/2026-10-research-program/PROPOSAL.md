# Autonomous research program for nice: proposal (2026-10-28)

Goal: keep nice moving on throughput and theory with little input from you. You review
PRs; I run the research, the experiments and a small Vast budget. This document is the
design. Nothing is set up yet.

## 1. Mechanism: a scheduled task that wakes a standing "director" session

**Recommendation: a recurring scheduled task (routine) that fires once a day into one
standing session, which self-schedules one-shot follow-ups while an experiment is
running.** The session is the director. It plans, delegates to subagents, rents Vast
boxes, records results and writes the daily report. Between wakes nothing runs and
nothing is billed.

Why not the alternatives you named:

- `/loop` (self-paced wakeups) is in-session only. The longest wakeup it allows is one
  hour, so the session never idles, and the loop ends with the session. The in-session
  cron (`CronCreate`) is also session-only and expires after 7 days. Both suit a working
  day, not weeks. I would use `/loop`-style pacing *inside* a day to wait on a Vast run,
  nothing more.
- A fresh session per firing (the other routine mode) is the most robust shape, and it
  is the fallback if the standing session drifts. Its cost is that every day starts
  from zero and rebuilds context from disk. It also cannot answer a question you typed
  into yesterday's session. I prefer the standing session, with the discipline that
  **everything that matters lives on disk**, so the session can be replaced at any time.

Facts that make this work here:

- This session runs on ivory (bridge environment). A routine created from it inherits
  that environment, so disk state under `~/projects/nice/scratchpad` and the memory
  directory persist across sessions and container restarts.
- Scheduled tasks are server-side and survive restarts. One-shot reminders into a
  session already work (the Trope Log overnight checks used them).
- This session has a 1M-token context. Compaction over weeks is the known risk, handled
  by re-reading the journal head at every wake and by rotation (section 7).

## 2. The daily cycle

One firing per day, at a quiet hour so the report is ready for your morning.
Proposed: **00:41 America/Indiana/Indianapolis** (05:41 UTC), report by about 06:00.

1. **Reconcile.** Research-labelled Vast instances (destroy anything past its TTL),
   the Vast ledger against `vastai show invoices-v1`, account credit, CI state of my
   open PRs, and any replies from you (in the session, or on the report thread).
2. **Choose.** From `LEDGER.md`, by expected gain ÷ cost, at most two leads active at
   once. Every lead has a kill criterion written down before work starts.
3. **Execute.** Subagents on Opus or Sonnet only, never nested, at most N per day
   (section 4). Experiments on Vast or on ivory (CPU work under `nice -n 19`; ivory is
   shared and its disk fills). Your machines (demoux, mayalaran) only with a per-task
   yes, as today.
4. **Record.** `JOURNAL.md` (what happened, dated), `LEDGER.md` (lead status and
   verdicts), `EXPERIMENTS.md` (numbers, commands, raw data paths), `vast-ledger.csv`.
   Committed to a `research-program` branch on the fork so it survives ivory.
5. **Report.** `REPORTS/YYYY-MM-DD.md`, also sent as the session's reply. Questions
   for you are collected in one section and marked; a blocking question also goes out
   as a push notification. Non-blocking questions never stop the work; I pick another
   lead.

If a Vast run needs hours, the director sets a one-shot reminder into itself and ends
the turn. Nothing polls.

## 3. Vast budget: $30/month, separate from the fleet

The fleet spends $50/month ($40 nice-only, $10 detailed) from the same account credit.
Credit today is $23.42. Rules:

- Research instances carry the label prefix `nice-research-`. The fleet controller
  leaves foreign labels alone (verified in its failure drills), and the fleet's
  `nice-fleet` prefix is never used.
- Hard cap $30 per calendar month on invoiced charges, measured from
  `vastai show invoices-v1` (dated, per instance, includes disk storage, which the
  fleet ledger misses). A $5 reserve is held for the last week of the month.
- **Credit floor:** no rental if account credit is below $10, and the report says so.
  The account ran dry on 10-15 and stopped the fleet. Research must not do that.
- Every instance is created with a self-destroy TTL in its onstart (the explore
  self-retirement call) plus the reconcile at every wake. Worst case for a lost
  instance is one TTL, which I will set at 2 h by default.
- Typical unit costs: a GPU A/B round on an RTX 3080 or 3060 is about $0.30; an H100
  check about $1. The budget covers roughly 100 rounds a month, so most of it will go
  unspent most months. Unspent money does not roll over.

## 4. Token posture

Tokens are the bigger risk than dollars: on 2026-09-09 two default-model research agents
fanned out and blew the monthly limit in one session. Standing rules I will keep:
director plans, subagents execute; subagents on Opus (hard reasoning, code) or Sonnet
(surveys, reductions); no subagent may spawn subagents; the day ends with the report,
never open-ended. You choose the size:

| posture | director time/day | subagents/day | fits |
|---|---|---|---|
| light | ~1 h | ≤3 | monitoring + one small experiment |
| medium (recommended) | ~2–3 h | ≤6 | one lead advanced per day, one in the background |
| heavy | ~5 h | ≤12 | two leads a day, literature sweeps weekly |

I cannot see your plan's limits, so I propose medium and will report the day's agent
count each day so you can resize.

## 5. The merge bar and how it is measured

A PR from this program needs one of: **5 % or more on NiceMark**, a correctness or
integrity fix, or a cost reason you have already agreed to. Measurement protocol, the
same for every claim:

- The scenarios in `common/src/bench_defs.rs` (b58_msd_weak/strong, b60_msd_weak,
  b62_msd_weak, b40_detailed, b50_detailed) at their pinned floors; score = the
  client's geometric mean for the mode.
- A/B on the **same box in the same session**, interleaved, at least 3 rounds, median
  and spread reported per scenario. Same-config benchmarks repeat to about 1 %, so 5 %
  is resolvable this way; across boxes it is not.
- No scenario regresses more than 2 %. CPU and GPU both measured where the change
  touches both.
- Filter and search-order changes also get a **production-weighted whole-field** check
  (the Hall-subdivision lesson: a 2-slice smoke run showed +6 %, the whole field was
  negative) and parity (survivor counts or witness tests) before any speed number.
- Where it matters, a production cross-check against `/submissions` telemetry after
  release, as done for the join.

PR hygiene: numbers in the PR body, CHANGELOG one to three sentences, every PR named
in the daily report before it is opened. **Cap: 3 program PRs open at a time.** You
already have 19 open PRs (8 from 10-15, 7 from 10-10, Lean, dependabot); I will not add
to that queue faster than you clear it. I can keep those rebased and green and tell
you which are ready, if you want that.

Changes on the scale of the bidirectional tree search get a proposal document and your
explicit yes before any implementation beyond a throwaway prototype.

## 6. Rails (things the program never does without asking)

- Touch the live fleet (config, crontab, `~/fleet-run`), the server, its schema or
  data (including the range_end and base-insert corrections, items 24 and 60).
- Deploy anything. Merge anything. Push to upstream `main`.
- Destructive git operations (worktree removal, branch deletion, force pushes outside
  its own branches).
- Spend above the cap, rent below the credit floor, or use your machines.
- Re-open a closed lead without new evidence (the closed list is seeded from the
  BACKLOG "Not re-proposed" section and the 2026-08 theory-review verdicts).

Everything else inside a worktree under `.worktrees/` and the scratchpad is fair game.

## 7. Resilience and rotation

- State of record is the scratchpad directory, not the session. A new director can be
  started from `JOURNAL.md` + `LEDGER.md` + the memory directory in one read.
- When the session's context passes about 60 %, or every 4 weeks, the director writes a
  handover entry and the scheduled task is pointed at a fresh session.
- If a firing fails (session dead, container down), the task's run history shows it;
  the next report says what was missed. I will check the task's last-run status in
  each reconcile.

## 8. Initial research portfolio

Ranked by expected gain ÷ cost, with the bases that matter: b60 (about $206 of search
left, months), then b62 ($983, roughly two years at the fleet's spend). b64 and beyond
are not where throughput matters yet.

| # | lead | path | expected | cost | kill criterion |
|---|---|---|---|---|---|
| 1 | Join per-prefix cost at b62–b64 (BACKLOG 68): profile the join phases per base, find why cost per prefix climbs ~2.5× at b64 and whether b62 pays part of it | compute | 5–20 % on b62_msd_weak | 2 days, ~$1 | profile shows the climb is irreducible bottom-layer work |
| 2 | Detailed mode: SIMD batch digit extraction (BACKLOG 55) | compute | 2–4× on b40/b50_detailed (CPU) | 2–4 weeks | prototype under 1.3× on one core |
| 3 | Detailed mode on GPU: profile the kernel; it has had none of the join's attention | compute | unknown, possibly large | 3 days, ~$1 | occupancy and memory profile show it already bound by the final check |
| 4 | Post-join filters bundle (BACKLOG 56): central-digit check, exact-high seeding, slack-1 Hall; measure the final check's share of join time first | compute+math | 3–10 % if the final check is >30 % of time | 1 week | final check under 15 % of join time |
| 5 | CUDA occupancy hint for the join (BACKLOG 19) | compute | 0–5 % | 1 day, $0.50 | no scenario moves 2 % |
| 6 | Interior-digit theorems (Bassily–Kátai) and the carry-contraction lemma: can either give a sound rejection on the join's bottom layer? | math | a new filter, or a closed question | 1 week reading + prototype | no admissible hypothesis at our lengths, as with Swaenepoel |
| 7 | Weekly literature sweep: arXiv math.NT/cs.DS, GPU hash-join and bit-sliced scan papers for the join's AND scan | math+compute | leads | 2 h/week | none; it is a feed |
| 8 | Near-miss tail test (BACKLOG 39): does the density model's tail match the data? | science | model validation, a blog number | 2 days | none |
| 9 | H100/L40S on the join (BACKLOG 59) | compute sourcing | fleet pricing data | $1 | none |
| 10 | Join past 64 (BACKLOG 31) | compute | held by you until b64 is close | — | — |

Operational items I will watch and report but not act on: detailed mode running out of
fields after base 50 (BACKLOG 13, has a deadline), the fleet pricing defect (61) and
the unbilled disk storage, account credit.

First two weeks: set up (section 10), lead 1, scoping of leads 2–4 (measure the shares
before building anything), first literature sweep, one report a day from day one.

## 9. Decisions I need from you

1. Mechanism: routine into this session (recommended), or a fresh session per day.
2. Wake time and report channel: 00:41 Eastern and the session reply (recommended), or
   also a comment on a standing GitHub issue (upstream or fork, your choice) so it
   reaches your inbox.
3. Token posture: light / medium (recommended) / heavy; director on Fable (recommended,
   it is the planner and runs once a day) or Opus.
4. Budget: $30/month research on top of the fleet's $50, same credit; credit floor $10.
5. PR cap of 3 open at a time, and whether I may maintain (rebase, re-run CI, re-verify)
   your 19 existing open PRs.
6. Portfolio order above, and anything off-limits beyond section 6.

## 10. Setup steps after your yes

1. Create the recurring scheduled task (cron in your time zone) firing into this
   session, with the daily-cycle prompt; rename the session "nice research director".
2. Create `LEDGER.md` (seeded from BACKLOG items, the closed list and the theory-review
   verdicts), `JOURNAL.md`, `EXPERIMENTS.md`, `vast-ledger.csv`, `REPORTS/`.
3. Write the Vast helper: create-with-TTL, reconcile, invoice pull, monthly total.
4. Push the `research-program` branch to the fork.
5. Save the program's rules to memory so any future session honours them.
6. Run day one by hand and send the first report.
