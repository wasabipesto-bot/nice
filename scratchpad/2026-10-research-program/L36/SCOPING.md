# L36 SCOPING: what a stepped `top_fd_kernel` slot still pays for, on all5 (RTX 3080 at 150 W, 2026-11-03)

Branch **`exp/top-fd-ablate`** on the fork, head **`47c1b36`**: `exp/join-all5` `6ddab24` + `db32f95` (switches
1–64) + `cd239e0` (128, 256) + `1036a4c` (prototype switches 512, 1024) + `47c1b36` (prototype switch 2048).
Experiment only, no PR. Raw logs `raw/box/{pre,q,lad,s,l,l4}_b*_a*_r*.log`, `diag_b*.log`, `x3_fd_*.log`,
`x4_fd_*.log`, `fx_*.log`, `raw/box/sass/`; analysis `python3 raw/scripts/abl.py raw/box TAG` (outputs
`raw/abl_*.txt`) and `python3 raw/scripts/abl_table.py raw/box TAG CONFIGS` (`raw/abl_*_table.md`).

## Summary

- **A stepped `top_fd_kernel` slot costs 0.219 ns per prefix at b62 1e17 (0.212 at b60 1e16)** on this card at
  150 W (L35: 0.198 / 0.192 at 180 W). Removed one at a time (9 timing rounds each; the baseline is the production kernel):

  | part | b62 1e17 | b60 1e16 |
  |---|---|---|
  | **the digit scan** of both certificates | **0.071 ns (32.5 %)** | 0.064 (29.9 %) |
  | of which: per-digit c0 test, selects and low term | 0.042 (19.0 %) | 0.034 (16.2 %) |
  | of which: run-of-(b − 1)s bookkeeping | 0.032 (14.5 %) | 0.021 (10.2 %) |
  | of which: extracting each digit and setting its bit | 0.013 (6 %) | 0.010 (5 %) |
  | the append (plane scans, stores, bucket atomics) | 0.038 (17.1 %) | 0.035 (16.5 %) |
  | the carry test | 0.030 (13.9 %) | 0.024 (11.1 %) |
  | x mod b^c0 (one cost with the carry test: both 14.5 %) | 0.029 (13.0 %) | 0.023 (10.7 %) |
  | the step's additions (and 110 → 80 registers) | 0.029 (13.2 %) | 0.033 (15.7 %) |
  | `ndig_fast`'s power-table compare | 0.013 (5.7 %) | 0.017 (7.8 %) |
  | carry test + `ndig` (the two power-table reads) | 0.049 (22.5 %) | 0.043 (20.2 %) |
  | all six removed: the floor left | 0.066 (30 %) | 0.068 (32 %) |

  Single removals overlap (they sum to 95 %, all six remove 70 %). A ladder without double counting: append 17 %,
  scan 22 %, carry test + `ndig` 22 %, step 8 %, floor 31 %.
- **The scan cannot be skipped when the digits above c0 did not change.** Per lane they stand still in 65 % of
  stepped slots (b62) and 96 % (b60), and c0 never changed in 1.1 billion stepped lanes; but a plane of 32
  independent prefixes almost always holds a lane whose digits changed (99.6 % of plane-slots at b62, 85 % at b60),
  so a skip would save ≤ 0.1 % / ≤ 4.5 %.
- **No single change plausibly takes 25 % off.** The scan is the largest part, but its cost is per-digit
  bookkeeping, not the digit work SWAR would speed up; the other parts are 6–17 % each. Three exact changes together
  plausibly could, so I prototyped them (`exp/top-fd-ablate`, switches 512, 1024, 2048; each passes #240's device
  test against `top_kernel`, 26 fields, 279 batches):
  - **carry c0 and b^c0 − d from slot to slot** (no power-table reads in a stepped slot): **−14.4 % / −14.3 %**;
  - a bookkeeping-free path for scanned words wholly above c0: −6.7 % / −5.5 %;
  - stepping slots skip forming a, e and the clip test: −2.5 % / −1.8 %;
  - **all three: −22.3 % (b62 1e17) / −22.9 % (b60 1e16), 0.218 → 0.170 ns.** Just short of 25 %. Also exact on
    lavapipe (naga and SPIR-V) and on whole fields.
  - **Whole fields** (X4, the same binary with the switches off and on, 3 interleaved rounds): **b62 1e17 ×1.041**
    (139.7 → 134.3 s, −5.4 s; ×1.04 clock-matched), **b60 1e16 ×1.078** (×1.02–1.05 per round clock-matched),
    counts identical to the exact ones. About 3–4 % of a field, as the kernel numbers predict.
- **Verdict** (§5): the FD kernel is now about 20 % of a b62 1e17 field (~29 of 149 s, its stepped slots ~22 s),
  so a 25 % cut of the stepped slot is worth 3.7 % of the field; the 22 % one predicts 3.3 % and measured about 4 %.
  **Carrying c0 (−14 %) is the change worth a PR**; the rest are small. The join (56 % of the field) remains the
  bigger target.

## 1. Method

- **Switches.** `NICE_EXP_TOP_FD_ABL` is read in `JoinDevice::new` and passed to `top_fd_kernel` as a comptime
  `abl`, so one binary runs every configuration and the unablated kernel is the production one. With `abl = 0` the
  kernel compiles to #240's: 110 registers and 3,888 SASS instructions at b62 (108 / 3,696 at b60), as L35's mode 2;
  its timings equal the production binary `S`'s within 1 % (b62: stepped 0.2185 against 0.2219 ns, b60: 0.2101
  against 0.2109). Each bit removes one part of the per-slot work and keeps the rest alive:

  | bit | removes | what stays in its place |
  |---|---|---|
  | 1 `scan` | the digit scan of both certificates (`cert_power_fd`'s per-digit path for the words with a digit at or above c0) | each such word XORed into `run`/`runc` and the run bookkeeping once per word |
  | 2 `rem` | x mod b^c0: the base-b value of the words below c0 and the multiword `rem += low·b^p0` | `rem[0] ^= word` |
  | 4 `carry` | #235's carry test: `rem + d` and its compare with b^c0 from the power table | `one_more = (rem[0] ^ d[0]) & 1` (so the rem words above the first are dead too) |
  | 8 `append` | the plane append, the five stores and the bucket atomics | per thread a count and an XOR of the masks, one store at the end |
  | 16 `step` | the five digit-array additions and the three binary ones | one XOR into each of `sq[0]`, `cu[0]`, `d2[0]`, `d3[0]` |
  | 32 `ndig` | `ndig_fast`'s compare with the power table (c0 of each power) | the bit-length estimate alone |
  | 64 `diag` | (diagnostic, implies 8) counts stepped slots whose digits from c0 up, or c0, changed since the previous slot | |
  | 128 `inrun` | inside the scan: the per-digit run-of-(b − 1)s bookkeeping (`runc`, `dlo`, `qend`, `in_run`) | once per word |
  | 256 `above` | inside the scan: the per-digit `c0 <= pos` test, its selects and the `low` term | every digit of a scanned word taken as above c0 |
  | 512 `LSCAN` | **prototype, exact**: see §4 (b) | |
  | 1024 `LC0` | **prototype, exact**: see §4 (c) | |
  | 2048 `LCLIP` | **prototype, exact**: see §4 (d) | |

  The tops are wrong whenever one of bits 1–256 is set; only timings are taken from those runs. Bits 512–2048 are
  exact.
- **Timing:** #240's ignored test `cubecl_cuda_top_fd_timing` (`NICE_TEST_TOPFD_TIMING`) on the first slice of the
  production plan: b62 1e17 (3,620,628 prefixes, k = 5 slots a batch) and b60 1e16 (4,347,381 prefixes, k = 4).
  40 batches of consecutive partitions (c, ns per (prefix, slot)) and 40 of every other partition, where every FD slot
  seeds (g); each process runs both kernels three times. **Stepped slot s = (k·c − g)/(k − 1)** (L35 §9).
  `top_kernel`'s time in the same round normalises the clock (s × median `top_kernel` time / this round's).
- **Rounds:** `q` = 3 processes per configuration and field, interleaved over the configurations, nothing else on
  the box except a niced build (`nice -n 19`, 4 jobs) during the last minute of the third round and the first
  half of the ladder (9 timing rounds each); `pre` = 1 process under concurrent builds
  (`raw/abl_pre.txt`, within 1–3 points of `q`). The first round of each process runs its all-seed set ~8 %
  slow (warm-up), which lowers s in that round; leaving those rounds out moves the shares by at most 2.3 points
  at b62 and 1.2 at b60 (`raw/abl_q_skip0.txt`).

## 2. The stepped slot's cost by part

Stepped slot s in ns per (prefix, slot), normalised to the median `top_kernel` time; "saves" = s(none) − s(config).
At 150 W; L35 measured 0.198 / 0.192 ns at 180 W.

**One part at a time, and some pairs** (`q`, 9 timing rounds per row; `raw/abl_q.txt`):

| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2192** | | | **0.2123** | | | 9 / 9 |
| scan | 0.1479 | 0.0713 | 32.5 % | 0.1487 | 0.0635 | 29.9 % | 9 / 9 |
| rem | 0.1906 | 0.0286 | 13.0 % | 0.1895 | 0.0228 | 10.7 % | 9 / 9 |
| carry | 0.1888 | 0.0304 | 13.9 % | 0.1887 | 0.0235 | 11.1 % | 9 / 9 |
| rem + carry | 0.1875 | 0.0318 | 14.5 % | 0.1867 | 0.0255 | 12.0 % | 9 / 9 |
| ndig | 0.2067 | 0.0125 | 5.7 % | 0.1956 | 0.0167 | 7.8 % | 9 / 9 |
| carry + ndig | 0.1699 | 0.0493 | 22.5 % | 0.1694 | 0.0429 | 20.2 % | 9 / 9 |
| rem + carry + ndig | 0.1703 | 0.0490 | 22.3 % | 0.1681 | 0.0442 | 20.8 % | 9 / 9 |
| append | 0.1816 | 0.0376 | 17.1 % | 0.1772 | 0.0350 | 16.5 % | 9 / 9 |
| step | 0.1904 | 0.0288 | 13.2 % | 0.1790 | 0.0332 | 15.7 % | 9 / 9 |
| rem + carry + step + ndig | 0.1385 | 0.0807 | 36.8 % | 0.1392 | 0.0730 | 34.4 % | 9 / 9 |
| scan + rem + carry + append + step + ndig | 0.0661 | 0.1531 | 69.8 % | 0.0680 | 0.1443 | 68.0 % | 9 / 9 |

**Inside the digit scan** (`s`, binary `X2` = `cd239e0`, 6 timing rounds per row; `raw/abl_s.txt`):

| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2205** | | | **0.2099** | | | 6 / 6 |
| scan | 0.1483 | 0.0722 | 32.7 % | 0.1502 | 0.0598 | 28.5 % | 6 / 6 |
| inrun | 0.1885 | 0.0320 | 14.5 % | 0.1885 | 0.0214 | 10.2 % | 6 / 6 |
| above | 0.1787 | 0.0418 | 19.0 % | 0.1759 | 0.0341 | 16.2 % | 6 / 6 |
| inrun + above | 0.1610 | 0.0595 | 27.0 % | 0.1601 | 0.0498 | 23.7 % | 6 / 6 |
| append | 0.1810 | 0.0395 | 17.9 % | 0.1758 | 0.0342 | 16.3 % | 6 / 6 |
| scan + append | 0.1344 | 0.0861 | 39.1 % | 0.1347 | 0.0752 | 35.8 % | 6 / 6 |
| append + inrun | 0.1567 | 0.0638 | 28.9 % | 0.1548 | 0.0552 | 26.3 % | 6 / 6 |
| append + above | 0.1648 | 0.0557 | 25.3 % | 0.1632 | 0.0468 | 22.3 % | 6 / 6 |
| append + inrun + above | 0.1465 | 0.0740 | 33.5 % | 0.1460 | 0.0639 | 30.5 % | 6 / 6 |

**A removal ladder** (`lad`, 9 timing rounds per row; `raw/abl_lad.txt`):

| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2230** | | | **0.2144** | | | 9 / 9 |
| append | 0.1845 | 0.0385 | 17.3 % | 0.1802 | 0.0342 | 15.9 % | 9 / 9 |
| scan + append | 0.1357 | 0.0873 | 39.2 % | 0.1373 | 0.0771 | 35.9 % | 9 / 9 |
| scan + carry + append + ndig | 0.0867 | 0.1363 | 61.1 % | 0.0883 | 0.1261 | 58.8 % | 9 / 9 |
| scan + rem + carry + append + ndig | 0.0945 | 0.1286 | 57.6 % | 0.0971 | 0.1173 | 54.7 % | 9 / 9 |
| scan + rem + carry + append + step + ndig | 0.0683 | 0.1548 | 69.4 % | 0.0700 | 0.1444 | 67.4 % | 9 / 9 |

**Registers and static SASS** (offline `nvcc -cubin -arch=sm_86 -O3` of CubeCL's CUDA for a 1e14 field;
`raw/box/sass/registers.txt`, `raw/box/regs_abl2.log`): unablated 110 registers / 3,888 instructions at b62 (108 /
3,696 at b60), 2 blocks of 256 per SM. `scan` 100 / 3,208; `rem` 100 / 3,512; `carry` 98 / 3,352; `append` 109 / 3,680;
`ndig` 110 / 3,792; **`step` 80 / 3,376 (3 blocks per SM)**; `inrun` 108 / 3,568; `above` 110 / 3,680; all six 64 /
1,944.

Reading the tables (b62 1e17 first, b60 1e16 in brackets):

- **The stepped slot costs 0.219 ns (0.212).** Removed one at a time: the **digit scan 32.5 %** (29.9), the
  **append 17.1 %** (16.5), the **carry test 13.9 %** (11.1), **x mod b^c0 13.0 %** (10.7), the **step's additions
  13.2 %** (15.7), **`ndig_fast`'s power-table compare 5.7 %** (7.8).
- **They do not add up.** The single removals sum to 95 % (92); all six together remove 69.8 % (68.0) and leave a
  floor of **0.066 ns (30 %)**: the slot loop, P, a and e and the clip test, `close_cert`, the popcounts, the
  stand-ins and the checksum. Parts overlap in time (16 warps per SM hide some of each), so a single removal is the
  most that removing that part alone can save. The ladder splits the slot without double counting: append 17 %,
  then the scan 22 %, then the carry test with `ndig` 22 %, then the step 8 %, floor 31 % (b62; b60 16 / 20 / 23 /
  9 / 33 %). Adding the `rem` switch on top of the carry and `ndig` switches costs 3.5 points instead of saving: with
  the carry test gone the remainder words are dead anyway, and the switch's stand-in is then extra work.
- **Pairs that overlap:** `rem` + `carry` together (14.5 %) cost no more than either alone. The carry switch also
  makes every remainder word but the first dead, so the two switches remove mostly the same instructions: x mod
  b^c0 and the test that reads it are one cost of about 14 %. **`carry` + `ndig` (22.5 %) is more than the sum
  (19.6 %)**: these are the two places that read the power table `pw` at a row chosen by c0, and with one left the
  other's load latency is still exposed.
- **The step's 13 %** comes with a register drop from 110 to 80 (3 blocks per SM instead of 2), so it is partly
  occupancy; the step's own instructions are a smaller share.
- **The scan's 32.5 %** is mostly bookkeeping: the per-digit c0 test with its selects and the low term (`above`)
  19.0 % (16.2), the run-of-(b − 1)s bookkeeping (`inrun`) 14.5 % (10.2), both 27.0 % (23.7). What remains of the
  scan with both gone, taking each digit out of its word and setting its bit, is 0.013 ns (6 %).
- The seeded slot (g ≈ 0.40 ns) shrinks by similar absolute amounts under each switch; it is not the subject here.


## 3. How often the digits above c0 change between consecutive partitions

`NICE_EXP_TOP_FD_ABL=64` (`diag_b62.log`, `diag_b60.log`): over the timing test's 40 consecutive batches, for every
stepped (prefix, slot), whether any digit of P² or P³ at a position ≥ its c0 differs from the previous slot's, or c0
itself changed; and, per plane (32 lanes) and slot, whether any stepped lane saw such a change.

| field | stepped lanes | square's digits ≥ c0 changed | cube's | either | c0 changed | planes (with a stepped lane) where some lane changed | planes where none did |
|---|---|---|---|---|---|---|---|
| b62 1e17 | 579,300,320 | 8.0 % | **29.7 %** | **35.4 %** | **0** | **99.58 %** of 18,103,200 | 0.42 % |
| b60 1e16 | 521,685,720 | 2.1 % | 2.0 % | **4.0 %** | **0** | **84.7 %** of 16,302,720 | 15.3 % |

- **Per lane the digits above c0 mostly stand still** (65 % of stepped slots at b62, 96 % at b60), and **c0 never
  changed** between consecutive slots in 1.1 billion stepped lanes. A step adds 2P + 1 to P² and 3P² + 3P + 1 to P³;
  these change the digits from c0 up only by a carry out of the digits below, which happens with a probability of
  about the increment over b^(c0 − k·f0) (for the cube at this b62 field that ratio is about 0.3).
- **But a warp runs the scan if any of its 32 lanes needs it**, and the lanes of a plane are independent prefixes:
  at b62 99.6 % of plane-slots have at least one lane whose digits changed, at b60 85 %. So **skipping the scan when
  the step's carry did not reach c0 would skip it in 0.4 % of plane-slots at b62 and 15 % at b60**: at most 0.1 % and
  ~4.5 % of the stepped slot (×0.30–0.33 scan share), before the cost of the test and of keeping the previous slot's
  results (run, runc, dup flags, dlo, qend, ~8 registers a power, at 110 registers already).
- c0 standing still is useful elsewhere: see §4 (c).

## 4. Candidates, and what each could take off the stepped slot

How much of a b62 1e17 field is at stake: the field has 30.6 M top-layer prefixes × 3,844 partitions = 1.18e11
(prefix, partition) pairs in 6,439 batches (6.57 slots a batch on average over the 11 slices; the first slice's plan
has 5). With s = 0.219 and a seeded slot g = 0.40 ns, the FD kernel is about 29 s of the 148.9 s field (20 %), its
stepped slots about 22 s (15 %), its seeds about 7 s. **A 25 % cut of the stepped slot is about 5.5 s, 3.7 % of
the field** (b60 1e16: 0.8 s of 29.2 s, 2.8 %). The profile's top phase (40.6 s profiled) also holds the top scan,
the top fill and the clipped-block launches, which this test does not time.

**(a) Skip the scan when the step's carry did not reach c0** (the brief's last suggestion). Dead on a GPU: §3. A
plane skips only if all 32 of its lanes skip, which happens in 0.4 % of plane-slots at b62 1e17 and 15 % at b60.
Upper bound 0.1 % / 4.5 % of the stepped slot, before the extra registers.

**(b) Scanning the packed digits four at a time (SWAR).** The scan's own work, extracting each digit and setting
its bit in a 64-bit mask, is 6 % of the slot (§2); a mask of four digits still needs four shifts, and the repeat
test is already a popcount at the end, so there is nothing to win on distinctness itself. What costs is the
per-digit bookkeeping around it: the c0 test, its selects and the low term (19 %), and the run of (b − 1)s (14.5 %),
27 % together. Byte tricks can move that bookkeeping from digits to words: which bytes lie above c0 is a mask
from c0 − p0, and where x's run of (b − 1)s ends is a zero-byte test of word ⊕ (b − 1)·0x01010101 and a
find-first-set. **Prototyped, the cheapest half (bit 512, `LSCAN`):** a word that lies wholly above c0 once the run
has ended (in practice every scanned word but the first, the one that holds c0) takes a path with no bookkeeping
at all.
The run continues past the straddling word only if all its digits from c0 up are b − 1 (probability b^−m for m such
digits), so the branch is nearly uniform across a plane. The straddling word keeps the per-digit path.

**(c) Carry c0 and b^c0 − d from slot to slot** (c0 never changed in 1.1 billion stepped lanes, §3). **Prototyped
(bit 1024, `LC0`):** a seed computes c0 = max(cap, `ndig_fast`(d)) as before and dp = b^c0 − d from the power
table; a step subtracts d's step from dp (the binary step of d becomes a subtraction), and only when that borrows or
reaches zero (d ≥ b^c0) does it recover d = b^c0 − dp and recompute c0 and dp. The carry test becomes x mod b^c0 ≥ dp,
one compare of registers: a stepped slot reads no power table and runs no `ndig_fast`. x mod b^c0 is still formed
from the digits below c0. The ablations put the ceiling at `carry` + `ndig` = 22.5 % less the remainder words the
carry switch also killed.

**(d) Stepping slots skip a, e and the clip test** (bit 2048, `LCLIP`): only P = plo and P = phi can be clipped, and
a stepping slot needs neither a nor e (they only feed the seed), so a slot that steps and is neither skips the
multiply, the add and six compares with the field bounds.

**Prototype results** (`exp/top-fd-ablate` `1036a4c`, binary `X3`, 6 timing rounds each; all three are exact:
#240's device test `cubecl_cuda_top_fd_matches_the_top_kernel` passes with `NICE_EXP_TOP_FD_ABL` = 512, 1024 and
1536, 26 fields, 279 batches, 237,948,545 tops, `x3_fd_a*.log`):

| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2190** | | | **0.2092** | | | 6 / 6 |
| LSCAN (fast path) | 0.2045 | 0.0146 | 6.7 % | 0.1976 | 0.0116 | 5.5 % | 6 / 6 |
| LC0 (carried c0, b^c0 - d) | 0.1876 | 0.0314 | 14.4 % | 0.1794 | 0.0298 | 14.3 % | 6 / 6 |
| LSCAN (fast path) + LC0 (carried c0, b^c0 - d) | 0.1736 | 0.0454 | 20.7 % | 0.1638 | 0.0454 | 21.7 % | 6 / 6 |

With the clip skip (`exp/top-fd-ablate` `47c1b36`, binary `X4`, 6 timing rounds each; #240's device test passes
with `NICE_EXP_TOP_FD_ABL` = 2048 and 3584 = 512 + 1024 + 2048, `x4_fd_*.log`):

| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2182** | | | **0.2092** | | | 6 / 6 |
| LSCAN (fast path) + LC0 (carried c0, b^c0 - d) | 0.1732 | 0.0450 | 20.6 % | 0.1644 | 0.0447 | 21.4 % | 6 / 6 |
| LCLIP (no a, e on steps) | 0.2127 | 0.0055 | 2.5 % | 0.2054 | 0.0038 | 1.8 % | 6 / 6 |
| LSCAN (fast path) + LC0 (carried c0, b^c0 - d) + LCLIP (no a, e on steps) | 0.1695 | 0.0487 | 22.3 % | 0.1612 | 0.0479 | 22.9 % | 6 / 6 |

- **`LC0` is the larger and the surer one: −14.4 % (b62) / −14.3 % (b60)**, more than its estimate. It also drops
  5 registers at b62 (110 → 105) and adds static code for the rare fix-up (3,888 → 4,296 SASS).
- **`LSCAN` gives −6.7 % / −5.5 %**, a quarter of the bookkeeping's 27 % ceiling: the straddling word, which keeps
  the full per-digit path, holds a large share of the scanned digits (up to four of each power's), and the fast path
  still extracts and shifts every digit.
- **Together −20.7 % / −21.7 %**: they add (6.7 + 14.4 = 21.1); X4 reproduces it (−20.6 % / −21.4 %).
- **`LCLIP` −2.5 % / −1.8 %**, and **all three −22.3 % (b62 1e17) / −22.9 % (b60 1e16)**: 0.218 → 0.170 ns.

**On lavapipe** (`chain_x4lvp.sh`; `X4` built for naga and for CubeCL's direct SPIR-V compiler, md5 61025536 /
adf73a05): #240's light device test with `NICE_EXP_TOP_FD_ABL=3584` passes on both (21 fields, 142 batches, 20 with
a clipped block, 1,018,088 tops; `x4lvp_fd_*.log`). TopFdKernel's SPIR-V basic blocks go from 298–310 to 325–343
with all three switches (`x4blocks_spv_a*.txt`), still below TopKernel's 374–386, which bounds that compiler's
recursion. Metal was not run.

**Whole fields with all three** (`chain_x4.sh`, `chain_fx3.sh`; X4 = `47c1b36`, `NICE_EXP_TOP_FD_ABL` = 0 against
3584, interleaved off/on, 3 rounds, nothing else on the box; `fx_*.log`):

| field | off (rounds) | on (rounds) | speed-up (medians) | per round | per round, clock-matched | clocks off / on (MHz) |
|---|---|---|---|---|---|---|
| b62 1e17, 1 field | 137.92, 139.74, 144.03 (**139.74**) | 134.38, 134.30, 133.77 (**134.30**) | **×1.041** (−5.4 s) | 1.026, 1.041, 1.077 | 1.040, 1.037, 1.057 | 1180, 1167, 1114 / 1164, 1171, 1135 |
| b60 1e16, 2 fields | 29.06, 29.07, 27.66 (**29.06**) | 26.95, 28.32, 26.75 (**26.95**) | ×1.078 | 1.079, 1.026, 1.034 | 1.042, 1.022, 1.045 | 1124, 1065, 1175 / 1163, 1070, 1163 |

- Counts identical on both sides in every round and equal to the exact ones (b62 1e17 1,020,844,021,499 /
  62,584,252,554; b60 1e16 460,847,952,346 / 30,871,838,404).
- The clock under the 150 W cap wandered by up to 6 % between runs here, so the clock-matched ratios
  (device s × mean SM MHz) are the better reading: **about ×1.04 at both fields**. The kernel numbers predicted
  22 % of ~22 s = 4.9 s at b62 1e17 (3.3 %) and ~2.6 % at b60.

**(e) What else is left**, by size, none prototyped:
- **x mod b^c0 (13 %).** With `LC0` it is only compared with dp, and that comparison is decided by the remainder's
  top digits except with probability ~b^−4. Forming only the words within two words below c0 and falling back to
  the full sum when the bounds overlap would skip the lower words (at b62 1e17 one of the square's three and about
  three of the cube's five, but the cheaper ones: their powers have fewer limbs). With the extra bound compare that
  is about 3–6 %, and it needs b^(c0 − 4) carried in registers (15 more words) and a rarely taken second loop.
- **The append (17 %).** Partly fixed costs every slot pays (plane sum, plane exclusive scan, broadcast), partly per
  kept top (nine stores, nroots bucket atomics). A ballot and two popcounts could replace the two plane scans (a few
  percent); the stores of fields that are constant for FD tops (`top_r` = (0, w), the seed flag) would need the
  consumers changed.
- **The straddling word's bookkeeping** (the other half of (b)): byte masks for "above c0" and the run's end; a few
  percent at most after `LSCAN`.
- **Fusing the square's and the cube's scans** saves no instruction; it could only help latency, and the kernel
  already holds 16 warps per SM with independent work in each. Not measured.
- **The step (13 %, partly occupancy).** Its additions are needed; fewer registers (110 → 80 without them) is what
  made the switch look large.

**(f) Not a stepped-slot change: keeping the state across batches** (L35's persistence) turns each batch's seed
into a stepped slot. At the field's 6.57 slots a batch that is (g − s)·pairs/6.57 ≈ 3.3 s at b62 1e17 (11 % of the FD
kernel, 2.2 % of the field) and 0.7 s per b60 1e16 field (2.4 %), for ~700 MB of device memory per b62 slice. It is
comparable to the stepped-slot cuts above and adds to them.


## 5. Verdict

**What could be cut, and by how much (stepped slot, b62 1e17 / b60 1e16):**

| change | measured or estimated | exact | effort / risk |
|---|---|---|---|
| **carry c0 and b^c0 − d across steps** (`LC0`) | **−14.4 % / −14.3 %, measured** | yes (device test on CUDA; with all three also on lavapipe naga and SPIR-V) | small: dp replaces d in the state, a rare fix-up branch, the carry test becomes a register compare; 5 fewer registers |
| bookkeeping-free path for scanned words wholly above c0 (`LSCAN`) | −6.7 % / −5.5 %, measured | yes | small: one runtime branch per scanned word |
| stepping slots skip a, e and the clip test (`LCLIP`) | −2.5 % / −1.8 %, measured | yes | trivial |
| **the three together** | **−22.3 % / −22.9 %, measured; whole fields: b62 1e17 ×1.041, b60 1e16 ×1.02–1.08** | yes | |
| x mod b^c0 from only the words just below c0, full sum only when the bound is ambiguous (p ≈ b^−4) | ~3–6 %, estimated | would be | moderate: a carried bound, 15 more registers, a second loop |
| byte-mask bookkeeping in the straddling word (the rest of SWAR) | a few %, estimated | would be | moderate |
| ballot + popcounts for the append's plane scans | a few %, estimated | would be | small, but plane sizes other than 32 need care |
| skip the scan when the carry missed c0 | ≤ 0.1 % / ≤ 4.5 % (warp-level) | | dead |
| SWAR distinctness, fusing the two scans | ~0 (the digit work itself is 6 %) | | not worth it |
| keeping the FD state across batches (seeds, not stepped slots) | ~11 % of the FD kernel, 2.2 % of a b62 1e17 field, estimated | | ~700 MB per slice |

- **The largest term is the digit scan (a third of the slot), and it is bookkeeping, not digit work.** The brief's
  candidates aimed at the digit work (SWAR distinctness, fused scans) or at skipping the scan (which a warp cannot
  do). Neither can reach 25 %.
- **The best single change is not in the scan: carrying c0 and b^c0 − d (−14 %).** It removes both power-table
  reads from the stepped slot; c0 did not change once in 1.1 billion stepped lanes.
- **Prototyped because three exact changes together plausibly could reach 25 %: they reach 22–23 %**, which is
  about **3–4 % of a b62 1e17 field** (×1.041 measured on whole fields, ×1.04 clock-matched). The remaining
  candidates are a few percent each.
- **Recommendation.** `LC0` alone is a clean small PR candidate (−14 % of the stepped slot, about 2 % of a b62 1e17
  field), `LSCAN` and `LCLIP` can ride along for another ~8 %. All three are exact on #240's device test on CUDA and
  on lavapipe (naga and SPIR-V, +27–33 SPIR-V blocks); a PR would still need the rest of a PR's checks (join parity,
  dense and whole fields, Metal), none run here with the switches. The FD kernel is now ~20 % of a b62 1e17 field and
  the join ~56 %, so the join remains the bigger target.
