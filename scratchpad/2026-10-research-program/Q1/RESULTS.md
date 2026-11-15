# Q1 results: nice-only queue re-issue at base 62 (2026-11-15)

Branch `pr/api-niceonly-queue-stale-claims` on fork `wasabipesto-bot/nice`. It is one commit, `6a629136`, on upstream main `54d0aac4`, pushed with a plain push. No PR has been opened. The PR body is `PR-BODY.md`. Worktree: `~/projects/nice/.worktrees/q1-queue`.

## 1. Mechanism: confirmed from the code and the data

**Code (main `54d0aac4`):**

- `FieldQueue::claim_niceonly` calls `Preclaimed::claim`. When the queue holds 50 or fewer (`REFILL_THRESHOLD`), it runs `bulk_claim_fields(200, now − 1 h, cl 0)`, then calls `pop_front()` with no age check.
- `bulk_claim_fields` stamps `last_claim_time = NOW()` on the lowest-id `check_level = 0` fields whose claim is NULL or over `CLAIM_DURATION_HOURS = 1` old. It appends them with `extend`, without checking for duplicates.
- `insert_claim` (at hand-out) writes only a `claims` row. It does not re-stamp the field, so a field's claim runs from its bulk claim, not from its hand-out.
- A nice-only `/submit` moves the field to `check_level = 1`. Late submissions are accepted.

**Data:** the public API, read-only. Data and scripts are in `raw/`:

- `fields_*.json`: id range 207060000–207090000.
- `claims_*.json` and `submissions_*.json`: `field_id=in.(…)` batches of 100, 0.15 s apart, on base-62 fields 207064110–207073600.
- Three claim primary keys, and one 1,472-id claim range for the detailed rate.
- Base 62 starts at field 207064110.

**Refills reconstructed from shared `last_claim_time` stamps:**

- 43 refills between 00:57:48 and 01:00:28. In that window about 9,000 instantly rejected fields went out in 3 minutes.
- After that: 02:18:33, 02:20:33, 03:59:26, 06:15:20 and 08:33:33.
- Nice-only hand-outs ran at 83–93 an hour from 03:00 onward. That is lower than the brief's 120. A 200-field batch therefore lasts about 1.8 h between refills, and a field waits up to about 2.9 h.

**Counts (`raw/analyse.py`):**

- 655 real submissions (join > 1 s) on 530 distinct fields, 125 of them searched twice. The brief's 126 differs by one, at the cutoff.
- 213 fields have two nice-only claims and none has three. The other 88 were instantly rejected both times.
- Pairs by client: demoux twice 95, the fleet twice 6, one client then the other 24.
- Gap between the two hand-outs: median 38 min (p10 1.9, p90 42).

**Routes (`raw/routes.py`):** each refill's stamp is the field's surviving `last_claim_time`, R2, and each claim carries its hand-out time.

- If the re-claim R2 came before the first hand-out, the field was **re-claimed while still queued (route A)**.
- If the re-claim came after the hand-out and before the first submission, the field was **re-claimed after hand-out, before submission (route B)**.
- No other case occurs.

| refill R2 (UTC) | A | A, both searches real | B | B, both real |
|---|---|---|---|---|
| 02:18:33 | 50 | 0 | 9 | 2 |
| 03:59:26 | 50 | 45 | 6 | 4 |
| 06:15:20 | 50 | 44 | 6 | 6 |
| 08:33:33 | 36 (rest still queued) | 21 | 6 | 3 |
| **total** | **186** | **110** | **27** | **15** |

- Every refill re-claimed exactly the 50 fields still in the queue.
- **Route A** accounts for 87 % of the real repeats and 81 % of the repeated join time (2.31 h against 0.53 h). The first copy went out a median 8 min after the re-claim and the second copy behind it about 38 min later, which matches the gap. It is usually the same machine because demoux does most of the search.
- **Route B** accounts for 13 %. The first holder took a median 2.9 min (at most 18.5) to submit, but the refill re-claimed the field a median 1.5 min after its hand-out. So the field had been handed out with a claim already over an hour old.

**Detailed queues cannot do this at today's rates:**

- Claim ids 294717471 → 294817471 → 294917471 span 10.8 h and 9.8 h, about 9–10k claims an hour.
- The 1,472 claims in the last 9.6 min are 1,460 detailed and 12 nice-only: about 9,100 detailed an hour. Those 1,460 detailed claims covered 1,460 distinct fields.
- Split 90/5/5, the oldest field each queue hands out is about (threshold + amount) ÷ rate:

| queue | rate | oldest field handed out |
|---|---|---|
| `Next` | 8,200/h | 120 fields, ~1 min |
| `Thin` | 455/h | 150 fields, ~20 min |
| recheck | 455/h | 120 fields, ~16 min |

All three are far below 60 min.
- Detailed fields are at most 1e10 in size, so no detailed strategy can take a base-62 field.

## 2. Reproduction

`a_slow_niceonly_queue_hands_no_field_out_twice` in `api/src/field_queue.rs` runs against a scratch Postgres. It back-dates every claim, in the database and in the queue, by 61 min instead of sleeping.

The test:

1. Hands out 150 fields from the first batch: 100 submitted, 50 in flight.
2. Moves the clock an hour forward, so the next claim refills.
3. Submits the 50 in-flight fields (slow holders), then hands out 249 more.

On unfixed main the test fails with **100 fields handed out twice**: 50 by route A and 50 by route B, ids 701–800. That is the production pattern. Mutation check: with renewal at hand-out removed and only the merge kept, 50 fields are still handed out twice, all route B.

## 3. The fix

| rule | how | where | DB cost |
|---|---|---|---|
| never in a queue twice | `Preclaimed::merge`: a refill's fields that are already queued replace the queued record in place, with the new claim time; the rest are appended in order | all queues | none |
| no hand-out of an expired or nearly expired claim (nice-only) | `renew_niceonly_claim`: `UPDATE fields SET last_claim_time = NOW() WHERE id = $1 AND last_claim_time = $held AND check_level = 0 RETURNING *` at hand-out; no row means skip and pop the next (bounded at 250) | nice-only | one PK update per nice-only claim |
| no hand-out of a field submitted while queued | the same statement (`check_level = 0`) | nice-only | (same) |
| no hand-out of an expired or nearly expired claim (detailed) | `DETAILED_MAX_QUEUED_AGE = 30 min`: entries older than that are pruned before the threshold check (so an aged queue refills) and skipped at pop | detailed queues | none |

- **On error:** if the renewal hits a database error, the field is handed out as before and an error is logged.
- **Unchanged:** the single-flight gate, `REFILL_WAIT`, the `NextCursor` logic and every constant from #226 and #238. There is no schema change and no configuration change.

**Why these rules rather than the alternatives:**

- **Age-dropping the nice-only queue:** at about 85 an hour, with a 30–50 min limit, it would drop roughly 130–160 of each 200-field batch. The dropped fields stay claimed for an hour, which punches holes in the frontier.
- **Sizing the batch to consumption:** this has to cope with a swing from about 3,000 a minute (instant rejects at the start of a base) to 85 an hour. It needs a rate estimator and still leaves route B open.
- **Renewal at hand-out:** this makes the queue's age irrelevant for nice-only and is the only rule that catches route B. It costs about 90 PK updates an hour today, and briefly about 50 a second at the start of a base, next to the `claims` insert that every claim already does.
- **Detailed:** the detailed queues get the in-memory age limit because the brief forbids per-claim DB work there.

**Slow client:** fleet card, 338 s a field, `prefetch_target` floor 2, so 2 claims held.

- It submits within about 11 min of hand-out, against a renewed 60 min, so route B needs a holder more than an hour late.
- Under the old code its window was 60 min minus the queue age, which at base 62 was often already negative.

**Consumption changes:**

- *Sudden rise:* refills come sooner and nothing else changes. The refill herd gate is untouched.
- *Sudden fall, nice-only:* fields wait. The next refill re-claims the stale queued fields in place (no copies), and renewal hands them out with a fresh hour.
- *Sudden fall, detailed:* below about 6,000 detailed claims an hour (`Thin` and recheck under about 300 an hour), tails older than 30 min are dropped. They come back as claimable when their claim expires, and a refill replaces them.

## 4. Tests run (ivory, `nice -n 19`)

- `just lint`: clean. There is one pre-existing manifest warning about `web-sys` in wasm-client, which is not under `-D`.
- `cargo test --locked --release --no-fail-fast -p nice_api` (CI's command, API package, no database): 5 passed. The Postgres test skips.
- The same command with `NICE_TEST_DATABASE_URL` pointing at the scratch Postgres: 5 passed. These include, in `field_queue_against_postgres`:
  - the reproduction;
  - `niceonly_claims_are_renewed_at_hand_out`: a claim that waited 50 min comes back with an age under 60 s, the record matches the database, and a field re-claimed elsewhere is skipped;
  - `detailed_queues_drop_old_claims`;
  - the seven existing scenarios.
- The unit tests `a_refill_never_queues_a_field_twice` and `an_aged_queue_drops_old_fields_and_refills` pass, as do the two existing wait tests.
- `cargo test --locked -p nice_common --features database --test claim_queries` with the database: passed.
- Test output is in `raw/test_runs.txt`.

## Notes for the director

- **Refused action:** running cargo with `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`, as the brief suggested, was refused by the permission classifier. It was not retried. The builds used the worktree's own `target/` instead (inside the allowed worktree). Free disk is 9.5 GB, and the worktree's `target/` can be deleted once review is done.
- **Scratch Postgres:** the `q1-queue-pg` container (tmpfs, port 55441) was removed at the end.
- **Live at the time of the fetch:** 144 fields of the 08:33:33 batch were still at `check_level = 0`. Their claims expired at 09:33, so the next refill re-claims them while they are still queued. The duplication continues until the fix is deployed.

## After review (10:15 UTC)

I applied the changes from `REVIEW.md` F1–F5 as one new commit, **`acc615d4`**, on top of `6a629136`. It went up as a plain push and is a fast-forward (`git merge-base --is-ancestor 6a629136 acc615d4` succeeds). The branch is now 54d0aac4 → 6a629136 → acc615d4.

**What changed:**

- **F1:** the detailed queues' age limit is removed. That covers `DETAILED_MAX_QUEUED_AGE`, `max_age`, `too_old` and `prune`, and the two tests `detailed_queues_drop_old_claims` and `an_aged_queue_drops_old_fields_and_refills`. `Preclaimed::new` takes two arguments again, `claim` is back to `len()` and `pop_front()`, and the comment about the nice-only queue having "no age limit" went with the removed block. The diff against main now contains only:
  - `merge` (all queues);
  - the renewal at hand-out;
  - the tests;
  - the `claimed` helper.
  Section 3's last table row and its "Sudden fall, detailed" paragraph above are superseded by this.
- **F4:** the changelog line is now the one sentence given in the review.
- **F2, F3 and F5** are in `PR-BODY.md` (595 words plus tables), along with the removal of the detailed and clock items and a "Not in this PR" line for a separate detailed age limit (those queues turn over in 1–20 min today).

**Tests** (scratch Postgres on 127.0.0.1:55441; output in `raw/test_runs_after_review.txt`):

| run | result |
|---|---|
| `cargo test --locked --release -p nice_api`, no database | 4 passed, Postgres scenarios skipped |
| the same with `NICE_TEST_DATABASE_URL` | 4 passed: the reproduction, the renewal test and the seven existing scenarios |
| reproduction against main's behaviour (temporary mutant: no merge, no renewal; restored) | fails, 100 fields handed out twice (ids 701–800) |
| `cargo test --locked -p nice_common --features database --test claim_queries` | passed |
| `just lint` | exit 0; only the existing `web-sys` manifest warning |

The run "renewal only → no duplicates" comes from the reviewer's mutant. I did not repeat it. The container `q1-queue-pg` and the worktree's `target/` have been removed (14 GB free).

**Not as asked:** the first commit's message, `6a629136`, still describes the detailed age limit. It was not rewritten, per the no-rewrite rule. A squash merge would replace it, or the PR description can be relied on instead.
