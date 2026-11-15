## What

The nice-only queue hands fields out twice once it is consumed more slowly than a claim lasts. This stops it:

- A refill keeps each field in the queue once. A field it re-claims while still queued keeps its place and takes the new claim.
- Each nice-only claim is renewed at hand-out: one primary-key `UPDATE`, only if the field is still at `check_level = 0` and still carries its queued claim. A field submitted, or claimed elsewhere, while it waited is skipped.
- The detailed queues drop a field whose claim is more than half expired (30 min) instead of handing it out. This adds no database work.

## Production evidence (public data, base 62, 00:58–09:29 UTC today)

| | |
|---|---|
| real nice-only submissions (join > 1 s) | 655 |
| distinct fields | 530 |
| fields searched twice | 125 (19 % of submissions, 18 % of join time) |
| same client / one then another / fleet twice | 95 / 24 / 6 |
| gap between the two hand-outs | median 38 min (p10 2, p90 42) |
| nice-only hand-outs per hour, 03:00–09:00 | 83–93 |

Every repeat traces to a refill:

| refill (UTC) | queued fields re-claimed (A) | handed out, unsubmitted, re-claimed (B) |
|---|---|---|
| 02:18 | 50 | 9 |
| 03:59 | 50 | 6 |
| 06:15 | 50 | 6 |
| 08:33 | 36 so far | 6 |

Of the 213 fields with two nice-only claims (125 searched twice for real): 186 route A, 27 route B, none other.

## Mechanism

`bulk_claim_fields` stamps 200 fields when the queue holds 50 or fewer, and the queue hands them out in order without checking their age. At about 85 an hour, a refill comes every 1.8 h or so. By then the 50 fields left in the queue are older than `CLAIM_DURATION_HOURS`. The refill takes the lowest-id claimable fields: those 50, plus handed-out fields not yet submitted. The queue then holds two copies of each.

- **Route A:** old copy first, new copy about 38 min later, usually to the same machine.
- **Route B:** the field was handed out with a claim already over an hour old (median 1.5 min before the refill re-claimed it), then handed out again after its holder submitted.

## Why it is safe

- **Nice-only:**
  - No queued field is duplicated.
  - Every client gets a full hour from hand-out.
  - A field that is no longer unsearched, or no longer ours, is never handed out.
  - Cost: one update per nice-only claim, about 90 an hour (briefly about 50 a second at a new base's start).
  - A slow client (338 s a field, two claims held) submits within about 11 min of hand-out.
- **Detailed:**
  - About 9,100 claims an hour today. The oldest field handed out is about 1 min old for `Next` and about 20 min for `Thin` and recheck, so the limit does not fire.
  - Below about 6,000 detailed claims an hour, `Thin` starts dropping fields, which return when their claims expire.
- **Unchanged:** the single-flight refill, the refill wait and the `Next` cursor. No schema change and no new configuration.
- **Consumption:** a rise means sooner refills; a fall, the next refill re-claims waiting fields in place.

## Tests

- New Postgres test reproducing production by back-dating claims. Before the fix it hands 100 fields out twice. With only the merge, 50 still go out twice. With the full fix, none.
- New tests for renewal, the detailed age limit, merging and dropping.
- `just lint` clean; `cargo test --locked --release -p nice_api` passes, also with `NICE_TEST_DATABASE_URL`; `claim_queries` passes.

## Deploy notes

- `Skipped a queued niceonly field…`: a few per refill is normal (late submissions). A steady stream is not.
- `Failed to renew a queued niceonly claim` should not appear. Nor should `Dropped queued fields…` at today's detailed rates.
- Recount base-62 fields with two real nice-only submissions: 19 % should fall to near zero.
- The detailed limit compares the API's clock with the database's `NOW()`; they must agree within minutes.

## Not in this PR

Sizing the nice-only batch to consumption; client prefetch; the fields already searched twice (their results agree).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
