# Review: `nice_client midout` and its development server (`66305ada..f61cf79e`, 2026-11-26)

**Verdict: sound to build on.** No path found in a release build that records an unsearched field as searched or drops a found number from a submission. The stop rule, claim/result pairing and retry identity hold.
**Findings: 2 rank A (wrong result possible: one in a test build only, one an audit that can certify a wrong canon), 7 rank B (robustness), 7 rank C (quality).** Each fix below is small.
Reviewer: independent, reading only. Commits read by hash (`git show f61cf79e:…`, `git diff 66305ada f61cf79e`), never in the worktree. Line numbers are at `f61cf79e`.

---

## What holds (checked, no finding)

- **Claim and result cannot cross.** `run_loop` is one thread. The field searched (`accept(&c)`), the `FieldId` (`FieldId::of_claim(&c)`) and the body's `claim_id` all come from the same local `c` (`midout_route.rs:393-436`). `in_flight` carries the claim id of the body it holds.
- **Stop rule.** A failed search, or a panic seen right after the search (`.and_then(healthy)`, :412-414), returns before `submission()` is built. A refused or failed submission comes up either at the `is_finished` peek (:400) or at the `finish` before the next spawn (:435), so the field searched meanwhile is not submitted. A claim error (`??`, :366) ends the run. Every exit path that returns goes through the tail `finish` (:444) and returns `Err`, so the exit is non-zero (`main` returns the `Err`).
- **Retry identity.** The body is built once (:433), and `retry_request_async` re-serialises the same `&Submission` on each attempt, so a retry carries identical bytes. `processing_secs` is computed once. Telemetry is excluded from "the same result" anyway (`midout_coordinator.py:328-331`).
- **No non-200 is treated as success.** `claim_answer`: only 200 gives a field, 204 means `Empty`, everything else is an error. `submit_answer`: only 200 with a valid `Reply` counts. 5xx and network errors are retried, anything else stops (`wire.rs:158-199`). This matches the notes' §2 table.
- **Big integers.** Claims are parsed with `serde_json::from_slice` straight into `u128`, which is exact, and never pass through `Value`. Submissions use canonical decimal strings. No `f64` is involved anywhere. The counters are `u64` JSON numbers, and Python reads them as exact ints.
- **The claim is checked before work.** `field_of` (`midout_route.rs:496-539`) parses the id, checks the base is 64–65, builds `Coord::with_digits`, requires `is_known`, requires whole quanta inside v, and requires `n_count == range_size`. `FieldJoin::search` checks `is_known` and the base again (`route.rs:97-105`).
- **The dev server's eight checks** run in the proposal's §3 order (`midout_coordinator.py:508-563`). Durability: every acknowledgement (claim 200, submit 200, 409/422) follows `append` → `fsync`. `already_recorded` is served only from memory, and memory is filled only after a durable append, or from files that are fsynced at start (a38c9f4d) before `serve_forever`. I found no second path that acknowledges first (but see C6).
- **The server's coordinate port** (my 5-line check): base 64 under `4,8,5` and `4,9,6` gives quantum 2^57 and 4096 slices under `4,10`. Base 10 under `0,1,0` gives quantum 6, counts `[5×7, 6×3]`, and 69 falls in t = 9. `default_shape` and `slice_count` agree with `cpu::Shape::for_coord/fits/slices_of`. Padded slices are not skipped on any path (`gpu_wide.rs:3903`, `cpu.rs:953`), so the server's formula equals the device's count.
- **Other modes are unchanged** (item 7). `ClientMode` has the same value names and `Display` output as `SearchMode`. Every `cli.mode.search()` (main.rs 725, 746, 871, 1122, 1213, 1366/1368, 1442, 1595; bench.rs) runs after the midout dispatch (main.rs:1797). Moving the `--validate`/niceonly check below that dispatch changes nothing for the other modes. `route.rs` only threads `cpu_threads` through, and `client_api_async.rs` only adds code.

---

## Rank A: a wrong result is possible

### A1. A `midout-fault` build can now submit to any server, and the `sample` fault is not reliably caught
`midout_route.rs:549-561, 665-683`, together with the removal of `wire::check_coordinator_url` (66305ada `midout_route.rs:152`).
- **Scenario.** Someone runs a `--features midout-fault` binary with `NICE_MIDOUT_FAULT=sample` and an `--api-base` that serves `/claim/midout`. Today that is the dev server; once the server change lands, it is production.
- **Mechanism.** `sample` makes the prefilter drop ~1/1024 of survivors, and "only the sampled CPU check sees it" (`route.rs:146-150`). That check covers one random slice of 4096. Whenever the dropped survivors miss that slice, the field passes every guard and is submitted with missing work. A nice number among the dropped survivors would then be lost, and the field recorded as searched.
- **Why it is new.** The old route refused the production address. The mode now deliberately has no such guard (notes §1). I could not determine from reading how often a slice holds a dropped survivor, so the detection rate is unknown.
- **Smallest fix.** In `midout-fault` builds, while a fault is set, refuse any `--api-base` whose host is not loopback. Cheaper alternative: refuse to submit at all when `fault.is_some()` and the host is not `127.0.0.1`/`localhost`. Optional server-side backstop: 422 on a non-null `telemetry.test_fault`.

### A2. The audit says OK when a check disagrees with its canon, and leaves out numbers that only a check found
`midout_audit.py:154-161, 174-176, 216`. The server side of the same gap is `midout_coordinator.py:341-349` and `/status` :503-505.
- **Scenario.** Field F gets a canon with no nice numbers. A later accepted check of F reports `["n"]`.
- **What happens now.** The audit puts the check in `disagree` (printed only when not `--quiet`) and leaves it out of `problems`. Its "nice numbers reported (accepted)" line lists canons only, so `n` appears nowhere in that summary. It exits **0 (OK)**. That is exactly the case where the canon recorded an unsearched or mis-searched field as searched, and the only tool that certifies a state directory passes it. The dev server answers `check` with no mark, keeps level 1, and `/status` has no disagreement count. The proposal records `matches_canon = false` and indexes it.
- **Smallest fix.**
  - Make every disagreement a `PROBLEM` (exit 1).
  - List nice numbers from every accepted submission, marking those missing from the canon.
  - Optionally add `"disagree"` to `/status`.

---

## Rank B: robustness (waste, a stopped client, or a test double weaker or stricter than the real thing)

### B1. A panic on the loop's own thread skips the tail and drops the submission in flight
`midout_route.rs:412-414, 571-573`.
- **Scenario.** `FieldJoin::new` (:657) or the search panics on the calling thread (a CubeCL allocation panic surfacing there, an `expect` in the library) while field k-1's submission is in flight.
- **What happens now.** The unwind leaves `run_loop` without running `finish`, and the `JoinHandle` is detached. `main` returns `Err("the mode's thread ended: … panicked")`, and runtime shutdown cancels the request. Field k-1 was searched correctly, but it is not recorded and is re-searched after expiry. Field k is not submitted, which is correct.
- **Fix.** Wrap `searcher.search(...)` (and the `FieldJoin::new` inside it) in `catch_unwind(AssertUnwindSafe(..))` and map a panic to `Err`, so it takes the failed-search path and the tail runs.

### B2. `--gpu-backend auto` has no wgpu fallback in GPU release builds
`midout_route.rs:587-594`.
- **The difference.** With `cubecl-cuda` built (the `gpu` umbrella, i.e. every GPU release), `Auto` means `new_cuda` only, and that call is unguarded. The other modes' `Auto` runs it under `guarded_init` and falls through to wgpu (main.rs:683-705). main.rs:419-421 says a box with no NVIDIA driver fails through a cudarc panic.
- **Scenario.** On an AMD or Intel card, the README's `./nice_client midout --repeat` dies with a panic and "the mode's thread ended". Users of the other modes expect `auto` to find the card. The notes' option table says "`auto` (cubecl-cuda if built, else wgpu)", which is true of the build but not of the box.
- **Fix.** Reuse `guarded_init` (make it `pub(crate)`) for `new_cuda` under `Auto`, and fall back to `wgpu_context` on error, as `init_gpu` does.

### B3. A server outage of about 8.5 min stops every midout client and loses each one's last searched field
`client_api_async.rs:240-262` via `retry_request_async`. With 10 attempts, the waits are 1 + 2 + … + 256 s.
- **Scope.** Notes §6.8 and proposal §9.7 raise this for the claim only. The submission is the costly side, since a searched field is thrown away and re-searched after expiry. It also hits the whole fleet at once on a long server restart. A submit is idempotent (`already_recorded`), so retrying it longer is safe.
- **Fix.** Under `--repeat`, keep retrying submit 5xx and network errors at the 256 s cap with no limit, or for at least the claim duration. If wanted, do the same for the claim, as §9.7 recommends.

### B4. A reply lost mid-body is not retried
`client_api_async.rs:221-225, 251-257`.
- **The gap.** `retry_request_async` retries only `send()` errors and 5xx. A 200 whose body read fails or times out (`CLIENT_REQUEST_TIMEOUT_SECS = 5` covers the whole request) goes to `process_response` and becomes a hard error.
- **Effect.** For the submit, the client stops even though the server recorded the field and a retry would get `already_recorded`. For the claim, a held claim is lost and the client stops.
- **Fix.** In the two midout closures, turn a body-read error into a retry. For submit this is safe because the call is idempotent. The smallest version is a loop around `submit_midout_async` that retries on that one error.

### B5. SIGTERM/SIGINT drop the submission in flight and the claim held ahead
No handler, which is the same as the other modes. `docker stop` costs up to one searched field (re-searched after an hour) and one idle claim. Nothing wrong is recorded.
- **Fix (optional).** On SIGTERM, stop claiming, `finish` the submission in flight, and exit. Under `--init`, docker's 10 s grace period is usually enough.

### B6. The dev server is stricter than the proposal on telemetry size
`midout_coordinator.py:525` measures `json.dumps(..., separators)`, which defaults to `ensure_ascii=True`. The client measures UTF-8 `serde_json::to_vec` (`midout_route.rs:281`).
- **Effect.** Any non-ASCII character counts 6–12 bytes on the server and 2–4 in the client (checked: `{"d":"é™"}` is 20 vs 13 bytes). The client's trim also removes only `pipeline.join`, so it does not guarantee a fit. A 413 then stops the client.
- **Real-world reach.** None today: telemetry is about 1.5 kB of ASCII.
- **Fix.** `ensure_ascii=False` and `.encode()` on the server. In the client, re-measure after the trim and drop `extra` too if still over.

### B7. Two test-flake sources in the end-to-end tests
`midout_route/tests.rs:646-663, 733-734, 797-800`.
1. **Port race.** `Server::start` binds port 0, closes it, and then hands the number to Python. With cargo running the four e2e tests in parallel, another test (or process) can take the port. The readiness probe would then connect to the other test's server, and the test would run against the wrong state. Fix: start the server with `--port 0` and read the bound port from its first stderr line.
2. **Timeout turns Canon into AlreadyRecorded.** The 5 s request timeout and fsync under one global lock: on a loaded machine (the notes mention load ~46), a reply slower than 5 s is retried and comes back `AlreadyRecorded`. That fails `replies == [Canon; 30]` and `[AlreadyRecorded, Canon]`. Fix: give the test `HttpApi` a longer timeout, or assert "Canon or AlreadyRecorded" except where the test means it.

---

## Rank C: quality

- **C1.** The claim ahead is spawned (:396-398) before the peek that reads a finished refusal (:400). A refusal therefore costs one extra claim that idles for an hour. Swap the two blocks.
- **C2.** `healthy()` is not re-asked after `finish` at :435, which can block for minutes on retries. A panic recorded there does not hold back this field's submission. This is benign, because the results were read back and accounted before the post-search check, but one more `healthy()?` before the spawn at :436 costs nothing and keeps the rule literal.
- **C3.** `--gpu-backend cubecl-cuda` in a build without `cubecl-cuda` falls to `other => bail!("backend CubeclCuda has no middle-out path")` (:593). The Debug name and wording are wrong (1e173f7d fixed the spelling only in `from_cli`). Say "this build has no cubecl-cuda".
- **C4.** Option-table surprises (item 6):
  - An `NICE_BENCHMARK_UPLOAD`/`_JSON` truthy env var implies `--benchmark` (main.rs:1724), so `midout` refuses with a sentence about `--benchmark` the user never typed. Name the env var in the refusal.
  - `--threads 0` (or `NICE_THREADS=0`) counts as "given" and resolves to every CPU for the sampled check (main.rs:1733-1745), which undoes bbbb4c7e's purpose on a fleet that sets 0. Treat 0 as "not given" in `midout`.
  - `--telemetry` and `--no-progress` are accepted silently. That is fine, but `--telemetry` deserves the same warning `--prefetch-*` gets.
- **C5.** Wire forward-compatibility. `ReplyStatus` has no catch-all, so a server that adds a status (one option for proposal §9.6) makes every deployed client stop after its submission was recorded. Recommend §9.6 add a field (`matches_canon`), not a status. Proposal gap: `midout_submissions.elapsed_secs REAL NOT NULL`, but `Submission` has no top-level elapsed, the dev server treats telemetry as optional, and the §3 example sends `"telemetry": {}`. The real server would have to read `telemetry.processing_secs` or refuse the example. Decide this in §9 (add `elapsed_secs` to the typed body).
- **C6.** Dev-server durability corner cases, both very unlikely:
  - The parent directory of a newly created `--state` directory is never fsynced (:242, :381-383 fsync only its entries).
  - An exception after a durable `append` and before `accept()` (e.g. `os.close` failing in `append`'s `finally` after a good fsync, :313-314) leaves memory behind disk. The retry then writes a second accepted record for the claim, and the next start refuses to run (:365-367).
  - Fsync `dirname(state)` once at start. In `append`, ignore `close` errors after a successful fsync.
- **C7.** Documentation:
  - README:36/79 say "base 64 and up", but the client takes 64–65 only (`field_of`, :502).
  - `ClientMode::search()` is an `unreachable!` panic, not a type. It is documented and temporary, but a future call placed above main.rs:1797 panics in every `midout` run. A one-line test that runs `main`'s pre-dispatch path with `midout` would catch it.

---

## Tests (item 5)

**What is real.**
- The e2e tests run the production `run_loop`, `HttpApi`, `claim_midout_async`/`submit_midout_async` and `wire` against the real dev server.
- The searcher is a stand-in, and so is its `accept`: `CpuSearch::accept` is `field_in` without `field_of`'s base and `is_known` guards.
- The loop config is the tests' (`Idle::Stop`), not `drive`'s (`Idle::Wait`).

**Behaviours with no test.**
- The panic hook itself (`install_panic_hook`/`no_panic_so_far`): every test uses a `healthy` closure.
- `field_of` refusing a claim mid-run, after good fields (the in-flight submission must still finish).
- A change of base (the join is dropped).
- A panic on the loop thread (B1).
- Submit 5xx until retries run out.
- An e2e 413.
- The tail's double error (`(Err, Err)`).
- A body-read failure (B4).
- `Idle::Wait` with `repeat = false`, which is production's one-shot path. Covered only by the notes' manual lavapipe run.

**Timing.** The stand-in tests' margins (300–400 ms against a microsecond CPU search) are safe. The e2e tests have the two flake sources in B7. The 404 test now skips where loopback is missing (f61cf79e). `Server::start`'s own `bind(...).unwrap()` would panic the same way on a target that has `python3` but no loopback (today such targets lack `python3` and skip).

---

## What I read and ran

**Read in full at `f61cf79e`:**
- `client/src/midout_route.rs`, `client/src/midout_route/tests.rs`
- `common/src/midout/wire.rs`
- the new part of `common/src/client_api_async.rs`, plus `retry_request_async`
- `scripts/midout_coordinator.py`, `scripts/midout_audit.py`
- `common/examples/midout_fields.rs`, `common/examples/support/args.rs`
- the diffs of `main.rs`, `bench.rs`, `route.rs`, `mod.rs`, `README.md`, `Cargo.toml`s and `midout_bench.rs`
- the old route at `66305ada`

**Read in part:** `main.rs` (main, `init_gpu`'s auto fallback, `guarded_init` docs), `cpu::Shape`, and the slice and nice-number gathering in `gpu.rs`/`gpu_wide.rs`.

**Briefs and notes:** BRIEF-REVIEW, G2/MODE-NOTES (all), PROPOSAL-B §2, §3, §6–§9.

**Ran:** `python3 -I midout_coordinator.py --help`, from a copy in my scratchpad. A Python check of the server's `Coord`, `slice_count`, `contains` and `is_nice` (results above), and of the `ensure_ascii` byte counts.

**Not done:** no cargo build, no server started, nothing pushed or commented, no network access beyond this machine.

## What I could not judge by reading

- How often `NICE_MIDOUT_FAULT=sample` escapes the one-slice sampled check (A1). This needs per-slice prefilter-survivor counts at base 64/65.
- Whether `CubeclContext::new_cuda` without a driver panics on the calling thread or on cubecl's device thread (B2). Either way there is no fallback; which one decides whether `no_panic_so_far` (:596) or the `JoinError` reports it.
- The library's own soundness. Only the parts the loop relies on were checked: accounts, slices done equal to slices queued, and the multiset difference of `nice_before`, which is correct even when a field repeats.
- Real-server behaviour (§3 is not built). Fork CI results are taken from the notes and not re-checked.
