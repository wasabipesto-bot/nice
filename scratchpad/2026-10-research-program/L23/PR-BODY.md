# Browser client: CPU detailed mode through the finite-difference dispatch

One commit on `main` (2 files); #221, which added the dispatch this uses, is merged.

## What and why

#221 added `detailed_fd::process_range_detailed_fd`, which has the same signature and output as `process_range_detailed`, uses finite differences at bases 40 to 64 (all with a legal range except 63) and sends every other base to the division loop. Only the native client's CPU path calls it so far. The browser client's CPU path is `process_chunk_wasm`, which every page worker calls once per 100,000-number chunk. It still calls `process_range_detailed` directly. This PR points it at `process_range_detailed_fd`. The dispatch stays in `nice_common`, so the bases without the new loop fall back exactly as on native. The JSON that comes back is unchanged, so no JavaScript changes. The finite-difference code is plain integer Rust with no `std::arch`, so it builds for `wasm32-unknown-unknown` as is. Per number it does 64-bit adds, a `u64` mask and `count_ones()`. Its only `u128` work per number is the loop counter and the histogram increment, the same as the division loop. The `U256` seed runs once per call, so once per 100k chunk in the browser.

## Exactness

The comparison ran in a real browser. I built the wasm twice with `wasm-pack build --target web --out-dir pkg`, the command the Browser Client workflow runs: once from #221's parent (d1ff798, old: `process_range_detailed`) and once from this branch (new). I served each build with a copy of `web/search`. In one headless Chromium (151.0.7922.34, from the Playwright 1.62.0 image the e2e uses), I loaded each build in its own page and called the exported `process_chunk_wasm(start, end, base)`, the function the workers call, on the windows below. Each call's JSON string came back unparsed, so a near miss above 2^53 is compared digit for digit. The two builds' strings had to be byte-identical, chunk by chunk:

| windows | numbers compared | near misses | identical |
|---|---|---|---|
| `b40_detailed` and `b50_detailed` benchmark windows (2,000,000 each; `b50_detailed_1t` is the first half of the base-50 one), each in 100k chunks (as the worker does), as one call, and in 7,919-number chunks | 12,000,000 | 0 | yes |
| the page's offline benchmark field (base 40, 10,000,000), 100k chunks | 10,000,000 | 0 | yes |
| first and last 100k of the range and four seeded random 100k windows, every base 40 to 64 with a range (63 included; it stays on the division loop) | 12,000,000 | 0 | yes |
| the base-49 window from the e2e's claim stub, with the near miss 20363742218601559 (45 unique digits), as one call and in 997-number chunks | 200,000 | 1 (in each) | yes |
| the whole range of every base 10 to 24 that has one (division fallback) | 2,243,540 | 27 | yes |

Near misses are rare at the bases the new loop covers, so I also scanned with the new build from the start of base 40's range. Its first near miss is 1917398732423 (37 unique digits), 1.11 billion numbers in. The 20,000,000 numbers around it (1M chunks) and a 100k window centred on it are identical on both builds.

`wasm-client/e2e/run.sh` (the CI job's end-to-end run) passes locally on this branch. Its CPU-against-GPU check now compares the new loop with the unchanged WebGPU kernel (on SwiftShader): their histograms for the offline benchmark field are identical. The submit-shape checks pass on both backends: the base-49 near miss is submitted as exact digits.

## Measured

All runs used headless Chromium 151.0.7922.34 from the Playwright 1.62.0 image on a 4-vCPU AMD EPYC (Rome) VPS. Builds: Rust 1.99.1 (the pinned toolchain), wasm-pack 0.13.1 (what the workflow's installer fetches), wasm-bindgen 0.2.127. Old is #221's parent and new is this branch. Spread is the lowest and highest round relative to the median.

**The page's benchmark suite** ("Benchmark suite (NiceMark)", CPU backend, 60 s budget) was driven by Playwright, alternating old, new, old, new, old, new. The pool used its default 3 workers (80 % of 4 logical CPUs), and `b50_detailed_1t` ran on its one-worker pool. API requests were answered locally. Rates are in million numbers per second:

| scenario | old rounds | old median (spread) | new rounds | new median (spread) | new / old |
|---|---|---|---|---|---|
| b40_detailed | 3.563 3.580 3.564 | 3.564 (−0.0/+0.5 %) | 36.571 36.795 36.002 | 36.571 (−1.6/+0.6 %) | **10.26×** |
| b50_detailed | 4.715 4.662 4.717 | 4.715 (−1.1/+0.0 %) | 31.097 31.562 31.127 | 31.127 (−0.1/+1.4 %) | **6.60×** |
| b50_detailed_1t | 1.813 1.782 1.751 | 1.782 (−1.7/+1.8 %) | 8.802 8.776 8.690 | 8.776 (−1.0/+0.3 %) | **4.92×** |
| NiceMark (browser) | 247.9 245.9 245.1 | 245.9 (−0.3/+0.8 %) | 1710.8 1721.0 1695.2 | 1710.8 (−0.9/+0.6 %) | **6.96×** |

**One `process_chunk_wasm` call, without the page.** Each measurement covers the 1,000,000 numbers at the start of the base's range. It uses a fresh page with two untimed calls, then the median of three timed calls. A fresh instance's first call runs on V8's baseline wasm compiler, which is 1.7 to 1.9× slower here. Old and new alternate over three rounds, in ns per number. For reference, the native column is the same box and the same window, single thread, pinned (#221's `fd_timing`):

| base | old (spread) | new (spread) | new / old | native division | native finite differences |
|---|---|---|---|---|---|
| 40 | 682.7 (−0.7/+1.4 %) | 58.3 (−0.9/+0.0 %) | **11.71×** | 265.80 | 43.07 |
| 50 | 508.4 (−1.1/+0.5 %) | 70.2 (−3.8/+6.8 %) | **7.24×** | 414.42 | 48.77 |
| 60 | 654.5 (−0.5/+0.7 %) | 72.2 (−1.5/+1.4 %) | **9.07×** | 540.92 | 50.21 |

In the browser, the new loop runs 1.35 to 1.44× its native time. Base 40 gains the most because the old loop's base-40 path extracts digits from a `u128`, and in wasm that runs 2.6× its native time (683 against 266 ns), against 1.2× at bases 50 and 60. `b50_detailed_1t` gains less than the bare call (4.9× against 7.2×). The suite's 1M-number window takes 114 ms on the new build against 70 ms for the bare call, and 561 ms against 508 on the old. Both builds pay a similar fixed cost per window in the page and pool (44 and 53 ms), which weighs more once the loop is fast.

## Not in this PR

- The browser GPU path: the WebGPU kernel behind `process_range_detailed_web_async` still divides per number.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
