# G2 proposal: working notes (2026-11-17, 07:30– UTC, ivory, reading only)

Code read on upstream main 7e0113fc (`git show origin/main:<path>`), nothing checked out or built.

## 1. Base 64's range is a power-of-two rectangle (the fact option A rests on)

`common/src/base_range.rs` (b % 5 == 4): [ceil(sqrt(64^25)), ceil(cbrt(64^38))) = [2^75, 2^76), size
3.778e22 = 377,789 of today's 1e17 fields. Write n in base 64 as

    n = h·64^10 + d9·64^9 + π′·64^4 + low,   h ∈ [2^15, 2^16), d9 < 64, π′ < 2^30, low < 2^24.

The range is exactly every h in [2^15, 2^16) with every lower digit: no clipped end. A G2 super-unit is
one π′ value (digits 4–8) with every h, d9, low: 2^15·2^6·2^24 = 2^45 n, of which 4.468e12 are
admissible (0.127; BENCH counts). In bits: n = [75..60] h, [59..54] d9, [53..24] π′, [23..0] low. Define

    v(n) = 2^75 + π′·2^45 + (h − 2^15)·2^30 + d9·2^24 + low

i.e. **v is n with bits 24–53 moved up to bits 45–74**. It maps [2^75, 2^76) onto itself one to one,
preserves counts, and any v-interval [2^75 + a·2^45, 2^75 + c·2^45) is exactly the super-units
π′ ∈ [a, c). With fields of 2^57 (break_range_into_fields(2^75, 2^76, 2^57), `generate_fields.rs:14–34`:
exact, no remainder field) there are 2^18 = 262,144 fields of 4,096 super-units each, in id order of π′.
2^58 gives 131,072 fields of 8,192. `scripts/insert_new_fields.rs` takes the size as "XeY"; "144115188075855872e0"
parses, so no script change.

Within a field the client may visit the 4,096 super-units in any order. With π′'s digit 8 most significant,
a 2^57 field fixes digits 6–8 and spans digits 4–5, so the tops' f0 5 parents (digit 4 innermost, REVIEW F4)
are shared inside a field, and bottom tree nodes of depth ≤ 6 are too.

Every digit operation at b64 is a shift or mask (b = 2^6); only the class (mod 63) needs a real reduction.
That also keeps G2 away from the Apple divide-by-constant miscompile classes.

## 2. Cost arithmetic (BENCH measured numbers, 3080)

- per super-unit: 4.4679e12 adm × 1.24 fs = 5.54 ms; a 2^57 field = 22.7 s; whole base 2^30 SU = 1,652
  card-hours = 69 days on one 3080 (main at 6.35 fs: 8,462 card-hours = 353 days).
- split of the 1.24 fs: per-super-unit fixed (prep 0.101 + bottom side 0.145 = 0.246) and per-top
  proportional (probes 0.877 + tops 0.049 + survivors 0.066 = 0.992).
- contiguous fields of 1/m of the base (option C with m fields): each re-pays the fixed part, so
  total = 0.992 + 0.246·m fs: m = 1 ×5.13, 2 ×4.28, 4 ×3.21, 8 ×2.15, 16 ×1.29 (optimistic: fewer probes per
  chunk lowers lane density). The review's model gave ×6.3 (whole base) / ×3.5 (1/10) for unsorted variants.
- bridge (today's n-fields search the first fraction p, G2 the rest, bottoms still paid for the whole base):
  ratio over the remainder 6.35(1−p) / (0.992(1−p) + 0.246): p = 0.05 ×5.08, 0.10 ×5.02, 0.25 ×4.81.
- survivor records: 10.9e6 × 16 B = 174 MB per super-unit leave the BENCH kernel; production must prefilter
  them on the device (the BENCH costs them at 0.066 fs but does not run that code).

## 3. Inventory: everything that reads a field's range (origin/main 7e0113fc)

Server/API
- `api/src/main.rs:162–166` nice-only claim: strategy Next, cl 0, **max size u128::MAX**, no base filter.
- `api/src/main.rs:200–217` nice-only claim via `FieldQueue::claim_niceonly`, fallback `try_claim_field`.
- `api/src/main.rs:268–276` DataToClient built straight from the row (base, range_start/end/size).
- `api/src/main.rs:289–296, 641–642` routes `/claim/detailed`, `/claim/niceonly`; no client capability, no version check.
- `api/src/main.rs:346–370` nice-only submit: "No checks for nice-only, honor system"; inserts, sets cl 0 → 1.
  No check that numbers lie in the range, none on telemetry.
- `api/src/main.rs:371–460` detailed submit checks distribution total == range_size (b64 never detailed).
- `api/src/field_queue.rs:341–365` nice-only queue: `bulk_claim_fields(.., 0, u128::MAX)`, lowest id first.
- `api/src/field_queue.rs:468–479` prefill; `:139` status sizes.
- `common/src/db_util/fields.rs:266–267` claimable = last_claim_time NULL or ≤ now − 1 h (`lib.rs:51`).
- `fields.rs:414–430` try_claim_field Next cl 0: lowest-id cl 0 claimable row, any base.
- `fields.rs:699–751` bulk_claim_fields: same, LIMIT n.
- `fields.rs:753–780` renew_niceonly_claim.
- `fields.rs:296–315, 351–368, 421, 452` detailed paths: `range_size <= $3` with $3 = 1e10 (`lib.rs:56`) → b64 never detailed.
- `fields.rs:993–1061` validation field: ids 10k–50k, cl ≥ 2 → never b64.
- `fields.rs:1063–1104` get_count_checked_by_range / get_minimum_cl_by_range: interval queries on range_start/end.
- `common/src/db_util/submissions.rs:153–180` get_canon_submissions_by_range: interval query.
- `schema/schema.sql:45–56` fields (DECIMAL ranges, fine for v); `:59–65` claims.field_id INTEGER (b62 ids
  ≈ 2.07e8; +262k is fine); `:121` partial index `idx_fields_cl0_id`.

Jobs
- `jobs/src/main.rs:237–268` chunk checked_niceonly = Σ range_size of cl ≥ 1 fields; `:319–336` base totals from
  chunks. Count-preserving under v: unchanged and correct as "fraction of super-units done".
- consensus (`common/src/consensus.rs`) and downsampling: detailed only.

Wire types (`common/src/lib.rs`)
- `:264–272` DataToClient {claim_id, base, range_start, range_end, range_size}; `:276–290` DataToServer
  (nice_numbers are real n; telemetry optional, capped 16 KB at `api/src/main.rs:29`).

Client
- `client/src/main.rs:724–776` GPU dispatch: every backend's process_niceonly takes the range as n.
- `client/src/main.rs:778–858` CPU: slices_for / overlap join / stride walk on the range as n.
- `client/src/main.rs:978–995` begin_field_sync → `gpu_route::begin_niceonly` (route by n-range: answered on the
  spot / join / stride); `common/src/gpu_config.rs:32–35` gpu_supports_base(64) is true.
- `client/src/main.rs:1115–1158` compile_results: numbers + telemetry, nothing range-specific.
- `client/src/main.rs:1202–1240` validation: server-chosen detailed fields only.
- `common/src/client_api_async.rs:108–116` claim URL is `/claim/{mode}` only.
- `client/src/bench.rs`, `common/src/bench_defs.rs`: b64 scenarios are n-ranges.

Site and other readers
- `web/index.html:67–70` chunks (range_start, range_end, range_size, minimum_cl) from PostgREST.
- `web/index.html:439–466` niceness chart: chunks with niceness_mean (detailed) → b64 absent.
- `web/index.html:511–550` completion chart: chunk index × minimum_cl, no range axis → unchanged, meaning shifts.
- `web/search/index.html:1237` the browser client claims `/claim/detailed` only → not a b64 client.
- `schema/migrations/2026-10-15_incremental_search_caches.sql:49–52` leaderboard / daily totals Σ f.range_size → count-preserving.
- `scripts/search_progress.rs` base totals by range → fine.
- `fleet/controller.py:61–67` launches `nice_client niceonly ...`; no field reads.
- Program audit tooling (T28 etc., scratch only): compares telemetry survivors/checked per field across
  implementations; G2's counters are a different quantity → key on telemetry route.
