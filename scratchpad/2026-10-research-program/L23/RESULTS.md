# L23: browser CPU detailed path through `process_range_detailed_fd`

Branch `pr/wasm-detailed-finite-diff` on `fork`: one commit, fe38c7e, on top of #221 (`pr/detailed-finite-diff`, 7019653). Pushed. No PR opened. The PR body is in PR-BODY.md next to this file.

Change: `wasm-client/src/lib.rs`, where `process_chunk_wasm` now calls `nice_common::detailed_fd::process_range_detailed_fd` instead of `client_process::process_range_detailed`. Doc comment updated, plus a one-sentence CHANGELOG entry ("Speed up the browser client's CPU detailed mode the same way.", placed under #221's entry).

Host: ivory, AMD EPYC-Rome VPS, 4 vCPUs, Linux 6.12. Other agent sessions were idle but present (load average 0.6 to 2.7 during the runs).

## Builds

| build | source | command | wasm sha256 |
|---|---|---|---|
| old | #221's parent d1ff798 (temporary detached worktree `.worktrees/l23-old-d1ff798`, removed afterwards) | `cd wasm-client && wasm-pack build --target web --out-dir pkg` | b6815fe6…5b9 (2,003,330 B) |
| new | this branch fe38c7e, `NICE_BUILD_SHA=fe38c7e…` | same | 71f98059…beb (2,132,238 B) |

- Toolchain: rustc 1.99.1 (rust-toolchain.toml), `rustup target add wasm32-unknown-unknown` (was missing for 1.99.1). wasm-pack 0.13.1 is what CI's installer (`rustwasm.github.io/wasm-pack/installer/init.sh`) fetches (its UPDATE_ROOT is v0.13.1). wasm-pack downloaded wasm-bindgen 0.2.127 to match Cargo.lock. `CARGO_BUILD_JOBS=3`, `nice -n 19`.
- The old build used `CARGO_TARGET_DIR=<pr-wasm-fd>/target` to share registry deps. Afterwards the first new build reused the old tree's `nice_common` artifact (the shared-target-dir fingerprint collision noted in memory) and failed with "could not find `detailed_fd`". `cargo clean -p nice_common -p nice-wasm-client --release --target wasm32-unknown-unknown` fixed it. The old build was done first, into an empty target, so it is d1ff798's code.
- The new build contains the commit SHA (`strings | grep fe38c7e…`: 1 hit).
- Logs: raw/build-old.log, raw/build-new.log (failed collision, then pre-commit), raw/build-new-committed.log. Hashes: raw/wasm-sha256.txt.
- Sites: `site-old/`, `site-new/` = `web/search` (identical in both trees, checked with `diff -r`) + `vendor/` from `scripts/vendor-fetch.sh` + each build's `pkg/`.

## Container note

`docker` on ivory is rootless podman 5.4.2. Inside this session's sandbox `docker run` fails with `crun: sd-bus call: Permission denied`. `CONTAINERS_CONF_OVERRIDE=raw/containers-cgroupfs.conf` (`[engine] cgroup_manager = "cgroupfs"`) fixes it without editing run.sh. All container runs below use it.

## Exactness (browser)

Harness: harness/l23-parity.mjs (copy of ~/browser-harness/l23-parity.mjs).

```
docker run --rm --network host --ipc=host -v ~/browser-harness:/w -v $L/site-old:/site-old:ro \
  -v $L/site-new:/site-new:ro -v $L/raw:/out -w /w mcr.microsoft.com/playwright:v1.62.0-noble \
  node l23-parity.mjs /out/parity.jsonl
```

The harness opens one page per build (blank HTML served next to that build's pkg) and calls `process_chunk_wasm(start, end, base)` per chunk. Raw JSON strings come back to node and are sha256'd. The harness also requires every chunk's distribution to sum to the window, and checks that its JS base-range computation matches `benchmark_plan()`'s starts (it does: b40 1916284264916, b50 26507984537059635).

Result (raw/parity.log, raw/parity.jsonl; committed build): **141 windows, 903 calls, 36,443,540 numbers compared, 29 near-miss entries, 0 differing**, Chromium 151.0.7922.34.

| category | windows | numbers | near misses | differing |
|---|---|---|---|---|
| b40_detailed / b50_detailed windows × {100k chunks, whole, 7,919 chunks} | 6 | 12,000,000 | 0 | 0 |
| offline benchmark field b40 [1916284264916, +10M), 100k chunks | 1 | 10,000,000 | 0 | 0 |
| b49 claim-stub window [20363742218551559, +100k), whole + 997 chunks | 2 | 200,000 | 2 (20363742218601559:45 in each) | 0 |
| bases 40–64 with a range (20 bases incl. 63): first/last 100k + 4 seeded random 100k | 120 | 12,000,000 | 0 | 0 |
| bases 10–24 with a range (12 bases), whole range | 12 | 2,243,540 | 27 | 0 |

The same run on the pre-commit build of the identical code (raw/parity-precommit.*) also had 0 differing.

Near misses at the FD bases (harness/l23-nearmiss.mjs). The harness scans with the new build from range start in 20M stretches (1M chunks). It re-runs any stretch that contains a near miss through the old build chunk for chunk, and then compares a 100k window centred on each near miss.

- Pre-commit build (raw/nearmiss-precommit.*): b40 scanned 1.5e9 from range start: 1 near miss, **1917398732423 (37 uniques)**. b42/43/44/45 6e8 each, b47 and b50 4e8 each: none. The stretch and the window are identical.
- Committed build (raw/nearmiss-b40.*, `PLAN=40:1500000000:1`): the same near miss after 1.12e9. Stretch [1917384264916, 1917404264916) and window [1917398682423, +100k) are identical. The old build lists the same `1917398732423:37`.
- Not done: the stretches without a near miss were not re-run through the old build (1.5e9 numbers at ~1.4M/s would take 18 min). A near miss the new build missed there would go unseen. The per-window histograms above, and #221's native per-number tests, cover that.

CI's end-to-end on the branch (raw/e2e-run-sh.log): `CONTAINERS_CONF_OVERRIDE=… bash wasm-client/e2e/run.sh` after `cp -r pkg ../web/search/` exits 0 in 28 s. CPU offline benchmark 3.39e7/s, GPU (SwiftShader) 1.29e6/s, **"CPU and GPU histograms agree exactly"** (new FD loop vs the unchanged WebGPU kernel on the 10M b40 field). Submit shape OK on both backends (near miss 20363742218601559 exact, 1 wasm fetch). Suite OK (NiceMark 1607 at the default 10 s budget).

## Speed: page benchmark suite (harness/l23-speed.mjs)

```
docker run ... node l23-speed.mjs /out/speed.json 3 60
```

The harness drives the real page (testMode=suite, backend=cpu, benchBudget=60) and alternates old new old new old new in one Chromium 151.0.7922.34 (Playwright 1.62.0 image, default headless). It captures the page's own `benchmark report:` console object. Every non-local request is aborted except `/ping`, which is answered with "pong" (nothing reaches api.nicenumbers.net). Worker pool: 3 (floor(0.8 × hardwareConcurrency 4)); `_1t` uses the page's 1-worker pool. Raw data: raw/speed.json, raw/speed.log. Smoke run at 10 s: raw/speed-smoke.*.

Rates in M numbers/s:

| scenario | old r1 r2 r3 | old median (spread) | new r1 r2 r3 | new median (spread) | × |
|---|---|---|---|---|---|
| b40_detailed (3 workers) | 3.563 3.580 3.564 | 3.564 (−0.0/+0.5 %) | 36.571 36.795 36.002 | 36.571 (−1.6/+0.6 %) | 10.26 |
| b50_detailed (3 workers) | 4.715 4.662 4.717 | 4.715 (−1.1/+0.0 %) | 31.097 31.562 31.127 | 31.127 (−0.1/+1.4 %) | 6.60 |
| b50_detailed_1t (1 worker) | 1.813 1.782 1.751 | 1.782 (−1.7/+1.8 %) | 8.802 8.776 8.690 | 8.776 (−1.0/+0.3 %) | 4.92 |
| browser NiceMark | 247.9 245.9 245.1 | 245.9 | 1710.8 1721.0 1695.2 | 1710.8 | 6.96 |

Repetitions per scenario (about 18 s timed each): old 33/43/33, 33/42/33, 33/43/32; new 330/280/159, 332/285/158, 324/281/157.

## Speed: bare `process_chunk_wasm`, single thread (harness/l23-rawrate.mjs)

```
docker run ... node l23-rawrate.mjs /out/rawrate3.json 3 2 40,50,60
```

1,000,000 numbers at range start (the `fd_timing` window). Each measurement uses a fresh page: 2 untimed full calls, then 3 timed calls (median), with `performance.now()` inside the page. Old and new are interleaved per round, 3 rounds. Results equal on every timed call. ns per number (raw/rawrate3.*):

| base | old rounds | old med | new rounds | new med | × |
|---|---|---|---|---|---|
| 40 | 692.2 682.7 678.1 | 682.7 (−0.7/+1.4 %) | 58.3 57.8 58.3 | 58.3 (−0.9/+0.0 %) | 11.71 |
| 50 | 510.9 502.9 508.4 | 508.4 (−1.1/+0.5 %) | 70.2 67.5 75.0 | 70.2 (−3.8/+6.8 %) | 7.24 |
| 60 | 659.3 654.5 651.1 | 654.5 (−0.5/+0.7 %) | 72.2 73.2 71.1 | 72.2 (−1.5/+1.4 %) | 9.07 |

Discarded earlier attempts (kept in raw/): rawrate.* (1 × 100k warmup, both pages open) and rawrate2.* (5 × 200k warmups, 5 rounds) gave noisy, bimodal new-build times (b40 58–103 ns, b60 71–120 ns). The series diagnostic (harness/l23-series.mjs, raw/series-*.log) shows why: the same 1M call repeated in one fresh page runs 97.9 ns on the first call and then 56–69 ns (new b40). New b50 runs 133.7 ns, then ~68–80 with one 100.7 outlier. Old b40 runs 865, then ~668–691. That is V8's baseline wasm code on the first call, with tier-up between calls; in rawrate2 the switch also came late in some cases. Fresh page + 2 full untimed calls fixed it (spreads under 7 %).

## Native reference (same box)

`cargo test --release -p nice_common --lib --no-run` (1m46s), then `taskset -c 3 cargo test --release -p nice_common --lib fd_timing -- --ignored --nocapture --test-threads 1` (raw/native-fd-timing.log, raw/native-build.log):

| base | division | finite differences | × | wasm new / native new | wasm old / native old |
|---|---|---|---|---|---|
| 40 | 273.49 265.80 264.54 → 265.80 | 43.07 43.27 41.66 → 43.07 | 6.17 | 1.35 | 2.57 |
| 50 | 414.34 414.42 420.66 → 414.42 | 49.25 48.70 48.77 → 48.77 | 8.50 | 1.44 | 1.23 |
| 60 | 544.12 540.92 538.21 → 540.92 | 50.67 50.21 50.16 → 50.21 | 10.77 | 1.44 | 1.21 |

The old base-40 path is `get_num_unique_digits_u128_const::<40>`. Its 2.6× wasm penalty, against 1.2× for the `U256` path at 50 and 60, is why base 40 gains most in the browser. That u128 digit extraction likely becomes compiler-rt calls in wasm; I did not check this in the disassembly.

`u128` in the FD loop, per number: only the `for num in start..end` counter and the `[u128; 65]` histogram increment, the same as the division loop. The seed (`U256` mul plus 5 digit conversions) runs once per call, so once per 100k chunk in the browser. No `std::arch`, and `as_chunks` is core. It compiles for wasm32 without changes.

## Page overhead (observation, not acted on)

`_1t` per 1M window: new 1/8.776 = 114 ms against 70.2 ms bare; old 561 ms against 508 ms bare. Both builds therefore pay a fixed ~44–53 ms per suite window in the page and worker pool. That is why `b50_detailed_1t` shows 4.9× while the bare call shows 7.2×. The pool splits a 1M window into five 200k sub-ranges; I did not profile where the time goes.

## Lint / checks

- `cargo fmt --all --check`: clean.
- `cargo clippy -p nice-wasm-client --all-targets -- -D warnings` (host; this is what CI's `just lint` `-p "*"` covers for this crate): clean (raw/clippy-host.log).
- `cargo clippy -p nice-wasm-client --target wasm32-unknown-unknown --all-targets --no-deps -- -D warnings`: clean (raw/clippy-wasm32-nodeps.log).
- Without `--no-deps`, the wasm32 clippy fails on a **pre-existing** `clippy::doc_markdown` at `common/src/cubecl_web.rs:63` ("LibreWolf 149"). That line sits in a `#[cfg(target_family = "wasm")]` item, so host CI never lints it. It is also on upstream main. Not touched here (raw/clippy-wasm32.log).
- The repo's wasm-target gate is the Browser Client workflow (wasm-pack build + e2e), and it passes locally as above. No other wasm compile check exists to extend.

## Cleanup

- Temporary worktree `.worktrees/l23-old-d1ff798` removed after the runs.
- The `wasm-client/LICENSE` that wasm-pack drops was deleted before committing. So was an empty `wasm-client/e2e/oom` that the e2e run leaves behind.
- `.worktrees/pr-wasm-fd` is kept: it holds the branch, about 2.5 GB of target with wasm32 release + host check + host release test artifacts.
