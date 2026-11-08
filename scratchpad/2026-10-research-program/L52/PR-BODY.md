Stacked on #248 (which is on #247): #248's commit is the base of this branch; the new work is the last commit.

## What

The CPU join tests each top against the bottoms of the digit-sum classes its roots name, one 64-bit AND per bottom (`CpuJoin::scan`). A pair passes when the AND is zero, which about 3 % of pairs do at the production shapes. Each of the three scan paths (`scan_avx512`, `scan_avx2`, `scan_any`) formed the pass bits of a chunk of 32, 16 or 8 bottoms and looped over the set bits, calling `survivor` (not inlined) for each one: the in-range test, the prefilter and, for the ~6 % that pass it, the full check.

This PR splits a scan into two passes over each piece of a class (up to 1024 bottoms; a class at the production shapes holds about 300):

- **Pass 1** forms a byte of pass bits per eight bottoms, with the same AND and zero test as before: `_mm512_testn_epi64_mask` (`vptestnmq`) on AVX-512F; `_mm256_and_si256`, `_mm256_cmpeq_epi64` and `_mm256_movemask_pd` on AVX2 (LLVM packs the two compares of a byte into one `vmovmskps`); eight scalar tests on the portable path. It appends the positions of the byte's set bits to a `u16` index list through a 256-entry table: it stores the table's row of eight positions, plus the byte's offset, at the list's end, and moves the end by the byte's bit count (a second 256-entry table). Nothing branches on the bits. A piece's last 0–7 bottoms are listed one at a time in the same way: store always, move the end by the test.
- **Pass 2** runs `survivor` on the listed bottoms in order. `survivor` is now inlined into it (`#[inline(always)]`); the full check stays a call.
- The three paths share the compaction (`emit`), the tail (`pass1_rest`), the piece loop (`for_each_passing`) and pass 2. They differ only in how they form the byte. The index list (2 KiB) lives in `Scratch` with the thread's other buffers.
- Classes longer than a piece are scanned a piece at a time, so there is no length limit (the old paths had none either). The piece length is a field of `CpuJoin` (always 1024 outside the tests), so that tests can lower it, as they lower the SIMD paths.
- **The AVX-512 path is now taken only where the CPU also has AVX2.** Its pass 1 is compiled with `avx512f`, which rustc lets imply `avx2`, and it does execute an AVX2 instruction (the VEX `vpbroadcastw` of the byte's offset; the EVEX form would need AVX512BW/VL). The stride walk already requires both, since a VM can expose AVX-512F without AVX2.
- No knobs, no new public API.

## Why

perf on #248's head, on the machine below (1 thread, 4 sampled partitions each of b60 1e16 and b62 1e17 slice 0, recording after the slice setup):

| | b60 1e16 | b62 1e17 slice 0 |
|---|---|---|
| **`scan_avx2`** (the AND and the pass extraction): share of cycles | **39.0 %** | **37.6 %** |
| its IPC | 1.66 | 1.65 |
| **its share of the partition's branch mispredictions** | **50.0 %** | **49.8 %** |
| `survivor` (the in-range test and the prefilter) | 14.6 % | 14.7 % |
| `get_is_nice_with_known_lsd` (the full check) | 11.1 % | 12.1 % |
| the whole partition (`perf stat`, counting): IPC, branch mispredictions | 2.18, 61 M (3.3 % of branches) | 2.17, 58 M (3.3 %) |

- **The chunk branch is a coin toss.** A 16-bottom chunk holds a passing bottom with probability about 1 − 0.97^16 ≈ 0.39, so the branch on the chunk's pass bits mispredicts about 0.4 times a chunk. That is about 30 M mispredictions per b60 1e16 partition, half of the partition's, at roughly 18 cycles each on this core.
- **Each pass left the vector loop.** Every passing bottom was a `vzeroupper` and a `call` into `survivor`, and the loop kept its chunk pointer and both broadcast masks on the stack across the call. By address range, about 52 % of `scan_avx2`'s cycle samples fell in this per-pass extraction and 36 % in the vector loop itself.
- **Two passes remove both.** Pass 1 has no data-dependent branch. Pass 2 is a counted loop over the list, whose loop branch mispredicts only at its end, and the inlined `survivor`'s loads and arithmetic overlap from one pair to the next.

## Soundness

- **The same predicate.** A bottom passes iff `mask & top.mask == 0`, as before, on every path. AVX-512F's `vptestnmq` sets a lane's bit iff the lane's AND is zero. AVX2 compares the AND with zero (`vpcmpeqq`) and takes each lane's sign bit (`vmovmskpd`). The portable path tests `m & t == 0`. The two SIMD paths use the old paths' instructions, now eight bottoms per byte (the old AVX-512 loop took 32 per step, the AVX2 one 16).
- **The same pairs, in the same order.** `BIT_POS[byte]` lists the set bits of `byte` in ascending order, and `BIT_CNT[byte]` counts them. The byte for bottoms `at..at + 8` writes `at + BIT_POS[byte][i]` for `i < 8` at the list's end and moves the end by `BIT_CNT[byte]`. The entries past the count are written over by the next byte or the tail, or lie past the final count and are never read. So after each byte the list holds exactly the passing indices so far, ascending. The tail does the same one bottom at a time (write the index, move by the test). Pieces go in order, and pass 2 adds the piece's start. So `survivor` sees the same (top, bottom) pairs in the same order as before: the old scans also took each chunk's set bits from the lowest, chunk by chunk, then the rest. Only the new test pins that order (it compares the index lists in order); the end-to-end comparisons compare sets. The order does not matter for correctness anyway: `run_all` sorts the hits, and the client treats them as a set.
- **In bounds.** The list holds 1024 entries, and a piece at most 1024 bottoms (a `debug_assert` in `pass1` states the contract). Before each byte the list's length is at most `at` (each byte adds at most 8 to both), so its eight slots lie below `at + 8`, within the piece's length. The tail writes at an index no greater than the bottom's own. The stores are bounds-checked slice writes, not raw pointers: a broken bound would panic, not write out of bounds. Indices are below 1024, so they fit `u16`.
- **`survivor` is unchanged** apart from `#[inline(always)]`.

**Tests:**

- New `the_bit_tables_list_every_byte`: `BIT_POS` and `BIT_CNT` against the set bits of all 256 bytes.
- New `the_first_pass_lists_the_same_bottoms_on_every_path`. On every pass-1 path the CPU has, it checks the list against a plain filter:
  - random classes of lengths 0, 1, 7, 8, 9, 15, 16, 17, 31, 32, 33, 300, 1023 and 1024, and 100 random lengths up to 1024;
  - each with 0 %, 1 %, 40 % and 100 % of the bottoms passing, against random top masks of 1–32 digits (a passing bottom has none of the top's digits, a failing one at least one);
  - classes of 1025, 2085 and 5120 bottoms (1 %, 40 % and 100 % passing) through `for_each_passing` with each path's dispatch (the CPU's best, AVX2 forced, the portable loop forced), which takes them in pieces.
- `every_scan_finds_the_same_pairs` now also runs each path with pieces of 9 bottoms. The test windows scan classes of at most about 140 bottoms (no production shape comes near 1024 either), so without this no end-to-end test would cross a piece boundary.
- The existing tests cover the whole scan: the reference join on the test windows (every visited partition's join survivors, prefilter survivors and hits), `every_scan_finds_the_same_pairs` (the best path against AVX2 and the portable loop forced, on every partition of the windows), the stride path on whole windows, slices, and the opt-in production and whole-field references.
- Once, with the piece constant itself set to 9 (not committed), the whole `cpu_join` suite but the pass-1 test (whose lengths assume a piece of 1024) and the opt-in production reference passed: every class of every test, production shapes included, scanned in pieces of 9.

## Measurements

**Machine:** a 4-vCPU AMD EPYC-Rome (**Zen 2**) VM with **AVX2 only**, so pass 1 is the AVX2 one; every run under `nice -n 19`. Mispredictions, calls and spills cost differently on other cores, so the ratio there may differ; besides this machine I measured one AVX-512 host (below).

**Method:** release builds of #248's head (`7f5260b`) and this PR. A harness outside this PR, using only `CpuJoin`'s public API, runs sampled partitions of one slice (NiceMark's bit-reversed `sample_order`) through `CpuJoin::run_partition` on 1 or 4 threads; whole fields run every partition. The two binaries are interleaved with the order alternating per round (#248, PR; PR, #248; #248, PR), 3 rounds. Figures are medians; spread = (max − min) / median; "per round" is #248's time over the PR's in the same round. Before each round the script waited for the 1-min load average to be ≤ 2 and logged it: the rounds started at 1.36, 2.00 and 1.94. It also sampled the other processes at the start of every run: other sessions never used more than 1.7 cores there. The 4-thread runs lift the load to 3–5 themselves.

Fields as in #248: b60 at NiceMark's `b60_msd_weak` start, 1157209632114824200908. b62 1e17 is the whole field 4473066762334864396992 + 1e17, which the CPU cuts into 7 slices; its slice 0 is used here. b62 1e14 starts at 4473156762334864396992, b64 at 41242006262957161709568, and b58 1e15 is NiceMark's field at 104400216587923470200.

Times are ms per partition and thread for the sampled partitions (wall × threads / partitions) and wall seconds for the whole fields. Every run of both sides found the same join survivors and full checks (below).

| work | threads | #248 (rounds) | spread | this PR (rounds) | spread | speed-up | per round |
|---|---|---|---|---|---|---|---|
| **b60 1e16**, 4 partitions | 1 | **2225** ms (2222, 2236, 2225) | 0.6 % | **1758** ms (1764, 1758, 1750) | 0.8 % | **×1.266** | 1.260, 1.272, 1.272 |
| **b62 1e17** slice 0, 4 partitions | 1 | **2110** ms (2110, 2107, 2148) | 2.0 % | **1706** ms (1706, 1688, 1710) | 1.3 % | **×1.237** | 1.237, 1.248, 1.256 |
| **b60 1e16**, 16 partitions | 4 | **2436** ms (2365, 2436, 2439) | 3.0 % | **1934** ms (1936, 1921, 1934) | 0.8 % | **×1.260** | 1.222, 1.268, 1.261 |
| **b62 1e17** slice 0, 16 partitions | 4 | **2371** ms (2378, 2346, 2371) | 1.3 % | **1916** ms (1860, 1922, 1916) | 3.2 % | **×1.237** | 1.278, 1.221, 1.237 |
| b58 1e15 (NiceMark's field), 32 partitions | 1 | **536** ms (536, 538, 521) | 3.2 % | **412** ms (414, 400, 412) | 3.3 % | **×1.300** | 1.296, 1.345, 1.264 |
| b58 1e15, 128 partitions | 4 | **593** ms (593, 606, 586) | 3.3 % | **451** ms (451, 450, 476) | 5.7 % | **×1.316** | 1.316, 1.346, 1.233 |
| b60 1e14, whole field (3600 partitions) | 1 | **122.7** s (122.7, 122.6, 124.6) | 1.6 % | **111.6** s (111.6, 112.6, 110.8) | 1.6 % | **×1.100** | 1.100, 1.089, 1.124 |
| b62 1e14, whole field (3844 partitions) | 1 | **156.4** s (156.3, 156.4, 156.5) | 0.2 % | **145.0** s (145.0, 144.1, 145.1) | 0.6 % | **×1.079** | 1.078, 1.085, 1.079 |
| b64 1e14, whole field (4096 partitions) | 1 | **299.8** s (299.6, 301.8, 299.8) | 0.7 % | **258.0** s (262.8, 258.0, 255.9) | 2.7 % | **×1.162** | 1.140, 1.170, 1.172 |
| b60 1e14, whole field | 4 | **33.8** s (33.0, 33.8, 33.8) | 2.4 % | **30.6** s (30.3, 30.6, 31.0) | 2.3 % | **×1.104** | 1.089, 1.105, 1.089 |
| b62 1e14, whole field | 4 | **42.9** s (42.5, 42.9, 45.0) | 5.8 % | **39.6** s (39.1, 39.6, 39.6) | 1.3 % | **×1.083** | 1.085, 1.082, 1.135 |
| b64 1e14, whole field | 4 | **83.9** s (83.9, 84.7, 83.9) | 1.0 % | **71.0** s (70.8, 71.0, 73.9) | 4.4 % | **×1.182** | 1.186, 1.194, 1.135 |

- **At the production shapes (b60 1e16, b62 1e17) the join is ×1.24–1.27 faster**, at 1 and 4 threads alike; every single round is ×1.22–1.28. b58 1e15, where the scan is a larger share of a partition, gains ×1.30–1.32.
- The whole 1e14 fields gain less (b60 ×1.10, b62 ×1.08, at 1 and 4 threads): their partitions spend a larger share on listing and extending the bottoms, which this PR does not touch. b64 1e14 has 4.3× b60's join survivors for 1.14× its partitions, so it gains more (×1.16 / ×1.18).
- The 1-thread whole fields ran as a separate block of 3 rounds after NiceMark (rounds started at a 1-min load of 1.89, 1.41 and 1.09; other sessions ≤ 0.3 cores at every run start).

**Counters** (`perf stat`, counting from 3.5 s on, past the slice setup; 1 thread, 4 partitions, 2 rounds alternating; per partition = count × ms per partition / task-clock; medians):

| per partition | b60 1e16, #248 | b60 1e16, this PR | b62 1e17 slice 0, #248 | b62 1e17 slice 0, this PR |
|---|---|---|---|---|
| instructions | 1.571e10 | 1.635e10 (+4.1 %) | 1.511e10 | 1.557e10 (+3.0 %) |
| branches | 1.854e9 | 1.999e9 (+7.8 %) | 1.777e9 | 1.869e9 (+5.2 %) |
| **branch mispredictions** | **61.3 M** (3.31 % of branches) | **25.3 M** (1.26 %) | **58.4 M** (3.29 %) | **21.7 M** (1.16 %) |
| cycles | 7.21e9 | 5.83e9 (−19.2 %) | 6.96e9 | 5.53e9 (−20.5 %) |
| **IPC** | **2.18** | **2.81** | **2.17** | **2.81** |
| ms per partition in these runs | 2218 | 1797 | 2136 | 1703 |

- **Mispredictions fall by 59–63 %** (61 → 25 M a b60 1e16 partition, 58 → 22 M at b62), and IPC rises from 2.2 to 2.8. Instructions grow by 3–4 % and branches by 5–8 %: the compaction's table loads and stores, and two bounds compares per eight bottoms, all predictable. Cycles fall by 19–21 %.

NiceMark nice-only on the CPU (`nice_client niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json`, no `--gpu`), 4 rounds alternating (#248, PR; PR, #248; …), every run started at a 1-min load of ≤ 2.0 (1.85–1.98); medians; the scenario rows are numbers/s; "per round" is the PR's over #248's:

| | #248 (rounds) | this PR (rounds) | speed-up | per round |
|---|---|---|---|---|
| **score** | 864.9 (851.4, 861.0, 868.8, 874.2) | 1091.0 (1090.2, 1099.7, 1091.8, 1068.2) | **×1.261** | 1.280, 1.277, 1.257, 1.222 |
| b58 MSD-weak (1e15 field, 4 threads) | 2.045e12 (1.949e12, 2.017e12, 2.073e12, 2.090e12) | 2.666e12 (2.641e12, 2.690e12, 2.692e12, 2.627e12) | **×1.303** | 1.355, 1.334, 1.298, 1.257 |
| b58 MSD-weak, 1 thread | 5.453e11 (5.461e11, 5.366e11, 5.446e11, 5.529e11) | 7.228e11 (7.330e11, 7.250e11, 7.206e11, 6.908e11) | **×1.325** | 1.342, 1.351, 1.323, 1.249 |
| b58 MSD-strong | 1.275e13 (1.252e13, 1.273e13, 1.279e13, 1.277e13) | 1.511e13 (1.501e13, 1.522e13, 1.525e13, 1.424e13) | **×1.185** | 1.199, 1.196, 1.192, 1.115 |
| b60 MSD-weak (sampled) | 5.297e12 (5.242e12, 5.296e12, 5.297e12, 5.417e12) | 6.537e12 (6.545e12, 6.591e12, 6.528e12, 6.478e12) | **×1.234** | 1.248, 1.244, 1.232, 1.196 |
| b62 MSD-weak (sampled) | 5.627e12 (5.599e12, 5.672e12, 5.656e12, 5.583e12) | 7.134e12 (7.079e12, 7.188e12, 7.027e12, 7.262e12) | **×1.268** | 1.264, 1.267, 1.242, 1.301 |

- #248's score here (864.9) is within 0.5 % of what its own PR measured on this machine (868.5).
- The PR's fourth round was its lowest (score 1068.2, b58 MSD-strong 1.424e13 against 1.50–1.53e13 in the others); the medians do not use it.
- MSD-strong gains least: it has about an eighth of MSD-weak's join survivors per partition, so the scan's passes, and the mispredictions they caused, are a smaller part of its work.
- NiceMark samples partitions for a fixed time, so the two sides sampled different numbers of partitions and their survivor counts are not comparable; the A/B above compares counts. Within a side, runs that sampled the same number of partitions agree.

**AVX-512.** The machine above has none, so the AVX-512 path was run on a rented AMD Ryzen 9 9950X (Zen 5; `avx2` and `avx512f` with BW/VL/DQ/VBMI2 in `/proc/cpuinfo`; a container with a quota of about 15 cores), from this branch's head:

- **Detection:** `is_x86_feature_detected!` reports `avx512f` and `avx2`, so the join takes the AVX-512 path, and the new test ran all three paths: `first pass on ["portable", "avx2", "avx512"]: 84860 bottoms listed alike`.
- **Tests there, all with AVX-512 as the best path:** the whole `cpu_join` suite (15 passed, including `every_scan_finds_the_same_pairs` against AVX2 and the portable loop, with pieces of 1024 and of 9); `cargo test --release -p nice_common -p nice_client` (190 + 22 passed); the opt-in production reference (`NICE_TEST_CPU_JOIN_REF=3`); and the whole b42 field (join = reference = stride, 417,789,835 / 16,879,877, no hits).
- **Speed, and counts against the AVX2 path on the same box.** Three binaries, interleaved with the order alternating: #248's head (whose AVX-512 scan is the old 32-a-step loop), this PR, and this PR with the AVX-512 path switched off (a local one-line edit, so it runs AVX2). Two blocks of 3 rounds; ms per partition and thread, medians. Every run of the three binaries found the same survivors and full checks (the same as the AVX2 runs above where the shapes match; b60 1e16 32 partitions 1,102,408,589 / 70,031,302, b62 1e17 slice 0 32 partitions 1,103,191,075 / 65,690,652; no hits).

| work | threads | #248 | this PR (AVX-512) | this PR, AVX2 | speed-up over #248 (per round) | AVX2 / AVX-512 |
|---|---|---|---|---|---|---|
| **b60 1e16**, 4 partitions | 1 | 1310 (1297, 1323, 1291, 1363, 1266, 1390) | 1064 (1043, 1122, 1019, 1048, 1079, 1148) | 1084 | **×1.232** (1.17–1.30) | ×1.02 |
| **b62 1e17** slice 0, 4 partitions | 1 | 1214 (1203, 1265, 1207, 1247, 1220, 1194) | 980 (971, 1001, 987, 1008, 972, 973) | 1018 | **×1.238** (1.22–1.26) | ×1.04 |
| b60 1e16, 32 partitions | 8 | 1307 (1278, 1343, 1307) | 1067 (1033, 1174, 1067) | 1060 | ×1.225 (1.14–1.24) | ×0.99 |
| b62 1e17 slice 0, 32 partitions | 8 | 1198 (1159, 1277, 1198) | 985 (976, 1157, 985) | 1007 | ×1.216 (1.10–1.22) | ×1.02 |
| b60 1e14, whole field (s) | 16 | 4.76 (5.47, 4.74, 4.76) | 4.65 (5.14, 4.65, 4.22) | 4.42 | ×1.025 (1.02–1.13) | ×0.95 |

- **On this AVX-512 core the PR is ×1.22–1.24 faster at the production shapes**, about what it gains on the Zen 2 machine with AVX2, and more than the ×1.08–1.15 I had estimated: the old AVX-512 loop's branch per 32 bottoms and call per pass cost as much there.
- **Its AVX-512 pass 1 is at most a few percent faster than its AVX2 pass 1** (×0.95–1.04 by row, single rounds ×0.95–1.15): once pass 1 has no branch, the vector width matters little to the scan.
- The box's runs scatter more than the VM's (single rounds up to ±8 %). The 16-thread runs exceeded its CPU quota, so the whole-field row and the 16-thread sampled runs (×1.19–1.26, in `raw`) are the least reliable.

## Exactness

All release builds of this head, on the Zen 2 machine unless marked; the AVX-512 host's runs are listed above.

- **The new tests** pass: `the_bit_tables_list_every_byte`, and `the_first_pass_lists_the_same_bottoms_on_every_path`, which ran the portable and AVX2 paths here (`first pass on ["portable", "avx2"]: 84860 bottoms listed alike`) and all three on the AVX-512 host.
- **The existing `cpu_join` tests pass unchanged**: the reference join on the test windows (including the b57 window whose classes take two pieces), all three scan dispatches on every partition of the windows, the stride path on whole windows, slices, the field prune, the stepped against the divided tops, b10's 69, and the fixed-point prefilter tests. `cargo test --release -p nice_common -p nice_client`: 190 + 22 passed, 6 ignored (opt-in); #248 had 188 + 22.
- The opt-in `cpu_join_matches_the_reference_on_production_fields` (`NICE_TEST_CPU_JOIN_REF=3`: 3 partitions of each plan field, b42–b64): ok, against the reference join; also with the piece constant at 9, and on the AVX-512 host.
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = reference = stride, 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits. On 4 threads: reference 84 s, join 10.7 s, stride 113 s. On the AVX-512 host the same, on 15 threads.
- **Every timed run above, of both sides, has #248's join survivors and full checks** (the A/B ran on the first version of this commit, which differs only in the AVX-512 gate, the test-only piece field and the tests; two sanity rounds of this head against #248 at the production shapes gave ×1.21–1.29 with the same counts):
  - b60 1e16, 4 partitions: 136,900,315 / 8,692,368; 16 partitions: 549,719,536 / 34,926,644;
  - b62 1e17 slice 0, 4 partitions: 137,605,271 / 8,194,223; 16 partitions: 550,916,180 / 32,806,057;
  - b58 1e15, 32 partitions: 319,652,260 / 18,029,967; 128 partitions: 1,277,611,815 / 72,056,777;
  - whole b60 1e14 field: 1,326,103,590 / 84,383,498;
  - whole b62 1e14 field: 1,470,093,637 / 87,495,922;
  - whole b64 1e14 field: 5,702,041,796 / 346,647,759.
  - No hits on either side.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc 1.99.1): clean. The GPU feature sets do not touch this code: `cpu_join.rs` has no feature-gated items, and the GPU modules use only `CpuJoin`'s public API.

## Not in this PR

- **The seeded check.** The full check could start from the 16 digits the join already knows (positions 0..7 of n² and n³: the bottom's 12 and the prefilter's 4) instead of re-deriving some of them; a prototype measured ×1.07–1.11 on top of this PR at the production shapes on this machine. A separate PR.
- **A vectorised second pass** (the prefilter run eight listed pairs at a time): not tried.
- **Raw-pointer stores in the compaction.** The slice writes cost two predictable bounds compares per eight bottoms; unchecked stores would save some of the 3–4 % more instructions and 5–8 % more branches in the counter table under Measurements. Not measured; the checked form adds no `unsafe` beyond the SIMD loads, which the old scans had too.
- **A switch to force a lesser scan path** at run time, as `NICE_SIMD` does for the stride walk: the CPU join always takes the best path it detects. That would be a new knob.
- **Other shapes of the same scan**, measured in single runs at b60 1e16 on 1 thread and no better: AVX2 taking 16 bottoms a step as the old loop did (two bytes per step; 1733 and 1740 ms per partition against 1742 and 1800 ms for 8 a step), and `scan` kept out of line (`#[inline(never)]`; 1772 and 1809 ms against 1745 and 1706 ms).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
