# L24 step (c): browser parity step, adapter check, parity.html, WGSL lint

2026-10-31, 16:14–17:05 UTC. Branch `pr/browser-parity-step` on the fork, head **0f87771**, on upstream main 2a1caf2 (#229 merged at 16:28, during this work; the branch was rebased onto it). PR not opened. PR body: `PR-BODY-C.md`. Logs: `raw-c/`.

## Commits

| commit | files |
|---|---|
| `20c955e` Browser client: GPU-versus-CPU parity step and adapter check in the e2e | `web/search/parity.js` (new, window lists, adapter record, byte comparison, diff), `web/search/parity.html` (new, the page), `wasm-client/e2e/e2e.mjs` (adapter check, parity step, options), `wasm-client/e2e/run.sh` (usage line), `.github/workflows/browser-client.yml` (header comment) |
| `0f87771` CI: lint the kernels' WGSL for the division Apple's Metal compiler gets wrong | `scripts/wgsl-lint.py` (new), `common/src/cubecl_backend.rs` (`wgsl_dump_for_lint`, ignored, no-op without `CUBECL_DEBUG_LOG`), `.github/workflows/gpu-parity.yml` (lint step and an on-failure artifact upload in the lavapipe job) |

No Rust change to the wasm crate: `process_chunk_gpu` and `process_chunk_wasm` were already exported, so no `#[doc(hidden)]` export was needed for this PR (run length 1 is reachable as a window; the seed-word probe stays for (b)). No CHANGELOG line: the repo's CI/test-only PRs (#209, #176, #148) have none.

How the harness was shaped: the bring-up harness's `lib.mjs` window lists, base ranges, adapter record and diff moved into `web/search/parity.js`, a browser module. `parity.html` imports it and exposes `window.parity`. `e2e.mjs` opens `parity.html` and calls `window.parity.compare(i)` once per window, so a hung window can time out and the run continue in a fresh page. The page is therefore exercised by every CI run and cannot rot unnoticed. `adapter.mjs`, `bench.mjs` and `serve.mjs` were not brought over (the adapter check is in e2e.mjs; `just dev` serves the page; the suite A/B belongs to (b)).

## Local checks (ivory)

Wasm built with `wasm-pack build --target web` at nice 19, `CARGO_BUILD_JOBS=3`, `NICE_BUILD_SHA` set (`raw-c/wasm-build-*.log`). Containers: rootless podman with `CONTAINERS_CONF_OVERRIDE=L23/raw/containers-cgroupfs.conf`, image `mcr.microsoft.com/playwright:v1.62.0-noble` (Chromium 151.0.7922.34).

| command | result | log |
|---|---|---|
| `bash wasm-client/e2e/run.sh` | rc 0, 41 s wall incl. container. Adapter `google`/`swiftshader`, fallback true, check passed (software, as pinned). Parity (ci): 13 windows, 1,106,584 numbers, 11 near misses, 0 failed, **10.3 s** | `e2e-run-sh-final.log` |
| `run.sh --parity-only` | rc 0, 14 s wall incl. container; parity 10.5 s | `e2e-parity-only-ci.log` |
| `run.sh --parity-only --parity hw --parity-out …` | rc 0, 100 s wall; **199 windows, 25,471,443 numbers, 50 near misses, 0 failed, 97.4 s on SwiftShader** | `e2e-parity-hw-swiftshader.log`, `parity-hw-swiftshader.jsonl` |
| `run.sh --hw --parity-only` (container, no GPU) | rc 1: `ADAPTER CHECK FAILED: no WebGPU adapter`, then `PARITY SKIPPED: no usable WebGPU adapter (none offered)` | `e2e-hw-in-container-no-gpu.log` |
| fault injection: `parity.js` temporarily altered the GPU JSON of `b40/len61` and `b49/nearmiss` (not committed; file restored, checked) | rc 1. `FAIL b40/len61 … window [1916284264916, 1916284264977) at base 40 … results differ, first at distribution[num_uniques=1].count: gpu 1, cpu 0`; `FAIL b49/nearmiss … first at distribution[num_uniques=44].count: gpu 1, cpu 0 / also distribution[num_uniques=45].count: gpu absent, cpu 1`; summary `PARITY FAILED … 2 failed` with both windows listed | `e2e-injected-fault.log` |
| `run.sh --firefox --parity-only` | rc 0: Playwright Firefox 153 has no adapter in the container; `no WebGPU adapter offered`, `PARITY SKIPPED` | `e2e-firefox-parity-only.log` |
| `parity.html?subset=ci&run=1` (scratch Playwright script, SwiftShader) | `PASS: 13 windows, 1,106,584 numbers, 11 near misses, identical on GPU and CPU (10.6 s)`; screenshot | `page/swiftshader-ci.png`, `page/page-check.mjs` |
| `cargo fmt --all --check` | clean | — |
| `cargo clippy -p nice_common -p nice-wasm-client --all-targets --features nice_common/cubecl -- -D warnings` (check only, `-j 3`) | clean; a temporary type error in the new test was caught by the same command, so the test target is linted | `clippy-host*.log` |
| `actionlint` 1.7.12 (downloaded to /tmp) on `gpu-parity.yml`, `browser-client.yml` | clean | — |

The window lists match the bring-up: 199 hardware windows, 25,471,443 numbers; CI subset 13 windows, 1,106,584 numbers. `baseRange` spot checks: b5 [3,5), b7 [7,14), b8 [16,23), b6 none, b10 [47,100), b40 [1916284264916, 6553600000000). `checkRangesAgainstPlan` compares the wasm plan's starts on every run.

## WGSL lint

`scripts/wgsl-lint.py` is a fresh, documented version of L25's `wgsl_scan.py` (same zero-folding idea), extended to naga's MSL (`naga_div`/`naga_mod`, `uint x = …;`, `static_cast<uint>(as_type<ulong>(…))`), with `--require` coverage checks and 18 built-in self-test cases that run before every scan. A u64 shift by 16 (amount spelled 64-bit) is not HALF; any `>> 32` is HI32.

Validation over dumps from earlier work (`raw-c/lint-validation/`):

| corpus | shaders | flagged | expected |
|---|---|---|---|
| browser kernel as Chromium received it (createShaderModule intercepted on SwiftShader, main 806caec), b10/23/40/50/57/64/80/97 (`raw-c/capture/`) | 8 | 0 | 0 (runtime loop-carried remainder) |
| L3 minimal reproducers, WGSL and naga MSL (u32 `>> 16` and u64 `>> 32` forms) | 4 | 4 | 4 |
| L3 #225 FD kernel before the Metal fix, lavapipe debug log | 5 | 92 (7 / 26 / 59 at b10 / b40 / b62) | same as L25's validation |
| L3 M4 shaders before the Metal fix, WGSL and MSL, b22/23/40/50 | 8 | 212 | flagged at every base, WGSL and MSL counts equal |
| L25 lavapipe test run on 472c9a0 + windows (before #228) | 62 | 626, all `TopKernel` (b10–b60; b64 has K = 4096) | L25's `wgsl_basew_scan.txt` |
| L25 lavapipe test run with the top-kernel fix (= #228) | 62 | 0 | 0 |
| L25 b40 dumps on 472c9a0 (stride code identical to 806caec, before #229) | 9 | 34: `TopKernel` 28, `NiceonlyKernel` 6 | L25 audit: 28 and 6 |

The browser WGSL captured from Chromium is byte-identical to the native `CUBECL_DEBUG_LOG` dump of `DetailedKernelU32` (minus the log's code fences), so linting the native dump covers what browsers receive.

## CI on the fork

The fork's default branch lacks `gpu-parity.yml` and `browser-client.yml`, so `workflow_dispatch` was refused (404). A temporary commit added `pr/browser-parity-step` to both workflows' push triggers, was pushed, ran, and was then dropped by resetting to 0f87771 and force-pushing (`--force-with-lease`). The code under test was identical to 0f87771.

| run | result | timing |
|---|---|---|
| Browser Client 41220564972 | success | e2e step **64 s** (main: 53 s and 50 s in runs 41219859616, 41218330170). Parity (ci) **9.3 s** on SwiftShader, adapter check 0.2 s, all 13 windows `same` (`raw-c/ci-browser-client-41220564972.log`) |
| GPU Device Parity 41220564975 | success (lavapipe and macOS) | lint step **8 s**: `wgsl_dump_for_lint` 7.22 s, lint 0.2 s; `wgsl-lint: 14 shaders (BucketKernel, CheckKernel, DetailedFdKernel, DetailedKernel, DetailedKernelU32, JoinKernel, NiceonlyKernel, TopFillKernel, TopKernel, TopScanKernel), 0 flagged sites`; every `--require` met. The test printed `CUBECL_DEBUG_LOG is not set; no shaders to dump` in the two other steps (`raw-c/ci-gpu-parity-lavapipe-41220564975.log`) |
| Rust Cross-Platform 41221758477 (`workflow_dispatch` on 0f87771, for `just lint`) | Format and clippy, Test workspace and Test GPU host code (cuda feature, NVRTC): success; release builds were still running at hand-off (no non-test code changed) | lint job 1 m 40 s |

**Lint result on current main (2a1caf2): clean.** It would have failed on 806caec (before #229) with the stride prefilter's 6 sites at b40.

## M4 (mayalaran)

16:40:51–16:50:56 UTC, `~/claude-exp-2026-10-31-parity` only. Node v24.14.1 (SHA-256 checked), Playwright 1.62.0 with `--omit=optional --ignore-scripts`, Chromium 151.0.7922.34 (`--no-shell`), `PLAYWRIGHT_BROWSERS_PATH`, `npm_config_cache` and `TMPDIR` inside the directory. Harness and site copied from ivory (SHA-256 of e2e.mjs, parity.js and the wasm matched). Each run went through a wrapper writing its PID and a perl watchdog PID (30 min); none fired. Logs in `raw-c/m4/`.

| run | result |
|---|---|
| `e2e.mjs --hw --expect-vendor apple --parity hw --parity-out …` | rc 0, **26 s**. Adapter `apple`/`metal-3`, description "", fallback false, `gpu_init` " (BrowserWebGpu, wgpu<wgsl>)"; warm b40 2e8 call 0.304 s = **6.583e8 n/s** (first 0.359 s); check passed (hardware). Offline field CPU = GPU; submit shape ok on both; CPU suite NiceMark 10602. **Parity (hw): 199 windows, 25,471,443 numbers, 50 near misses, 0 failed, 5.8 s on apple/metal-3** |
| `--hw --expect-vendor amd --parity-only --parity off` | rc 1, `ADAPTER CHECK FAILED: vendor "apple", expected "amd"` (rate 6.596e8) |
| `--hw --expect-vendor apple --parity-only --parity hw --parity-random 10` | rc 0, **639 windows, 366,555,603 numbers, 370 near misses, 0 failed, 53.8 s** |
| `parity.html?subset=hw&run=1` (page-check.mjs, `channel: "chromium"`, no flags) | `PASS: 199 windows, 25,471,443 numbers, 50 near misses, identical on GPU and CPU (4.4 s)`; `raw-c/page/m4-page-hw.png` |

Cleanup: every PID file's process gone and no process with the directory in its command line; `defaults delete com.google.chrome.for.testing`, then the plist file removed (it held only `LastRunAppBundlePath`); `Crashpad/settings.dat` (40 B, exists since 08-26) was rewritten by Chrome and left in place; no crash reports; no node-gyp or python cache writes (`find ~/Library -newer start-marker`); directory removed; `ls -d ~/claude-exp-*` empty at 16:50:56.

## Not done

- **Raw-WGSL Metal probe** (the proposal's report-only (c) item, H5): not in this brief, not built.
- **demoux** `--hw` log (the proposal's merge evidence for (c)): not run; needs a request.
- **`just lint` with `nice_client/gpu,cubecl-spirv` on ivory**: not run locally (GPU-feature build); covered by the dispatched Rust workflow.

## Side note

Rootless podman on ivory leaves an empty file named `oom` in the working directory of every `docker run` (seen in `wasm-client/e2e/` after each `run.sh`; reproduced with `docker run … true`). Upstream main has a tracked empty `oom` at the repo root since #226 (472c9a0), probably from the same cause. Not touched here.
