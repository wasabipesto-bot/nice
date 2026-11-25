# The middle-out mode on the server: tables, endpoints, cost, rollout (proposal, 2026-11-25)

References are file:line on `origin/main` at `fdbe07d3`, or *(dev)* for branch `dev/mo-clean` at `66305ada`. Nothing
here has been built or run.

## Summary

**Added:**
- five tables (`midout_bases`, `midout_chunks`, `midout_fields`, `midout_claims`, `midout_submissions`), a one-row
  cursor table (`midout_job_state`), their indexes and read grants;
- two endpoints, `GET /claim/midout` and `POST /submit/midout`;
- a midout pass in the scheduled jobs, a field-insertion script, and the client mode `nice_client midout`, listed
  in `--help`.

**Untouched:**
- no existing table gets a column, constraint or index; the only new rows in an existing table are one `bases` row
  per midout base;
- `/claim/detailed`, `/claim/niceonly`, `/submit`, their queues, consensus, chunk statistics and
  `insert_new_fields.rs`;
- old clients never call the new paths, so they cannot reach a midout field.

**Cost:**
- about 55 MB of field rows and indexes per base, against a `fields` table of 130M rows whose primary key alone is
  about 7 GB (`common/src/db_util/fields.rs:244, 290`), and about 0.45 GB of submissions per base, mostly telemetry;
- per field, one index-bounded claim query and four primary-key writes, with no in-memory queue;
- scheduled work reads only new midout submissions since a cursor, and the dirty midout chunks. It never scans
  `fields` or `submissions` for midout.

**Two existing paths must change:**
- the jobs' per-base loop must skip midout bases, or a `--full` run writes zero progress and `minimum_cl = 255`
  into their `bases` row (§4);
- the site needs one fetch and a wider mode filter to show base 64.

**The maintainer decides** (§7): field size, how fields are inserted, the double-check policy, how credit is shown,
and the submit body. Each has a default.

## 1. Facts this rests on

- **The nice-only claim has no base filter.** It takes the lowest-id claimable field at `check_level = 0`
  (`api/src/main.rs:162–166`, `fields.rs:699–745`).
  - So "niceonly will not be dispensed past b62" holds only while no base-64 row is in `fields`, which option B
    gives by construction.
  - `scripts/insert_new_fields.rs:119–121` panics on an existing base, so once base 64 has a `bases` row, nobody
    can add n-fields for it by mistake.
- **`/submit` trusts the claim id.** It looks the id up in `claims` (`main.rs:330–332`) and accepts a nice-only
  body with no checks (`main.rs:346–370`). A midout claim id posted there would be recorded against whichever
  nice-only field holds that id.
  - Hence a separate submit path, and ids that cannot collide.
  - It also drops telemetry over 16 KB silently and accepts the submission (`main.rs:29, 308–315`).
- **Timeouts.** A claim lasts 1 h (`common/src/lib.rs:51`). API statements time out after 30 s
  (`common/src/db_util/mod.rs:48–99`).
- **`fields.check_level`:** 0 unsearched, 1 one nice-only submission (`main.rs:360–369`), 2 one detailed submission
  (`main.rs:442–453`), k+1 for k agreeing detailed submissions (`common/src/consensus.rs:68`).
- **Credit.** Every non-disqualified submission is credited its field's `range_size` per (day, mode, user)
  (`common/src/db_util/cache.rs:29–37`). `--full` deletes the totals and rebuilds them from `submissions` alone
  (`cache.rs:91–104`).
- **The site** reads `chunks` (`range_start, range_end, range_size, minimum_cl`, `web/index.html:69–71`) and the two
  cache tables, filtered to `detailed`/`niceonly` (`index.html:558, 595, 630–637`). It does not read `bases`.
- **A field** *(dev)* is `(base, v_start, v_size)` in a coordinate named `midout:K0,K1,Q0`, in whole quanta
  (`common/src/midout/coord.rs:48–61, 283–301`). Its count of n is `n_count` (`coord.rs:307–329`).
  - The claim body is `CoordClaim` (`common/src/midout/wire.rs:41–52`), checked by the client's `field_of`
    (`client/src/midout_route.rs:96–130`).
  - The submission carries `telemetry.pipeline.{route, coordinate, field}` (`midout_route.rs:280–306`).
- **Rows per base.** A one-quantum field fixes three digits, so a base has b³ fields:
  - base 64: 262,144 fields of 2^57 n, unpadded;
  - base 65: 274,625 fields, with the first and last h padded, so `n_count < v_size` on some (`coord.rs:37–44`).

  Rows of k quanta divide these counts by k. A coordinate fixing four digits would give b⁴ rows (16.8M at base 64,
  about 1.5 GB with indexes). Only then would the row count matter.

## 2. Data model (one additive migration, `schema/migrations/2026-12-xx_midout.sql`)

```sql
-- Midout fields are ranges of a per-base coordinate v, not of n. Apply manually; schema.sql updated to match.
BEGIN;
CREATE TABLE midout_bases (
    base_id INTEGER PRIMARY KEY REFERENCES bases(id),
    coordinate VARCHAR NOT NULL,                 -- e.g. 'midout:4,8,5'; its meaning lives in coord.rs
    UNIQUE (base_id, coordinate));
CREATE TABLE midout_chunks (                     -- ~100 per base; chunks' column names, ranges in v
    id SERIAL PRIMARY KEY, base_id INTEGER NOT NULL REFERENCES midout_bases(base_id),
    range_start DECIMAL NOT NULL, range_end DECIMAL NOT NULL, range_size DECIMAL NOT NULL,  -- size = n count
    checked_niceonly DECIMAL NOT NULL DEFAULT 0, checked_twice DECIMAL NOT NULL DEFAULT 0,
    minimum_cl INTEGER NOT NULL DEFAULT 0);
CREATE TABLE midout_fields (
    id BIGSERIAL PRIMARY KEY,
    base_id INTEGER NOT NULL, coordinate VARCHAR NOT NULL,
    chunk_id INTEGER NOT NULL REFERENCES midout_chunks(id),
    v_start DECIMAL NOT NULL, v_size DECIMAL NOT NULL, n_count DECIMAL NOT NULL,
    check_level INTEGER NOT NULL DEFAULT 0,
    last_claim_time TIMESTAMPTZ, canon_submission_id BIGINT,
    FOREIGN KEY (base_id, coordinate) REFERENCES midout_bases(base_id, coordinate),
    UNIQUE (base_id, v_start),
    CHECK (v_size > 0 AND n_count > 0 AND n_count <= v_size));
CREATE SEQUENCE midout_claims_id_seq START 1000000000000000;   -- never meets claims.id
CREATE TABLE midout_claims (
    id BIGINT PRIMARY KEY DEFAULT nextval('midout_claims_id_seq'),
    field_id BIGINT NOT NULL REFERENCES midout_fields(id),
    claim_time TIMESTAMPTZ NOT NULL DEFAULT NOW(), user_ip VARCHAR NOT NULL);
ALTER SEQUENCE midout_claims_id_seq OWNED BY midout_claims.id;
CREATE TABLE midout_submissions (
    id BIGSERIAL PRIMARY KEY,
    claim_id BIGINT NOT NULL UNIQUE REFERENCES midout_claims(id),  -- one per claim: idempotent resubmit
    field_id BIGINT NOT NULL REFERENCES midout_fields(id),
    submit_time TIMESTAMPTZ NOT NULL DEFAULT NOW(), elapsed_secs REAL NOT NULL,
    username VARCHAR NOT NULL, user_ip VARCHAR NOT NULL, client_version VARCHAR NOT NULL,
    disqualified BOOLEAN NOT NULL DEFAULT 'false',
    numbers JSONB NOT NULL DEFAULT '[]',
    shape VARCHAR NOT NULL,                      -- the join's shape, e.g. '4,10'
    survivors BIGINT NOT NULL, checked BIGINT NOT NULL, slices BIGINT NOT NULL,
    matches_canon BOOLEAN,                       -- NULL on the canon; false = a recorded disagreement
    telemetry JSONB);
CREATE TABLE midout_job_state (id INTEGER PRIMARY KEY CHECK (id = 1), last_submission_id BIGINT NOT NULL);
INSERT INTO midout_job_state VALUES (1, 0);
CREATE INDEX idx_midout_fields_cl0 ON midout_fields(base_id, id) WHERE check_level = 0;
CREATE INDEX idx_midout_fields_chunk ON midout_fields(chunk_id);
CREATE INDEX idx_midout_submissions_field ON midout_submissions(field_id);
CREATE INDEX idx_midout_submissions_numbers ON midout_submissions(id) WHERE numbers <> '[]';
CREATE INDEX idx_midout_submissions_disagree ON midout_submissions(field_id) WHERE matches_canon = false;
GRANT SELECT ON midout_bases, midout_chunks, midout_fields, midout_claims, midout_submissions TO web_anon;
COMMIT;
```

**`midout_bases`** says that a base is searched this way, and in which coordinate. The coordinate is data, not
schema, so the field definition is not locked in.
- The composite foreign key from `midout_fields` makes the database refuse a coordinate change while any field of
  the base exists.
- Changing the coordinate later takes:
  - before insertion: nothing;
  - after insertion, before the first claim: deleting and re-inserting the base's chunks and fields (seconds);
  - after the first accepted submission: deleting that work and redoing it, because fields cut along other digits
    are not unions of searched fields (middle-out design document §3, item 1). The key makes this deliberate.
- A new quantum or field size in the same coordinate is no schema change: unclaimed rows can be merged or split.
- The `bases` row is still inserted, for the key and so the public `bases` endpoint lists the base.

**`midout_chunks`** is the progress unit. It keeps the column names of `chunks` (`schema/schema.sql:29–42`), so
the site's completion chart draws it with the same code.
- Its ranges are in v, so "searched up to n = X" is never claimed for a midout base.
- `checked_twice` replaces `checked_detailed`, which has no meaning here.
- It cannot live in `chunks`, which the jobs recompute from `fields` (`fields.rs:1162–1215`) and would zero.

**`midout_fields`** has one row per field.
- **Identity:** `base_id, coordinate, v_start, v_size`, which is what a claim hands out and what a submission must
  repeat. Copying `coordinate` onto the row lets every claim and submission name its field by value.
- `UNIQUE (base_id, v_start)` refuses duplicate fields. No code updates the identity columns; a 10-line trigger
  refusing such updates is an option.
- `n_count` is what progress and credit sum. `chunk_id` makes progress incremental. `last_claim_time` gives claim
  expiry as in `fields`, and `canon_submission_id` is the first accepted submission.
- **`check_level`** keeps today's 0 (unsearched) and 1 (one accepted submission), and uses 2 for a second,
  agreeing submission.
  - This departs from `fields`, where 2 means one detailed search, because midout has no detailed form.
  - The scale appears only in midout tables. The site's colours (`index.html:535–539`) still read: searched, then
    checked.

**`midout_claims`** ids start at 10^15. Production's claim sequence, at about 58 submissions/s
(`jobs/src/main.rs:47`), will not get there for centuries.
- So a midout id posted to `/submit` fails with "Invalid claim_id" (`main.rs:330–332`) and is never recorded
  against a nice-only field.
- There is no `search_mode` column: the table is the mode.

**`midout_submissions`** holds accepted submissions only. Refused ones get a 4xx and no row, as on `/submit` today.
- `UNIQUE (claim_id)` makes a resubmission idempotent.
- The counters and `shape` are columns, because they are a deterministic function of (shape, field). Two searches
  of a field are then compared without parsing JSON.
- `matches_canon` records a disagreement on the row itself, and a partial index lists the disagreements. The
  `numbers` partial index makes "nice numbers found" cheap.
- `midout_job_state` is its own table so that `job_state` is not altered.

## 3. Endpoints

**`GET /claim/midout`** answers with the dev branch's `CoordClaim`, unchanged, so `field_of` checks it as now.
`range_*` are in v, and `range_size` is `n_count`:

```json
{"claim_id": 1000000000000417, "base": 64, "coordinate": "midout:4,8,5", "range_start": 37778931862957161709568,
 "range_end": 37779075978145237565440, "range_size": 144115188075855872}
```

The status is 200, or 204 when nothing is claimable (the dev client already reads 204 as "none left",
`wire.rs:15–16`), or 503 when the database is unavailable (`main.rs:71–79`). The claim is one transaction:

```sql
WITH c AS (SELECT id FROM midout_fields
           WHERE check_level = 0 AND (last_claim_time IS NULL OR last_claim_time <= $1)  -- $1 = now - 1 h
           ORDER BY base_id, id FOR NO KEY UPDATE SKIP LOCKED LIMIT 1)
UPDATE midout_fields f SET last_claim_time = NOW() FROM c WHERE f.id = c.id RETURNING f.*;
INSERT INTO midout_claims (field_id, user_ip) VALUES ($field, 'unknown') RETURNING id;
```

**Expiry and reissue.** After `CLAIM_DURATION_HOURS` the field is claimable again. A lost claim reply or a dead
client delays one field by at most an hour; the development coordinator needed a manual `--reissue-after` for this.
A base-64 field takes about 30 s on a 3080 (`route.rs:68–72`, dev).

**`POST /submit/midout`** (big integers as decimal strings, as the dev client sends them):

```json
{"claim_id": 1000000000000417, "username": "...", "client_version": "3.5.0",
 "field": {"base": 64, "coordinate": "midout:4,8,5", "v_start": "37778931862957161709568",
           "v_size": "144115188075855872", "range_size": "144115188075855872"},
 "nice_numbers": [], "shape": "4,10", "survivors": 0, "checked": 0, "slices": 4096, "telemetry": {}}
```

The checks, in order. The right-hand column is what went wrong without each one when the development coordinator
was tested under faults:

| check | status | without it |
|---|---|---|
| body parses, integer `claim_id`, within the size limit; telemetry over 16 KB **refused, not dropped** | 400 / 413 | junk bodies were accepted unseen |
| claim id in `midout_claims` | 404 | a reused or foreign id records another field |
| `field` equals the claim's row (base, coordinate, v_start, v_size, n_count) | 422 | another field's body under a known claim marks an unsearched field as searched |
| every nice number lies in the field (`coord.rs` digits) and is nice (as `main.rs:420–428`) | 422 | never checked by the coordinator; detailed submissions get it today |
| counters present and `slices` equals the field's slice count | 422 | an all-zero result is legal, so a body without evidence of the work would pass |
| same claim again: identical body → 200 with the stored id; different body → 409 | 200 / 409 | a lost reply after acceptance stops the client, or records twice |
| field at level 0 → canon, level 1, even if its claim expired (a late but real search) | 200 | a legitimate late result is thrown away |
| field already searched → stored as a check. `matches_canon` = same nice numbers and, if the `shape` is the same, the same counters. Agreement → level 2 | 200 | two canons, or an unseen disagreement |

The database covers the coordinator's remaining failure classes. The row and the field update commit before the
reply, so an acknowledged record is never lost. A failed write rolls back and answers 503, so memory never runs
ahead of disk. There are no state files to tear. Two instances share one database under `SKIP LOCKED`.

The reply is `{"submission_id": N, "status": "canon" | "check" | "already_recorded"}`. Double-checking exists in
the schema from the start; whether the server ever reissues searched fields on purpose is decision 3.

**The client:**
- `SearchMode` gains `Midout` (`lib.rs:60–66`), so `nice_client midout` shows in `--help`
  (`client/src/main.rs:236–238`). The compiler then flags each match on the mode: `client_api_async.rs:114–117`,
  `main.rs:833–850`, `db_util/conversions.rs:115–128`, `estimator.rs:117–123`.
- The new tables never store the mode as a string.
- The mode runs the dev route's loop (`midout_route.rs:221–316`, dev) against the two paths, without the dev guard
  against the production API (`wire.rs:136–154`, dev).
- It treats `already_recorded` as success. The dev client exits on any 4xx (`client_api_async.rs:153–160`), and
  answering checks with 200 keeps 4xx rare.

## 4. What the database pays

| query | index | rows touched |
|---|---|---|
| claim: select + update (above) | `idx_midout_fields_cl0` (base_id, id) | live claims at the index front (about the number of cards) + 1 |
| claim: insert | primary key | 1 |
| submit: claim, field, existing submission | primary and unique keys | 3 |
| submit: insert, field update | primary key | 2, plus 1 canon read for a check |

**Load.** About one claim and one submission per card every 30 s. 150 cards make about 10 requests/s, against
about 58 submissions/s that the API takes today.

**No pre-claim queue.**
- The nice-only queue exists because a direct claim cost 90 ms against 130M rows (`CHANGELOG.md:225`). Here the
  claim index holds at most b³ rows, it shrinks as fields complete, and the walk is bounded by the live claims.
- Without a queue, #264's defect, a field outliving the claim window while queued and then handed out twice
  (`CHANGELOG.md:29`, `api/src/field_queue.rs:341–365`), cannot occur.
- #238's runaway direct claim, which ran 21 h and pinned the frontier (`CHANGELOG.md:30`), cannot recur either:
  there is no frontier-chunk search, no sort beyond index order, and the 30 s timeout covers every API connection.
- **Check before deploy:** EXPLAIN on a copy with base 64 inserted, half claimed and half done. It must be an index
  scan on `idx_midout_fields_cl0` under `SKIP LOCKED`, under 1 ms.

**Storage.**
- Fields are about 120 B a row: 32 MB of heap plus 25 MB of indexes per base. Claims are about 60 B.
- Submissions are about 1.7 kB, the body being about 1.5 kB in development runs: about 0.45 GB per base, doubled
  under full double-checking.
- Each field row is updated twice and leaves the claim index once.

**Scheduled jobs (`jobs/src/main.rs`).**
- **The fix.** The existing loop visits every base (`:126–133`). In `--full` mode it rewrites each base's progress
  from its `chunks` (`:317–337`), which for a base with no chunks gives 0 and `minimum_cl = 255`
  (`db_util/chunks.rs:202–206`).
  - One filter, "skip bases with a `midout_bases` row", fixes it.
  - Incremental runs already skip them, because they have no `submissions`.
- **The new midout pass** runs after the existing work, in the same window-and-cursor transaction as
  `cache.rs:58–84`:
  1. Read midout submissions with ids in (cursor, max − 10,000] by primary key. The margin is
     `WATERMARK_SAFETY_MARGIN` (`:53`); windows are at most `MAX_CACHE_WINDOW` (`cache.rs:24`).
  2. Recompute the dirty `midout_chunks`: one `GROUP BY` over each dirty chunk's ≈ 2,622 fields via
     `idx_midout_fields_chunk`. Claims run in id order, so an hour dirties one or two chunks, about 5k rows.
  3. Write `bases.checked_niceonly` and `minimum_cl` for each midout base from its ≈ 100 chunks. Base 64's progress
     is then on the public `bases` endpoint.
  4. Add the window to `cache_search_daily_totals` as `search_mode = 'midout'`, `total_range = n_count`, and
     advance `midout_job_state` in the same transaction.
- **`--full`.** Its rebuild deletes every daily total (`cache.rs:96`), so it must also re-add the midout
  submissions, or midout credit vanishes. It then recomputes all midout chunks. That is one read of
  `midout_fields` (≈ 55 MB) and of `midout_submissions` (≈ 0.45 GB per base): the same kind of cost as today's
  `--full`, run as rarely.
- **No change:**
  - the hourly `refresh_search_caches` (`cache.rs:110–138`) reads only the totals and `bases`, so midout costs it
    nothing;
  - notable numbers come from `bases.numbers`, which nice-only searches never feed (`jobs/src/main.rs:338`).

**Public data API and site, with no new views.**
- **Progress:** `bases?id=eq.64` (`checked_niceonly` against `range_size`), and `midout_chunks` for the completion
  chart. That is one fetch beside `index.html:69–71`, drawn by `buildCompletionChart` with the caption "base 64 is
  searched by slices of digits 5–7, not in n order".
- **Credit:** the cache tables carry mode `midout`, and the site's two mode filters (`:558, 595`) decide where it
  shows (decision 4).
- **Nice numbers:** `midout_submissions?numbers=neq.[]`, served by its partial index.
- **Exposure:** PostgREST exposes the new tables exactly as it exposes `fields`, `claims` and `submissions`
  (`schema.sql:101–107`). A full anonymous read of `midout_submissions` costs what one of `submissions` does today,
  on about 1/500 the size.

## 5. Rollout (each step with its undo)

1. **Migration.** Only `CREATE TABLE`/`INDEX`/`GRANT`; the key to `bases` locks that tiny table for a moment. Apply
   it between scheduled runs. *Undo:* drop the six tables and the sequence.
2. **API with the two endpoints.** No current client calls them, and with no `midout_bases` rows the claim answers
   204. *Undo:* redeploy the previous binary.
3. **Jobs with the skip and the midout pass.** These are inert without midout rows. Deploy them before any
   insertion, so the skip is in place before base 64 has a `bases` row. *Undo:* redeploy, then run `--full` once.
4. **Insertion by a new `scripts/insert_midout_fields.rs`.**
   - It writes the `bases` row, the `midout_bases` row, about 100 chunks and the fields, in batches of 10,000 as
     `insert_fields` does (`fields.rs:88–105`). Each field is checked by `Coord::field_digits` and `n_count`.
   - It needs `coord.rs` on main first; that is pure arithmetic, with no GPU dependency.
   - *Undo before the first claim:* delete the rows.
5. **First claims from the maintainer's own machine,** with a client built from the release branch.
   - Until the release is published, no other client has the mode.
   - Watch that every canon submission has counters and `slices = 4096`, the claim plan, and one hourly jobs run
     (one dirty chunk, base 64's `bases` row, the totals).
   - *Undo:* delete the base's midout rows; only the maintainer's own work is lost.
6. **Client release.** The fleet controller then chooses a mode per box.
   - Base 62's nice-only work continues through `/claim/niceonly`, unchanged. It shares no table, queue or claim id
     with midout.
   - Once base 62 runs out, that endpoint answers 500 "Could not find any niceonly field!" (`main.rs:216`), as it
     would today.

**Backfilling development-coordinator results is recommended against.**
- What it holds so far is test runs. Some use the earlier coordinate (`midout:4,9,6`) or an earlier wire form that
  its own audit tool flags.
- Re-searching a field costs about 30 s.
- If a production-quality coordinator run ever comes first:
  - accept its state only if the audit tool exits 0;
  - insert one claim and one submission per accepted record, with the original times and `client_version`, marked
    `"backfilled": true` in telemetry;
  - do this before anyone else can claim.

## 6. Tests

All of the following run against a real PostgreSQL, skipped unless `NICE_TEST_DATABASE_URL` is set, in the
existing pattern (`common/tests/claim_queries.rs:1–25`), with 8-thread concurrency tests as in
`api/src/field_queue.rs:499–512`. CI has no PostgreSQL, so they run by hand, as today.

- **`common/tests/midout_queries.rs`:**
  - claim order (lowest base, then lowest id);
  - 8 threads × 100 claims never hand out a field twice;
  - an aged claim frees its field, and a live claim holds it;
  - the scan stays bounded when the base's front is all live claims;
  - overlapping inserts are refused;
  - a coordinate change fails while fields exist.
- **Submit, one test per row of the §3 table:**
  - cross-claim body, other coordinate, string id, unknown id, a midout id sent to `/submit`;
  - oversized telemetry, a number outside the field, a non-nice number, missing counters;
  - an identical resubmission (same id back) and a different one (409);
  - a late submission after a reissue (becomes canon);
  - an agreeing check (level 2) and a disagreeing one (`matches_canon = false`, level unchanged).
- **Jobs:**
  - an incremental run equals `--full` on the same data;
  - each midout submission is counted once across windows;
  - `--full` keeps midout credit and leaves base 64's `bases` row as the midout pass wrote it.
- **Pure unit tests, no database:** the body-against-field validator, and nice-number membership via `Coord`.
- **The client mode, as the maintainer set it:**
  - lavapipe and CPU-reference runs against an ephemeral local API and database;
  - owned or rented cards for key PRs and releases.
- **Only testable on the real database or a copy:**
  - the claim plan at production statistics;
  - the migration's lock on `bases` under load;
  - the jobs' window plans beside today's 130M-row tables;
  - PostgREST's schema reload and grants on the live host.

## 7. Open sub-decisions (options; recommendation; *default if unanswered*)

1. **Field size: one quantum per row, or k quanta per row.**
   - At one quantum a field is about 30 s on a 3080 (56 s at base 65).
   - Recommendation: one quantum. Rows are cheap, a lost claim wastes less, and an audit samples finer.
   - Changing it later is a data change on unclaimed rows, not a schema change.
   - *Default: one quantum.*
2. **Insertion: per base by script, or generated on demand from a cursor.**
   - Recommendation: the script. Every query stays a plain indexed read, progress has a denominator, and it mirrors
     `insert_new_fields.rs`.
   - On demand saves 55 MB but still needs progress rows.
   - *Default: script.*
3. **Double-check policy.** Options:
   - (a) record checks that arrive on their own (late submissions after a reissue), and never reissue on purpose;
   - (b) serve a fraction of claims from level-1 fields that another user searched, like detailed's 5 % recheck
     (`main.rs:175–176`);
   - (c) refuse second submissions with 409, as the coordinator did.

   Recommendation: (a) now, and (b) later as a server-only change once there is data. The client's sampled CPU
   check already tests one slice of every field. *Default: (a).*
4. **Credit.** Options:
   - (i) `n_count` per accepted submission under mode `midout`, shown inside the site's nice-only rate chart and
     leaderboard (filter `niceonly` or `midout`);
   - (ii) the same, but in its own chart;
   - (iii) credit the canon submission only.

   Recommendation: (i). It credits every accepted submission as today (`cache.rs:29–37`), it is a nice-only
   search, and users see one number. *Default: (i).*
5. **Submit body.**
   - Options: the typed body in §3 (`field`, counters and `shape` at top level), or the dev client's
     `DataToServer` with the field inside `telemetry.pipeline`.
   - Recommendation: typed. The field's identity then does not ride in a blob that `/submit` drops when large, and
     the counters become columns. It costs about 20 lines in the client route.
   - *Default: typed.*

## 8. What could not be determined by reading

- **Production numbers.** Table sizes, and the current maximum `claims.id` (10^15 is assumed far above it).
- **Bases above 62.** Whether any base above 62 (63, say) already has rows in `fields`. If one does, old nice-only
  clients would be handed them.
- **Outside readers.** Whether anything outside the repository reads `bases.minimum_cl` or `checked_niceonly` for a
  base without chunks.
- **Deployed configuration.** PostgREST's row limits and whether its schema cache reloads itself. The API's request
  size limit: there is no `Rocket.toml`, so Rocket's default is assumed.
- **Fleet size.** How many cards will run midout, and so the real claim rate. Only the per-card rate is measured.
- **Measured versus estimated.** Field time and submission size come from development runs, not production. Row
  sizes are estimated from column widths, not measured with `pg_column_size`.
- **Merge form.** Whether `coord.rs` merges in its present form. Its header says no server stores it yet
  (`coord.rs:78–79`, dev).
