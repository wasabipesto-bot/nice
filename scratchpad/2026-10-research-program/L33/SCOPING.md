# L33 SCOPING: an early reject in the overlap join's top certificates (2026-11-01)

Branch **`exp/top-early-reject`** on the fork (no PR), on the combined tree `e9cdac4` (main + #235 + #236):

| commit | what | switch |
|---|---|---|
| `deadc8d`, `7cc3ba8` | failure-stage histograms in the top kernel (throwaway) | `NICE_EXP_TOP_HIST=1` |
| `5d78054` | early reject: skip the cube when the square's certificate is already dead, in place (1) or with the survivors compacted within the cube (2) | `NICE_EXP_TOP_ER` = 1, 2 |
| `06e4c9d` | side lead: the long division only over the limbs that can be nonzero | `NICE_EXP_TOP_ER` bit 4 |
| `d7fe106` | early reject also on the parent prefix's cube digits (host adds them to `tlay`) | bit 8 (with 2) |
| `f409f51` | compaction queues a, e and the clip state instead of recomputing them | bit 16 (with 2) |

Every switch is a comptime parameter read at launch; unset, the kernel is `e9cdac4`'s. Raw logs `raw/box/` (the box's `/root/l33/logs`), scripts `raw/scripts/` (`hist.py`, `ab.py`), the commits as patches and the two patch scripts `raw/patches/`, histogram tables `raw/hist-analysis.txt`, A/B tables `raw/ab-analysis.txt`.

**Summary**

- **Verdict on the early reject as scoped: no-go.** It is exact and cheap to build, but measured at **×1.000 at b62 1e17** and ×1.018 at b62 1e16 and b60 1e16 in its compacted form, and nothing in place. **With the parent prefix's cube digits** (new information on the device, 2 more words a `tlay` entry) and the queue carrying a, e and the clip state, compaction measured **×1.036 at b62 1e17 and ×1.035 at b62 1e16** (including a host cost the prototype adds, section 3.4). That is still below 5 % alone, but it adds to the trim below.
- **Where failures happen** (question 1; histograms over every pair of one field at b60 1e16, b62 1e16 and b62 1e17, 150.7 G pairs):
  - 67.6 % of pairs fail at b62 (63.9 % at b60). **60 % of failures involve a digit shared by a² and a³**, 33 % a repeat within a², 31 % within a³ (overlapping), 1.7 % the closure only. The carry and ndig never reject by themselves.
  - **The first repeat is always among the two lowest certified digits of a power** (index 7–8 of 9 from the top at b62): the parent prefix already certified the digits above them, distinct. A failure is one of the two new low digits repeating a higher one.
  - **In production order nothing is known before the square's 10th pass of 13.** By the end of the square 22.5 % of pairs are dead (b60: 20.4 %); the rest only in the cube's last 5 passes or at the end.
- **Production order** (question 2): low digits first. The colliding digits come out first, but their partners come later, and 60 % sit in the other power. High-first would need the same long division by a multi-limb power; a² already goes first. A first-chunk test needs digits already known, and the only ones are the parent's. With the parent's cube digits on the device (2 words more a `tlay` entry), 39.9 % of pairs are dead after the square. This is sound (0 violations in 150.7 G pairs) and leaves the certificate unchanged.
- **Divergence** (question 3): an exit in place can fire only if all 32 lanes of a plane are dead, and **99.9998 % of planes hold a kept pair** (0 of 435 M at b62 1e16). Measured ×1.010 (noise). Compaction within the cube saves whole planes only (7 of 8 still run phase 2 at 22.5 %), and the barrier and the recomputation of a, e and the powers eat that.
- **The side lead found on the way is the real one: trim the long division to the limbs that can be nonzero.** Before pass p, a^j < b^(sp − 2p), but the unrolled division ran all 12/18 limbs every pass. Bounding each pass at compile time cuts the division steps by 60 % (466 → 185 at b62). It is about 8 lines, exact (certificate test with #235's counts, join parity, identical counts in every run), and adds no branch. **×1.044 at b62 1e17** in A/B 1 and ×1.058 in A/B 2: **×1.051 over six rounds** (per round 1.044–1.072), **×1.071 and ×1.058 at b62 1e16, ×1.057 at b60 1e16**; NiceMark score **×1.066** (b60 ×1.077, b62 ×1.070, sampled scenarios).
- **Against the 5 % bar:** the early reject fails it in every form. The trim clears it at b60 and b62 1e16 and just clears it at b62 1e17 (×1.051, per-round spread 1.044–1.072). **Trim plus the parent-digit early reject (ER=30) clears it clearly at b62: ×1.092 (1e17) and ×1.099 (1e16)**, but the early-reject half needs host plumbing and 40 % more `tlay` memory, and was not measured at b60. The trim cuts a different stage from L31's (a) + (c) (`exp/top-cert-2b`, ×1.045 at b62 1e17 on this tree). Composing the two is the obvious next measurement (not done here); section 5 lists what a PR needs.

## 0. Setup

- **Box:** Vast 58638855 (`nice-research-earlyreject`) on m139246. RTX 3080 10 GB, **power-capped by the host at 180 W** (default 340, max 374), driver 580.159.03, CUDA 12.8, PCIe gen 3 x16; Xeon E5-2630 v4, cgroup quota 9.6 CPUs (`raw/box-info.txt`).
- **Binaries** (`raw/scripts/build.sh`; `cargo test --release -p nice_common --features gpu --no-run`, toolchain 1.99.1, one target dir, `cargo clean -p nice_common` before each):
  - `A` = `e9cdac4`, md5 **8f421599** (L31's A, so tree and build reproduce).
  - `H` = `7cc3ba8` (histograms), md5 17e78070.
  - `B` = `06e4c9d` (ER 1/2, trim), md5 2c69755e. `B2` = `f409f51` (adds bits 8 and 16), md5 44f89b96.
  - `client_A` 239e7f78 (L31's), `client_B` 27bebdd7 (from `06e4c9d`), for NiceMark.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62 7997740455941656911841), one untimed 1e14 warm-up field per process; the metric is `device=` (mean device wall seconds per field), as in L31.

## 1. Where the failures happen (question 1)

**Method** (`7cc3ba8`, `raw/patches/hist_patch.py`). With `NICE_EXP_TOP_HIST=1` the top kernel records, for every in-range (prefix, partition) pair, and sums per plane before one atomic per bin:
- the final failure category: A = two certified digits of a² repeat, B = the same in a³, C = a² and a³ share a digit, D = only the closure rejects;
- the earliest point **in production order** at which the certificate is provably dead, in passes of the long division done (a² first, 2 digits a pass from the bottom, then a³). The sound tests available mid-stream: a repeat among the square's digits above x's run of (b − 1)s (dead whatever the carry decides); the end of the square (its carry known); a repeat in the cube's same digits or a cube digit in the square's final mask; else the end of the cube and the closure;
- the same with the **parent prefix's cube digits** (host-computed per `tlay` entry, `Base::cert_cube_digits`): a square digit among them is a repeat across powers, because a sub-interval keeps its parent's common digits. The kernel counts any pair this calls dead but that is kept: **0 violations in 150.7 G pairs**;
- per plane (32 lanes): the last lane's detection point, i.e. what an exit in place could skip;
- the index from the top of the first certified digit that repeats one above it, per power, and the certified digit counts.

Runs (`raw/box/hist_*.log`, tables `raw/hist-analysis.txt`): b60 1e16, b62 1e16 and b62 1e17, one field each. The b62 1e16 run certified the same 4,508,762,994 tops as L31's profiles.

#### Failure categories (% of failing pairs; the final certificate)

| | b60 1e16 | b62 1e16 | b62 1e17 |
|---|---|---|---|
| pairs in range | 19.01 G | 13.92 G | 117.77 G |
| kept | 36.1 % | 32.4 % | 32.4 % |
| **fail** | **63.9 %** | **67.6 %** | **67.6 %** |
| A only (repeat within a²) | 17.2 | 17.1 | 17.1 |
| B only (within a³) | 17.2 | 15.5 | 15.5 |
| **C only (a² and a³ share a digit)** | **42.4** | **40.5** | **40.6** |
| A + B | 5.1 | 5.2 | 5.2 |
| A + C | 8.2 | 9.2 | 9.2 |
| B + C | 8.2 | 8.9 | 8.8 |
| A + B + C | 1.4 | 1.9 | 1.8 |
| D (closure only) | 0.2 | 1.7 | 1.7 |
| any A: the square alone is dead | 32.0 | 33.4 | 33.3 |
| any A, or a square digit among the parent's cube digits | 58.2 | 59.1 | 59.1 |

- The carry test and ndig never reject by themselves: they choose which digits are certified (c0, and the run of (b − 1)s when the carry is set). So the "carry/ndig stage" has no failures of its own; every failure is a repeat (98.3 %) or the closure (1.7 %).
- Most failures (60 %) involve a repeat **across** the two powers, which no test on one power can see.

#### When a failure becomes known, in production order (% of all pairs, cumulative; b62 1e17, b62 1e16 within 0.1 point)

| passes done (of 13 + 19) | stage | dead | dead, with the parent's cube digits |
|---|---|---|---|
| 1–8 | square, digits below c0 | 0 | 0 |
| 9 | square, first certified pass | 0 | 10.5 |
| 10–12 | square | 10.3 | 21.3 |
| 13 | end of square (carry known) | **22.5** | **39.9** |
| 14–27 | cube, digits below c0 | 22.5 | 39.9 |
| 28–31 | cube passes 15–18 of 19 | 55.6 | 57.3 |
| 32 | end of cube, closure | 67.6 | 67.6 |
| (kept) | | 32.4 kept | |

At b60 1e16 the end of the square has 20.4 % (37.2 % with the parent's cube digits).

- **Nothing is known before the square's 9th or 10th pass of 13**, and the cube is the larger conversion (19 passes of 18 limbs against 13 of 12). The only large cut is "square dead, skip the cube": 22.5 % of pairs, or 39.9 % with the parent's cube digits.

#### Per plane: the in-place exit cannot fire

| | b60 1e16 | b62 1e16 | b62 1e17 |
|---|---|---|---|
| planes (32 lanes, ~32 in range each) | 594.2 M | 434.9 M | 3,680.2 M |
| every lane square-dead | 0 | 0 | 42 |
| every lane square-dead, with the parent | 0 | 0 | 169 |
| last lane runs to the end (a kept pair in the plane) | 100.000 % | 100.000 % | 99.9998 % |

With 32 % of pairs kept and the lanes of a plane being 32 neighbouring `tlay` prefixes with independent outcomes, P(no kept lane) ≈ 0.68³² ≈ 4·10⁻⁶. An exit in place therefore saves nothing: the plane runs until its last lane, which is a kept pair. The early reject needs the survivors regrouped (section 3).

#### At which digit the first repeat appears

| | b62 1e17 square | b62 1e17 cube | b60 1e16 square | b60 1e16 cube |
|---|---|---|---|---|
| certified digits (mode) | 9 (92.0 %), 8 (7.9 %) | 9 (70.3 %), 8 (29.3 %) | 8 (97.9 %) | 8 (98.0 %) |
| first repeat, index from the top (0 = top digit), pairs with a repeat in that power | **7: 50.0 %, 8: 46.3 %**, 6: 3.7 % | 6: 11.4 %, **7: 51.4 %, 8: 37.0 %** | 6: 48.8 %, 7: 50.3 % | 6: 48.8 %, 7: 50.3 % |

- **A repeat always involves one of the two lowest certified digits** of a power. That is structural: the parent prefix (depth t − pp, the `tlay` entry) passed its own certificate, so the top 6–7 digits of each power are already distinct, and the child's pp extra digits add about two certified digits **at the bottom** of each power. A failure is one of those new digits repeating a digit above it, in its own power or in the other.

## 2. The order of production (question 2)

- **Production is low digits first.** `cert_power` divides x = a^j by B = b² over 16-bit limbs, pass after pass, and each pass's remainder gives the two lowest remaining digits. The certified digits are the **top** 8–9 of a² (25 digits at b62) and of a³ (37), so they come out in the last 4–5 passes of each power. The first 8 passes (square) and 14 (cube) produce only digits below c0, which serve x mod b^c0 for the carry test.
- **Where the collisions are, against that order.** The repeating digit is one of the two lowest certified ones (section 1), which are the **first** certified digits produced. Its partner, a higher digit of the same power or a digit of the other power, comes later. Low-first production therefore finds a repeat at the end of the power, and a cross repeat only once both powers are done.
- **Reordering does not help without new information.**
  - High digits first would need floor(a^j / b^(sp − k)) first: a division by a multi-limb constant, i.e. the same long division. Exact top digits from the top words alone would need an interval argument and a fallback; not a cheap step.
  - a² is already converted before a³. The other order (a³ first, skip a²) would gate the cheaper conversion on the dearer one.
  - A cheap collision test on the first certified chunk can only compare the new digits against digits already known. Within one power nothing is known yet at that point (two digits a chunk).
- **The digits that are known: the parent's.** A child interval keeps its parent's common digits, at the same positions, so the parent's certified digits (before the closure) are among the child's. The device does not have it: a `tlay` entry holds only P0 and three residues. With the parent's **cube** digits on the device (2 more words a `tlay` entry, `d7fe106`), a square digit among them is a cross repeat. That is sound (0 violations in 150.7 G pairs) and moves "dead after the square" from 22.5 % to **39.9 %** of pairs at b62. The certificate is unchanged: the test only rejects pairs the full certificate rejects.
  - With the parent's per-power digits **and** their positions, the new digits could be tested the moment they are produced (the square's 9th pass), and the passes above them would only reproduce the parent's digits. But the passes below c0 still have to run (8 of 13, 14 of 19), so this saves at most the top 4–5 passes of each power, the ones the trimmed division (section 4) already makes cheapest.

## 3. The prototype (question 3)

### 3.1 What was built

- **ER=1, an exit in place** (`5d78054`, in `top_cert`): the cube's `cert_power`, the closure (moved into `top_close`) and the cube's floor run only if the square's `dup` is 0. About 25 lines.
- **ER=2, compaction** (`5d78054`, in `top_kernel`), because the exit in place cannot fire (section 1, planes):
  - Phase 1, every unit: a and e (`top_ae`, factored out), the powers, the square's certificate. A unit whose square is not dead appends its `tlay` index, the square's mask, c0 and first-disagreement digits (6 words) to a queue in shared memory, with one shared atomic.
  - `sync_cube`.
  - Phase 2: unit u < n takes entry u, recomputes a, e and the powers, and runs the cube's certificate, the closure and the bookkeeping. Planes past ⌈n/32⌉ have no phase 2.
  - About 130 lines of new logic. The diff is +421/−202 because the a/e setup and the closure moved into helpers and the kernel body was re-indented.
- **Bit 8, the parent's cube digits** (`d7fe106`, +21/−4): the host computes each `tlay` entry's pure cube digits (a second pass with `Base::cert_cube_digits` on 8 threads, inside the timed span; its cost is measured in 3.4) and appends them to `tlay` (2 words an entry: `tlay` grows by 40 %). Phase 1 also rejects a square digit among them.
- **Bit 16, queued state** (`f409f51`, +33/−5): a queue entry also carries a, e and the clip state (18 words), so phase 2 does not recompute them. It still recomputes the powers (a³ is 18 limbs and a² 12, too much to queue).

### 3.2 Exactness (`raw/box/x_*.log`, `x2_*.log`)

| check | result |
|---|---|
| certificate test (`cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`), ER=1 (the same `top_cert` path as 2) | ok, **102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry** (#235's counts); 25,572 rejected intervals skipped their cube |
| the same, ER=4 (trim) and ER=5 (trim + skip) | ok, same counts; ER=5 skipped 25,572 cubes |
| join parity (`cubecl_cuda_join_matches_the_cpu_reference`: every window b10–b64 incl. b50/b54, the b57 frontier, tight, sliced and refused layouts), ER=2 and ER=6 | ok |
| join parity, `B2`: ER=10, 26, 30 (parent digits, queued state) | ok, all three |
| certificate test, `B2`, ER=31 (every bit; the test runs `top_cert`'s skip and the trim) | ok, same counts, 25,572 cubes skipped |
| every A/B run (sections 3.4, 4) | survivors / checked / found identical to A's in every run, and equal to L30/L31's exact counts for this tree |
| the parent-digit test's soundness (histogram build) | 0 pairs called dead by it and kept, in 150.7 G pairs |
| lavapipe (Mesa llvmpipe), `B2`: CI's lint dump on naga and on the direct SPIR-V compiler, ER=0, 4 and 26 (`raw/box/lvp/`) | all six ran; the lint flags 0 sites in each naga dump. The certificate test and join parity were **not** run on lavapipe |

- The test change: with the skip, a rejected interval whose cube did not run has no cube floor. Production reads the floor only for kept intervals, so the test now checks `cert_floor` wherever the cube ran and asserts that the others were rejected. The certificate itself (`Option<mask>`) is still checked for every interval.
- The certificate test has no parent prefix, so bit 8 is covered by join parity, the A/B counts and the histogram's violation count, not by the certificate test.

### 3.3 Divergence

- **In place:** the plane table in section 1. A plane exits early only if all 32 lanes are dead after the square: 0 of 435 M planes at b62 1e16, 42 of 3.68 G at 1e17. The exit costs a branch and saves nothing. Measured: ER=1 ×1.010 at b62 1e16 (per round 1.007, 1.010, 1.001), i.e. noise.
- **Compaction** turns the dead lanes into idle planes, but only in whole planes, and pays for it with a barrier and with recomputing a, e and the powers.
  - With 22.5 % of the square dead, a cube queues about 198 of 256 units: phase 2 runs 7 of 8 planes. It saves one plane's cube work in eight and recomputes the powers in seven.
  - With the parent's cube digits (39.9 % dead) it queues about 154: 5 of 8 planes.

### 3.4 A/B (device s per field; rounds interleaved A, then each variant; `raw/ab-analysis.txt`)

#### A/B 1: b62 1e17, 1 field

| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |
|---|---|---|---|---|---|---|
| A (e9cdac4) | 168.450, 172.186, 169.256 | **169.256** | 2.2 % | **×1.000** | 1.000, 1.000, 1.000 | 1398 / 179 / 69 |
| ER=2 compaction | 170.423, 167.118, 169.295 | **169.295** | 2.0 % | **×1.000** | 0.988, 1.030, 1.000 | 1372 / 179 / 69 |
| ER=4 trimmed division | 160.182, 162.292, 162.119 | **162.119** | 1.3 % | **×1.044** | 1.052, 1.061, 1.044 | 1387 / 179 / 68 |
| ER=6 compaction + trim | 160.871, 160.328, 160.954 | **160.871** | 0.4 % | **×1.052** | 1.047, 1.074, 1.052 | 1377 / 179 / 68 |

- A (e9cdac4) counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=2 compaction counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=4 trimmed division counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=6 compaction + trim counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671

#### A/B 1: b62 1e16, 2 fields

| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |
|---|---|---|---|---|---|---|
| A (e9cdac4) | 14.358, 14.402, 14.430 | **14.402** | 0.5 % | **×1.000** | 1.000, 1.000, 1.000 | 1389 / 180 / 68 |
| ER=1 in-place skip | 14.259, 14.256, 14.413 | **14.259** | 1.1 % | **×1.010** | 1.007, 1.010, 1.001 | 1400 / 180 / 68 |
| ER=2 compaction | 14.143, 14.262, 14.029 | **14.143** | 1.6 % | **×1.018** | 1.015, 1.010, 1.029 | 1382 / 180 / 68 |
| ER=4 trimmed division | 13.389, 13.450, 13.596 | **13.450** | 1.5 % | **×1.071** | 1.072, 1.071, 1.061 | 1400 / 179 / 68 |
| ER=6 compaction + trim | 13.443, 13.538, 13.219 | **13.443** | 2.4 % | **×1.071** | 1.068, 1.064, 1.092 | 1372 / 179 / 68 |

- A (e9cdac4) counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=1 in-place skip counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=2 compaction counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=4 trimmed division counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=6 compaction + trim counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050

#### A/B 1: b60 1e16, 2 fields

| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |
|---|---|---|---|---|---|---|
| A (e9cdac4) | 31.837, 32.042, 32.081 | **32.042** | 0.8 % | **×1.000** | 1.000, 1.000, 1.000 | 1401 / 180 / 68 |
| ER=2 compaction | 31.509, 31.181, 31.472 | **31.472** | 1.0 % | **×1.018** | 1.010, 1.028, 1.019 | 1403 / 180 / 68 |
| ER=4 trimmed division | 30.301, 29.971, 30.368 | **30.301** | 1.3 % | **×1.057** | 1.051, 1.069, 1.056 | 1390 / 179 / 68 |
| ER=6 compaction + trim | 30.109, 30.161, 30.313 | **30.161** | 0.7 % | **×1.062** | 1.057, 1.062, 1.058 | 1393 / 179 / 69 |

- A (e9cdac4) counts (survivors / checked / found): 460,847,952,346 / 30,871,838,404 / 0; slots 4, plan MiB 1566
- ER=2 compaction counts (survivors / checked / found): 460,847,952,346 / 30,871,838,404 / 0; slots 4, plan MiB 1566
- ER=4 trimmed division counts (survivors / checked / found): 460,847,952,346 / 30,871,838,404 / 0; slots 4, plan MiB 1566
- ER=6 compaction + trim counts (survivors / checked / found): 460,847,952,346 / 30,871,838,404 / 0; slots 4, plan MiB 1566

- Every run of both A/Bs sat at the 180 W cap: mean SM clock 1337–1403 MHz at ≥ 90 % utilisation, at most 70 °C. No clock normalisation is applied.
- `B2` was built (niced, `-j 3`) from 09:35:33 to 09:38:43, during b62 1e17 round 2 of A (09:33:53–09:36:51) and of ER=2 (09:36:51–09:39:44). Those two runs are A's slowest and ER=2's fastest. Without round 2: ER=2 ×0.988 and ×1.000, ER=4 ×1.052 and ×1.044, ER=6 ×1.047 and ×1.052.

**A/B 2**, after the first showed compaction at ×1.000: `B2` with the parent's cube digits and the queued state (ER=26), and with the trim (ER=30), against A and the trim alone (`raw/ab2-analysis.txt`). Not run at b60.

#### A/B 2 (`B2`): b62 1e17, 1 field

| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |
|---|---|---|---|---|---|---|
| A (e9cdac4) | 174.338, 169.394, 171.643 | **171.643** | 2.9 % | **×1.000** | 1.000, 1.000, 1.000 | 1392 / 179 / 70 |
| ER=4 trimmed division | 162.642, 159.753, 162.233 | **162.233** | 1.8 % | **×1.058** | 1.072, 1.060, 1.058 | 1373 / 179 / 70 |
| ER=26 compaction + parent digits + queued state | 166.241, 165.184, 165.711 | **165.711** | 0.6 % | **×1.036** | 1.049, 1.025, 1.036 | 1366 / 179 / 69 |
| ER=30 the same + trim | 157.182, 157.312, 155.239 | **157.182** | 1.3 % | **×1.092** | 1.109, 1.077, 1.106 | 1337 / 179 / 68 |

- A (e9cdac4) counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=4 trimmed division counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=26 compaction + parent digits + queued state counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671
- ER=30 the same + trim counts (survivors / checked / found): 1,020,844,021,499 / 62,584,252,554 / 0; slots 5, plan MiB 1671

#### A/B 2 (`B2`): b62 1e16, 2 fields

| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |
|---|---|---|---|---|---|---|
| A (e9cdac4) | 14.274, 14.395, 14.209 | **14.274** | 1.3 % | **×1.000** | 1.000, 1.000, 1.000 | 1401 / 180 / 68 |
| ER=4 trimmed division | 13.574, 13.488, 13.420 | **13.488** | 1.1 % | **×1.058** | 1.052, 1.067, 1.059 | 1396 / 179 / 68 |
| ER=26 compaction + parent digits + queued state | 13.797, 13.636, 13.803 | **13.797** | 1.2 % | **×1.035** | 1.035, 1.056, 1.029 | 1391 / 180 / 68 |
| ER=30 the same + trim | 12.991, 13.144, 12.973 | **12.991** | 1.3 % | **×1.099** | 1.099, 1.095, 1.095 | 1385 / 179 / 68 |

- A (e9cdac4) counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=4 trimmed division counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=26 compaction + parent digits + queued state counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050
- ER=30 the same + trim counts (survivors / checked / found): 163,513,599,082 / 10,027,698,695 / 0; slots 13, plan MiB 2050

- **The device time of ER=26 and ER=30 includes the host's computation of the parent digits.** `JoinDevice::new` runs inside the timed span, and this prototype computes them in a second pass over `tlay` (8 threads), where a PR would take them from `top_layer`, which already certifies every parent. To size it, `B2` with ER=8 alone builds the parent digits on the host while the kernel stays A's (`raw/box/ab3_*`): b62 1e16 A 14.187, 14.269, 14.515 s against 14.401, 14.637, 14.520 (medians 14.269 / 14.520, **+0.25 s a field, 1.8 %**); b62 1e17 A 172.28 s against 173.67 (**+1.4 s, 0.8 %**, one round). Without it, the device side of ER=26 is about ×1.045 (1e17) and ×1.053 (1e16), and of ER=30 about ×1.10 and ×1.12. These are estimates: a separately measured cost subtracted from a median.
- **b62 1e17 over both A/Bs** (six rounds of A and the trim; the rounds of A/B 1 round 2 overlapped the `B2` build): A 170.52 s, trim 162.18 s, **×1.051**, per round 1.052, 1.061, 1.044, 1.072, 1.060, 1.058 (median ×1.059).

#### NiceMark nice-only, once each (`--benchmark-secs 150`, `NICE_API_BASE=http://127.0.0.1:9`; `raw/box/nm_*.json`, `raw/nm-analysis.txt`)

Run for A and the trim (ER=4, `client_B`). The compaction variants were not run under NiceMark: ER=2 measured ×1.000 on the harness, and the parent-digit variants are only in `B2`, which has no client build.

| | A | er4 |
|---|---|---|
| score | 4744.0 | 5055.7 (×1.066) |
| b58_msd_weak | 2.141e+14 | 2.266e+14 (×1.059) |
| b58_msd_strong | 1.199e+15 | 1.268e+15 (×1.057) |
| b60_msd_weak | 4.006e+14 | 4.316e+14 (×1.077) |
| b62_msd_weak | 5.27e+14 | 5.637e+14 (×1.070) |
- b58_msd_weak counts: A 33590315220 / 1894592860 (3364 of 3364 partitions); er4 33590315220 / 1894592860 (3364 of 3364 partitions)
- b58_msd_strong counts: A 4027773430 / 226773299 (3364 of 3364 partitions); er4 4027773430 / 226773299 (3364 of 3364 partitions)
- b60_msd_weak counts: A 14362998731 / 912665087 (535 of 3600 partitions); er4 14765514911 / 938245972 (550 of 3600 partitions)
- b62_msd_weak counts: A 19210264579 / 1143551105 (762 of 3844 partitions); er4 19815911959 / 1179611545 (786 of 3844 partitions)

- Score **×1.066**. The whole-field b58 scenarios have identical counts in A and the trim. The sampled b60 and b62 scenarios draw different samples per run, so their counts differ.
- A's score (4744) is below L31's A on m139250 (4887): this card ran at 1,372–1,403 MHz under the same 180 W cap, against 1,424–1,464 there.

## 4. Side lead: the long division over the limbs that can be nonzero

- **What it is.** Before pass p of `cert_power`, x < b^(sp − 2p) (a^j has sp digits, and each pass removes two). Its 16-bit limbs above that bound are zero, but the unrolled division ran all of them in every pass: 12 limbs for a², 18 for a³ at 3 words. `06e4c9d` bounds each pass's division by the limb count of b^(sp − 2p), a comptime constant (`pow_limbs16`): about 8 lines of logic, plus the comptime flag on the six calls.
- **Division steps per certificate** (static; only a^j is converted, e^j enters as d = e^j − a^j):

  | base | a² steps | a³ steps | total | trimmed | ratio |
  |---|---|---|---|---|---|
  | b60 | 132 → 52 | 306 → 118 | 438 | 170 | 0.39 |
  | b62 | 143 → 58 | 323 → 127 | 466 | 185 | 0.40 |
  | b64 | 143 → 64 | 323 → 136 | 466 | 200 | 0.43 |

  L31's breakdown put the long division at 33 % of the top kernel on #235, so this should take about a fifth of the kernel's time off.
- **Exact** by construction (the skipped limbs are zero) and by test: the certificate test passes with #235's counts (ER=4, ER=5), join parity passes with it (ER=6), and every A/B run's counts equal A's. The precondition (x < b^sp) holds for production intervals (n in the field, so n^j has exactly sp digits) and for the test's arbitrary intervals (`Base::try_new` keeps the digit counts).
- **Speed** (section 3.4): **×1.044 at b62 1e17** (per round 1.052, 1.061, 1.044), **×1.071 at b62 1e16**, **×1.057 at b60 1e16**. Together with compaction (ER=6): ×1.052, ×1.071, ×1.062. A/B 2 repeated the trim against A: ×1.058 at b62 1e17 (per round 1.072, 1.060, 1.058) and ×1.058 at b62 1e16; over both A/Bs, b62 1e17 is **×1.051** (six rounds, per round 1.044–1.072). With the parent-digit compaction (ER=30): **×1.092 at b62 1e17, ×1.099 at b62 1e16**.
- **Metal.** The first step of a trimmed pass still divides the top two limbs as one u32, `(x[t] << 16) | x[t − 1]`, where both limbs are stored values (a masked schoolbook limb in pass 0, quotients later). That is the OR form, which L3 found exact on the M4; it is not a bare half-width shift. It still needs a mayalaran run before a PR.
- **SPIR-V:** the change removes straight-line division steps and adds no branch, so the block count should not move, and it does not: TopKernel b57 on CI's lint dump (lavapipe, direct SPIR-V, `B2`; `raw/box/lvp/`) has **483 blocks with the switches off and 483 with ER=4**. The 5 blocks over A's 478 (L29, L31) come from this branch's restructuring of the kernel (`top_ae`, one bookkeeping block), not from the trim. CI's WGSL lint on the naga dump flags **0 sites** with ER=4.

## 5. Verdict and what a PR needs (question 4)

**Against the bar** (≥ 5 % whole-field at b60 and b62; device s per field, ratio of medians):

| change | b62 1e17 | b62 1e16 | b60 1e16 | verdict |
|---|---|---|---|---|
| ER=1 exit in place | – | ×1.010 | – | no-go: it cannot fire (99.9998 % of planes hold a kept pair) |
| ER=2 compaction on the square's own repeats | ×1.000 | ×1.018 | ×1.018 | **no-go** |
| ER=26 compaction + the parent's cube digits + queued state | ×1.036 | ×1.035 | – | below the bar as measured; about ×1.045 and ×1.053 without the prototype's host pass (3.4); not run at b60 |
| **ER=4 trimmed division** | **×1.051** (6 rounds) | ×1.071, ×1.058 | **×1.057** | **meets it**, narrowly at b62 1e17 |
| ER=6 trim + compaction | ×1.052 | ×1.071 | ×1.062 | compaction adds nothing measurable |
| **ER=30 trim + parent-digit compaction** | **×1.092** | **×1.099** | – | meets it clearly at b62, not run at b60 |

**The early reject, as asked: no-go.** Only "the square is dead, skip the cube" is available before the end. In place it never fires. Compacted, on the square's own repeats (22.5 % of pairs), it breaks even, because it saves whole planes and pays a barrier and a recomputation. It turns positive (+3.5 % measured, about +5 % without the prototype's host pass) only with information the device does not have today, the parent prefix's cube digits, which lift the square-stage rejections to 39.9 %. If it is ever taken up, it needs:
1. The parent's cube digits from `top_layer` itself. It certifies every parent already, so the digits cost nothing there; this prototype recomputes them in a second host pass, inside the timed span. `tlay` goes from 5 to 7 words an entry (+40 %, about 245 MB at b62 1e17), which the plan's footprint has to count.
2. A test for the parent-digit reject. The certificate test has no parent; for example, check the device's kept tops for a field against the CPU's `top_layer` at depth t, as join parity does indirectly.
3. Phase 2 still recomputes the powers. Queuing a² as well (12 more words a unit) might be worth trying, at 30 KB of shared memory a block.
4. SPIR-V blocks: the two-phase kernel with the parent digits and the queued state (ER=26) has 489 blocks at b57 (483 with the switches off, A 478), which is small; the lint flags 0 sites. An M4 run, fmt and clippy, and the #235 suite.
5. b60 and b64, NiceMark.

**The trimmed division: a PR candidate**, best folded into one top-kernel PR with L31's (a) + (c) (`exp/top-cert-2b`, which reached ×1.045 at b62 1e17 on this tree, from other stages: the powers and the ndig search). Composing the two was not measured. A PR needs:
1. **M4 (mayalaran):** the certificate test and join parity on Metal. A trimmed pass's first dividend is `(x[t] << 16) | x[t − 1]`, two stored limbs. That is the OR shape L3 found exact, not a bare half-width shift, but it has to be seen to work.
2. **CI's WGSL lint**: it should flag nothing, since the change removes divisions and adds none. **SPIR-V blocks:** unchanged by the trim (483 = 483 on this branch, section 4). Both were checked here on `B2`'s dump (0 flagged; ER=0, 4 and 26); recount on the PR's code.
3. **Code:** drop the switch (the bound is always on: about 8 lines in `cert_power`). Rewrite `cert_power`'s Metal paragraph ("the first step of each pass divides the top two limbs that can be nonzero"), and state the precondition (a^j has at most sp digits; true for every production interval and for the test's) in its doc.
4. **The #235 checks:** the certificate test on CUDA and on lavapipe (naga and direct SPIR-V); join parity; the dense b58 and b62 fields; the whole b42 field; join = stride at 1e14; the host suite; fmt and clippy in three configurations.
5. **Measure:** b64, more b62 1e17 rounds (the six here spread 1.044–1.072), an uncapped card, NiceMark rounds (one run here: ×1.066), and the composition with (a) + (c). (b), L31's division-free digit step, targets the same stage; after the trim, what it can still save is smaller.
6. One CHANGELOG line.
