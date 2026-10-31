# L24 headless browser-GPU bring-up on mayalaran (M4)

2026-10-31, 15:50–16:11 UTC. Today's main (7362e18) wasm, built on ivory (`wasm-pack build --target web`, nice 19); no wasm change was needed. Harness: `exp/browser-gpu-harness` on the fork (5eeed09), `wasm-client/e2e/hw/`. Raw outputs: `raw-bringup/`.

## Result

- **Headless Metal works with no flags.** Playwright 1.62.0, `chromium.launch({channel: "chromium", headless: true})`, Chrome for Testing 151.0.7922.34, macOS 26.3 (25D125), over SSH with no GUI session. The adapter is `apple` / `metal-3`, `isFallbackAdapter` false. The warm 2e8-number b40 call runs at 6.56e8 n/s. SwiftShader on the same Mac does 1.77e7.
- **Today's browser kernel is exact on Apple through Tint.** 201 parity windows (the full §3.3 list plus both 2e8 benchmark windows): 4.25e8 numbers, 46 bases, 50 near misses, 0 differences. A repeat run gave the same GPU SHA-256 on all 199 windows it shared. A seeded sweep of 440 windows (3.41e8 numbers) also showed 0 differences.
- **Rates.** b40 6.58e8 and b50 3.83e8 n/s. The browser GPU NiceMark is 263–265; the proposal's estimate was "about 270". No thermal warning was recorded and the three rounds agree within 0.5 %.

## Setup (H6)

Nothing needed staging from ivory. The Mac's own downloads did not stall today.

| item | how | time |
|---|---|---|
| Node v24.14.1 darwin-arm64 | `curl` from nodejs.org into the exp dir; SHA-256 checked against SHASUMS256 | 6 s, 51 MB |
| Playwright 1.62.0 (CI's version) | `npm i --no-save playwright@1.62.0` with `npm_config_cache` inside the dir | 6 s |
| Chromium | `npx playwright install --no-shell chromium` with `PLAYWRIGHT_BROWSERS_PATH` inside the dir; `cdn.playwright.dev/builds/cft/151.0.7922.34/mac-arm64/chrome-mac-arm64.zip` | < 45 s, 179 MiB |
| site | `web/search` plus `pkg/` and `vendor/` (`scripts/vendor-fetch.sh`), copied by scp | — |

`TMPDIR` inside the dir keeps Playwright's throwaway Chromium profile there as well (`--user-data-dir=$D/tmp/playwright_chromiumdev_profile-*`, confirmed on chrome://gpu). Every run went through a wrapper that writes its own PID file, and a 3 h watchdog was set to kill those PIDs and their descendants, parent first. It never fired.

## Adapter and flags (H1–H3)

All Mac runs used Chromium 151.0.7922.34. Rate = the warm (second) `process_chunk_gpu` call over `[1916284264916, +2e8)` at b40.

| flags | vendor / architecture | description | fallback | first call | warm rate |
|---|---|---|---|---|---|
| **none** | apple / metal-3 | "" | false | 0.365 s | **6.557e8** |
| `--enable-webgpu-developer-features` | apple / metal-3 | **"Apple M4"** (device "0x0000") | false | 0.329 s | 6.564e8 |
| `--enable-unsafe-webgpu` | apple / metal-3 | "" | false | 0.325 s | 6.575e8 |
| `--use-angle=metal` | apple / metal-3 | "" | false | 0.326 s | 6.572e8 |
| `--enable-features=Vulkan` | apple / metal-3 | "" | false | 0.326 s | 6.572e8 |
| `--ignore-gpu-blocklist` | apple / metal-3 | "" | false | 0.336 s | 6.566e8 |
| CI's SwiftShader pin (`--enable-unsafe-webgpu --use-webgpu-adapter=swiftshader --enable-features=Vulkan`) | google / swiftshader | "" | true | 13.0 s | 1.766e7 |
| same, ivory (CI image, 4 cores, 2e6 window) | google / swiftshader | "" | true | 8.0 s | 7.07e5 |

- **H1 holds.** Unflagged headless Chromium reaches Metal over SSH. The other flags are no-ops here.
- **H2 holds.** `vendor` and `architecture` are reported without flags. `isFallbackAdapter` is on `GPUAdapterInfo`. The harness records where the flag was found (`fallback_source`); that field was added after the Mac runs and reads `info` on the same Chromium build on Linux.
- **The developer-features hypothesis holds.** `--enable-webgpu-developer-features` unmasks `description` = "Apple M4". Without it, wasm `gpu_init()` returns `" (BrowserWebGpu, wgpu<wgsl>)"`, with a blank device name as predicted. With it, `gpu_init()` returns "Apple M4 (BrowserWebGpu, wgpu<wgsl>)".
- **H3 holds**, on the Mac and on ivory.
- **Assertion margin.** SwiftShader on the M4's CPU is about 15× faster than in CI (1.77e7 against about 1.2e6), but still 5.7× below the 1e8 bar. Metal is 6.6× above it.
- **Other adapter details:** subgroups 32/32; features include `shader-f16`, `subgroups` and `timestamp-query`; `maxStorageBufferBindingSize` and `maxBufferSize` are 4 GiB−4.
- **chrome://gpu** (text in `adapter-devfeatures.json`): "WebGPU: Hardware accelerated", Skia backend GraphiteDawnMetal, `ANGLE Metal Renderer: Apple M4, Version 26.3`.
- **Playwright's default arguments** include `--enable-unsafe-swiftshader` and `--no-sandbox`. Neither moved the WebGPU adapter off Metal.

The existing CI harness also runs unchanged with `node e2e.mjs --hw` (`raw-bringup/e2e-hw.log`):
- the offline b40 field gives the same histogram on the CPU pool and the GPU worker;
- the GPU submit shape is correct, with the b49 near miss 20363742218601559 exact;
- CPU suite NiceMark 709.

## Exactness of today's browser GPU kernel (Tint → MSL → Apple)

`parity.mjs` loads `pkg/nice_wasm_client.js` into a blank page at the site's origin. For each window it calls `process_chunk_gpu(s, e, b)` and then `process_chunk_wasm(s, e, b)` on the main thread, and compares the two raw JSON strings with `===`. Nothing is parsed before the comparison. Every window's record holds both SHA-256s, its near misses and timings.

The two exports already existed, so no `#[doc(hidden)]` hook was added. Run length 1 and the seed-word probe still need one, in (b), per Q4.

| set (§3.3) | windows | numbers | near misses | differing |
|---|---|---|---|---|
| bases 10–25 in full (13 bases) | 13 | 8,669,368 | 45 (27 to b24, 18 at b25; 69 at b10) | 0 |
| bases 27–64: start, middle, end (31 bases) | 93 | 9.3e6 | 0 | 0 |
| M4 failure bases 27–30, 49, 50, 52–55: 4 seeded windows each (23 and 25 are covered in full above) | 40 | 4.0e6 | 0 | 0 |
| digit-gain points, 1e5 centred, 27 points, bases 27–64 (b40 dS 3,276,800,000,000 and dC 3,783,722,724,161; b50 dS 48,828,125,000,000,000 and dC 56,381,862,225,549,391, matching §3.3) | 27 | 2.7e6 | 1 | 0 |
| kernel boundary: b40 and b50 straddling the range start, b40 straddling the end, b10 `[47, 200)` | 4 | 300,153 | 2 (69, 128) | 0 |
| partial runs at the b40 and b57 starts, lengths 1…100,001 | 18 | 201,922 | 0 | 0 |
| near-miss windows: b49 20363742218601559:45 and b40 1917398732423:37 | 2 | 2e5 | 2 | 0 |
| fallback only: b80 and b97 starts, 5e4 | 2 | 1e5 | 0 | 0 |
| benchmark windows, 2e8 whole, b40 and b50 (extra) | 2 | 4e8 | 0 | 0 |
| **total** | **201** | **425,471,443** | **50** | **0** |
| repeat of the above without the 2e8 windows | 199 | 25,471,443 | 50 | 0; GPU SHA-256 identical to run 1 on all 199 |
| seeded sweep: 10 × 1e6 per base 10–64 (small bases take their whole range) | 440 | 341,084,160 | 320 | 0 |

The CPU side's distribution sums to the window size in every window. Wall time was 126 s for the 201 windows; the two 2e8 windows took 57 s and 58 s of single-thread wasm. The sweep took 107 s.

**CI subset on SwiftShader** (ivory, `mcr.microsoft.com/playwright:v1.62.0-noble`, nice 19): 13 windows, 1.1e6 numbers, 11 near misses, 0 differing. It takes 10.9 s in the harness and 13.6 s including container start, far under the 2-minute cap. Each new base's first GPU call costs about 1 s of SwiftShader compile, which is most of that time.

## Rates

`bench.mjs`, three rounds interleaved. A second agent was building and testing Rust on the Mac at the same time (load averages 1.3–6). `pmset -g therm` recorded no thermal, performance or CPU-power warning before or after. Round-to-round spread is 0.5 % or less, with no drift.

| | b40_detailed | b50_detailed | NiceMark |
|---|---|---|---|
| kernel only: `process_chunk_gpu` 2e8 from the plan start, fresh page, 2 untimed + 3 timed calls, median; rounds 1/2/3 | 6.557e8 / 6.592e8 / 6.577e8 | 3.813e8 / 3.830e8 / 3.826e8 | — |
| real page, suite mode, GPU worker, 60 s budget; rounds 1/2/3 | 6.581e8 / 6.567e8 / 6.584e8 (89 × 2e8) | 3.829e8 / 3.801e8 / 3.818e8 (52 × 2e8) | 265 / 263 / 264 |
| compile cost: first call minus a steady call | 0.03–0.09 s | 0.03–0.09 s | suite `warmup_seconds` 0.34 / 0.53 |

- b40 equals the 08-28 figure, 6.57e8.
- b50 in the browser is 0.80 of native per-number (4.81e8), the same ratio as b40 (0.81).
- The §4 projection for (b) therefore keeps today's baseline: about 264 → 840–1,000.

## Machine time and cleanup

- **Time:** first SSH at 15:49:53Z, cleanup verified at 16:11:30Z. That is about 22 min wall, of which harness processes ran about 9 min.
- **Authorisation:** §7 dates the mayalaran window from "~16:30 UTC". This session started 40 minutes earlier, on the brief's statement that the window was open.
- **Cleanup:**
  - Killed by PID: the watchdog (90844), then its `sleep`.
  - Removed `~/claude-exp-2026-10-31-browser`.
  - No process of mine remains (`ps -axo`).
- **Writes outside the directory**, found by `find ~/Library -newer <start>`:
  - **`npm i` ran node-gyp** for Playwright's optional `fsevents`. It created `~/Library/Caches/node-gyp/24.14.1` and `~/Library/Caches/com.apple.python/Users/…` (.pyc files). Both were created today and both were removed.
  - **Chrome for Testing created `~/Library/Preferences/com.google.chrome.for.testing.plist`**, holding `LastRunAppBundlePath`. I removed it with `defaults delete com.google.chrome.for.testing`, then deleted the empty plist that cfprefsd left behind.
  - **Chrome rewrote `~/Library/Application Support/Google/Chrome for Testing/Crashpad/settings.dat`.** The file is 40 B and already existed (created 08-26 by the earlier harness), so it was left in place. No crash reports were written.
  - Untouched: the other agent's `~/claude-exp-2026-10-31-seed`.
  - The staging recipe in `lib.mjs` now uses `--omit=optional --ignore-scripts` and notes the plist.

## What step (c) can reuse

`wasm-client/e2e/hw/` on `exp/browser-gpu-harness`:

- **`lib.mjs`**:
  - `launch({software, args})`: `channel: "chromium"` in both modes. It works in the CI image too, so the SwiftShader parity runs on the same binary.
  - `adapterRecord(page)`: the §3.2 record plus `fallback_source`, `gpu_init` name, build SHA and limits.
  - `hardwareProblems(rec, {expectVendor, rate})` and `softwareProblems(rec)`: the `--hw` assertion and its CI inverse.
  - `hwWindows({extra, randomPerBase})` and `ciWindows()`: the §3.3 lists as BigInt, with `gainPoints()` mirroring the native `windows()`.
  - `parseExact` and `describeDiff`: a readable diff without losing values above 2⁵³.
  - `serve()` with `/blank.html`.
  - A `parseArgs` that takes repeated `--chromium-arg`.
- **`parity.mjs`**: the parity step, `--subset hw|ci`. Per-window timeout, recovery in a fresh page, JSONL output.
- **`adapter.mjs`**: `--expect-vendor` and `--software` exit codes; `--chrome-gpu` saves chrome://gpu.
- **`bench.mjs`**: the suite A/B skeleton. A second site root is still needed for old against new.
- **`serve.mjs`**: for `parity.html` by hand.

For (c) to fold in:
- move the parity, `--expect-vendor` and `--chromium-arg` into `e2e.mjs`;
- add the CI step (`node parity.mjs --software --subset ci`, about 11 s);
- write `parity.html`;
- add the raw-WGSL probe.

## Not done

- **The H5 raw-WGSL Tint probe** (`metal_half_shift_div_repro` variants × K) was not run. It was outside this half-day's brief and belongs to (c).
- **H4 (demoux)** was out of scope.
- **Run length 1 and the seed-word probe** need the test export, which comes with (b).
- **Parity ran on the main thread, not the GPU worker.** Tint compiles the same WGSL either way. The worker path is covered by `e2e.mjs --hw`: the offline field gives equal histograms on CPU and GPU, and the b49 submission is exact.
