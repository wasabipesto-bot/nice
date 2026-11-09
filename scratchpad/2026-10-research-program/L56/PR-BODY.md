Stacked on the two-pass scan (`pr/cpu-join-two-pass-scan`), which is on #248, on #247: the two-pass scan's commit is the base of this branch; the new work is the last commit.

## What

A pair that passes the CPU join's prefilter goes through the full check. Until now that was the client's `get_is_nice_with_known_lsd(n, b, 3, mask)`: square and cube `n` as 256-bit numbers, drop the three low digits the bottom list's mask already holds, and divide out every other digit of `n²` and then of `n³`, one long division by `b` per digit, until a digit repeats. By then the join has proved more than three digits of each power, and this PR starts the check from all of them:

- **What the check takes as known** (the soundness section says why each is proved):
  - the digits of `n²` and `n³` at positions `0..k` (the bottom's mask, the operand of the AND) and `k..k2` (the prefilter's four, read off again by the prefilter's own fixed-point formula): `2·k2 = 16` distinct digits at the production shapes;
  - for a top whose certificate gates the prefilter (every certified position `>= k2`, the seed flag), the certificate's **common** digits: `n²`'s from position `from[0]` up and `n³`'s from `from[1]` up, the same for every `n` of the top's block. On average 16.0 of them at b60 1e16 and 17.8 at b62 1e17. A digit the certificate's closure adds is **not** among them (below).
- **What it converts:** only the middle, `n²`'s positions `k2..from[0]` and `n³`'s `k2..from[1]`, against the known digits, stopping at the first repeat.
- **How:** a new module, `cpu_check`, with no long division of a binary number:
  - `n`'s base-b² limbs (two digits each) from the top's `P` and the bottom's `r0`: one 64-bit multiply-high quotient splits `P` at `b^(e − f0)` (`e` = 10 at bases 39–64), giving `L = n mod b^e` (below 2^63) and `H = ⌊n/b^e⌋` (below 2^31); `L`'s limbs come from four more independent quotients by `b^2i`, `H`'s from quotients by `b²`;
  - `n²` by schoolbook columns of `u32` products from the low end, each column written out (so every index is a constant), normalised to a limb by a multiply-high quotient by `b²` and split into its two digits by one by `b`. Both quotients are exact for every input below 2^31, and every column is below 2^31 (`Check::new` checks the bound per field). The columns below `k2` only carry;
  - two digits a column are taken without a branch, and the scan tests for a repeat every other column: at the production shapes about 97 % of the checks are decided by the first four middle digits;
  - when `n²`'s middle passes, `n³ = n²·n` the same way, by columns of `n²`'s limbs times `n`'s.
  - A field outside the column form's bounds (`P` of 2^63 or more, `H` of 2^31 or more, more than 16 digits; none in production) takes the same digits by long division of a 256-bit `n²` and `n³`.
- **The certificate's parts.** `Base::cert_parts` (and `cert`, now its mask) and the stepped certificate `TopFdSetup::cert` return a `Cert`: the certificate as before, its common digits apart from the ones the closure adds, and each power's lowest common position. A `Top` keeps the common digits and the two positions where its check stops; it stays 48 bytes (its `gmask` becomes a flag, `P mod (b − 1)` a byte).
- No knobs, no new public API.

## Why

perf of the two-pass scan's head (`1cce00d`) and of this PR, 1 thread, 2 sampled partitions each of b60 1e16 and b62 1e17 slice 0, recording after the slice setup, on the machine under Measurements (shares of cycles; the time per check is the share × the partition's time under `perf stat` / its checked survivors, over the 4 partitions of the A/B below):

| | b60 1e16 | b62 1e17 slice 0 |
|---|---|---|
| checked survivors per partition | 2.17 M | 2.05 M |
| **full check, before** (`get_is_nice_with_known_lsd`): share of cycles | **14.8 %** | **16.1 %** |
| its time per check | 119 ns | 133 ns |
| **full check, after** (`full_check` with the inlined `Check::nice`): share | **4.9 %** | **4.7 %** |
| its time per check | 36 ns | 34 ns |

- The full check was the third-largest item of a partition after the two-pass scan (the tops and the scan's second pass, all inlined into `CpuJoin::run`, 61 %; the scan's first pass 14–19 %).
- It converted 9.6–9.8 digits a survivor before its verdict, each a long division of a 256-bit number by `b`, and built and scanned `n³` whenever `n²` passed, although the 16 low digits of `n²` and `n³` were already known and so, in every production field, were 16–18 of their top digits.
- After this PR the check is ×3.3–3.9 faster per survivor in place (×4.2–4.5 on recorded survivors alone, below), and 5 % of a partition.

## Soundness

**Which digits are proved, and by what.** Write `n = P·b^f0 + r0` for a survivor of the top `P` and the bottom residue `r0`.

- **Positions `0..k` of `n²` and `n³`** are functions of `n mod b^k`, the bottom: the bottom list (`bpre`, positions `0..f0`), its extension by the partition's digits (`f0..k − 1`) and the list's last digit (`k − 1`) compute them exactly, and drop a bottom whose digits repeat. The AND tests these masks against the top's certificate. They are the entry's mask, unchanged.
- **Positions `k..k2`** are the prefilter's: the digits of `(A + P·D) mod b²` for each power at `mid = 2` (the fixed-point form, `Fx::digits`; `fresh_digits`' division form for the other shapes). The check reads them again with the same function on the same inputs. The prefilter passed only if these four are distinct and none of them is in the bottom's mask, so the `2·k2` known low digits are distinct.
- **The top's common digits.** For every `n` of the top's block `[a, e]`, `n^j` lies between `a^j` and `e^j`; the certificate reads off the digits the two agree on from its scan's start `c0` up (`Base::cert`). If they differ only by a carry into position `c0`, they differ on `a^j`'s trailing run of `b − 1`s and on the digit above it, which is `d` for `a^j` and `d + 1` for `e^j`; the digits above that are common. `Cert::common` is exactly those digits, at positions `from[j]..s_j`, where `from[j]` is `c0`, or the position above the `d`/`d + 1` digit. They are distinct (a repeat makes the certificate fail and drops the top). The survivor's `n` is in the block: an unclipped top's block is all of `[P·b^f0, P·b^f0 + b^f0)`, a clipped one passes only the residues in its range (the in-range test before the prefilter).
- **Not the closure's digits.** The certificate's mask (`Cert::mask`) also holds digits that `close_certificate` adds: where the `d`/`d + 1` position has one free digit left, every *nice* `n` must take it there. Such a digit is not a digit of every `n` of the block, and its position, `from[j] − 1`, is in the middle. Seeding the scan with it would reject exactly the `n` that put it there, the nice ones. So the check takes only `common`, and converts the `d`/`d + 1` position like any other middle position. (The AND and the prefilter keep testing against the whole mask, as before: there it only rules out `n` that cannot be nice.)
- **Only where the seed flag allows.** The top keeps `common` only if every certified position is `>= k2`, the condition under which the prefilter already tests its digits against the certificate (`gmask`): then `from[j] >= c0 >= k2`, so the common positions lie above the known low ones, and the known low digits miss the whole mask, `common` included (the AND for the bottom's, the prefilter for its four). For any other top (a clipped block whose certificate sits lower, or a field whose floor is below `k2`; none at the production shapes) the check takes no top digits and scans each power to its last digit.

**Why the seeded scan decides the same predicate.** The client's check (`get_is_nice`) is: no digit repeats among all the digits of `n²` and `n³` (with `s2 + s3 = b` in the band, that is niceness). The positions split into the known low ones, the middle and the known top ones. The low digits are distinct, the top digits are distinct, and the two sets are disjoint. So all the digits are distinct exactly when every middle digit is new against the low and top digits and the middle digits before it — which is what the scan tests, digit by digit, from a mask that holds exactly the low and top digits. Where it stops at a repeat, so would the client's check (on a digit it reaches later or earlier); where it finds none, neither does the client's.

**The arithmetic is exact.**

- `Magic` (`⌊x/d⌋ = (x·m) >> s`, `m = ⌈2^s/d⌉`, `s = 32 + ⌊log₂ d⌋`; a shift for a power of two): with `e = m·d − 2^s < d`, the error term `x·e/(d·2^s)` is below `1/d` for every `x < 2^31`, so the quotient is exact on the whole range. `Magic64` is the same at 64 bits, exact for every `x < 2^63`.
- Every input stays in range: `r0`, `H` and the columns are below 2^31 (a column has at most `nl` products of limbs below `b²` and a carry below `nl·b²`, so it is below `nl·(b⁴ + b²)`, at most 1.2·10^8 in production; `Check::new` takes the column form only where `P < 2^63`, `H < 2^31` and the bound holds), and every `u32` sum and product is bounded by the same column bound.
- The top column of `n²` carries nothing out (`n² < b^(2·nl)`), and `n³`'s columns stop at its last middle position.

## Measurements

**Machine:** a 4-vCPU AMD EPYC-Rome (**Zen 2**) VM, AVX2 only; every run under `nice -n 19`. The check has no SIMD and no division instruction, so I expect it to behave alike on other x86 cores, but its share of a partition, and so the ratio, depends on the rest of the join on each core; I measured no other machine.

**Method:** as in the two-pass scan's PR. Release builds of the two-pass scan's head (`1cce00d`) and this PR. A harness outside this PR, using only `CpuJoin`'s public API, runs sampled partitions of one slice (NiceMark's bit-reversed `sample_order`) through `CpuJoin::run_partition` on 1 or 4 threads; whole fields run every partition. The binaries are interleaved with the order alternating per round, 3 rounds; medians; spread = (max − min) / median; "per round" is the base's time over this PR's in the same round. Each round waited for a 1-min load average ≤ 2 and logged it (main block: 1.29, 1.86, 1.97); other sessions used at most one core at any run start. Fields as in the two-pass scan's PR: b60 at NiceMark's `b60_msd_weak` start 1157209632114824200908; b62 1e17 = the whole field 4473066762334864396992 + 1e17, which the CPU cuts into 7 slices, slice 0; b62 1e14 at 4473156762334864396992; b64 1e14 at 41242006262957161709568; b58 1e15 = NiceMark's field at 104400216587923470200. Times are ms per partition and thread for sampled partitions (wall × threads / partitions), wall seconds for whole fields.

| work | threads | two-pass scan (rounds) | spread | this PR (rounds) | spread | speed-up | per round |
|---|---|---|---|---|---|---|---|
| **b60 1e16**, 4 partitions | 1 | **1743** ms (1718, 1743, 1759) | 2.4 % | **1560** ms (1537, 1560, 1594) | 3.6 % | **×1.117** | 1.118, 1.117, 1.104 |
| **b62 1e17** slice 0, 4 partitions | 1 | **1693** ms (1693, 1654, 1727) | 4.3 % | **1491** ms (1494, 1482, 1491) | 0.8 % | **×1.136** | 1.133, 1.116, 1.159 |
| **b60 1e16**, 16 partitions | 4 | **1899** ms (1888, 1923, 1899) | 1.8 % | **1667** ms (1656, 1667, 1681) | 1.5 % | **×1.139** | 1.140, 1.154, 1.129 |
| **b62 1e17** slice 0, 16 partitions | 4 | **1769** ms (1802, 1769, 1759) | 2.4 % | **1596** ms (1683, 1596, 1550) | 8.4 % | **×1.109** | 1.071, 1.109, 1.135 |
| b58 1e15 (NiceMark's field), 32 partitions | 1 | **415** ms (415, 409, 418) | 2.1 % | **355** ms (355, 350, 356) | 1.9 % | **×1.168** | 1.168, 1.170, 1.173 |
| b58 1e15, 128 partitions | 4 | **444** ms (433, 453, 444) | 4.3 % | **381** ms (381, 437, 367) | 18.5 % | **×1.167** | 1.139, 1.035, 1.210 |
| b60 1e14, whole field (3600 partitions) | 4 | **29.1** s (30.0, 29.1, 29.1) | 3.1 % | **27.2** s (27.2, 27.1, 27.2) | 0.5 % | **×1.069** | 1.102, 1.072, 1.067 |
| b62 1e14, whole field (3844 partitions) | 4 | **38.8** s (38.9, 38.8, 38.4) | 1.3 % | **35.1** s (35.3, 35.1, 35.0) | 0.7 % | **×1.106** | 1.103, 1.106, 1.096 |
| b64 1e14, whole field (4096 partitions) | 4 | **69.1** s (69.1, 67.5, 69.7) | 3.2 % | **62.3** s (62.3, 63.0, 61.4) | 2.6 % | **×1.110** | 1.110, 1.071, 1.136 |
WHOLE1T

- **At the production shapes (b60 1e16, b62 1e17) the join is ×1.11–1.14 faster**, at 1 and 4 threads; every round is ×1.10 or more but one 4-thread b62 round (×1.071, whose PR run started while another session used 0.6 of a core). b58 1e15, whose partitions check a larger share of their pairs, gains ×1.17.
- The whole 1e14 fields gain ×1.07–1.11: their partitions spend more of their time listing and extending bottoms.
- That is the check's share of a partition going from 15–16 % to 5 % (Why): ×1.12 if nothing else changed, as measured.

**Counters** (`perf stat`, counting from 3.5 s on, past the slice setup; 1 thread, 4 partitions, 2 rounds alternating; per partition = count × ms per partition / task-clock; medians):

| per partition | b60 1e16, two-pass scan | b60 1e16, this PR | b62 1e17 slice 0, two-pass scan | b62 1e17 slice 0, this PR |
|---|---|---|---|---|
| instructions | 1.623e10 | 1.622e10 | 1.541e10 | 1.530e10 |
| branches | 2.009e9 | 1.999e9 | 1.872e9 | 1.876e9 |
| branch mispredictions | 24.3 M (1.21 %) | 22.8 M (1.14 %) | 20.7 M (1.11 %) | 19.1 M (1.02 %) |
| cycles | 5.69e9 | 5.20e9 (−8.6 %) | 5.53e9 | 4.83e9 (−12.7 %) |
| **IPC** | **2.85** | **3.12** | **2.79** | **3.17** |

- The instruction count barely moves: the column form executes about as many instructions per check as the old long divisions (its 6–8 columns of products and quotients against ~10 digits of a chain of 64-bit divisions by a constant), but they are independent of each other, where every digit of the old check waited on the last one's quotient. IPC rises from 2.8 to 3.1–3.2.

NICEMARK

**The check alone** on recorded survivors (every checked survivor of the first 2 sampled partitions, 4.28 M at b60 1e16 and 4.09 M at b62 1e17 slice 0, each check fed the digits the join records for it; a scratch harness, 3 repetitions; ns a check):

CHECKBENCH

## Exactness

All release builds of this head on the machine under Measurements. Hits are empty in every production field and all but one test window, so the tests compare the check's digits and its count of distinct digits, not only its verdicts.

- **The quotients** (`magic_quotients_are_exact_on_the_checks_inputs`, CI): the exactness bound of `Magic` is at least 2^31 for every divisor `b` and `b²` at bases 3–64, and the quotient is exact at the worst element of every block of `d` below the inputs the check gives it (by `b²`: every `x < 2^31`, which covers every column and `H`'s limbs; by `b`: every limb, below `b²`). That covers every input, since the quotient is monotone and never below `⌊x/d⌋`. `Magic64`'s bound is at least 2^63 for every power of every base below 2^63, and its quotients match `/` at block ends, edges and 2,000 random `x` per divisor. Opt-in (`NICE_TEST_CPU_CHECK_EXHAUSTIVE=1`): every `x < 2^31` for every divisor that is not a power of two, against `/`: EXHAUSTIVE-RESULT.
- **The column form's digits** (`the_columns_take_the_digits_of_the_square_and_the_cube`, CI): at every base 3–64 and every length the column form takes, on adversarial `n` (every digit `b − 1`, the smallest, alternating `0`/`b − 1`, `b − 1` but one digit, `b^i − 1` above the smallest, the parts' edges) and random ones, in every shape `(f0, k2)` of the join (production and test windows): in count mode (no early exit, nothing seeded), every digit of `n²` and `n³` from `k2` up equals malachite's, position by position; the long division gives the same; and a scan with random ends takes exactly the digits below them. 274,661 (n, shape) pairs.
- **The verdict and the count** (`the_seeded_check_decides_what_the_full_check_decides`, CI): seeded with the true known digits at random ends, at the top (no top digits) and at `k2`, the check's verdict equals `get_is_nice`, and in count mode its mask holds `get_num_unique_digits` digits and it finds a repeat exactly where `get_is_nice` says no, on: every `n` of the bands of bases 10–22 with at least `b − 2` distinct digits (81 near-nice `n`, 69 among them), and at bases 23–64 the band's ends, the `n` around `n²` or `n³` gaining a digit, adversarial `n` (digits up to 63) and 3,000 random `n` per base. 298,153 decisions. `sixty_nine_is_nice`: 69 in the base-10 window's shape, with and without its top digits.
- **Every checked survivor of real partitions** (`assert_checked`), against the client's check: its known low digits are exactly `n²`'s and `n³`'s below `k2` (16 distinct), its top digits exactly those at and above its ends (distinct, disjoint from the low ones); in count mode the middle digits equal the true ones position by position, the mask's count equals `get_num_unique_digits`, and a repeat is found exactly where `get_is_nice` says no; and the verdict equals `get_is_nice`.
  - CI: every checked survivor of the test windows (17 of the 18 take the column form; the b64 window, whose `P` exceeds 2^63, takes the long division), and of two partitions of each production field (b42, b50, b57 frontier, b60, b62, b64 at 1e14): 1,088,360 survivors, all with their top's digits.
  - Opt-in (`NICE_TEST_CPU_CHECK_REF=4`): 4 partitions each of the timed shapes: b60 1e16 (8,692,368 checked survivors), b62 1e17 slice 0 (8,194,223), b58 1e15 (2,247,150), b60 1e14 (93,515), b62 1e14 (90,465), b64 1e14 (334,391): 19.65 M survivors, every one with its top's digits, every one exact.
- **The certificate's parts:** `the_fast_certificate_matches_the_reference` now also compares `cert_parts` (the common digits and the lowest common positions) with a reference read off both endpoints' digits; `stepped_certificates_equal_the_divided_ones` compares the stepped `Cert` with `cert_parts` on 1.86 M blocks; `stepped_tops_equal_divided_tops_on_production_fields` compares whole tops, the new fields included.
- **The existing tests pass unchanged:** the reference join on the test windows (every visited partition's join survivors, prefilter survivors and hits), every scan path, the stride path on whole windows, slices, the prune, the prefilter tests, b10's 69 through the join. `cargo test --release -p nice_common -p nice_client`: 196 + 22 passed, 8 ignored (opt-in); the two-pass scan had 190 + 22.
- `NICE_TEST_CPU_JOIN_REF=3` (3 partitions of each plan field against the reference join): ok.
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = reference = stride, 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits; on 4 threads reference 87 s, join 10.2 s, stride 112.5 s.
- **Every timed run below, of both sides, has the same join survivors and full checks**, and the same (empty) hits. The check does not produce those counts (the join and the prefilter do), so they show that the tops' new layout changed no pair; the check's own exactness is the tests above.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc 1.99.1): clean. No GPU code changed; `Base::cert` keeps its signature and result.

## Not in this PR

- **One `Magic` for the CPU and the GPU check.** The GPU's base-b² check (on another branch, `join_check::magic`) uses the same multiply-high construction for the same divisors; this PR has its own because that module is not on this stack. Once both land, one copy can go.
- **The stride walk's check.** `get_is_nice_with_known_lsd` stays as it is for the stride walk, which knows only the three low digits of each power and nothing above them.
- **A vectorised second pass of the scan** and **the tops' finite-difference trims** (carried certificate screen, no clip work on interior prefixes): the other two items left on the CPU join; after this PR the tops and the scan are about 85 % of a partition at the production shapes.
- **Other cores.** Everything was measured on one Zen 2 machine. The check has no SIMD and no division, so I expect the gain to carry over, but its share of a partition depends on the scan's, which is smaller on AVX-512 hosts.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
