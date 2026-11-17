# Searching base 64 in the G2 structure: what it would take (decision document, 2026-11-17)

## Decision in half a page

**What is on offer.** G2 is a redesigned nice-only join that searched base 64 **×5.1 faster** than today's main on an RTX
3080 this morning (×4.8 after host overheads, exact on every unit). That would cut base 64 from about 1.5 years of
today's fleet to about 3.5 months. G2 only works if a work unit is a **slice of the shared middle digits across the whole
base** (64^5 "super-units", digits 4–8 of n), not a contiguous range of n. The card that does 86 % of the work, the RX
9070 XT, has not been measured.

**The server change is smaller than it looked.** Base 64's range is exactly [2^75, 2^76). Base 64 is a power of two. So the
map that moves n's bits 24–53 up to bits 45–74 is a one-to-one, count-preserving renumbering of that same interval. In the
new numbering, every aligned interval is exactly a set of whole super-units.

- Base 64 can go into **today's `fields` table, with today's columns, jobs, chunks, leaderboard and completion chart unchanged**
  (option A, a "virtual coordinate").
- Its 262,144 fields of 2^57 each take about 23 s on a 3080.
- **The one thing that must change**: old clients must never be handed a base-64 field. They would search the wrong
  numbers and mark the field done. That needs a claim filter plus an opt-in claim parameter: **about 150–250 lines in
  `api/` and `db_util/fields.rs`, one optional index, no new tables**, plus a 5-line submit guard.
- Even that can be deferred. A private coordinator for the owner's own machines (option C′) speaks the same wire format
  with zero server change. Its results can be backfilled into the same rows later.

**What it costs.** About **15–22 agent-days**. Most of it is client work: one CubeCL kernel source, run on Vulkan for the AMD
card and on CUDA for the rented fleet. Metal, hand-CUDA, CPU and browser backends are not needed. The maintainer would
spend about 2–3 days reviewing over several PRs, plus one API deploy.

**Recommendation.** Spend 3–5 agent-days and under an hour of the 9070 XT on a CubeCL port of the benchmark kernel.
- **Stop everything if the same-session ratio there is below ×4.0.**
- Otherwise build the client against option A's wire format, and ship base 64's first fields through option A (or C′ if
  the maintainer prefers no deploy yet).
- **Do not build option B** (a separate unit table): it costs 3–4× the server work and buys nothing at base 64.

**Strongest argument against.** It is a permanent second search implementation, plus a rule that base-64 field ranges
are not ranges of n, which every future tool must know. All that buys about a year on one base. The program's own
pre-registered rule said stop at ×5.1, because the AMD run needed ×6 on the 3080.

Read on if the AMD measurement is worth an hour of the card.

---

## 1. Facts this rests on

- **G2's numbers** (`BENCH.md`, 3080, 3 rounds):
  - End to end: kernel plus preparation measured at 1.123 fs per admissible n. Tops and survivor stages add 0.115 fs,
    costed but not run. Total 1.24 fs.
  - Same-session main: 6.35 fs. Ratio ×5.13.
  - The kernel is LDS-issue-bound: 32 ps per kept 64-pair word, with 17 slice loads per word.
  - BX Day 2 shows the pairing structure itself cannot gain more than ×1.14–1.36. So ×5 is about what G2 is worth on NVIDIA.
- **Base 64's range**: [2^75, 2^76), 3.78e22 n (377,789 of today's 1e17 fields). It is not in the database yet.
- **Super-unit**: one value π′ of digits 4–8, covering every leading value h ∈ [2^15, 2^16), every digit 9 and every low
  value. That is 2^45 n, 4.47e12 of them admissible.
  - Cost: 5.54 ms on a 3080.
  - Whole base: 1,652 card-hours on a 3080, against 8,462 for main (`proposal/NOTES.md` §2).
- **How today's server hands out nice-only work**:
  - The lowest-id field at `check_level` 0 whose claim is older than 1 h. There is **no base filter, no size cap**
    (`api/src/main.rs:162–166`, `fields.rs:414–430, 699–751`) and no client capability or version check.
  - Submit has no checks at all: "honor system" (`api/src/main.rs:346–370`). It sets `check_level` 1.
  - Detailed claims never see a field over 1e10 (`lib.rs:56`). **Detailed searches are untouched by anything below.**

## 2. Option A: a virtual coordinate in the existing fields table

**The coordinate.**

    v(n) = 2^75 + π′·2^45 + (h − 2^15)·2^30 + d9·2^24 + low,    where n = h·64^10 + d9·64^9 + π′·64^4 + low

- v is n with bits 24–53 (π′) moved up to bits 45–74. It maps [2^75, 2^76) onto itself one to one.
- It is exact only because of base 64's power-of-two rectangle. Base 62's range is not aligned (it would need a padded
  coordinate), but base 62 ends before G2 could ship, so this does not matter.
- Fields are inserted with today's script at size 2^57, as "144115188075855872e0": 262,144 aligned fields of 4,096
  super-units each. 2^58 gives 131,072 fields of about 45 s.
- A field's `range_size` is still its count of n. Everything that sums sizes stays right.

**What must know about v, and what it changes** (complete list from reading origin/main; `proposal/NOTES.md` §3 has all lines):

| reader | file:line | under v | change needed |
|---|---|---|---|
| nice-only claim (queue, direct, bulk) | `api/src/main.rs:162–217`, `api/src/field_queue.rs:341–365, 468–479`, `fields.rs:414–430, 699–751` | hands b64 to any client | **yes**: legacy claims exclude G2 bases; an opt-in `?g2=1` (or `/claim/niceonly-g2`) claims only them; a second in-memory queue |
| nice-only submit | `api/src/main.rs:346–370` | accepts anything | **yes, 5 lines**: for a G2 base, reject a submission whose telemetry route is not `"g2"` (a second guard against coverage holes) |
| detailed claim/submit, validation | `fields.rs:296–368, 993–1061`; `main.rs:371–460` | size cap 1e10 excludes b64 | none |
| claim expiry 1 h | `lib.rs:51`, `fields.rs:266` | a field must finish within 1 h on the slowest G2 client | none (23–45 s on a 3080) |
| jobs: chunk and base `checked_niceonly`, `minimum_cl` | `jobs/src/main.rs:237–336` | counts are preserved | none; the meaning becomes "fraction of super-units done" |
| leaderboard, daily totals | `migrations/2026-10-15…sql:49–52` | Σ range_size | none |
| site completion chart | `web/index.html:511–550` | chunk index × `minimum_cl` | none; one caption line for b64 |
| site niceness chart | `web/index.html:439–466` | detailed chunks only | none |
| interval queries (`get_count_checked_by_range`, `get_minimum_cl_by_range`, `get_canon_submissions_by_range`) | `fields.rs:1063–1104`, `submissions.rs:153–180` | right for the whole base; **wrong for sub-intervals of n** | none in code; document. "Searched up to n = X" cannot be said for b64 |
| nice numbers, notable numbers, near misses | `main.rs:344` `expand_numbers`, `cache_notable_numbers` | real n, as now | none |
| client, every nice-only route | `client/src/main.rs:724–858, 978–995`, `gpu_route.rs`, `gpu_config.rs:32–35` | would search the v-range as n | **yes**: a G2 route; every non-G2 path refuses a G2 base (third guard) |
| benchmarks | `bench.rs`, `bench_defs.rs` | b64 scenarios are n-ranges | add a super-unit scenario |
| fleet controller | `fleet/controller.py:61–67` | launches the client | a release containing G2 |
| program audit scripts (scratch) | T28 etc. | compare survivors/checked across implementations | key on telemetry route `g2` |

**Schema and API diff (outline).**
- `common/src/g2_coord.rs` (new, about 80 lines plus tests): the `G2_BASES = [64]` constant, v↔n, and v-range →
  super-unit range (rejects misalignment).
- `fields.rs`: a `BaseFilter { Legacy, G2 }` argument on `bulk_claim_fields` and the cl 0 branch of `try_claim_field`
  (`AND base_id <> ALL($5)` / `= ANY($5)`).
- `field_queue.rs`: a `niceonly_g2` queue mirroring `claim_niceonly`.
- `main.rs`: the optional query parameter, the submit guard, and the status counter.
- An optional migration: a partial index `ON fields(id) WHERE check_level = 0 AND base_id = 64`.
  - Without it, once base 62 is done, every legacy refill walks the 262k base-64 rows of `idx_fields_cl0_id` to find
    nothing.
  - EXPLAIN it on a copy first (the 11-01 runaway query is the precedent).
- Tests in `common/tests/claim_queries.rs`.
- **No column, table or wire-type change**: `DataToClient` already carries the base.

**What breaks or is lost.**
1. Base-64 progress cannot be stated as an interval of n until the base is complete. The site shows "x % of
   middle-digit slices", which is true but new.
2. **Lock-in**: once base 64 runs in v, switching it back to n-fields means redoing the work.
3. Clients without G2 get no base-64 nice-only work: the public CPU clients and any build without CubeCL. Once base 62
   ends, the legacy endpoint returns "no field", unless another base is open.
4. Telemetry `survivors`/`checked` from G2 measure a different quantity, so they cannot be compared with today's.

## 3. Option B: a separate unit table and endpoints

- **Schema**:
  - `g2_units(id, base_id, chunk_id, su_start, su_end, shape, check_level, last_claim_time, canon_submission_id)`;
  - either `g2_claims`/`g2_submissions`, or making `claims.field_id`/`submissions.field_id` nullable with a `unit_id`
    (both are `NOT NULL REFERENCES fields`, `schema.sql:59–82`).
- **API**: `/claim/g2` and a submit branch keyed on the claim's kind, with a queue of their own.
- **Jobs**: unit coverage has to enter `chunks.checked_niceonly` and `bases`, a second aggregation in `jobs/src/main.rs`.
- **Caches**: the leaderboard and daily totals join `fields` for `range_size` (`migrations/2026-10-15…:49–52`), so
  they need a union.
- **Site**: the completion chart needs unit chunks or a view.
- **PostgREST**: grants for the new tables.
- **Gains over A at base 64**: semantic honesty (rows say super-units), which a SQL view decoding v gives A for free.
  B would also be base-agnostic, but no other base needs it yet.
- **Cost**: about 5–8 agent-days of server work, migrations on four tables, and a maintainer review of exactly the
  "server rearchitecture" he declined. **Not recommended.**

## 4. Option C: no server change

**C, one or a few giant contiguous fields.** A contiguous field of 1/m of the base re-pays the bottom side and the
preparation (0.246 of the 1.24 fs) m times:

| fields of the base | 1 | 2 | 4 | 8 |
|---|---|---|---|---|
| ×, measured costs | **×5.1** | ×4.3 | ×3.2 | ×2.2 |

This is optimistic, because sparser tops per chunk lower the lane density. So only one or two fields are worth having.

What is lost:
- **Other clients**: no one else can take part.
- **The claim**: it expires after 1 h. After that, every legacy client that claims the giant field would sit on it for
  years. The field must be parked (`last_claim_time` in 2099: a data write, which no claim path can match; checked
  against `claimable_predicate`, `fields.rs:266`), or not inserted until it is done.
- **Restart safety**: rests on a client-side checkpoint of finished super-units.
- **Audit**: one submission for 3.78e22 n, with per-super-unit evidence that does not fit the 16 KB telemetry cap.
- **Public progress**: none for about 3–4 months, then a one-day spike of 3.78e22 in the rate chart and the leaderboard.

**C′, the middle form: a private coordinator for the owner's machines.**
- A small service, grown from `bench/box/stub_api.py`, speaks today's `/claim/niceonly` + `/submit` wire format,
  handing out option A's v-fields of 2^57.
- It runs on ivory or the AMD box; the fleet points `--api-base` at it.
- The client code is identical to option A's.
- Each finished v-field and its telemetry are logged.
- Later the maintainer inserts base 64's v-fields and backfills the finished ones (a `check_level` 1 row and a
  submission per field). They are the same rows option A would have produced.
- **Zero server code and zero deploy**. The costs: the public sees nothing until the backfill, the fleet has to reach
  a private endpoint, and the coordinator is a second claim server to babysit.
- It is a good bridge if the maintainer wants to see G2 run before touching the API.

## 5. Client work per backend, and which backends are needed

The BENCH kernel is the inner part only. The production G2 route needs the following:

1. **Tops on the device**: 32,768 tested per unit, 64 units per super-unit, an f0 4 FD certificate. This is an
   adaptation of `top_fd_kernel` in `cubecl_join.rs`, costed at 0.049 fs.
2. **Roots and parents**: the 9.3M depth-4 roots are built once per client on the host. Parents and the 8-bit counting
   sort run per super-unit, replacing `cub` (there is no `cub` in CubeCL).
3. **The main kernel**, from BENCH v10.
4. **Survivors**: 10.9M records, 174 MB per super-unit, which must not leave the device. They go to the existing
   middle-digit prefilter and `check_kernel` (`join_check.rs`), costed at 0.066 fs.
5. **Routing and guards**: field → super-unit range (`g2_coord`), a G2 route in `gpu_route.rs` and
   `client/src/main.rs:724–995`, and refusal of G2 bases on every other path.
6. **Telemetry**: `{route: "g2", shape: [4,10], su_first, su_count, survivors, checked, block_survivors[64]}`. The
   last item holds the survivor counts of 64-super-unit blocks: about 600 B, well under the cap.
7. **Benchmark**: a NiceMark super-unit scenario.

| backend | share of today's nice-only work | needed for base 64? | work |
|---|---|---|---|
| CubeCL wgpu → Vulkan (RX 9070 XT) | ≈ 86 % | **yes**: the only one that matters | the port. Watch for: LDS 32 KB against production's 18.9 KiB occupancy budget; wave32/64 (u64 ballots exist: `plane_ballot` is already used in `cubecl_join.rs`); the CubeCL SPIR-V atomic-store rule (not hit as written) |
| CubeCL CUDA (rented NVIDIA fleet) | most of the rest | yes, same source | validation on one rented box, about 0.5–1 day |
| CubeCL wgpu → Metal (M4) | small | **no** (later, if at all) | same source; at b64 all digit arithmetic is shifts, so the Apple divide bug classes do not arise; still 1–2 days of testing |
| hand-CUDA (`client_process_cuda.rs`) | — | no | none: NVIDIA takes the CubeCL route |
| CPU client | occasional | **no as a client**; **yes as code**, as the audit reference and test oracle | port `G2/proto` (about 1,200 lines) into `common/` or `scripts/`, 2–3 days. As a client it would be ×4–5 over today's CPU join (RESULTS §5), optional |
| browser (WGSL) | — | no | the site's client is detailed-only (`web/search/index.html:1237`) |

**Which clients can simply not take base-64 work:** all of them except the AMD card and the CUDA fleet. Under option A
the gate makes that automatic.

## 6. Verification, audit, mid-base and fallback

**Exactness gates, before any base-64 field is submitted:**
- Whole-base runs at b10–b28 against brute force, through the client's G2 code on the CPU reference and on the GPU.
- Every unit's survivor set on the two dumped base-64 super-units: BENCH's `surv.bin`.
- The v-map round trip and alignment tests.

**Audit of production results:**
- A super-unit's AND-survivor count, and its prefilter count, are properties of (shape, super-unit). An independent
  implementation reproduced them exactly (REVIEW F7).
- **Audit = recompute random 64-super-unit blocks with the CPU reference and compare `block_survivors`.** One block is
  about 6–7 min of one CPU thread.
- One block in every 1,000 fields is 262 blocks, about 28 thread-hours over the whole base.
- The nice numbers themselves are checked as today.

**Mid-base and coexistence:**
- G2 and ordinary fields coexist in one table by base: base 64 is G2-only and every other base is unchanged.
- **If G2 is not ready when base 62 ends** (around 23 Dec to 6 Jan), a clean bridge exists:
  - insert n-fields for a prefix h < h0, i.e. n < h0·64^10, where 64^10 = 2^60. Use aligned 2^56 fields (7.2e16).
    Today's client searches them in id order;
  - later insert v-fields over the remaining rectangle h ∈ [h0, 2^16). It is again a product set, so the map stays
    exact with super-units of (2^16 − h0)·2^30 n;
  - this is a partition, not an overlap, so the counts stay exact;
  - it costs little at b64, because the bottoms are cheap: ×5.0 on the remainder after a 10 % bridge.
- **Fallback if G2 turns out wrong mid-base**: disqualify the affected v-fields and reset them to `check_level` 0. They
  can only be redone by G2 (lock-in, §2). Keep the CPU reference able to search a whole v-field as a slow last resort.

## 7. Effort, review, deploy

| piece | files | agent-days |
|---|---|---|
| Phase 0: CubeCL port of BENCH v10 + preparation (counting sort), dump reader, exactness against `surv.bin`, run on the 9070 XT + same-session main on b64 fields | scratch harness only | 3–5 |
| `g2_coord` + tests | `common/src/g2_coord.rs`, `lib.rs` | 0.5 |
| G2 device pipeline (tops, parents/sort, main, survivors → prefilter → check, slicing to memory) | new `common/src/g2_join.rs` (about 2–3k lines), reuse of `join_check.rs`, `cubecl_backend.rs` | 6–9 |
| client route, guards, telemetry | `client/src/main.rs`, `gpu_route.rs`, `gpu_config.rs` | 1 |
| CPU reference / oracle + whole-base tests | `common/` or `scripts/` (port of `G2/proto`) | 2–3 |
| NiceMark scenario, CUDA validation on one rented box | `bench_defs.rs`, `bench.rs` | 1–1.5 |
| server, option A (claim filter, queue, submit guard, index, tests) | `api/src/main.rs`, `field_queue.rs`, `fields.rs`, migration, `tests/claim_queries.rs` | 1.5–2 |
| audit script | `scripts/` | 1 |
| **total** | | **≈ 15–22** (Metal +1–2; option B instead of A +4–6) |

**What the maintainer would do:**
- Review: one server PR of about 200 lines (an hour), and client PRs of about 4–5k new lines, kernel-heavy (2–3 days
  over several weeks).
- Deploy: the API plus one optional index, then insert base 64 at 2^57.
- Release a client version the fleet pins.

Under C′ the API deploy waits; the backfill is a data write.

## 8. Risks

1. **The AMD ratio is unknown, and it decides everything.**
   - RDNA4's LDS throughput could favour G2 by up to about 1.5×. Its occupancy budget and wave size could equally cost
     more than that.
   - wgpu delivered less than half of CUDA's gain last time (REVIEW F5).
2. **Unmeasured pieces** are costed at 0.115 fs + 8 %: the tops on the device, the survivor prefilter and check, and
   host and launch overhead. The 3080 ratio is ×4.75 after the allowance, not ×5.1.
3. **Silent coverage holes** if a v-field is ever searched as an n-range. Three independent guards close this: the
   claim filter, the submit guard and client refusal. Without the submit guard, one misconfigured old client could
   mark base-64 slices done.
4. **Lock-in and permanence**: base 64 stays G2-only, and the second implementation must be maintained as long as base
   64 runs and is audited.
5. **Schedule**: base 62 ends in late December. The client will probably not be released by then. Bridge (§6) or idle.
6. **The claim query**: the legacy filter after base 62 ends (index above); queue starvation if the G2 queue and the
   fleet's lookahead are sized for 58 s fields.
7. **Device memory**: about 175 MB of survivor records per super-unit, plus the 9.3M roots, on 16 GB cards. These must be
   streamed. This is a design point, not a blocker.

## 9. Phased plan with decision points

| phase | what | cost | decision |
|---|---|---|---|
| **0** | CubeCL (wgpu/Vulkan) port of BENCH v10 + preparation. Exactness against both dumped super-units on ivory's CPU path first, then under an hour on the 9070 XT. Same-session main on 5–10 b64 1e17 fields (B64.1 protocol). Report kernel + preparation fs, with 0.115 fs + 8 % added | 3–5 agent-days, < 1 h of the card, the owner's permission for demoux | **Stop everything if the all-in ratio is below ×4.0** (≈ ×3.5 delivered after the unmeasured allowances, just above the maintainer's old ×3 bar). From ×4.0 up: phase 1, and the maintainer chooses A or C′ for phase 2 |
| **1** | Production G2 route in the client (CubeCL source; Vulkan and CUDA), CPU reference, exactness gates (§6), NiceMark scenario | 11–15 agent-days | gates pass and the in-client ratio on the 9070 XT is ≥ 90 % of phase 0's, or stop |
| **2** | **Smallest end-to-end slice**: base 64's first 64 fields (2^57; ≈ 1/4,096 of the base), the AMD card only, through option A's endpoint on a staging API (or through C′); one audit block per field against the CPU reference | 2–3 agent-days + one maintainer deploy | every audit block matches, the field time is steady, and nothing reached a legacy client: open base 64 to the fleet |
| **3** | Fleet (CUDA) on G2; audit sampling 1/1,000; optional Metal | ongoing | — |

## 10. Recommendation and the case against

**Recommendation.**
1. Run phase 0 now: it costs days of agent time and under an hour of the card, and it is the only number that can still
   change the answer.
2. If the 9070 XT gives ×4 or better, build the client against option A's wire format.
3. Ask the maintainer for option A's gate. It is about 200 lines, with no new table and no change to the jobs, the site
   or the wire types. If he declines, run base 64 through C′ for the owner's machines and backfill the rows later.
4. Hold the base-64 insertion until phase 0's answer. If G2 is a go but not ready when base 62 ends, use the aligned
   n-prefix bridge (§6) instead of inserting the base as 1e17 n-fields.
5. Do not build option B.

**The strongest argument against.** The gain is about a year on one base. The price is permanent:
- a second search implementation, of about 4–5k lines of kernel code, that must be kept correct and audited;
- a base whose field rows no longer mean "these n", which every future script, audit and statement about progress must
  know;
- all of it decided on a ratio that is measured on a card doing a minority of the work, and that the program's own rule
  had already called a stop (×5.1 against a bar of ×6).

The alternative costs nothing: let today's client finish base 64 in about 1.5 years. Spend the same agent-weeks on
improvements that every base and every client gets, with no server change at all.
