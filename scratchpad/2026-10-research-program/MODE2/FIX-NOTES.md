# dev/mo-mode: the whole CI matrix, Metal, and the review findings (2026-11-26)

Branch `dev/mo-mode` on the fork (`wasabipesto-bot/nice`), from `f61cf79e`. Final head and CI runs: §6.
Everything was compiled and tested on mayalaran (M4, macOS 27.2, Rust 1.100.0) from git bundles of the branch,
under `~/claude` there; the emulation probes ran on ivory in cross's own images (podman). No server-side file was
touched; no client run had any `--api-base` but `http://127.0.0.1:PORT`.

## 1. The failing CI jobs (run 45570638702 on `bbbb4c7e`)

I read the four failing jobs' logs in full (`--log-failed`, 4,886 lines). There are exactly the three tests of the
brief, plus one fact the brief did not have: **armv7 and arm-musl were also SIGKILLed** (not only aarch64), at the
same place (the next test after `shapes_that_do_not_fit_are_refused`, 70 s and 68 s into it; aarch64 132 s), besides
failing `b65_padded`. i686 is not emulated (cross runs it natively in its container) and finished its lib tests
(240 passed, 2 failed).

| test | jobs | cause | fix (commit) | verified |
|---|---|---|---|---|
| `midout::coord::tests::b65_padded` | i686, armv7, arm-musl | test code: `usize::try_from(q / 4099)` (q/4099 ≈ 2^5x) does not fit a 32-bit `usize` | the same v visited with u128: `(0u128..).map(\|i\| vs + i*step).take_while(..)` (`01727f23`) | mayalaran lib tests pass; CI i686 passed on `f61694b0` (§6) |
| `client_api_async::tests::ordinary_claims_refuse_a_coordinate_field` | i686 | binds a loopback socket; in cross's i686 container `bind` answers ENOSYS (errno 38; a 32-bit binary's socket call refused by the container's syscall filter, presumably) | no socket needed: the refusal is in reading the answer, so the body reading is a function `field_of_claim_body`, which `get_field_from_server_async` calls for both modes and the test calls directly (`dfbc36e5`) | as above |
| `midout_route::tests::a_server_without_the_endpoint_is_one_clear_error` | i686 | same ENOSYS | kept its socket (the real HTTP path stopping the loop is the point; the 404 sentence alone is `wire::claim_answer`'s socket-free test); skips with a message where bind fails (`f61cf79e`), comment says why (`dfbc36e5`) | CI i686 passed |
| `midout::cpu::tests::threaded_slice_join_equals_single_threaded` | aarch64, armv7, arm-musl (SIGKILL) | **qemu-user keeps the memory of every guest thread that ever ran**, and the test started 231,506 threads (below) | the ordinary test compares the threaded joins on 4 slices per base (≈ 2,100 threads; every slice still runs single-threaded); the every-slice form is `threaded_slice_join_every_slice` under `midout-box-tests` (`abf6446e`) | §6 |

### The aarch64 diagnosis (and armv7's)

- Natively (mayalaran, release, counter patch on `par_map`, not committed): the test takes 2.3 s, peak RSS 8.9 MB,
  and **starts 231,506 threads**: b20 20 slices → 3,120; b24 576 slices → 107,136 more; b25 625 slices → 121,250 more
  (≈ 156 / 186 / 194 per slice: every `slice_join_threads` call spawns fresh scoped threads for the parents, the
  tops and each class wave, at 2, 3, 7 and 64 threads, plus the u128 run). Logs: mayalaran
  `~/claude/runs/fix-1126/diag_run_{1,4}.log`.
- Under emulation, a standalone probe that only spawns and joins threads in scopes of 5 (as `par_map` does),
  cross-compiled in cross's own image and run by that image's runner (`/linux-runner`):
  - `aarch64-unknown-linux-gnu:0.2.5`, **qemu-aarch64 5.1.0**: RSS grows **229 KiB per thread started, never
    returned** (1,000 → 241 MB, 10,000 → 2.30 GB, linear); under a 3 GB cap it is killed at ~13,000 threads.
  - `armv7-unknown-linux-gnueabihf:0.2.5`, **qemu-arm 5.1.0**: **665 KiB per thread** (2,000 → 1.34 GB, 4,000 → 2.66
    GB); the process died at about 2.8 GB.
  - for comparison Debian's qemu-aarch64 10.0.13: 39 KiB per thread (30,000 → 1.17 GB): smaller, still a leak.
  - Probe source, outputs, the counter patch and the native run: `MODE2/qemu-probe/`.
- So the test needs ≈ 53 GB under qemu-aarch64 5.1 (231,506 × 229 KiB) and more on armv7; a hosted runner has 16 GB,
  and the kernel's OOM killer sends the SIGKILL. The time to the kill (70–130 s) matches the first ~70,000 threads.
  aarch64-**musl** passed because it runs natively on an arm64 runner (no qemu).
- **Not a library defect**: the result is right, and natively the spawns cost ~10 µs each. It is a property of
  `par_map` (threads started per call, not a pool) that only an emulator makes expensive; a production sampled
  check starts ~70 threads per slice of minutes. Not changed.
- The new size: ~2,100 threads ≈ 0.5 GB on qemu-aarch64 5.1, ≈ 1.4 GB on qemu-arm 5.1 (plus whatever the other
  tests of the same process start: the leak is per process).

## 2. Metal: the refusal replaced by a warning (`f61694b0`)

`is_metal` stays (tests renamed `metal_devices_are_told_apart`, plus a check of the warning's contents); the
refusal is gone; on a Metal device the mode logs once at start (as seen on the M4):

> WARN middle-out on an Apple Metal device (Apple M4 (Metal, wgpu<wgsl>)): the middle-out join has been checked on
> Apple Metal only on an Apple M4 under macOS 27.2, through WGSL (the device tests and whole base-64 fields); other
> Apple GPUs, macOS releases and CubeCL's MSL compiler (cubecl-metal) have not been checked. Older macOS releases
> miscompiled some divisions by a constant in GPU kernels (fixed by 26.7.2 and 27.2): keep macOS up to date. Every
> field is still checked on a sampled slice against the CPU before it is submitted.

The module comment and the README's `midout` paragraph say the same. **One correction to the brief's wording**: the
project's kernel lint (`scripts/wgsl-lint.py`, fed by `cubecl_backend::tests::wgsl_dump_for_lint`) does **not**
dump the middle-out kernels (its list: the browser kernel, the detailed kernels, the stride nice-only kernel, the
overlap join). So the warning does not claim the lint guards the middle-out join. Reading the middle-out kernels'
`>> 16` sites by eye (`gpu.rs`, `gpu_wide.rs`), every divisor of such a dividend is a mask or the dividend is not a
bare shift (`((cacc & 255) + ((cacc >> 16) & 255) * d) % b`), so none has the miscompiled form; adding the
middle-out kernels to the lint's dump is left open (§5).

### The real client mode on the M4 (run r2-route, binary at `1014d3fd`, `--features gpu` as the macOS GPU release)

- Recipe of EVENTEO phase c, mayalaran script `~/claude/scripts/route_fix.sh`: `midout_fields --base 64 --spread 3`,
  `midout_coordinator.py` on 127.0.0.1:8471, then plain `nice_client midout --api-base http://127.0.0.1:8471
  --repeat --username mayalaran-test` (no `--gpu-backend`, no `--threads`), SIGTERM by pid once the list was done,
  `midout_audit.py`. Logs copied to `MODE2/m4-runs/r2-route/`.
- `auto` found no CUDA ("CubeCL CUDA unavailable; trying the next backend"), took the wgpu device `Apple M4 (Metal,
  wgpu<wgsl>)` and logged the warning above. (Before B2 this command died in a panic on this machine.)
- 3 fields of 1.44e17 n (4096 slices each): **235.4 s, 236.9 s, 234.6 s** (≈ 6.1e14 n/s); survivors 4.82e10,
  checked 1.38e9 each; no nice numbers; every sampled CPU check equal (a differing one stops the client). Replies
  `canon` ×3; server status `{"fields": 3, "claimed": 3, "searched": 3, "checked": 0, "submissions": 3}`;
  **audit exit 0 ("audit: OK")**. Client exit 143 (the SIGTERM of the recipe, before the stop handler existed).
  Logs: mayalaran `~/claude/runs/r2-route/`.
- `--gpu-backend cubecl-cuda` on the same machine: one error line ("Unable to dynamically load the \"cuda\" shared
  library …"), exit 1, no panic.
- At `74591fd8` (run r3-stop, `MODE2/m4-runs/r3-stop/`, script `~/claude/scripts/stop_fix.sh`): one field
  (235.4 s, same plain command, same fallback and warning) against the server with `--drop-replies 1`, SIGTERM by
  pid as soon as "searched in" was logged. The first reply was lost and the client was in its 1 s retry wait:
  "stop signal; finishing the submission in flight, then exiting" → "claim 1000 recorded (AlreadyRecorded,
  submission 1) before the stop" → exit 143, 1 s after the signal; audit exit 0, 1 field, 1 submission.
- Again at the final head `4fff25e7` with the flag-only handler (run r4-stop, `MODE2/m4-runs/r4-stop/`): field
  235.45 s; "stop signal 15; finishing the submission in flight" → "claim 1000 recorded (AlreadyRecorded,
  submission 1) before the stop" → exit 143 within 1 s; audit exit 0.

## 3. Other things the matrix logs showed

- Nothing else failed. On macOS (mayalaran), clippy of `nice_common` with `-D warnings` fails in
  `common/src/cpu_join.rs:986` (`unused_self`) and `:2093` (`unused_mut`): code this branch did not touch, on a
  cfg path that only aarch64-apple compiles; the CI lint job (Linux x86-64) passes. Noted, not changed.

## 4. Review findings (`REVIEW.md`)

| finding | state |
|---|---|
| A1 fault build talks to any server | fixed in `fbd77e47`: a `midout-fault` build refuses any `--api-base` whose host is not localhost / 127.0.0.0/8 / ::1, before any device or request (`is_loopback_base`); tests `loopback_bases` (17 addresses) and `fault_builds_talk_only_to_this_machine` (run in both feature sets: refused only in the fault build) |
| A2 audit passes a disagreeing check | fixed in `3e2fa30b`: every disagreement is a PROBLEM (exit 1), with both results; nice numbers of every accepted submission listed, a check's missing from its canon marked `NOT IN THE CANON`. Test: the e2e test audits a copy of its real state with a disagreeing check added (exit 1, exactly one problem, the number listed). `/status` disagreement count not added (optional) |
| B2 `auto` CUDA only, unguarded | fixed in `0eed7188`: CUDA under `guarded_init`, on failure `log_cuda_fallthrough` and the wgpu device (also guarded); both failing → one error naming both. Verified on the M4 (§2). Software-renderer refusal (#277) is not on this branch (origin/main is at #271): not done, noted |
| B5 SIGTERM drops the submission in flight | fixed in `9f45eedd` + `a194aa9f`: SIGTERM/SIGINT close a gate on submissions (no new one; the one in flight is finished, its reply or failure logged), then exit 143/130. (`9f45eedd` used tokio's `signal` feature, which builds tokio's signal driver into every runtime of the client; it needs a socketpair, refused (ENOSYS) in cross's i686 container, so every runtime-making client test panicked there in run 45769103003. `a194aa9f` drops the feature: a `signal-hook-registry` handler (already in the lock through tokio; optional, part of the `cubecl` feature, Unix only) only stores the signal in an atomic, and a task polls it every 100 ms.) Test `the_stop_waits_for_the_submission_in_flight` (gate waits 300 ms for a pass; a closed gate refuses; `HttpApi::submit` after the stop is refused without sending). Real SIGTERM with a submission in flight on the M4: §2 (r3-stop) |
| B1 panic on the loop thread | fixed in `3536ad80`: the search under `catch_unwind`, a panic = failed search, tail runs. Test `a_search_that_panics_stops_and_the_submission_in_flight_finishes` |
| B3 + B4 submit retries, body lost | fixed together in `2d774939` (one helper serves both): `retry_midout` for both middle-out calls retries 5xx, network errors and a body that cannot be read (same body); **submissions: until 3600 s (`MIDOUT_SUBMIT_RETRY`, the claim's lifetime) have passed and at least `--api-max-retries` attempts**, waits 1, 2, 4 … 256 s; the claim keeps `--api-max-retries` attempts. Ordinary modes unchanged. Test `a_submission_lost_mid_body_or_refused_by_5xx_is_retried` (a raw server: a 200 cut short, a 503, then a reply; one attempt allowed by count, 20 s budget; 3 identical bodies received) |
| B7 e2e flakes | fixed in `ff00141e`: the dev server binds `--port 0` itself and logs `listening on 127.0.0.1:PORT`, which `Server::start` reads; the tests' API has a 60 s timeout. On the macOS runners (run 45769103003) two e2e tests then saw no "listening" line within 10 s; `4fff25e7`: the server binds as a plain TCP server (no `socket.getfqdn` reverse lookup, which can take seconds, my best explanation, not proven) and the tests wait up to 60 s |
| B6 telemetry size | fixed in `d93102d3`: server measures UTF-8 (`ensure_ascii=False`, `.encode()`); client re-measures after the join trim and drops the searcher's keys if still over (test extended with a non-ASCII 16 KiB device name) |
| C1 claim ahead before the refusal peek | fixed in `a05c2243` (swapped) |
| C2 `healthy()` before the submission | fixed in `02b40add` (test extended: a panic recorded between search and submission submits nothing) |
| C3 cubecl-cuda missing message | fixed in `80742925` |
| C4 `--threads 0`, implied `--benchmark`, `--telemetry` | fixed in `1ec9da9b` (0 counts as not given in midout) and `ddc0a96b` (refusal names the implying options and `NICE_BENCHMARK_*`; `--telemetry` warns) |
| C5 wire forward compatibility | not done: a proposal decision (§9.6: add `matches_canon`, not a status; `elapsed_secs`), not a client fix |
| C6 dev-server durability corners | fixed in `74591fd8` (parent dir fsynced at start; close errors after a good fsync ignored) |
| C7 docs / `unreachable!` | "base 64 and up" → "bases 64 and 65" in `5992ca59`; the pre-dispatch `ClientMode::search()` test not done (goes away with the server change) |

## 5. Not done

- The middle-out kernels are not in the WGSL lint's dump (§2).
- C5, the C7 test, the `/status` disagreement count, the software-renderer refusal (B2).
- `par_map` starting threads per call (§1) left as is.

## 6. Final head and CI

**Final head `4fff25e7`** (`dev/mo-mode` on the fork; 21 commits on `f61cf79e`, listed by `git log f61cf79e..4fff25e7`).

| run | head | result |
|---|---|---|
| matrix 45777405453 | `4fff25e7` | **success, all 16 jobs** (Release skipped): Linux x86-64/musl/i686/aarch64/aarch64-musl/armv7/arm-musl/riscv64, FreeBSD, Windows ×2, macOS ×2, CUDA host code, Format and clippy, Test workspace; finished 09:04 UTC |
| GPU Device Parity 45777409152 | `4fff25e7` | success: lavapipe (Linux) and Metal (macOS runner) |
| matrix 45766057560 | `f61694b0` (part 1 + Metal only) | everything success except armv7 and arm-musl, which I cancelled at 77 min (still in their tests) so the next head's run could start; by then armv7 had passed `b65_padded` and `threaded_slice_join_equals_single_threaded` (40 s), aarch64 had passed the whole lib (242 passed, the threaded test 7 s), i686 passed |
| matrix 45769103003 | `74591fd8` | i686 failed (tokio's signal driver, B5 note) and macOS ×2 failed (two e2e servers not ready in 10 s, B7 note); fixed in `a194aa9f`, `4fff25e7`; cancelled for the final head |

The arm jobs are slow on this branch: upstream main's armv7/arm-musl jobs take 72/84 min; here the lib tests alone
reached the middle-out tests only after ~70 min under qemu-arm (the slowest tests under emulation are the existing
`cpu_join` ones, e.g. `the_skip_walk_finds_every_top_on_production_fields` 746 s on qemu-aarch64; the middle-out ones
add ~2 min there).

Locally (mayalaran, at `4fff25e7`): `cargo fmt --check`; `nice_client` tests default and `cubecl,midout-fault`
(46 passed each, the e2e tests against the real dev server included); `cargo clippy --no-deps -p nice_client
--all-targets -D warnings` default and `cubecl,midout-fault,cubecl-cuda`. `nice_common` lib tests (default) passed there at the
tree of `f61694b0`; at the final head they are CI's ("Test workspace (native Linux-x86_64)" passed). The CI "Format and clippy" job (= `just lint`) passed at every
pushed head.

Left on machines: mayalaran `~/claude/{src,t,bin,runs,xfer,scripts}` (worktrees `src/{diag,fixtest,fixhead}`, binaries
`bin/fix-gpu`, `bin/fix-head`; nothing outside `~/claude`, no process left running); ivory: the two cross images and
the two rustup targets used for the probe were removed.
