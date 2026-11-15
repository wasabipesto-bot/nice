# Q1 review: `pr/api-niceonly-queue-stale-claims` (`6a629136`), 2026-11-15

## Verdict

**Open after the listed fixes.** The nice-only part (rules 1 and 2) is correct: I could not make
it hand a field out twice, lose a field or starve claims, under the author's reproduction, a
concurrency stress test of my own (two queues standing in for two API processes, a direct
claimer, claims aged by 61 min mid-run), or a real Postgres with a non-UTC session time zone.
It is the fix for the defect, and it is clock-independent.

**Required:** take rule 3 (the detailed age limit) out of this PR. It does nothing at today's
rates, is not needed for the defect, adds a new failure mode that rules 1 and 2 do not have
(it compares the API host's clock with the database's), and the maintainer wants one change
per PR. Propose it on its own if at all. The exact removal is in F1.

The rest is wording (PR body, changelog, deploy notes).

## Findings

### F1 (required, scope): the detailed age limit is a separate change

`api/src/field_queue.rs`: `DETAILED_MAX_QUEUED_AGE` (l. 39-47), `Preclaimed::max_age`,
`too_old`, `prune` (l. 140-164), the `prune()` call and the `too_old` pop loop in `claim`
(l. 177, 201-207), the three `Some(DETAILED_MAX_QUEUED_AGE)` in `FieldQueue::new`.

- **Not needed for the defect.** The defect is nice-only. The author's own numbers show no
  detailed queue holds a field more than about 20 min today (`Thin`/recheck about 455 an hour
  against at most 150 queued), so the rule never fires; the PR body says so.
- **New risk.** `too_old` compares `Utc::now()` on the API host with `last_claim_time`
  stamped by the database's `NOW()`. If the API clock runs 30 min or more ahead of the
  database, every detailed field is too old the moment it is queued: each detailed claim
  prunes the queue, bulk-claims 100 (or 100 `Next`) fields, drops them all at the pop and falls
  back to a direct claim. That is about 100 fields claimed and stranded for an hour per
  detailed request (about 900k an hour at today's 9,000 detailed claims an hour), the `Next`
  cursor racing ahead, and every hand-out on the slow direct path. Main degrades too with skew
  (`claim_cutoff` also uses the API clock: a skew of D shortens every claim by D), but not by
  amplification. The nice-only renewal compares database time with database time and has no
  such exposure.
- **At a traffic drop** it trades duplicates for churn: below about 6,000 detailed claims an
  hour, `Thin` and recheck drop their tails every 30 min and refill. Dropped `Next`/recheck
  fields sit below the cursor, so they return only at the next hourly rewind. Not a loss, but
  behaviour that deserves its own discussion.
- 30 min itself is a reasonable value (half the window, margin 1.5x over the measured 20 min),
  so the separate PR can keep it.

Fix, precisely: in `api/src/field_queue.rs` delete `DETAILED_MAX_QUEUED_AGE`, the `max_age`
field and parameter (`Preclaimed::new(name, threshold)` again, and the four calls in
`FieldQueue::new`), `too_old` and `prune`; in `claim` restore `if self.len() <= self.threshold`
and the final `queue.pop_front()`; delete the tests `detailed_queues_drop_old_claims` (and
its call in `field_queue_against_postgres`) and `an_aged_queue_drops_old_fields_and_refills`;
revert the three `Preclaimed::new("test", 0, None)` back to two arguments. Keep `merge` (on all
queues; it is a no-op on the detailed queues today and harmless), the `claimed` test helper
(the merge test uses it) and `record()` delegating to it. Drop the last clause of the
CHANGELOG line, the "Detailed" bullets in "What" and "Why it is safe", and the clock deploy
note. Then rerun the tests below.

### F2 (minor, PR body/RESULTS accuracy): route B claim age at hand-out

PR body, "Mechanism", route B: "handed out with a claim already over an hour old". The data
show the refill re-claimed route-B fields a median 1.5 min (max 16 min) after the hand-out, so
at hand-out the claim was at least 44 min old and typically about 58 min, not necessarily over
an hour. Example from the public API: field 207072586, handed out 02:02:32, re-claimed by the
02:18:33 refill. Suggested: "handed out with a claim already nearly an hour old, so the next
refill (a median 1.5 min later) re-claimed it".

### F3 (minor, PR body): say which rule is load-bearing

Mutation results (below): renewal alone (no merge) passes the reproduction and my stress
test; merge alone leaves the 50 route-B duplicates. So renewal is the fix and merge removes the
redundant queued copies (each would otherwise cost one failed renewal and a log line). The body
already says "with only the merge, 50 still go out twice"; one more clause, "renewal alone
removes all of them; the merge keeps the queue free of stale copies", makes the design clear
to the maintainer.

### F4 (nit, changelog): too long

The line is one sentence of about 60 words; the maintainer cuts these. After F1, suggested:

> Stop the API handing out a nice-only field twice when its queue is consumed more slowly than
> the claim window ([#NNN](https://github.com/wasabipesto/nice/pull/NNN)).

### F5 (nit, deploy notes)

- "`Skipped a queued niceonly field…`: a few per refill is normal (late submissions)": with
  renewal, a skip needs a holder more than an hour late, a direct-claim fallback or second API
  process taking an expired queued field, or a detailed claim of a `check_level = 0` field at a
  small base. Expect it rarely, not per refill; a steady stream would mean the stamp equality is
  failing, which is the thing to watch in the first hour.
- Worth one line for the operator: no migration and no configuration; rollback is the previous
  image; the first refill after deploy re-claims nothing new (queue starts empty on restart, as
  before).
- The clock note goes with F1.

### F6 (note, no change required): the error path

On a database error the renewal hands the field out unrenewed (`claim_niceonly`, "As before
this check existed"). That is exactly main's behaviour for that one field, so it cannot be worse
than today; a field whose claim had already expired could then be re-claimed by the next refill.
The alternative (drop it and `return None`, sending the request to the direct claim) holes
the field for at most an hour instead. Either is defensible; I would leave it.

### F7 (note): unreachable branch

`let Some(held) = field.last_claim_time else { continue; };`: every bulk claim stamps
`last_claim_time`, so this never runs; if it did, the field would simply be dropped from the
queue and stay claimable by the next refill. Harmless.

## Answers to the brief's questions

### 1. Routes to a duplicate

Every path that hands a field out stamps `last_claim_time` (bulk claim, direct claim,
renewal), and every nice-only hand-out from a queue now requires the stamp to be the one it was
queued with and `check_level = 0`, in one row-locked `UPDATE`. Interleavings (READ COMMITTED;
bulk claims lock with `FOR NO KEY UPDATE SKIP LOCKED`, so they never wait on a renewal; a
renewal waits on a bulk claim's row lock and then re-evaluates its `WHERE` on the new version):

- **Refill while a field is being handed out.** T1 pops X (stamp S1, expired), T2's refill
  re-claims X (S2). (a) T2 commits first: T1's renewal finds S2, no row, skip; T2's merge finds
  no X queued and appends it: handed out once, later. (b) T2 has X locked: T1 waits, then sees
  S2, skip; same as (a). (c) T1's renewal commits first: T2's lock re-check sees a fresh claim,
  X is not claimable, not re-claimed. (d) T1 pops after the merge: it pops the merged record
  carrying S2, renewal matches.
- **Route A** (re-claimed while queued): merge replaces the queued copy in place; even without
  merge the old copy fails renewal (verified by mutation).
- **Route B** (re-claimed after hand-out): a hand-out now renews, so the field is not claimable
  for a full hour from hand-out. A holder more than an hour late can still lose the field to the
  next refill; that is the claim window doing its job, as for direct claims. If the late holder
  then submits, the queued copy fails renewal (`check_level`), skipped.
- **Two API processes.** P1 queues X (S1); P2 re-claims X after S1 expires (S2); P1's
  renewal fails, skip. If P1 renewed first, P2 cannot re-claim X. Verified in the stress test.
- **Direct-claim fallback.** Stamps the field; any queued copy anywhere then fails renewal.
- **Error path.** As main, for that field (F6).
- **Detailed claims of `check_level = 0` fields** (small bases, `check_level <= 1`): they
  re-stamp, so the nice-only copy is skipped. Correct.

No deadlock: a renewal holds one row lock in its own autocommit statement; bulk claims skip
locked rows.

### 2. Lost or stranded fields; spinning; `None`

- A skipped field was submitted (done) or claimed by someone else (theirs): nothing to return.
- A field dropped for any other reason (F7, or a renewal error) keeps its claim until it
  expires, then the next refill or direct claim takes it.
- At the end of my stress run every one of 3,600 `check_level = 0` fields had been handed out
  exactly once, after draining both queues and expiring the rest.
- The loop is bounded at 250 passes, holds no lock across the renewal (`claim` returns
  before it; the refill runs under the refill gate only, as before; merge under the queue lock
  in memory), and waits at most `REFILL_WAIT` only when the queue is empty with a refill in
  flight. It returns `None` only when the queue is empty (as main) or after 250 consecutive
  skips; `None` goes to the direct claim in `claim_helper`, so the client still gets a field
  (a 500 "Could not find any niceonly field!" only when none is claimable, as main). Worst case,
  every queued field failing: 250 single-row updates plus one or two bulk claims, well under a
  second, then a direct claim.

### 3. `last_claim_time = $2`

The column is `TIMESTAMPTZ` (microseconds). The queued stamp is the database's own value from
the bulk claim's `RETURNING f.*` (or from the renewal's `RETURNING *`), round-tripped through
diesel's binary `Timestamptz` (microseconds since 2000-01-01, UTC), so there is no truncation or
zone conversion to go wrong. Tested on Postgres 17: the full suite and the reproduction pass
with the database's `timezone` set to `Pacific/Chatham` (+13:45) and the test process under
`TZ=America/St_Johns`; my stress test, which would starve if equality failed (it requires every
field to be handed out), passes. The reproduction itself would panic on `expect("field")` if
renewals failed systematically.

### 4. Things that must not change

Unchanged: the refill gate (`try_lock`, re-check under the gate, `RefillGuard`), the
`REFILL_WAIT` wait loop, `NextCursor` (`refill`, `advance_past`, rewind interval and window)
and `claim_detailed_next_direct`, every constant from #226 and #238, `prefill_all` (except that
it now merges, a no-op on an empty queue). The only change inside `claim`'s gate logic is
`len()` -> `prune()` in the first check, which is `len()` with no age limit (and goes with F1).
`merge` keeps queued records in place and appends new ones in refill order, deduplicated; on the
detailed queues a refill re-claims a queued field only if it sat there over an hour, and then it
keeps its earlier (lower-id) place, consistent with the `Next` queue's id order. `advance_past`
still sees the full refill result. The existing seven Postgres scenarios and both wait tests
pass.

### 5. Cost

`EXPLAIN (ANALYZE, BUFFERS)` on a 500k-row scratch table with `schema/schema.sql`:

| indexes | plan | buffers | time |
|---|---|---|---|
| repository schema | index scan on `idx_fields_last_claim_time` (stamp equality; at most ~200 rows share a refill's stamp), filter on id | 3 | 0.013 ms |
| claim indexes dropped (`idx_fields_last_claim_time`, the composite) | index scan on `idx_fields_cl0_id` (`id = $1`) | 6 | 0.046 ms |

Either way one row. With `last_claim_time` indexed the update is not HOT (the same as every
existing claim update); without those indexes, as in production, it can be HOT when the page has
room. About 90 extra single-row updates an hour today; at a base's start, one per instantly
rejected field (tens a second for a few minutes), alongside the `claims` insert every claim
already does. The detailed path does no extra database work (its claim functions are untouched;
`prune`/`too_old` are in memory and go with F1).

### 6. The detailed age limit

See F1: separate PR.

### 7. Tests

- Without a database: 5 passed (Postgres scenarios skip). With the scratch Postgres: 5 passed
  (the Postgres test ran: 2.8 s against 0.3 s).
- Mutations against the reproduction (`a_slow_niceonly_queue_hands_no_field_out_twice`): main's
  behaviour (no merge, no renewal) fails with 100 fields handed out twice (ids 701-800, both
  routes); merge only: 50 (701-750, route B); renewal only: passes.
- My stress test (temporary, reverted): 8 claimer threads on two `FieldQueue`s, one direct
  claimer, an ager moving every claim back 61 min every 15 ms while no field is in hand,
  holders submitting at once; 3 runs on the branch: 3,600 hand-outs, 3,600 distinct, 0
  duplicates; on the main-like mutant: 7,608 hand-outs, 4,008 duplicates; renewal only: 0.
- The new tests sleep nowhere; the only wall-clock assertion is "renewed claim under 60 s old",
  which is generous.
- `just lint`: exit 0 (fmt, clippy, clippy with the GPU features); the only output is the
  existing `web-sys` manifest warning in wasm-client.
- `cargo test --locked -p nice_common --features database --test claim_queries` against the
  scratch Postgres: passed.

### 8. PR body and changelog against the evidence

I re-ran `raw/analyse.py` and `raw/routes.py` on copies of the data: 655 real submissions, 530
fields, 125 searched twice, 213 with two nice-only claims (186 A, 27 B; 110 and 15 with both
searches real), gap median 38.0 min (p10 1.9, p90 42.1), the per-refill table and the
95 / 24 / 6 split all match. Spot checks against the public API (two fields, `field_id=eq.`,
claims and submissions) match the raw files. No mention of the program, its directories,
agents or model names in the body or commit message (the attribution line is the required one).
Corrections: F2, F3, F4, F5.

## What I verified and how

Scratch Postgres 17 on ivory (rootless podman, `--cgroups=disabled`, tmpfs data directory,
127.0.0.1:55461), schema from the branch; worktree `~/projects/nice/.worktrees/review-q1` at
`6a629136`, its own `target/`; `nice -n 19`, two jobs. Mutants and the stress test were applied
to the worktree and reverted (`git status` clean). Public API: four reads, 0.2 s apart,
`User-Agent: nice-audit-census`. Afterwards: container removed, `target/` deleted, the review
worktree removed (it was clean).

## What I could not verify

- Production's actual index set and clock arrangement (whether the API and database share a
  host clock); I did not touch production.
- Behaviour under a real multi-hour run; the tests compress time by back-dating claims.
