# The midout mode against the proposed endpoints (notes, 2026-11-25)

Brief: `G2/MODE-BRIEF.md`. Branch **`dev/mo-mode`** from `dev/mo-clean` `66305ada`, worktree
`~/projects/nice/.worktrees/mo-mode`, pushed to `fork` only (no PR, nothing to `origin`). Proposal read:
`G2/PROPOSAL-B.md` §3. Scratch: `G2/mode/` (logs, the adapted harness, captures).

## 0. Where it stands

**Head `f61cf79e`** (9 commits on `66305ada`, each compiling; pushed to `fork/dev/mo-mode`).

- `nice_client midout` exists, in `--help`, beside `detailed` and `niceonly`; `--midout-coordinator` is gone. It
  claims `GET /claim/midout` and submits `POST /submit/midout` in the proposal's shapes (`common/src/midout/wire.rs`),
  over `--api-base`, with the other modes' retries.
- The card does not wait on HTTP: the next field is claimed while one is searched (at most one ahead), the previous
  submission finishes in the background (at most one in flight); the stop rule is kept (§3).
- `scripts/midout_coordinator.py` serves the same two paths, the eight checks, expiring claims and the three reply
  statuses; the audit tool reads its new records. The fault harness, adapted, found **one real defect** in the
  coordinator that the new wire exposes (an unsynced record acknowledged after a restart, §5), fixed.
- End to end without a card: the real client loop, generic over the search, against the real coordinator on
  127.0.0.1 with the CPU reference on bases 10 and 20 (normal run + audit, lost reply, 409, 422, failed search,
  server without the endpoint). The real binary on lavapipe: device init, the refusals, 404, 204 (§4).
- Not done: a real base-64 field through the binary (needs a card: lavapipe cannot do one in the time); a merge of
  the two benches (not wanted today; §7).

## 1. The mode, option by option

| option | in `midout` | why |
|---|---|---|
| `--api-base` | the server (`/claim/midout`, `/submit/midout` under it); a trailing `/` is dropped | as every mode; the production-address refusal is gone: a server without the endpoint answers 404, read as one error |
| `--username`, `--api-max-retries` | as in the other modes | |
| `--repeat` | without: one field, or "nothing claimable" → message, exit 0. With: until stopped; 204 waits 1 s, doubling to 256 s, never giving up | the other modes, when the server has nothing, retry its 500 on the ladder 1, 2, …, 256 s and then exit; a midout box keeps asking at the ladder's longest step instead, as "nothing claimable" is a normal state for it |
| `--gpu` | implied (not needed) | the join has no CPU form for a real field |
| no `CubeCL` backend in the build | refused, exit 1: "this build carries no CubeCL backend, and the middle-out join has no CPU form for a real field" | must refuse, not crawl |
| `--gpu-backend` | `auto` (cubecl-cuda if built, else wgpu), `cubecl`, `cubecl-cuda`; `cuda` and `cubecl-hip` refused with one sentence | the join runs on `CubeCL` only; HIP never ran it |
| `--gpu-device` | the CUDA device; on wgpu a non-zero value warns (it does not pick a wgpu adapter) | as the other modes |
| `--gpu-wgpu-device` | sets `CUBECL_WGPU_DEFAULT_DEVICE` before the context | **the dev route ignored it** (it ran before `init_gpu`); fixed |
| `--threads` | the sampled CPU check's threads, **only when given**; otherwise the library default (CPUs − 1, at most 4) | passing the n-range default 4 always would oversubscribe small boxes |
| `--telemetry` | no effect: telemetry is always sent | it carries the sampled check's evidence and the join's counters; the hardware block of `--telemetry` needs the other modes' GPU context |
| `--validate` | refused: "the server has no validation data for middle-out fields; every field gets the sampled CPU check instead" | silent surprise otherwise |
| `--benchmark*` | refused, pointing at the `midout_bench` example | the sweep measures the n-range modes |
| `--prefetch-*` | ignored with a warning (also when set in the environment) | a tuning knob, not semantics; a refusal would break fleet boxes that export `NICE_PREFETCH_*` for every mode |
| `--no-progress` | no effect (no bar) | the route never fed the bar |
| `-l/--log-level` | as everywhere | |
| `NICE_MIDOUT_FAULT` | test switch, `midout-fault` builds only (unchanged) | |

Guards kept from the route (each refuses with a reason, exit ≠ 0, nothing submitted for that field): Apple Metal
refused; unknown coordinate / base without a device path / not whole quanta / wrong `range_size` refused
(`field_of`); failed accounts or a differing sampled check (library errors); the panic hook (installed before the
device context; checked before a claim is used and after each search).

**Where `ClientMode` and `SearchMode` merge.** `client/src/main.rs` has `ClientMode { Detailed, Niceonly, Midout }`
for the command line; `ClientMode::search()` maps the first two to `nice_common::SearchMode` at the 17 call sites
(`main.rs`, `bench.rs`), and its `Midout` arm is `unreachable!` because `main` hands the mode to `midout_route`
before anything asks. When the server change lands (proposal: `SearchMode` gains `Midout`, stored as mode
`midout` in the cache tables), give `SearchMode` the variant, delete `ClientMode`, make `Cli.mode: SearchMode`
again, and let the compiler flag the matches the proposal lists (`client_api_async.rs` claim URL: refuse
`Midout` there; `main.rs` process match; `db_util/conversions.rs`; `estimator.rs`). The `unreachable!` disappears
with it.

## 2. The wire as built

`common/src/midout/wire.rs`: `CLAIM_PATH = "/claim/midout"`, `SUBMIT_PATH = "/submit/midout"`, `CoordClaim`
(unchanged), `FieldId`, `Submission`, `Reply { submission_id: u64, status: canon | check | already_recorded }`,
`ClaimAnswer { Field, Empty }`, the pure `claim_answer(status, body)` / `submit_answer(status, body, claim_id)`, and
`TELEMETRY_MAX_BYTES = 16 KiB`. HTTP in `common/src/client_api_async.rs`: `claim_midout_async`,
`submit_midout_async` (on the existing `retry_request_async`: network errors and 5xx retried).

| answer | client |
|---|---|
| claim 200 | parse `CoordClaim` (u128, exact), `field_of` |
| claim 204 | nothing claimable (§1 `--repeat`) |
| claim 404 | stop: "this server does not offer middle-out fields (GET /claim/midout answered 404)" |
| claim 5xx (503) / network | retried; after `--api-max-retries`, stop |
| submit 200 `canon` / `check` / `already_recorded` | success (logged; `already_recorded` = a reply had been lost) |
| submit 409, 422 | stop with the server's message: "this client and the server disagree about the field" |
| submit 400, 413, 404, other 4xx | stop with the message |
| submit 5xx / network | retried with the same body (so a lost reply comes back `already_recorded`) |

Serde tests read the proposal's two JSON examples **verbatim** and write the submission back byte-equal as JSON
values; big integers are canonical decimal strings only (numbers, signs, leading zeros, `1e3`, 2^128 refused).
Telemetry over 16 KiB (never seen: the route's is ~1.5 kB, fixed size) is sent without its `pipeline.join`.

**One real exchange** (end-to-end test, base 10, coordinate `midout:0,1,0`, CPU reference; captured from the
server's state, `G2/mode/e2e_capture/nice-midout-normal-*`):

```
GET /claim/midout  ->  200 {"claim_id": 1009, "base": 10, "coordinate": "midout:0,1,0", "range_start": 101,
                            "range_end": 107, "range_size": 6}
POST /submit/midout   {"claim_id": 1009, "username": "test", "client_version": "3.4.9-dev",
  "field": {"base": 10, "coordinate": "midout:0,1,0", "v_start": "101", "v_size": "6", "range_size": "6"},
  "nice_numbers": ["69"], "shape": "0,2", "survivors": 1, "checked": 1, "slices": 1,
  "telemetry": {"build_sha": "a38c9f4d…", "client_version": "3.4.9-dev", "device": "the CPU reference",
                "pipeline": {"coordinate": "midout:0,1,0", "join": {"path": "cpu"}, "route": "midout"},
                "processing_secs": 0.0039}}
  ->  200 {"submission_id": 10, "status": "canon"}
```
(The lost-reply test: the first POST's connection closed after recording, the retry 1 s later answered
`{"submission_id": 1, "status": "already_recorded"}`; the 422 test: "slices 2, but the field has 1 slices under
shape 2,4".)

## 3. The loop (`client/src/midout_route.rs`, `run_loop`)

Generic over `FieldSearcher` (accept + search; the device path `DeviceSearch`, the tests' `CpuSearch`) and `Api`
(claim + submit futures; `HttpApi`, the tests' stand-in). On the search thread: ask the claim → (204: finish the
submission in flight, then wait or end) → `accept` (every guard) → **under `--repeat`, ask the next claim now** →
if the submission in flight has finished, read it (a refusal stops the run before more work) → search → health
check → **wait for the previous submission** (at most one in flight) → spawn this one → loop. On every exit, the
submission in flight is finished and reported (its failure joins the error); the claim held ahead is aborted
(on the server it expires). After a failed search, failed accounts, a recorded panic or a refused submission
nothing more is submitted and the result is an error (exit 1).

Cost of the overlap: at most one claim held unsearched when a run stops (expires after the claim duration). The
card waits only if a submission takes longer than a whole field (then the loop blocks before spawning the next).

## 4. What was tested, and where

| what | where | result |
|---|---|---|
| client unit + e2e tests (`midout_route::tests`, 17: options/refusals, `--help`, removed flag, Metal, claim checks, loop with stand-ins: run to nothing left, one held ahead, no claim ahead without `--repeat`, failed search with a submission in flight, unhealthy process, refused submission, overlap timing, 204 waits, telemetry trim; e2e vs the real coordinator: 30-field run + audit exit 0 + `already_recorded` + 409, lost reply, 422, failed search, 404) | ivory, default features and `cubecl,midout-fault` | all pass |
| wire serde/answer tests (`midout::wire`, 6) | ivory | pass |
| tier (a): `nice_common` lib (release, `cubecl,midout-fault`), `nice_client` | ivory, at `25d88cd1` (later commits: examples, docs, Python, client-only; client tests rerun at each) | 285 passed, 0 failed (48 ignored); client 41 passed |
| tier (b) on lavapipe, WGSL + SPIR-V (+ Metal) | fork CI "GPU Device Parity", dispatched on `e8240ebb` | success; dispatched again on `bbbb4c7e` (the Rust of the head but for one test-only commit): success, lavapipe and Metal |
| tier (b) locally in `lvp26` | ivory | **not completed**: the run stalled while the machine's load average reached ~46 (other work) and was stopped by the 30-min background limit; CI's result stands in for it |
| `just lint` | fork CI "Format and clippy" (= `just lint`) on `e8240ebb` | success; again on `bbbb4c7e`: success. Locally: `cargo fmt --check`, clippy `-D warnings` on client+common all targets with default features, `cubecl,midout-fault`, and the examples with `cubecl,midout-bench` |
| CI test matrix | fork CI on `e8240ebb` | native Linux, Windows, macOS ×2, musl, riscv, FreeBSD, CUDA host code pass; **i686, armv7, arm-musl, aarch64 fail in code this branch did not touch**: `midout::coord::tests::b65_padded` (`usize::try_from(q / 4099)` overflows on 32-bit, coord.rs:547), the existing `client_api_async::tests::ordinary_claims_refuse_a_coordinate_field` and my `a_server_without_the_endpoint…` (a loopback `bind` is ENOSYS under the i686 qemu runner), and a SIGKILL in `cpu::tests::threaded_slice_join_equals_single_threaded` (aarch64 qemu). **The same failures on `dev/mo-clean` `66305ada`** (fork CI run 45569796574, dispatched for the comparison): aarch64 SIGKILL, i686 `b65_padded` and `ordinary_claims…`; so none is from this branch. My 404 test is made to skip there (`f61cf79e`, not yet through CI). On `bbbb4c7e` the matrix was otherwise as above (armv7 and arm-musl still running at the time of writing). |
| the real binary on lavapipe (`lvp26`, `--network host`, release `cubecl,midout-fault`) | ivory | device init on llvmpipe; unknown coordinate `midout:4,8,6` refused, 0 submissions; a server without the endpoint (Python `http.server`) → the 404 sentence, exit 1; empty work list → "no middle-out field to hand out now", exit 0; `--validate`, `--gpu-backend cuda` refused. (The container needs the host's `/etc/ssl/certs` mounted, or reqwest's client cannot be built.) |
| the coordinator's coordinate port vs the Rust | ivory | at start the coordinator checks every field's quanta and `n_count`; started on 2,514 Rust-cut fields (bases 64, 65 ×2 coordinates, 68, 70, 10, 20, 25) and on the padded first/last fields of 65, 68, 70, 20: all equal |
| examples | ivory | `--help`, unknown option, bad value, `--t` with `--spread`, t past the end: refused with reasons; base-65 values equal the coordinator's |

All client runs used an explicit `--api-base http://127.0.0.1:PORT` (the unit tests use `http://127.0.0.1:9` where
an address is needed); nothing contacted `nicenumbers.net`.

## 5. The fault harness

Copied to `G2/mode/harness/` (the original `COORD/harness/` untouched) and adapted: shared wire helpers `mo.py`
(typed bodies; base-65 fields cut with the coordinate port, as the coordinator now validates them), the new paths,
`--claim-duration` for `--reissue-after`, the semantics (`dup` resends the same body → `already_recorded`; new kinds
`redo` (same claim, another result → 409), `slices`, `notnice`; the `route` kind dropped (telemetry is no longer
evidence of the field); junk `bigtel` (17 KB telemetry → 413), `numstr`, `deep` = field as a list). Invariants
changed with the wire: **H2** one canon per field, a check only after its canon, one accepted record per claim;
**H6** a late first holder is canon, the later one a check; **E1** exactly one canon per field. S1–S7, H1, H3–H5,
E2 unchanged. `repro/repro_unsynced_record.py` added.

**Finding (fixed, `a38c9f4d`).** A complete record written just before a kill but not yet fsynced was read at the
next start and trusted; with the new wire a resubmission is then answered `already_recorded`, so a power loss after
that reply lost an acknowledged record (S2) and the field was handed out again (H1) — chaos seed 1545. The
coordinator now fsyncs both state files after reading them; the repro fails on the version before and passes after.
(The old wire answered that resubmission 409, which is not an acknowledgement, so the gap was latent.)

**Runs (after the fix, `G2/mode/`):** `run_all.sh` (9 smallest reproductions incl. the new one, 60 randomized
runs, the byte sweep over 1,116 truncation offsets): all pass. **1,500 ordinary randomized runs (seeds 1000–2499,
with the audit): 0 failed** (every event, client kind and reply status exercised: 347 runs with a late first holder
accepted after a reissue, 353 with a check recorded, 409 in 588, 422 in 1,261). **300 stress runs (16–32 clients,
seeds 50000–50299): 1 failed**, seed 50081, H5: a 2 MB body refused by its Content-Length (413 and close) came back
as an empty read rather than a reset error, which the harness tolerates only as a reset; rerun 3× it passes, and
that code path is unchanged from `66305ada`: a tolerance of the harness under load, not a coordinator defect
(kept in `G2/mode/chaos/fail-50081`). Before the fix, a first 1,500-run batch had seed 1545 (the defect above) and
~25 runs that timed out while the machine's load average stood near 46 (other work); those seeds pass on rerun.

Harness sanity (mutants, 40 runs each, `G2/mode/mutants/`): accepting a different result under one claim (m1) →
17 of 40 runs fail (H2, H3/H4, E1). No check of the field against the claim (m2) → 8 of 20 fail (H3/H4); no slice-count check (m3) → 5 of
20 (H3/H4); a second canon allowed (m4) → 3 of 20 (H2, E1). Under m1 the audit and the harness's own file checker
disagreed in 4 runs: the audit also flags two accepted records under one claim, which the checker does not.

## 6. Questions the proposal must answer

Each: the reading built (easiest to change) and the question.

1. **Big integers in the claim are JSON numbers** (`range_start` 3.8·10^22 > 2^64), in the submit decimal strings.
   Built: as written (serde reads u128 exactly). Most JSON stacks (JavaScript, PostgREST clients, `jq`) read such
   numbers as doubles. Should the claim use strings too?
2. **`nice_numbers`' element type** is not given (the example is `[]`). Built: decimal strings (`["69"]`), per "big
   integers as decimal strings". `/submit` uses `{"number", "num_uniques"}` objects; which?
3. **"`slices` = the field's slice count"** depends on the shape. Built: the count under the submitted `shape`,
   which must be able to search the field (`f0 ≤ q0`, `k1 < k ≤ digits`). Should the server instead fix the shape
   per coordinate (e.g. in `midout_bases`) and refuse others?
4. **"Identical" resubmission** (check 6): built as everything but telemetry (field, numbers, shape, counters,
   username, client_version). A retry resends the same bytes either way; is telemetry part of identity?
5. **Order of checks 3–5 before 6**: a resubmission under the same claim with another *field* answers 422, not 409.
   Built as the table orders it; intended?
6. **404 means two things on submit**: "unknown claim" and "no such endpoint" (an old server). The claim's 404 is
   read as "no endpoint"; a submit 404 just stops. A distinct status or a JSON error body would tell them apart.
7. **A disagreeing check** is answered `check` like an agreeing one; the client cannot log a disagreement. Add
   `"matches_canon"` to the reply, or a status?
8. **503 on the claim** is retried on the client's ladder and then stops the client (~9 min at the default 10
   retries), like the other modes; 204 waits forever. Should a midout box also wait out a 503 indefinitely?
9. **Request body limit** is not stated (the API has no `Rocket.toml`): built 1 MiB → 413 in the development
   server; the client's bodies are ~1.5 kB.
10. **`telemetry`**: built as optional (object, null or absent) on the server side; the client always sends an
    object. Required?
11. **Counters as JSON numbers**: `survivors`/`checked`/`slices` per one-quantum field are far below 2^53, but a
    k-quanta field (§7.1) multiplies them; strings for safety, or a bound?
12. **Claim ahead**: the client holds one claim ahead, so a client that stops leaves one claim to expire (an hour
    of one field idle). A release endpoint (`DELETE /claim/midout/{id}`)? (Not needed for correctness.)
13. **204 can mean "no midout base inserted yet" or "all done"**; the client cannot tell. A status body?

## 7. Examples (`common/examples/`)

`midout_bench.rs`, `midout_wide_bench.rs`, `midout_fields.rs` read options through one shared reader
(`examples/support/args.rs`, not an example itself): `--help` with every option, unknown option / missing value /
bad value / repeated option refused by name; headers say what each is for, how to run it, and what **fs per
admissible n** means (femtoseconds of wall time per n of the field in a residue class `r mod (b−1)` a nice number
can be in, `arith::roots`: 8 of 63 at base 64); input refusals with reasons (classes outside 1–63, zero
group/threads/slices, fields past the base's last, unknown `MIDOUT_STOP`, wide base outside 64–70, `--t` with
`--spread`); `--host-tops` documented (it was a hidden switch). What they measure is unchanged except
**`midout_bench --tops-only`, which timed slices `t<<12 | i` — the field's slices only under `4,9,6`**; it now takes
the field's own slices (`Shape::slices_of`; identical under `4,9,6`). Not run on a card today.

**Merging the two benches** (not done, as asked): feasible at low risk — `midout_wide_bench --narrow-only --base 64`
already runs the base-64 path; what `midout_bench` adds is host tops, `--tops-only`, `--slices`, parent sharing and
its stops 11–15. One example with `--base` would need those switches to refuse at bases ≠ 64. Keep both until the
five sessions' numbers are re-taken with the merged one.

## 8. Found in the existing route while moving it

- `--gpu-wgpu-device` was ignored (the route ran before `init_gpu`, which sets `CUBECL_WGPU_DEFAULT_DEVICE`).
- The sampled check's threads could not be set (route: always the default).
- Any 4xx stopped the dev client, including the coordinator's 409 for a resubmission after a lost reply (COORD
  RESULTS §5); `already_recorded` removes that spurious stop.
- `midout_bench --tops-only` timed the wrong slices under the default coordinate (§7).
- Pre-existing CI failures on 32-bit/qemu targets in untouched code (§4).

## 9. Processes, ports, state

Started and stopped by PID: smoke servers on 127.0.0.1:18480–18482 (state `G2/mode/smoke/`), port checks on
18471–18472 (state removed), the tests' servers (ephemeral ports, state under the system temp dir, removed by the
tests), the harness's coordinators (ephemeral ports, `G2/mode/chaos`, `G2/mode/run_all`, removed per passing run).
One coordinator left by a crashed first repro run (PID 1718776, `repro_runs/cross-*`) and the smoke test's Python `http.server` on 18481 (PID 2143029: I had recorded its subshell's PID, 2143028) were found and killed by PID.
The `lvp26` containers ran with `--rm`. The worktree's `target/` is removed at the end (done before the report; 7.4 GB).
