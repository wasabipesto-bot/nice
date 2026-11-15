# Review brief: the API's claim queue no longer hands a nice-only field out twice (2026-11-15)

You are an independent reviewer. Repository `~/projects/nice` on this machine (ivory); upstream
`wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork` (fetch both).
You were not involved in writing the change; take none of its claims on trust. This is the
project's production API server: a mistake here can stall claims for every client, hand out
fields that are never searched, or make the search skip fields, so correctness under
concurrency comes first.

## What is under review

Fork branch **`pr/api-niceonly-queue-stale-claims`** (`6a629136`, one commit on upstream main
`54d0aac4`; `api/src/field_queue.rs`, `common/src/db_util/fields.rs`, CHANGELOG). The author's
write-up: `Q1/RESULTS.md`, the PR body draft `Q1/PR-BODY.md`, data and scripts under `Q1/raw/`, in
`~/projects/nice/scratchpad/2026-10-research-program/`; the task it answered: `Q1/BRIEF.md`.

The defect: the nice-only queue pre-claims 200 fields when it holds 50 or fewer and hands them
out first-in first-out; a claim expires after `CLAIM_DURATION_HOURS` (1 h). At base 62 the queue
is consumed at about 90 fields an hour, so a refill re-claims fields that are still queued (or
were handed out minutes ago), and they are searched twice: 125 of 530 real base-62 fields in
nine hours. The fix: (1) a refill that re-claims a queued field replaces it in place instead of
queueing it again (`merge`, all queues); (2) each nice-only field's claim is renewed at
hand-out with a conditional primary-key update (`renew_niceonly_claim`: `SET last_claim_time =
NOW() WHERE id = $1 AND last_claim_time = $2 AND check_level = 0`), and a field for which no row
matches is skipped; (3) the detailed queues drop, in memory, fields whose claim is older than
30 minutes (`DETAILED_MAX_QUEUED_AGE`, `prune`, `too_old`).

## Questions

1. **Does it remove both routes to a duplicate**, and can any remain (two API processes; a
   refill running while a field is being handed out; a renewal that races a refill's bulk
   claim; a client that holds a field longer than an hour; the direct-claim fallback when the
   queue is empty; the error path that hands the field out without a renewal)? Write the
   interleavings out. Run the author's reproduction on unfixed main and on the branch yourself.
2. **Can it lose or strand a field?** A field dropped or skipped must become claimable again:
   say when, for each rule. Can the nice-only loop spin, hold the queue lock across a database
   call, or return `None` (a 503 to the client?) where main returned a field? What does a
   client see when every queued field is skipped?
3. **`last_claim_time = $2`**: is the queued stamp exactly what the database holds (timestamp
   precision through diesel and chrono, time zones, the `RETURNING` of the bulk claim), so the
   equality cannot fail spuriously (which would skip every field and starve nice-only claims)?
   Test it against a real Postgres, not by reading.
4. **Concurrency and the things that must not change:** the single-flight refill, the refill
   wait, the `Next` cursor and rewind of #226 / #238, lock ordering, what is held across
   `await` points or blocking calls. `merge` on the detailed queues: can replacing a field in
   place reorder or duplicate anything the cursor logic relies on?
5. **Cost:** one extra `UPDATE` on `fields` per nice-only claim: which index does it use (the
   production table is about 130 million rows with no claim indexes; `EXPLAIN` on a scratch
   database with the repository's schema), is it a HOT update, what happens at the start of a
   base when thousands of instant fields are claimed within minutes; the detailed path must do
   no extra database work (check).
6. **The detailed age limit:** is 30 minutes right (the author measured queue ages of 1 to 20
   minutes), what happens at a traffic drop, and does comparing the API host's clock with the
   database's `NOW()` create a risk (clock skew dropping every field)? Is this third rule
   needed for the defect at hand, or is it a second change that belongs in its own PR? Say
   which, plainly: the maintainer wants one discrete change per PR.
7. **Tests:** do they fail on main for the right reason, cover each rule, and avoid sleeping
   or wall-clock flakiness? Run `cargo test --locked --release -p nice_api` with a scratch
   Postgres (the author's `Q1/raw/` shows how it was started; rootless podman; remove the
   container when done) and without one, and `just lint`.
8. **The PR body and changelog against the evidence** (sample the production numbers from
   `Q1/raw/` and, lightly, from the public API: primary keys, `field_id=eq.`, id ranges of at
   most 100,000, 0.15 s apart, `User-Agent: nice-audit-census`). No mention of the research
   program, its directories, agents or model names. Is the changelog line one short
   user-facing sentence (the maintainer cuts long ones)? Are the deploy notes right and
   sufficient for the operator?

## Method and limits

A worktree `~/projects/nice/.worktrees/review-q1` (detached at `6a629136`), building in its own
default `target/` (about 5 GB; 14 GB of disk is free: keep 5 GB free, and delete your `target/`
when you finish); mutants in the same worktree, reverted afterwards. `nice -n 19`, two threads.
**The production server, its database and its deployment are not to be touched**; never claim
from or submit to production. Do not change the branch, do not push, do not open, comment on
or edit any pull request, do not start subagents, nothing on the fleet, demoux or mayalaran.

## Deliver

`Q1/REVIEW.md`: the verdict first (open as is / open after the listed fixes / do not open),
findings by severity with file and line, how you know, and the fix you suggest; then what you
verified and how; then what you could not verify. Hard stop **11:45 UTC**. Your final message is
a short summary for the program's director, with any required fix stated precisely enough to
apply.
