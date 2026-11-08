Stacked on #248 (which is on #247): #248's commit is the base of this branch; the new work is the last commit.

## What

The CPU join tests each top against the bottoms of the digit-sum classes its roots name, one 64-bit AND per bottom (`CpuJoin::scan`). A pair passes when the AND is zero, which about 3 % of pairs do at the production shapes. Each of the three scan paths (`scan_avx512`, `scan_avx2`, `scan_any`) formed the pass bits of a chunk of 32, 16 or 8 bottoms and looped over the set bits, calling `survivor` (not inlined) for each one: the in-range test, the prefilter and, for the ~6 % that pass it, the full check.

This PR splits a scan into two passes over each piece of a class (up to 1024 bottoms; a class at the production shapes holds about 300):

- **Pass 1** forms a byte of pass bits per eight bottoms, with the same AND and zero test as before (`vptestnmq` on AVX-512F; `vpand`, `vpcmpeqq` and `vmovmskpd` on AVX2; eight scalar tests on the portable path). It appends the positions of the byte's set bits to a `u16` index list through a 256-entry table: it stores the table's row of eight positions, plus the byte's offset, at the list's end, and moves the end by the byte's bit count (a second 256-entry table). Nothing branches on the bits. A piece's last 0–7 bottoms are listed one at a time in the same way: store always, move the end by the test.
- **Pass 2** runs `survivor` on the listed bottoms in order. `survivor` is now inlined into it (`#[inline(always)]`); the full check stays a call.
- The three paths share the compaction (`emit`), the tail (`pass1_rest`), the piece loop (`each_pass`) and pass 2. They differ only in how they form the byte. The index list (2 KiB) lives in `Scratch` with the thread's other buffers.
- Classes longer than a piece are scanned a piece at a time, so there is no length limit (the old paths had none either).
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
- **Two passes remove both.** Pass 1 has no data-dependent branch. Pass 2 is a counted loop over the list, so its one branch mispredicts only at the end, and the inlined `survivor`'s loads and arithmetic overlap from one pair to the next.

## Soundness

- **The same predicate.** A bottom passes iff `mask & top.mask == 0`, as before, on every path. AVX-512F's `vptestnmq` sets a lane's bit iff the lane's AND is zero. AVX2 compares the AND with zero (`vpcmpeqq`) and takes each lane's sign bit (`vmovmskpd`). The portable path tests `m & t == 0`. The two SIMD paths use the old paths' instructions, now eight bottoms per byte (the old AVX-512 loop took 32 per step, the AVX2 one 16).
- **The same pairs, in the same order.** `BIT_POS[byte]` lists the set bits of `byte` in ascending order, and `BIT_CNT[byte]` counts them. The byte for bottoms `at..at + 8` writes `at + BIT_POS[byte][i]` for `i < 8` at the list's end and moves the end by `BIT_CNT[byte]`. The entries past the count are written over by the next byte or the tail, or lie past the final count and are never read. So after each byte the list holds exactly the passing indices so far, ascending. The tail does the same one bottom at a time (write the index, move by the test). Pieces go in order, and pass 2 adds the piece's start. So `survivor` sees the same (top, bottom) pairs in the same order as before: the old scans also took each chunk's set bits from the lowest, chunk by chunk, then the rest. The hits and the checked numbers come out in the same order (`every_scan_finds_the_same_pairs` compares whole `PartitionResult`s, hits in order).
- **In bounds.** The list holds 1024 entries, and a piece at most 1024 bottoms. Before each byte the list's length is at most `at` (each byte adds at most 8 to both), so its eight slots lie below `at + 8`, within the piece's length. The tail writes at an index no greater than the bottom's own. The stores are bounds-checked slice writes, not raw pointers: a broken bound would panic, not write out of bounds. Indices are below 1024, so they fit `u16`.
- **`survivor` is unchanged** apart from `#[inline(always)]`.

**Tests:**

- New `the_first_pass_lists_the_same_bottoms_on_every_path`. On every pass-1 path the CPU has, it checks the list against a plain filter:
  - random classes of lengths 0, 1, 7, 8, 9, 15, 16, 17, 31, 32, 33, 300, 1023 and 1024, and 100 random lengths up to 1024;
  - each with 0 %, 1 %, 40 % and 100 % of the bottoms passing, against random top masks of 1–32 digits (a passing bottom has none of the top's digits, a failing one at least one);
  - classes of 1025, 2085 and 5120 bottoms (1 %, 40 % and 100 % passing) through `each_pass` with each path's dispatch (the CPU's best, AVX2 forced, the portable loop forced), which takes them in pieces.
- The existing tests cover the whole scan: the reference join on the test windows (every visited partition's join survivors, prefilter survivors and hits), `every_scan_finds_the_same_pairs` (the best path against AVX2 and the portable loop forced, on every partition of the windows), the stride path on whole windows, slices, and the opt-in production and whole-field references. One test window (b57 at 20635899893042801193, t = 9, k = 5, p = 1) has classes of 1353–1439 bottoms, so those comparisons also run classes in two pieces.

## Measurements

TBD-MEAS

## Exactness

TBD-EXACT

## Not in this PR

- **The seeded check.** The full check could start from the 16 digits the join already knows (positions 0..7 of n² and n³: the bottom's 12 and the prefilter's 4) instead of re-deriving some of them; a prototype measured ×1.07–1.11 on top of this PR at the production shapes on this machine. A separate PR.
- **A vectorised second pass** (the prefilter run eight listed pairs at a time): not tried.
- **Raw-pointer stores in the compaction.** The slice writes cost one predictable bounds check per eight bottoms (most of the 5–8 % more branches in the counter table above); unchecked stores would save some of the 3–4 % more instructions. Not measured; the checked form keeps the module free of new `unsafe` beyond the existing SIMD loads.
- **Other shapes of the same scan**, measured in single runs at b60 1e16 on 1 thread and no better: AVX2 taking 16 bottoms a step as the old loop did (two bytes per step; 1733 and 1740 ms per partition against 1742 and 1800 ms for 8 a step), and `scan` kept out of line (`#[inline(never)]`; 1772 and 1809 ms against 1745 and 1706 ms).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
