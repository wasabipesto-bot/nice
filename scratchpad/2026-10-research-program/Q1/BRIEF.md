# Q1 brief: the nice-only claim queue hands out fields twice at base 62 (2026-11-15)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules); on upstream main (`54d0aac4`):
`api/src/field_queue.rs` (all of it, tests included), the claim handler in `api/src/main.rs`,
`bulk_claim_fields` and the claimable predicate in `common/src/db_util/fields.rs`,
`CLAIM_DURATION_HOURS` in `common/`; `../../2026-10-next-steps/BACKLOG.md` item 1 (this defect was
predicted there on 2026-10-09); merged PRs #226 and #238 for how claim-path fixes were written,
tested and described here (`gh pr view 226 --repo wasabipesto/nice`, `gh pr view 238 …`).

## The defect, as measured in production today

Base 62 started at 00:58 UTC today (fields of 1e17; a real field takes 56 s on the main AMD
client and 338 s on the fleet's cards; many fields are rejected instantly). From public
telemetry up to 09:29 UTC (`Q1/b62_niceonly_submissions_to_0929utc.json`: nice-only submissions
with id > 294552514; a "real" one has join `run_secs` > 1):

- 656 real base-62 submissions cover only 530 distinct fields: **126 fields were searched
  twice, 19.2 % of the real submissions and 17.9 % of the join seconds.**
- 96 of the 126 pairs are the same client both times, 24 are one client then another, 6 are the
  fleet twice. The two submissions of a pair are a median 38 minutes apart (p10 33, p90 42).
- They come in bursts: second searches per hour, over nine hours: 0, 2, 0, 25, 24, 8, 42, 0, 25
  (of 72–79 real submissions an hour).
- The repeated searches agree with the first (no integrity problem); they are wasted work on
  the machines that carry the search.

The mechanism as I read the code (verify it; do not take it from me): the nice-only queue
pre-claims `REFILL_AMOUNT = 200` fields when it holds `REFILL_THRESHOLD = 50` or fewer, hands
them out first-in first-out with no check of their age, and a claim expires after
`CLAIM_DURATION_HOURS` (one hour). At base 62 the queue is consumed at roughly 120 fields an
hour, so the back of a batch is handed out more than an hour after it was claimed, and the next
refill's `bulk_claim_fields` takes the lowest-id fields whose claim is over an hour old: fields
still sitting in the queue, and fields handed out but not yet submitted. Those are then in the
queue twice.

## Task

1. **Confirm the mechanism** from the code and from the data (for the duplicated fields: the
   fields' `last_claim_time`, the two submissions' times, their place in a 200-field batch by
   id; use the production API read-only and lightly: primary keys, `field_id=eq.`, or id ranges
   of at most 100,000, 0.15 s apart, `User-Agent: nice-audit-census`). Say which of the three
   routes produce duplicates and in what proportion: a field re-claimed while still queued; a
   field re-claimed after hand-out and before its submission; anything else. Check whether the
   detailed queues can do the same (their consumption is thousands an hour, so probably not:
   show it).
2. **Reproduce it in a test** against a scratch Postgres (the API's existing tests show how;
   back-date `last_claim_time` or inject the clock, do not sleep): a queue consumed more slowly
   than its batch over the claim lifetime hands a field out twice.
3. **Fix it, minimally and safely.** Requirements: a field is never in a queue twice; a queue
   never hands out a field whose claim has expired or will expire before a client could
   plausibly finish it; a field that was submitted while it sat in the queue is not handed out;
   no schema change; no new configuration unless it is needed; no extra database work per
   claim on the detailed path (3.5 million claims a day); the single-flight refill, the refill
   wait and the cursor logic of #226 / #238 stay as they are. Decide between, or combine, as the
   evidence says: dropping queue entries by age at pop and at refill; sizing the nice-only
   batch to the observed consumption so a batch lasts well under the claim lifetime;
   re-stamping the claim of a nice-only field at hand-out (one primary-key update per nice-only
   claim, a few hundred an hour). Say what happens to a slow client (338 s a field, plus its
   own local queue of claimed fields) under your rule, and what happens when consumption
   suddenly rises or falls.
4. **Tests:** the reproduction now passes; the existing API tests pass; a test for each rule
   you add. `just lint` (CI's recipe) clean; the API's test recipe as CI runs it.
5. **Deliver** a branch `pr/api-niceonly-queue-stale-claims` on the fork (one commit on upstream
   main, with a one-sentence CHANGELOG line in the file's style under the unreleased section
   ending in `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`), and `Q1/PR-BODY.md` (at
   most 600 words plus tables: what, the production evidence above, the mechanism, the fix and
   why it is safe for every queue, tests, deploy notes for the server's operator: anything to
   watch after deploying, "Not in this PR"). The body must not mention the research program,
   this directory, agents or model names; it may cite the public telemetry numbers. Last line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. No PR is opened by you.

## Rules

**The production server, its database and its deployment are not to be touched**: read-only
light queries of the public API from ivory, nothing else. A scratch Postgres on ivory only
(rootless podman; if `podman run` fails on the systemd bus, `--cgroups=disabled` and a tmpfs
data directory have worked before; keep it small and remove the container when done). ivory:
`nice -n 19`, keep 5 GB of disk free, writes only under `Q1/` and a worktree
`~/projects/nice/.worktrees/q1-queue`; `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`
is warm for Rust 1.100.0. Push only to the fork, only the new branch name; never force-push,
never delete a branch; if a push or any action is refused, report it and do not work around it.
Never push to `wasabipesto/nice`; no PR actions; no subagents; nothing on the fleet, `~/fleet-run`,
demoux or mayalaran.

## Deliver

`Q1/RESULTS.md` (the mechanism with evidence, the reproduction, the fix and its argument, the
tests run), `Q1/PR-BODY.md`, raw data and scripts under `Q1/raw/`. Hard stop **12:45 UTC**. Your
final message is a short report for the program's director.
