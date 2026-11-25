# The middle-out mode on the server: tables, endpoints, cost, rollout (proposal, 2026-11-25)

References are file:line on `origin/main` at `fdbe07d3`, or *(dev)* for branch `dev/mo-clean` at `66305ada`.
Nothing here has been built or run.

## Summary

- **Added:** five tables (`midout_bases`, `midout_chunks`, `midout_fields`, `midout_claims`,
  `midout_submissions`) and a one-row cursor table, with indexes and read grants; `GET /claim/midout` and
  `POST /submit/midout`; a midout pass in the scheduled jobs; an insertion script; the client mode
  `nice_client midout`, shown in `--help`.
- **Untouched:** no existing table gains a column, constraint or index (the only new rows elsewhere: one `bases` row
  per midout base); the detailed and nice-only claim paths, `/submit`, their queues, consensus and chunk statistics.
  Old clients never call the new paths.
- **Cost:** per base about 55 MB of fields and indexes and 0.45 GB of submissions, against a `fields` table of 130M
  rows with a 7 GB primary key (`common/src/db_util/fields.rs:244, 290`). Per field, one index-bounded claim and four
  primary-key writes, no queue in memory. Scheduled work reads only new midout submissions and dirty chunks.
- **Two existing paths change:** the jobs' per-base loop must skip midout bases, or `--full` zeroes their `bases` row
  (§4); the site needs one more fetch and a wider mode filter.
- **To decide (§7):** field size, insertion, double-check policy, credit display, submit body. Each has a default.

## 1. Facts this rests on

- The nice-only claim takes the lowest-id claimable field at `check_level = 0` with no base filter
  (`api/src/main.rs:162–166`, `fields.rs:699–745`): "niceonly will not be dispensed past b62" holds only while
  `fields` has no base-64 row, which option B guarantees. `scripts/insert_new_fields.rs:119–121` refuses a base that
  already exists, so once base 64 has its `bases` row no one can add n-fields for it by mistake.
- `/submit` looks the claim id up in `claims` (`main.rs:330–332`) and takes a nice-only body unchecked
  (`main.rs:346–370`); a midout claim id posted there would land on an unrelated field, hence a separate path and
  disjoint ids. It also drops telemetry over 16 KB silently (`main.rs:29, 308–315`). Claims last 1 h
  (`common/src/lib.rs:51`); API statements time out after 30 s (`common/src/db_util/mod.rs:48–99`).
- `fields.check_level`: 0 unsearched, 1 nice-only (`main.rs:360–369`), 2 one detailed (`main.rs:442–453`), k+1 for
  k agreeing detailed (`common/src/consensus.rs:68`). Credit: each non-disqualified submission earns its field's
  `range_size` per (day, mode, user) (`common/src/db_util/cache.rs:29–37`); `--full` rebuilds those totals from
  `submissions` alone (`cache.rs:91–104`). The site reads `chunks` (`web/index.html:69–71`) and the cache tables
  filtered to `detailed`/`niceonly` (`index.html:558, 595, 630–637`), never `bases`.
- A field (dev) is `(base, v_start, v_size)` in coordinate `midout:K0,K1,Q0`, in whole quanta, holding `n_count` n
  (`common/src/midout/coord.rs:48–61, 283–301, 307–329`). The claim is `CoordClaim` (`common/src/midout/wire.rs:41–52`),
  checked by `field_of` (`client/src/midout_route.rs:96–130`); the submission carries
  `telemetry.pipeline.{route, coordinate, field}` (`midout_route.rs:280–306`).
- A one-quantum field fixes three digits, so a base has b³ fields: base 64 has 262,144 of 2^57 n, unpadded; base 65
  has 274,625, padded at the edges of h, so some have `n_count < v_size` (`coord.rs:37–44`). k quanta per row
  divide this by k. Only a coordinate fixing four digits would make it matter (b⁴: 16.8M rows, ~1.5 GB at base 64).

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
    disqualified BOOLEAN NOT NULL DEFAULT 'false', numbers JSONB NOT NULL DEFAULT '[]',
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

**`midout_bases`** marks a base as searched this way and holds its coordinate as data, not schema, so the field
definition is not locked in. The composite foreign key from `midout_fields` makes the database refuse a coordinate
change while the base has any field. Changing it later costs nothing before insertion; seconds before the first
claim (delete and re-insert the base's rows); after the first accepted submission, redoing that work, because fields
cut along other digits are not unions of searched fields (middle-out design document §3, item 1). Field size and
quantum within one coordinate are not schema at all: unclaimed rows can be merged or split. The base keeps its
`bases` row, for the key and for the public `bases` endpoint.

**`midout_chunks`** are the progress rows, with the column names of `chunks` (`schema/schema.sql:29–42`) so the
completion chart draws them with the same code. Their ranges are in v, so they never claim "searched up to n = X";
`checked_twice` replaces `checked_detailed`. They cannot live in `chunks`, which the jobs recompute from `fields`
(`fields.rs:1162–1215`).

**`midout_fields`.** `base_id, coordinate, v_start, v_size` are the identity: what a claim hands out and a
submission must repeat, so every record names its field by value. `UNIQUE (base_id, v_start)` refuses duplicates and
the insertion script refuses overlaps; no code updates these columns (a 10-line trigger could enforce it). `n_count` is what progress and credit sum,
`chunk_id` makes progress incremental, `last_claim_time` gives expiry as in `fields`, and `canon_submission_id` is
the first accepted submission. **`check_level`** keeps today's 0 (unsearched) and 1 (searched once) and uses 2 for
a second, agreeing submission. That departs from `fields`, where 2 means a detailed search, which midout does not
have. The scale lives only in midout tables, and the site's colours (`index.html:535–539`) still read "searched",
then "checked".

**`midout_claims`** ids start at 10^15. Production's claim ids grow with about 58 submissions/s
(`jobs/src/main.rs:47`), so they will not get there for centuries, and a midout id posted to `/submit` fails
"Invalid claim_id" (`main.rs:330–332`) instead of landing on a nice-only field.

**`midout_submissions`** holds accepted submissions only; a refused one gets a 4xx and no row, as `/submit` does
today. `UNIQUE (claim_id)` makes a resubmission idempotent. The counters and `shape` are columns: they are
deterministic in (shape, field), so two searches compare without JSON. `matches_canon` records a disagreement.
Partial indexes list disagreements and nice numbers cheaply.
`midout_job_state` holds the jobs' cursor, in its own table so that `job_state` is not altered.

## 3. Endpoints

**`GET /claim/midout`** returns the dev branch's `CoordClaim` unchanged, so `field_of` checks it as it does now
(`range_*` in v, `range_size` = `n_count`). It answers 200, 204 when nothing is claimable (the dev client reads
that as "none left", `wire.rs:15–16`), or 503 when the database is unavailable (`main.rs:71–79`).

```json
{"claim_id": 1000000000000417, "base": 64, "coordinate": "midout:4,8,5", "range_start": 37778931862957161709568,
 "range_end": 37779075978145237565440, "range_size": 144115188075855872}
```

```sql
WITH c AS (SELECT id FROM midout_fields
           WHERE check_level = 0 AND (last_claim_time IS NULL OR last_claim_time <= $1)  -- $1 = now - 1 h
           ORDER BY base_id, id FOR NO KEY UPDATE SKIP LOCKED LIMIT 1)
UPDATE midout_fields f SET last_claim_time = NOW() FROM c WHERE f.id = c.id RETURNING f.*;
INSERT INTO midout_claims (field_id, user_ip) VALUES ($field, 'unknown') RETURNING id;   -- same transaction
```

**Expiry and reissue:** after `CLAIM_DURATION_HOURS` the field is claimable again, so a lost reply or a dead client
costs at most an hour on one field (the development coordinator needed a manual `--reissue-after`). A base-64
field takes about 30 s on a 3080 (`route.rs:68–72`, dev).

**`POST /submit/midout`.** Big integers go as decimal strings, as the dev client already sends them:

```json
{"claim_id": 1000000000000417, "username": "...", "client_version": "3.5.0",
 "field": {"base": 64, "coordinate": "midout:4,8,5", "v_start": "37778931862957161709568",
           "v_size": "144115188075855872", "range_size": "144115188075855872"},
 "nice_numbers": [], "shape": "4,10", "survivors": 0, "checked": 0, "slices": 4096, "telemetry": {}}
```

The checks run in order. The last column is what went wrong without each one when the development coordinator was
tested under faults:

| check | status | without it |
|---|---|---|
| parses; integer `claim_id`; size limit; telemetry over 16 KB **refused, not dropped** | 400 / 413 | junk accepted unseen |
| claim id is in `midout_claims` | 404 | a reused or foreign id records another field |
| `field` equals the claim's row (base, coordinate, v_start, v_size, n_count) | 422 | another field's body marks an unsearched field done |
| each nice number is in the field (`coord.rs`) and is nice (as `main.rs:420–428`) | 422 | the coordinator never checked; detailed gets this today |
| counters present; `slices` = the field's slice count | 422 | an all-zero result is legal, so no evidence of work would pass |
| same claim again: identical → 200 with the stored id; different → 409 | 200 / 409 | a lost reply stops the client, or records twice |
| field at level 0 → canon, level 1, even after its claim expired | 200 | a late but real result is lost |
| field already searched → stored as a check, `matches_canon` = same numbers (and counters, if same `shape`); agreeing → level 2 | 200 | two canons, or an unseen disagreement |

Committing before replying covers the coordinator's remaining failure classes (lost acknowledged records, memory
ahead of disk: a failed write rolls back and answers 503, two instances: one database under `SKIP LOCKED`). The
reply is `{"submission_id": N, "status": "canon" | "check" | "already_recorded"}`.

**Client:** `SearchMode` gains `Midout` (`lib.rs:60–66`), which puts `nice_client midout` in `--help`
(`client/src/main.rs:236–238`); the compiler then flags each match on the mode (`client_api_async.rs:114–117`,
`main.rs:833–850`, `db_util/conversions.rs:115–128`, `estimator.rs:117–123`). The mode runs the dev route's loop
(`midout_route.rs:221–316`, dev) against the new paths, without the dev guard that refuses the production API
(`wire.rs:136–154`, dev), and treats `already_recorded` as success: the dev client exits on any 4xx
(`client_api_async.rs:153–160`).

## 4. What the database pays

| query | index | rows touched |
|---|---|---|
| claim: select + update | `idx_midout_fields_cl0` (base_id, id) | the live claims at the index front (≈ cards) + 1 |
| claim insert; submit reads (claim, field, prior submission) | primary or unique key | 1; 3 |
| submit: insert, update field | primary key | 2, plus 1 canon read for a check |

**Load and storage.** About one claim and one submission per card every 30 s: 10 requests/s at 150 cards, against
the 58 submissions/s the API takes today. Fields are about 120 B a row (32 MB heap + 25 MB indexes per base), claims
about 60 B, submissions about 1.7 kB (0.45 GB per base; double that under full double-checking).

**No pre-claim queue.** The nice-only queue exists because a direct claim cost 90 ms against 130M rows
(`CHANGELOG.md:225`); this claim's index holds at most b³ rows, shrinks as fields finish, and its walk is bounded by
the live claims. Without a queue, #264's defect (a field outliving its claim while queued, then handed out twice;
`CHANGELOG.md:29`, `api/src/field_queue.rs:341–365`) cannot happen, nor #238's runaway direct claim
(`CHANGELOG.md:30`): no frontier search, no sort beyond index order, and the 30 s timeout applies. Before deploy,
EXPLAIN it on a copy with base 64 half claimed and half done: an index scan, under 1 ms, is expected.

**Scheduled jobs (`jobs/src/main.rs`).** The existing loop visits every base (`:126–133`) and under `--full`
rewrites each base's progress from its `chunks` (`:317–337`), which for a chunkless base yields 0 and
`minimum_cl = 255` (`db_util/chunks.rs:202–206`). One filter fixes it: skip bases with a `midout_bases` row
(incremental runs already skip them, having no `submissions`). The new midout pass uses the window-and-cursor
transaction of `cache.rs:58–84`:
1. read midout submissions in (cursor, max − 10,000] by primary key (the margin of `WATERMARK_SAFETY_MARGIN`, `:53`;
   windows of at most `MAX_CACHE_WINDOW`, `cache.rs:24`);
2. recompute dirty chunks: one `GROUP BY` over each chunk's ≈ 2,622 fields via `idx_midout_fields_chunk`; claims go
   in id order, so an hour dirties one or two chunks (about 5k rows);
3. write each midout base's `bases.checked_niceonly` and `minimum_cl` from its ≈ 100 chunks;
4. add the window to `cache_search_daily_totals` as mode `midout`, `total_range = n_count`, and advance the cursor.

`--full` deletes every daily total (`cache.rs:96`), so it must re-add midout submissions too, and it recomputes every
midout chunk: one read of `midout_fields` (≈ 55 MB) and `midout_submissions` (≈ 0.45 GB), as rare as today's
`--full`. The hourly `refresh_search_caches` (`cache.rs:110–138`) needs no change; notable numbers come from
`bases.numbers`, which nice-only results never feed (`jobs/src/main.rs:338`).

**Public data API and site, with no new views.** Progress: `bases?id=eq.64`, and `midout_chunks` for the completion
chart (one fetch beside `index.html:69–71`, drawn by `buildCompletionChart`, captioned "base 64 is searched by
slices of digits 5–7, not in n order"). Credit: the cache tables carry mode `midout`; the site's filters
(`:558, 595`) choose where it shows. Nice numbers: `midout_submissions?numbers=neq.[]` on its partial index.
PostgREST exposes the tables as it does `fields`, `claims` and `submissions` (`schema.sql:101–107`).

## 5. Rollout (each step with its undo)

1. **Migration.** It only creates tables and grants access. The foreign key locks the small `bases` table
   briefly, so apply it between scheduled runs. *Undo:* drop the tables and the sequence.
2. **API.** No current client calls the new endpoints, and while no midout bases exist the claim answers 204.
   *Undo:* redeploy the previous binary.
3. **Jobs.** The skip and the midout pass are inert until midout rows exist. Deploy them before any insertion.
   *Undo:* redeploy, then run `--full`.
4. **`scripts/insert_midout_fields.rs`.** It writes the `bases`, `midout_bases`, chunk and field rows in batches of
   10,000, like `insert_fields` (`fields.rs:88–105`). It checks each field with `Coord::field_digits` and `n_count`,
   so `coord.rs` must reach main first. *Undo, before any claim:* delete the rows.
5. **First claims, from the maintainer's own machine,** on a release-branch build. No other client has the mode
   yet. Watch three things: that canons carry counters with `slices = 4096`, the claim plan, and one hourly jobs
   run. *Undo:* delete the base's claims and submissions and reset its fields to level 0.
6. **Client release.** The fleet controller picks a mode per box. Base 62's nice-only work continues through
   `/claim/niceonly`, sharing no table, queue or claim id with midout; when it runs out, that endpoint answers 500
   "Could not find any niceonly field!" (`main.rs:216`), as today.

**Backfill: recommended against.** The development coordinator holds test runs, some in the earlier coordinate
(`midout:4,9,6`) or an earlier wire form its own audit tool flags, and redoing a field costs about 30 s. If a
production-quality run ever comes first: accept it only if the audit tool exits 0, insert one claim and one
submission per accepted record with the original times and `"backfilled": true` in telemetry, and do it before
anyone else can claim.

## 6. Tests

In the existing pattern: real PostgreSQL, skipped unless `NICE_TEST_DATABASE_URL` is set
(`common/tests/claim_queries.rs:1–25`), concurrency at 8 threads as in `api/src/field_queue.rs:499–512`; CI has no
PostgreSQL, so they run by hand.
- `common/tests/midout_queries.rs`: claim order; 8 threads × 100 claims never share a field; aged claims freed,
  live ones held; the scan stays bounded when the front is all live claims; overlapping inserts refused; a
  coordinate change refused while fields exist.
- Submit: one test per row of the §3 table, plus a midout id sent to `/submit`.
- Jobs: incremental equals `--full`; each submission counted once across windows; `--full` keeps midout credit and
  base 64's `bases` row. Unit tests: the body-against-field validator; nice-number membership via `Coord`.
- Client mode, as the maintainer set it: lavapipe and CPU-reference runs against a local API and database, then
  owned or rented cards for key PRs and releases.
- Only on the real database or a copy: the claim plan at production statistics, the migration's lock under load,
  the jobs' plans beside 130M-row tables, PostgREST's schema reload.

## 7. Open sub-decisions (options; recommendation; *default if unanswered*)

1. **Field size:** one quantum per row, or k quanta. Recommend one quantum (about 30 s on a 3080, 56 s at base 65):
   rows are cheap, a lost claim wastes less, audits sample finer; it can change later on unclaimed rows. *Default:
   one quantum.*
2. **Insertion:** per base by script, or generated on demand from a cursor. Recommend the script: plain indexed
   reads, a denominator for progress, mirrors `insert_new_fields.rs`; on demand saves 55 MB but still needs
   progress rows. *Default: script.*
3. **Double-checking:** (a) record checks that arrive on their own (late submissions); (b) also serve a share of
   claims from level-1 fields searched by another user, like detailed's 5 % recheck (`main.rs:175–176`); (c) refuse
   second submissions with 409. Recommend (a) now, (b) later as a server-only change; the client's sampled CPU check
   already covers one slice of every field. *Default: (a).*
4. **Credit:** `n_count` per accepted submission as mode `midout`, shown (i) inside the site's nice-only charts or
   (ii) in its own; or (iii) canon only. Recommend (i): today's rule (`cache.rs:29–37`), a nice-only search, one
   number for users. *Default: (i).*
5. **Submit body:** typed (§3), or the dev client's `DataToServer` with the field in `telemetry.pipeline`.
   Recommend typed: the field's identity never rides in a blob that is dropped when large, and the counters become
   columns; about 20 client lines. *Default: typed.*

## 8. What could not be determined by reading

- Production table sizes beyond what the public data API shows. Read there on 2026-11-25 (four single-row
  requests): the highest base with rows is 62, so no base above 62 is in `fields` and old nice-only clients
  cannot be handed one; the highest `claims.id` is 302,505,123 (10^15 is far above it); the highest `fields.id` is
  207,159,539 (the 130M-row figure above is the code comment's and is out of date).
- Whether anything outside the repository reads `bases.minimum_cl`/`checked_niceonly` for a base with no chunks.
- PostgREST's row limits and schema-cache reload; the API's request-size limit (no `Rocket.toml`: default assumed).
- How many cards will run midout (only the per-card rate is known). Field time and submission size come from
  development runs; row sizes are estimates from column widths.
- Whether `coord.rs` merges as it stands; its header says no server stores it yet (`coord.rs:78–79`, dev).

## 9. Questions raised by building the client against §3 (added 2026-11-25; each with what is built, a recommendation, and *the default if unanswered*)

The client mode now exists on the fork branch `dev/mo-mode` and speaks §3 against a development server. Building
it exposed thirteen points §3 leaves open (`G2/MODE-NOTES.md` §6 has all of them). The seven that change the wire:

1. **Big integers.** §3 sends them as JSON numbers in the claim (as `/claim/niceonly` does today) and as decimal
   strings in the submit. Numbers above 2^53 are read as doubles by JavaScript, `jq` and most tools. Built: as
   written. Recommend strings in both directions for the new endpoints, the client accepting either. *Default: as
   written.*
2. **`nice_numbers`.** The element type is not given (the example is empty). Built: decimal strings (`["69"]`).
   Recommend that. *Default: strings.*
3. **Which shape counts the slices.** "`slices` equals the field's slice count" depends on the join's shape, which
   the client sends. Built: the count under the submitted shape. Recommend one shape per base, stored in
   `midout_bases`, and a 422 for any other: counters of a canon and its check are then always comparable, and a
   change of shape is one row updated with a client release. *Default: as built (any valid shape).*
4. **What "the same submission again" means.** Built: everything but the telemetry. Recommend that. *Default: as
   built.*
5. **A 404 on submit means two things:** an unknown claim, and a server without the endpoint. Recommend a JSON
   error body with a short code on every 4xx (`{"error": "unknown_claim", "message": …}`), as the other endpoints'
   `ApiErrorBody` does. *Default: plain 404, the client stops either way.*
6. **A check that disagrees with its canon** is answered `check`, like one that agrees, so the client cannot say
   so in its log. Recommend adding `"matches_canon": true | false` to the reply. *Default: not added.*
7. **A 503 on the claim** is retried on the usual ladder (about nine minutes at the default) and then the client
   exits, as the other modes do; a 204 waits for ever under `--repeat`. Should a `midout` client also wait out
   a 503 for ever? Recommend yes under `--repeat` (an unattended card should survive a server restart).
   *Default: as the other modes.*

The other six (order of the checks, the request-size limit, whether telemetry is required, counters as JSON
numbers, an endpoint to give a claim back, a reason with the 204) need no answer to proceed; the notes say what
is built.
