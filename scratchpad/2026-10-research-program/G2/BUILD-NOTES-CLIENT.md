# The middle-out join, step 4F: a client route against a local coordinator (2026-11-19, 05:46–11:30 UTC)

Brief: `G2/BUILD-BRIEF-4F.md` (rules of `BUILD-BRIEF-1.md`). Branch **`dev/mo-client`** (from the trunk
`dev/middle-out-join` at `4abfab5c`), worktree `~/projects/nice/.worktrees/midout-client`, pushed to the fork only.
Box: Vast 61386517, RTX 3080 10 GB at its host's 240 W cap, 16 threads visible, CUDA 12.8 image; production hosts
mapped to 127.0.0.1 and ::1 before any client binary ran (`build4f/raw/round1/proof_hosts_block.txt`; every run
script re-checks the block and aborts if a production host answers, proof per run in `runs/*/hosts_proof.txt`).
Scripts `G2/build4f/box/`, raw logs `G2/build4f/raw/` (`round1/`: the first wire form; `round2/`: the explicit
coordinate id; `merge/`: after the trunk merge).

## 1. Where it stands

**2026-11-19 ~08:40 UTC.** Branch **`dev/mo-client`** at **`cc0a9e04`** on ivory and on `fork/dev/mo-client`: six
commits on the trunk's `4abfab5c` and an ordinary merge of the trunk's head `9b790647` (`99f113bb`). Nothing in
`gpu.rs` or `gpu_wide.rs`; no server, schema or API change; no pull request.

- **Runs end to end on the box**: a local coordinator (`scripts/midout_coordinator.py`) serves 24 base-64 fields spread
  over the base and two base-65 fields; one client process (`nice_client niceonly --midout-coordinator URL --repeat`)
  claims, searches (base 64 with the sampled CPU check, base 65 on the wide path) and submits all 26; **every recorded
  result equals the library's own for the same fields** (survivors, checked, slices, nice numbers), every sampled
  slice equal to the CPU reference (24/24). Done twice before the merge and once (7 fields) after it.
- **Every guard has a test and a negative run**, nothing submitted and a non-zero exit in each (§4).
- **The route costs nothing measurable**: 1.6935 fs against the library's 1.6914 at base 64 in the same session
  (×1.001; the other round ×0.9999) (§6).
- **The default client is unchanged**: its suites pass, and its routes give equal submissions to the trunk's client on
  the stub (§7).
- **The trunk's head `9b790647` on CUDA** (asked for mid-step): exact, every listed test passes, 1.681 fs (§10).
- The claim names its coordinate explicitly (`midout:4,9,6`); a coordinate the client does not know is refused (§3).

## 2. How to run it (one machine)

Build (the route needs a CubeCL backend; the test switch is a separate feature, never in a release):

    cargo build --release -p nice_client --features cubecl-cuda            # -> target/release/nice_client
    cargo build --release -p nice_common --example midout_fields           # the work-list cutter (no GPU)

A work list (cut by the library's own coordinate; `--spread N` = N fields evenly over the base, `--t` explicit
first quanta, `--quanta Q` fields of Q quanta):

    target/release/examples/midout_fields --base 64 --spread 24 > w64.json
    target/release/examples/midout_fields --base 65 --t 13731,77777 > w65.json
    python3 -c 'import json,sys; print(json.dumps(sum((json.load(open(f)) for f in sys.argv[1:]), [])))' w64.json w65.json > work.json

The coordinator (standard library only, binds 127.0.0.1; state in a directory, resumable):

    python3 scripts/midout_coordinator.py --worklist work.json --state ./mo-state --port 8471
        [--coordinate midout:4,9,6]   # refuse to start unless every field is in this coordinate
        [--reissue-after SECONDS]     # hand out again a claim this old without an accepted submission (default: never)
        [--legacy-path]               # TEST ONLY: also hand the marked fields to /claim/niceonly and /claim/detailed

The client (runs until the coordinator has no field left with `--repeat`, else one field):

    target/release/nice_client niceonly --midout-coordinator http://127.0.0.1:8471 --repeat --username NAME
        [--gpu-backend cubecl-cuda|cubecl] [--gpu-device N]

The flag is the one switch, and its only place is `Cli::midout_coordinator` (`client/src/main.rs`) and
`client/src/midout_route.rs`. It has no environment variable on purpose (nothing turns it on by accident; the fleet
configures by environment, so this is a decision for the owner). The mode positional is ignored, as are `--api-base`
and `--telemetry` (the route always attaches its telemetry); `--validate` and `--benchmark` are refused with it.
Records: `mo-state/claims.jsonl` (every claim), `mo-state/submissions.jsonl` (every submission, accepted or not:
field, claim time, receive time, whole body); `GET /status` gives counts.

## 3. The wire additions (all named in `common/src/midout/wire.rs`)

| | production | the middle-out route |
|---|---|---|
| claim | `GET /claim/niceonly` | `GET /claim/niceonly?coordinate=midout` |
| claim body | `{claim_id, base, range_start, range_end, range_size}` | the same plus **`"coordinate": "midout:K0,K1,Q0"`**; `range_start`/`range_end` = `v_start`/`v_start + v_size`; `range_size` = the n the field holds (`Coord::n_count`; = v_size at b64, less at b65 by its padding) |
| no work | (server-specific) | `204 No Content` |
| submit | `POST /submit`, `DataToServer` | unchanged; `telemetry.pipeline.route = "midout"` |

That is one query parameter, one claim key and one telemetry value. No type of production's changes (`DataToClient`
is built by the API, so a new field there would have been a server change; the route parses its own `CoordClaim`).

**Step 5L (2026-11-19, `G2/BUILD-NOTES.md` §13): the client takes both coordinates of base 64 and 65, and
`midout:4,8,5` is the default.** A claim's id must name one of its base's *known* coordinates
(`midout::coord::coord_digits_known`: bases 64 and 65 `midout:4,8,5` (default) and `midout:4,9,6`; bases 68–70
`midout:4,9,6`); `field_of` builds the `Coord` from the id and checks `Coord::is_known` (it no longer compares with
`Coord::for_base`), and `FieldJoin::search` does the same, so one client searches fields of either coordinate, each
by its own quanta and `range_size`. `midout_fields` cuts (4, 8, 5) fields by default (`--t` = digits 5–7 at base 64)
and (4, 9, 6) fields with `--digits 4,9,6`. The unit test `claims_are_checked_before_work` now accepts
`midout:4,8,5` at 64 and 65 (with its own quantum and padded count at 65), refuses a (4, 8, 5) field presented as
`midout:4,9,6` at 65 (wrong `range_size`), and refuses `midout:4,8,5` at 68; `midout:4,8,6`, `midout:4,9,7`,
`midout:3,9,6` stay unknown. End to end on the box: §11 below. The coordinator needed no change (it passes each
field's id through). The text that follows is step 4F's and describes the state before this.

**The coordinate is named explicitly** (changed mid-step after the field-structure review, `G2/fs/REVIEW.md` §1):
the id `midout:K0,K1,Q0` gives the coordinate's digit positions (digits `[K0, K1)` go on top of v, a field fixes
digits `[Q0, K1)`); base 64 today is `midout:4,9,6` (fields fix digits 6–8). The client parses the id, builds its
`Coord` with `Coord::with_digits(base, K0, K1, Q0)` and refuses it unless it equals the coordinate its device path
for that base was built for (`Coord::for_base`); `midout::route::FieldJoin::search` takes that `Coord` and refuses
any other. The coordinator knows nothing of what an id means: each work-list field carries its own coordinate and is
passed through. The review's proposal (digits 5–7, `(4, 8, 5)`) is expressible by `midout::coord`
(`Coord::with_digits(64, 4, 8, 5)` builds, and `midout_fields --digits 4,8,5` cuts such a work list), but the join
does not search it: `Shape::for_coord` returns `(k0, k1 + 1)` = (4, 9) for it, not (4, 10), and the device paths
were never run on it, so today's client refuses `midout:4,8,5` (unit test `claims_are_checked_before_work`, and the
negative run `unknowncoord` below). Adopting it would need `Shape::for_coord` to return (4, 10) for it, `coord_digits`
to name it for base 64, and the parity tests on it; no field or wire change beyond the id.

## 4. The guards and their tests

| guard | where | unit test | negative run on the box (nothing submitted in any) |
|---|---|---|---|
| refuses the production API | `wire::check_coordinator_url` (first thing `midout_route::run` does; the address is the flag's value, there is no default) | `wire::production_hosts_are_refused` (7 production spellings refused incl. upper case, trailing dot, port, user; 5 non-addresses refused; loopback, `[::1]`, `notnicenumbers.net` allowed); client `refuses_the_production_api` (through `run`) | `prod`: `https://api.nicenumbers.net`, `http://API.nicenumbers.net.:8471`, `https://nicenumbers.net/`: rc 1 each, "refusing the production API (api.nicenumbers.net)" |
| every other route refuses a coordinate-space field | `client_api_async::get_field_from_server_async` (the claim of every ordinary route, both modes) calls `wire::refuse_coordinate_space`: any value of the `coordinate` key is refused before the body is parsed | `wire::coordinate_marker`; `client_api_async::ordinary_claims_refuse_a_coordinate_field` (a loopback server; niceonly and detailed refused, a plain claim still parsed) | `legacy` (coordinator `--legacy-path`): `niceonly --gpu` (overlap join/stride), `niceonly --threads 4` (CPU), `detailed --threads 4`, `detailed --gpu`: rc 1 each, "refusing a field of the 'midout:4,9,6' coordinate", 0 submissions. `plain404`: an ordinary client against a normal coordinator gets 404, rc 1 |
| the claim is one this client can search | `midout_route::field_of`: the id parses, the base has a device path, the coordinate built from the id equals `Coord::for_base`, whole quanta (`field_digits`), `range_size` = `n_count` | client `claims_are_checked_before_work` (other coordinate, unknown ids incl. `midout:4,8,5`, misaligned, part of a quantum, wrong `range_size`, past the end, base 65's padded count, base 62) | `misaligned` (range_start + 1), `badsize` (range_size − 1), `unknowncoord` (`midout:4,8,5`): rc 1, 0 submissions |
| a failed account is not submitted | `FieldJoin::search` returns the library's error; the route logs "NOT submitted", exits non-zero | (the library's own fault tests) | `accounts` (`NICE_MIDOUT_FAULT=accounts`, `F_SKIP_MAIN`): rc 1, "main-kernel job instances done: 0, want 8064" |
| a failed sampled CPU check is not submitted | same (sampled check on at base 64) | (library) | `sample` (`F_PF_DROP`, accounts pass): rc 1, "sampled CPU check of slice …: the field run counted … checked 337523, CPU … checked 337802" |
| a runtime-thread panic: nothing more is submitted | `midout_route::install_panic_hook` (process-wide, installed by the route only, after the device context is up; records every panic, then runs the previous hook); checked after each field and before each claim | — (a process-wide hook in a unit test would catch the harness's own panics) | `panic` (a thread named `midout-test-fault` panics during the field; the field itself completes and passes its accounts): rc 1, "a thread of this process panicked (thread 'midout-test-fault' …): nothing more is submitted" |
| memory hog | (the accounts and the hook together) | — | `hog` (`hog 2100`: 7,549 MiB held, card at 7.8 GB before the client; the release binary, no switch): CubeCL's stream thread `DSD-0-0` panics (`server.rs:124`), the hook records it, and the accounts fail first: "expansion ran 0 of 4096 cubes, walked 0 of 0 slabs"; rc 1, 0 submissions |
| the coordinator's own rules | `scripts/midout_coordinator.py` | — | `coordtest.sh` (`runs/r*/coord/out.txt`): plain claim path 404; three claims, a restart, the third field next (never twice); 204 when none left; route `overlap` or no telemetry → 422; one accepted, the same again → 409; unknown claim → 404; `--reissue-after 0` reissues the unsubmitted field |

The test switch `NICE_MIDOUT_FAULT` exists only in a build with the `midout-fault` feature (`nice_mo_fault`); the
release-feature binary (`nice_mo`) carries no such string (`strings` count 0, `logs/b*/bins.txt`), and the `hog`,
`prod`, `legacy`, `misaligned`, `badsize` and `unknowncoord` runs used it. Every negative run ran twice (round 1 with
the first wire form `"coordinate": "midout"`, round 2 with the id) and again after the trunk merge (`merge/`); all
identical in outcome.

## 5. End to end

The run (`build4f/box/e2e.sh`): a coordinator on 127.0.0.1 with a work list of **24 base-64 fields spread evenly over
the base** (`midout_fields --spread 24`: t = 5461, 16384, …, 256682, one quantum = 2^57 n each) **and two base-65
fields** (t = 13731, 77777); one client process with `--repeat` claimed, searched and submitted all 26 and stopped
on the coordinator's 204 (rc 0). Then the library alone on the same fields in the same session (`lib.sh`:
`midout_bench --cuda` with its default sampled check, `midout_wide_bench --cuda --base 65`), and `compare.py` field by
field on survivors, checked, slices and nice numbers.

| run | commit (box tree) | fields | accepted | equal to the library, field for field | sampled CPU check (b64) |
|---|---|---|---|---|---|
| round 1, `raw/round1/runs/e2e1` vs `lib1` (06:12–06:41 UTC) | `13012788` | 24 b64 + 2 b65 | 26/26 | **26/26** | 24/24 slices equal (library: 24/24) |
| round 2, `raw/round2/runs/e2e2` vs `lib2` (06:53–07:22) | `0c45dccd` (id form) | 24 b64 + 2 b65 | 26/26 | **26/26** | 24/24 equal (library: 24/24) |
| after the merge, `raw/merge/runs/e2e3` vs `lib3` (07:48–07:57) | `cc0a9e04` (merged trunk `9b790647`) | 6 b64 + 1 b65 | 7/7 | **7/7** | 6/6 equal |

Survivors per base-64 field 48.10–48.31e9, checked 1.381–1.387e9, 4,096 slices each, no nice numbers (none expected:
the base-64 search has found none); base 65: 4,225 slices, t 13731 survivors 69,538,121,964 checked 2,220,555,907,
t 77777 69,631,545,810 / 2,223,545,865, identical in all three rounds (the merge did not change the wide path's
counts on CUDA for t 77777). The sampled check is the library's (one random slice per field through the CPU
reference, its counts in the field run and the slice rerun alone on the device n for n); the route records the slice
and its CPU time in the telemetry. One submission's telemetry (round 2, field t 5461), abbreviated:
`{"build_sha", "client_version": "3.4.9-dev", "device": "NVIDIA GeForce RTX 3080", "processing_secs": 32.72,
"pipeline": {"route": "midout", "coordinate": "midout:4,9,6", "field": {"base": 64, "t0": "5461", "quanta": "1",
"v_start", "v_size", "range_size"}, "join": {"path": "narrow", "shape": [4, 10], "plane_width": 32, "group": 16,
"survivors": 48199677437, "checked": 1384275209, "slices": 4096, "device_counts": {tops, children, chunks, flat, kept,
slices}, "sampled_check": {"slice": 22370829, "equal": true, "cpu_secs": 27.08}, "timing": {…}}, "test_fault": null}}`
(about 900 bytes). The binaries' `build_sha` is the box checkout's HEAD; rounds 2 and 3 ran on that HEAD plus the
uncommitted diff that was then committed unchanged as `0c45dccd` / `cc0a9e04` (the diff's md5 in `logs/b*/head.txt`).

## 6. The route's cost

Measured, Vast 61386517, RTX 3080 at the host's 240 W cap, same session (card while busy: 237 W mean, 1,564 MHz mean
SM clock, at most 72 °C, `smi.csv`). fs per admissible n (n × 8/63 at b64), the library's per-field wall against the
route's (claim to submit, the coordinator's clock; the route's own search time differs from it by < 1 ms per field):

| | library (`midout_bench`) | the route (claim → submit) | route / library |
|---|---|---|---|
| round 1, 24 b64 fields | 744.44 s = **1.6949** | 744.39 s = **1.6948** | **0.9999** |
| round 2, 24 b64 fields | 742.91 s = **1.6914** | 743.81 s = **1.6935** | **1.0012** |
| round 2, b64 first field to last submission (incl. claims, submissions, the join's set-up) | 742.91 s | 743.83 s | 1.0012 |
| after the merge, 6 b64 fields | 186.81 s = 1.7014 | 186.43 s = 1.6979 | 0.9980 |
| b65, the warm field (t 77777), rounds 1 / 2 | 56.25 / 56.29 s = 3.560 | 56.33 / 56.27 s | 1.0014 / 0.9996 |
| b65, the first field (t 13731) | 58.50 / 58.48 s | 60.63 / 60.19 s | 1.036 / 1.029 |

**The route costs nothing measurable at base 64: ±0.1 % of the library, inside the run-to-run noise** (the two
library runs differ by 0.2 %), and 1.69 fs per admissible n, as yesterday on this host (1.691). A claim and a
submission on loopback take milliseconds against a 31 s field, and the card waits for neither long enough to show.
The only visible cost is **the base change**: the route drops the base-64 join and builds the wide one when the first
base-65 claim arrives, inside that field's time (+1.7–2.1 s once), where the bench builds its join before its timer
starts; a client that stays on one base pays this once per process, like the bench's first field. Not measured: a
long run (hours), several clients against one coordinator, a coordinator on another machine.

## 7. Default client unchanged

What changed outside `midout/` and the new client module: `get_field_from_server_async` now reads the body as
bytes, runs `refuse_coordinate_space` (a no-op unless the claim carries a `coordinate` key, which production never
sends) and parses with `serde_json::from_slice` (what reqwest's `.json()` did); `Cli` has one optional flag; `main`
dispatches to the route only when it is given (before any other backend is set up); the route module is compiled
only with a CubeCL backend; the client's default features are unchanged and `midout-fault` is in no umbrella.

Shown three ways (`raw/merge/logs/lint3/`, `raw/merge/runs/def4/`, at the merged head):

- **The existing tests**: the client's suite, `cargo test --release -p nice_client` (default features) and with
  `cubecl-cuda`: 24 passed (default; the route module is not built) and 26 passed (`cubecl-cuda`: the 24 plus the
  route's own 2), 0 failed; production's common suite
  `cargo test --release -p nice_common --lib` (default features): **217 passed, 0 failed, 10 ignored** (214 on the
  trunk + the 3 new non-network tests; as on main otherwise); with `rustls-tls` the 4 wire/claim tests pass.
- **fmt and clippy**: `cargo fmt --all --check` clean; `cargo clippy -p nice_common -p nice_client --all-targets
  -- -D warnings` clean with default features, with `nice_client/gpu,nice_client/cubecl-spirv` (the lint recipe's GPU
  set) and with `nice_client/cubecl-cuda,nice_client/midout-fault`. (`just lint`'s `-p "*"` also lints the api and
  jobs crates, untouched here; not run on the box.)
- **The unmodified routes against the stub** (`build1/box/stub_api.py`, accepting `/claim/detailed` too:
  `build4f/box/stub_api2.py`; `default.sh`): the trunk's client built at `9b790647` (own checkout and target
  directory) and this branch's at the merged head, each with `--telemetry`, on the same fields: (a) base 64
  `q64small` (1e12 n) `niceonly --gpu` (stride route), (b) base 64 `qs1` (1e13 n) `niceonly --gpu` (the overlap
  join: survivors 609,926,573, checked 37,752,816), (c) base 10 `niceonly --threads 4` (69 found), (d) base 10
  `detailed --threads 4`, (e) base 10 `detailed --gpu`: **every submission equal** (nice numbers, distribution, route,
  survivors, checked), rc 0 for both binaries in all five. (An earlier pass, `merge/runs/def3`, compared against the
  trunk at `4abfab5c` by mistake of a failed fetch: also all equal.)

## 8. What the real server would need to do the coordinator's job (a list, no code)

1. **Hand out middle-out fields only to clients that ask**: the claim path's `?coordinate=midout` (or a separate
   path), a queue of its own for those fields, and **every legacy claim path excluding them** (PROPOSAL §2's
   `BaseFilter`: today any client claiming `/claim/niceonly` would be handed a base-64 v-field and, if released before
   this branch, search it as n). The coordinator's 404 for the plain path is that exclusion.
2. **Store which coordinate a field is in**: a field row needs the coordinate id (`midout:4,9,6`) or a per-base rule
   that says "base 64 is coordinate X"; the claim response then carries it (the one new key). A re-cut of the
   coordinate (the review's 5–7) is a new id, never a reinterpretation of old rows.
3. **Insert the fields**: 262,144 rows of 2^57 at base 64 in v (`range_start` = v_start), `range_size` = n count
   (`Coord::n_count`, the coordinator gets it from `midout_fields`), which keeps every sum of sizes right.
4. **Check the submission's route**: reject a submission for a middle-out field whose telemetry route is not
   `midout` (the coordinator answers 422); accept one submission per field (409).
5. **Claim expiry**: production's 1 h expiry is fine (a field is 31 s at b64, 56 s at b65 on a capped 3080); the
   coordinator never reissues by default, `--reissue-after` is the same rule.
6. **Nice numbers**: submitted as real n (as today); the server's expansion and notable-number caches need no change.
   It could check each n lies in the field (v of n in range), which the library already checks before submitting.
7. **Interval queries** on base 64 (`get_count_checked_by_range` etc.) become wrong for sub-intervals of n (PROPOSAL
   §2); progress is "fraction of fields", and the site's chart caption for b64 says so.
8. **Audit**: the submission carries survivors, checked, slices, the sampled slice and its result, the shape and the
   build; an audit job can recompute random slices with the CPU reference (PROPOSAL §6) keyed on route `midout`.
9. **Backfill** of what a private coordinator searched: each accepted record in `submissions.jsonl` is one field's
   submission (claim id, username, version, nice numbers, telemetry), the same rows option A would have produced.

## 9. What is not done

- **Not run**: several clients against one coordinator (the coordinator is threaded and locks every state change,
  but concurrency was not exercised); a coordinator on another machine than the client; a long run (hours); the route
  on lavapipe/Vulkan or any other card (the route takes `--gpu-backend cubecl` for wgpu, untested); base 68–70 fields
  (the route accepts bases 64–70; 68 does not fit this card).
- **The sampled CPU check is off at base 65** (the library's default: the CPU slice takes longer than the field), so a
  b65 field with a kernel that computes wrongly while every account holds would be submitted; the `sample` negative
  run is base 64 only.
- **No prefetch or overlap between fields**: the route claims the next field after submitting the last; at 31 s per
  field the gap is milliseconds, but on a coordinator far away a slow claim would idle the card.
- **The panic hook is installed after the device context is created**: a panic during context creation kills the
  process anyway (main thread), but a CubeCL thread that panicked before the hook would only be seen by the accounts.
- **Restart safety inside a field**: none; a killed client leaves its claim unsubmitted, and the coordinator does not
  hand that field out again unless started with `--reissue-after` (by design: "never twice unless told").
- **Claims spent on refusals**: a refused claim (the ordinary routes against `--legacy-path`, a bad claim) stays
  claimed in the coordinator's state; only `--reissue-after` frees it.
- **Not changed, for the owner**: the flag's name and that it has no environment variable; `range_size` is `n_count`
  while `range_end − range_start` is `v_size` (they differ at padded bases: a reader of the claim must not assume
  `range_size = range_end − range_start`); the coordinator binds 127.0.0.1 only (option C′ for a fleet would need it
  reachable, i.e. another bind address and some authentication).
- `just lint`'s `-p "*"` (api, jobs) and the lavapipe runs were not repeated here (only `nice_common` and
  `nice_client` changed).

## 10. The trunk's head on CUDA (asked mid-step; separate from the client route)

The trunk's seven commits after `4abfab5c` (scatter3's 32-bit children count, the expansion's prefilter in one loop,
the SPIR-V limb prefilter, `search_field_part`/`time_field_part`, `with_width`, `expansion_bits_profile`) had been run
only on lavapipe at 8 lanes. Run here at the merged head (`99f113bb` + this branch's last commit; the trunk's files
are the trunk's `9b790647`), CUDA, this box, 240 W cap, 08:02–08:26 UTC (`build4f/raw/trunk/trunk4/`, `trunk5/`;
scripts `box/trunk.sh`, `box/trunk_tests.sh`):

**Exact on CUDA: yes; no test failed, so no commit needed bisecting.**

| test (CUDA, `MIDOUT_CUDA=1`) | result |
|---|---|
| `gpu::tests::gpu_slices_equal_cpu`, slices 712012851, 318575442, 391856203, 1, 2^30 − 1 | pass (124 s) |
| `gpu::audit::accounts_faults_are_loud`, slices {502136830, 0} and {806726610, 712012851, 2^30 − 1} | pass: `F_SKIP_MAIN`, `F_SKIP_TOPS`, `F_DROP_PROBE`, `F_DROP_PARENT` loud through the accounts, `F_PF_DROP` loud through the sampled check; the account values are yesterday's to the unit (e.g. "probes run = 8 x tops: 1906740, want 1910856") |
| `gpu_wide::tests::wide_slices_equal_cpu`, b30 100, b40 1234, b50 77777, b64 forced wide 712012851, b65 717171717, 532260419, 1160290624 | pass (345 s) |
| `gpu_wide::tests::wide_faults_are_loud`, b65 | pass (every fault loud; `F_BAD_PARENT`, `F_PF_DROP` through the sampled check) |
| `gpu::tests::gpu_check_rebuilds_the_survivors`; `audit::audit_stop_env_is_loud`; `audit::audit_oom_is_loud` (9,216 MiB in process) | pass |

**The ten-field base-64 timing through the library** (`midout_bench --cuda --group 16`, the fields of BUILD-NOTES
§10.6: t = 13107, 39321, …, 249036; card 236 W mean, 1,548 MHz mean SM clock, at most 72 °C):

| run | 10 fields | fs per admissible n | against main (6.615) |
|---|---|---|---|
| sampled check on (the bench's default) | 307.60 s | **1.6809** (yesterday at `46c99784`: 1.6980) | ×3.94 |
| sampled check off | 305.93 s | **1.6717** (yesterday: 1.6911) | ×3.96 |

About −1.1 % against yesterday (estimate of the trunk's speed work on CUDA; the two sessions are different
instances on the same host model, so part of it may be the session). **Every field's survivors, checked and slice
count are identical to yesterday's run before these commits** (all ten, both runs; `raw/trunk/y.txt`, `a.txt`,
`b.txt`), and all ten sampled slices equal the CPU reference. The client route's merged run (§5, 6 b64 fields and
b65 t 77777) is a third check: equal to the library and, for b65 t 77777, to the pre-merge counts.

## 11. Step 5L: the route with both coordinates (2026-11-19, `G2/build5l/raw/p1b/e2e/`, `final/e2e/`)

Box Vast 61386517 (the same), production hosts blocked and checked (`hosts_proof.txt`). One coordinator, four fields
in one work list: b64 `midout:4,8,5` t 77777 and t 5461, b65 `midout:4,8,5` t 13731 (`range_size`
1,011,440,671,053,109,375, its padded count), b64 `midout:4,9,6` t 77777 (cut with `midout_fields --digits 4,9,6`);
one client `niceonly --midout-coordinator … --repeat`: **4/4 claimed, searched and accepted** (rc 0, 08:56–08:58 UTC).
Counts: (4, 8, 5) t 77777 survivors 48,216,914,309, checked 1,384,731,444 (= the library's test of the same field);
(4, 9, 6) t 77777 48,199,033,671 / 1,384,147,294 (= every earlier run of that field); b65 (4, 8, 5) t 13731
69,600,528,738 / 2,222,514,230 (= the library's production-path test); every b64 sampled CPU check equal. The client
binary was built at `4925122a`'s tree, so parent sharing (default on from `7e682f05`) was not in it; the head's
binary ran one (4, 8, 5) field through the route again in `final/e2e/` (§13.5 of BUILD-NOTES).

Telemetry: `pipeline.coordinate` carries the id the claim named (`midout:4,8,5` or `midout:4,9,6`); `join.shape` is
[4, 10] for both. For the server list of §8: item 2's "a re-cut is a new id" now has its first instance: fields of
`midout:4,8,5` and `midout:4,9,6` are different sets of n for the same `range_start` at base 64, so a field row must
carry its id.
