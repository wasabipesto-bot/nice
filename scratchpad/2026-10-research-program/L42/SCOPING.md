# L42 SCOPING: the CPU join's phase split, and FD top certificates on the CPU (2026-11-06; ivory, CPU only)

**Setup.** Worktree `.worktrees/l42-cpu-join-prof` from upstream main `6f060a9` (#240), scratch branch `l42-cpu-join-prof`
(not for a PR; nothing pushed). Machine: ivory, AMD EPYC-Rome VM, 4 vCPUs (1 thread per core, 512 KiB L2 each, 16 MiB L3),
**AVX2 only, no AVX-512** (so the scan measured is `scan_avx2`, not `scan_avx512`), TSC 2.495 GHz, cores boost to ~3.3 GHz.
Every run under `nice -n 19`. Also running: ~25 mostly idle Claude CLI processes (~1 % CPU each); load average 0.5–1.2
before my runs. Nothing else of mine ran during a timed run.

**Instruments** (all in `raw/`):
- the pristine release client's own NiceMark nice-only sweep (`raw/bench-pristine-4t.json`);
- `common/examples/l42_prof.rs`: runs sampled partitions of one slice (bit-reversed `sample_order`, as NiceMark) on 1 or N
  threads through `CpuJoin::run_partition`;
- a feature-gated rdtsc instrumentation of `CpuJoin::run` (`l42-prof`: one counter per phase per key; overhead not
  measurable) and a per-survivor variant (`l42-prof-surv`; costs ~10 %, used only for unit costs);
- `perf record` / `perf stat` on the uninstrumented harness with `--delay` past the field setup;
- `common/src/l42_fd.rs` + `common/examples/l42_fdbench.rs`: the FD certificate prototype against `Base::cert`, then wired
  into `CpuJoin::tops` behind `L42_FD=1` (self-check `L42_FD_CHECK=1`), and L41's lean prefilter behind `L42_LEAN`.

Fields: b60 = NiceMark's `b60_msd_weak` start (1157209632114824200908) at 1e14 and 1e16; b62 = NiceMark's `b62_msd_weak`
start (4473156762334864396992, the dense last 1e16 of grid field 12468) at 1e14 and 1e16, and that whole 1e17 field
(4473066762334864396992), which the CPU cuts into **7 slices** of ≤ 2^24 top-layer prefixes (slice 0: 4.75 M prefixes,
slice 6: 2.82 M). Production nice-only fields are 1e16 (b60) and 1e17 (b62), so the 1e16/1e17 rows decide; the 1e14
rows are the brief's profile.

## Summary

- **Build.** `cargo build --release -p nice_client` with default features (rustls-tls, no GPU dependency; the CPU join
  needs nothing else): **2 min 09 s** under `nice -n 19` on 4 vCPUs with a warm cargo registry; target **545 MB**
  (717 MB at the end, with the harness variants and the release test binary). Removed at the end.
- **Phase split at production shapes (b60 1e16, b62 1e16, b62 1e17 slices), the same at 1 and 4 threads:**
  **top certificates 42–43 %**, **AND scan + survivors 55 %** (perf: scan loop 28–29 %, survivor prefilter 17–18 %,
  full check 8–9 %), bottoms extension + lists ≈ 1 %, sorting tops ≈ 1 %. At 1e14 the per-partition bottom work shows:
  b60 tops 35 % / extend 7 % / list 22 % / scan 36 %; b62 tops 27 % / extend 9 % / list 30 % / scan 33 %.
  4 threads cost 3–7 % more per partition-thread than 1 (no phase is bandwidth-bound on ivory).
- **Where the top certificate's time goes (perf):** `Base::cert` + its `Div64::divrem_w4` = 40.4–40.6 % of the join at
  production shapes. Of `Base::cert`'s own samples, **~57 % sit on two hardware `div` instructions** in `digits_w` (the
  runtime `% b` / `/ b` per digit); `divrem_w4` (the `shift_down_rem` division) is another quarter of the certificate.
- **Verdict on FD top certificates: yes, they clear 5 % on the CPU, and more simply than on the GPU.**
  - The CPU's `tops()` already walks one key's prefixes in ascending order inside a partition, so consecutive
    certified P differ by multiples of h = b^o (b³), a power of the base. The #240 recurrences step in h with the same five
    digit-array adds; no batching of partitions, no new memory, no change to the threads, bottoms or scan.
  - Prototype (exact: **every unclipped slot equals `Base::cert`** — ~15.4 M slots in isolation, whole b60 and b62 1e14
    fields and production samples self-checked in place, and every survivor/checked count unchanged):
    **×1.6–1.8 per certificate** in isolation (b60 ×1.80, b62 1e17 ×1.62; GPU #240's kernel ×1.48–1.59).
  - **Field, measured in place** (whole partitions, one binary, modes interleaved, 2 rounds; §3.4): FD alone
    **×1.10–1.20 at production shapes (mean ×1.16)**, 1 and 4 threads alike, ×1.09–1.13 at 1e14; **FD + L41's lean
    prefilter ×1.23–1.29 (mean ×1.26)**. The crate's `cpu_join` tests, the opt-in production-field reference test
    (b42–b64) and the whole-b42-field test pass with both on and the FD self-check asserting.
- **Point 4.**
  - **#215's field-certificate prune: the CPU join has it** (`FieldSetup::fc`, `prune_bottoms`, and the
    `(mask | fc) & bits` test at every digit `extend` and `list` add).
  - **TRANSPOSE: no.** #239 replaced per-pair two-word tests by a digit-major bit-sliced copy of the top batch (an
    entry ORs its 12 digits' words to test 32 tops). The CPU's AND is already 8 masks per `vptestnmq` (AVX-512) or 16 per
    four AVX2 ops, ~0.3 of the ~2.3 TSC cycles an AND costs net of survivors; the rest is extracting the 3 % that pass
    (branch misses). A bit-sliced CPU variant would shave that 0.3, ≤ 4 % of the join, and leave the extraction as is.
  - **The survivor prefilter is `walk_pf`'s arithmetic** (L41 §3 says so; checked line by line). **L41's lean form ports:**
    FX + MT (fixed-point digits, shift-membership, branch-free) measured **×1.05–1.08** at production shapes alone
    (survivor/checked counts identical). RC (residue test only on clipped tops) measured ×1.00.
- **Recommendation:** one CPU PR: FD top certificates in `CpuJoin::tops` (with the cheap bookkeeping fixes), then the
  lean prefilter in `survivor` as a second commit or PR. Prototype plan in §6.

## 1. Build, and the client's own timing

| item | value |
|---|---|
| command | `CARGO_TARGET_DIR=<wt>/target nice -n 19 cargo build --release -p nice_client` (default features) |
| time | 2 min 09 s (130 s) wall |
| target | 545 MB after the client; 717 MB at the end with the harness variants and the test binary (removed) |
| `df -h /` before | 15 GB free of 75 GB |

Pristine NiceMark nice-only sweep, CPU, 4 threads, `--benchmark-secs 300` (`raw/bench-pristine-4t.json`), score 665:

| scenario | threads | rate (numbers/s) | sampled / partitions | run s | timed window → field s |
|---|---|---|---|---|---|
| b58_msd_weak (1e15 field) | 4 | 1.629e12 | 328 / 3364 | 59.8 | 614 s for 1e15 |
| b58_msd_weak_1t | 1 | 4.326e11 | 86 / 3364 | 59.1 | 2312 s for 1e15 |
| b58_msd_strong | 4 | 1.057e13 | 2136 / 3364 | 60.0 | 95 s for 1e15 |
| b60_msd_weak (3e15 of the 1e16 field) | 4 | 3.647e12 | 256 / 3600 | 58.4 | 823 s for 3e15 |
| b62_msd_weak (3e15 of the 1e16 window) | 4 | 4.187e12 | 316 / 3844 | 58.8 | 716 s for 3e15 |

The client prints no phase timers for the CPU join (only `setup_secs` / `run_secs` in the join telemetry), so the phase
split comes from the scratch instrumentation and perf below.

## 2. The phase split

### 2.1 Coarse rdtsc split (% of partition cycles, summed over threads; `raw/coarse-runs.txt`)

"tops" is `CpuJoin::tops` (the certificates and the kept-top bookkeeping), "extend" the bottom extension (once per
partition), "list" `advance` + `list` (per key), "scan" the AND scan including every survivor's prefilter and full check.

| shape | threads (partitions) | tops | extend | list | sort tops | scan + survivors | ms / partition-thread |
|---|---|---|---|---|---|---|---|
| b60 1e14 | 1 (400 of 3600) | 34.9 | 6.7 | 21.7 | 1.1 | 35.6 | 43.6 |
| b60 1e14 | 4 (all 3600) | 34.7 | 6.6 | 21.6 | 1.1 | 35.9 | 46.4 |
| b62 1e14 | 1 (400 of 3844) | 26.6 | 9.3 | 30.0 | 0.8 | 33.4 | 49.9 |
| b62 1e14 | 4 (all 3844) | 26.5 | 9.3 | 29.9 | 0.8 | 33.5 | 52.3 |
| **b60 1e16** | 1 (6) | **43.3** | 0.2 | 0.7 | 1.0 | **54.8** | 3027 |
| **b60 1e16** | 4 (16) | **43.1** | 0.2 | 0.7 | 1.0 | **55.0** | 3228 |
| b62 1e16 window | 1 (6) | 42.0 | 0.3 | 1.0 | 0.9 | 55.8 | 2274 |
| b62 1e16 window | 4 (16) | 42.3 | 0.3 | 1.0 | 0.9 | 55.5 | 2360 |
| **b62 1e17, slice 0/7** | 1 (4) | **43.1** | 0.2 | 0.8 | 0.9 | **55.0** | 2866 |
| b62 1e17, slice 6/7 | 1 (4) | 42.0 | 0.4 | 1.2 | 0.9 | 55.4 | 1792 |
| b62 1e17, slice 6/7 | 4 (16) | 42.0 | 0.4 | 1.2 | 0.9 | 55.6 | 1850 |

Per partition at b60 1e16: 5.07 M top-layer prefixes certified, 1.76 M kept (34.7 %); 33.5 k bottoms extended (`bpre`
78.7 k after the field prune); 1.15 M bottoms listed over the 60 keys; **1.15·10^9 ANDs, 34.3 M pass (3.0 %)**, all in
range; 2.18 M pass the prefilter (6.4 % of survivors) into the full check; 0 hits. Unit costs: **~650 TSC cycles
(≈ 260 ns) per certified prefix**, whatever the shape; 3.6–4.7 TSC cycles per AND including the survivor work.

Why the 1e14 rows differ: the bottom work (extension, 60 key lists) is per partition and fixed, the top and scan work
scales with the top layer (59 k prefixes at b60 1e14, 5.07 M at 1e16). At production sizes the per-partition bottom
work is ~1 %.

### 2.2 perf, uninstrumented (% of samples after the setup; `raw/perf-runs.txt`, `perf-b60-1e16-1t`)

| shape | thr | `Base::cert` | `divrem_w4` (cert's) | u128 `%`/`/` (kept tops' `dm`, `pc`) | `run` glue (tops loop, extend, list) | sort | `scan_avx2` | `survivor` (prefilter) | full check |
|---|---|---|---|---|---|---|---|---|---|
| b60 1e14 | 1 | 23.9 | 8.5 | 1.2 | 29.3 | 1.1 | 15.0 | 14.8 | 5.8 |
| b62 1e14 | 1 | 18.6 | 6.5 | 0.7 | 39.9 | 0.7 | 13.2 | 14.8 | 5.2 |
| **b60 1e16** | 1 | **29.4** | **11.1** | 1.4 | 2.2 | 1.0 | **29.0** | **17.5** | **8.2** |
| **b60 1e16** | 4 | **29.5** | **10.9** | 1.4 | 2.2 | 1.1 | **28.9** | **17.3** | **8.3** |
| b62 1e17 s0 | 1 | 29.9 | 10.5 | 1.4 | 2.3 | 0.9 | 27.9 | 18.0 | 8.8 |
| b62 1e17 s0 | 4 | 29.8 | 10.8 | 1.2 | 2.3 | 0.9 | 28.0 | 18.1 | 8.5 |

- The top certificate (`Base::cert` + `divrem_w4`) is **40.4–40.6 %** at production shapes; with the loop and the
  kept tops' bookkeeping, `tops()` is the 42–43 % above.
- Inside `Base::cert` (sample offsets mapped to `objdump`): **~57 % of its own samples are the two `div` instructions of
  `digits_w`'s per-digit loop** (`div r64` / `div r32` with the runtime base; ~9–11 digits a power). That is ~17 % of
  the whole join on this Zen 2 core. `divrem_w4` (Möller–Granlund, multiplies) is `shift_down_rem`'s division.
- `perf stat` (b60 1e16, 1 thread, 4 partitions): IPC 1.81; **2.96 % of branches mispredicted, 63 M per partition**,
  ≈ 12 % of cycles at Zen 2's ~18-cycle penalty. They are the scan's pop loop (a chunk of 16 holds a survivor with
  probability ~0.4) and the prefilter's early exits (first digit pair passes ~40 %).
- In `survivor`: the in-range test's dependent loads (`info → ext.idx → bp_r`) ~17 % of its samples, the prefilter's
  two `SmallDiv` remainders ~15 %, the digit loop with its exits ~45 %, the full-check call ~10 %.

## 3. FD top certificates on the CPU

### 3.1 The CPU's order already steps by a power of the base

`CpuJoin::run` calls `tops(v, layer)` once per key with that key's slice of the top layer, which `CpuJoin::new` sorts
by key **stably** (so ascending p0 within a key). For one partition value v, P = p0·b^p + v, and two prefixes of one key
differ by a multiple of the key space b^(o−p). So consecutive P in that loop differ by m·h with **h = b^o** (b³ at
production; b^p when the key level is off). The block [P·w, P·w + w − 1] (w = b^f0) moves by m·h·w, a power of the base
times m, and a^j = P^j·b^(j·f0) as in L35/#240.

The finite differences in step h are #240's with shifted constants:

    SQ = P²,  DS = 2Ph + h²,            DDS  = 2h²        (one digit, 2 at position 2o)
    CU = P³,  DC = 3P²h + 3Ph² + h³,  DDC = 6Ph² + 6h³,  DDDC = 6h³ (one digit, 6 at position 3o)
    step: SQ += DS; DS += DDS; CU += DC; DC += DDC; DDC += DDDC
    binary: d2 = δ(2a + δ) += 2δH;  d3 = δ(3a² + 3aδ + δ²) += Δ3;  Δ3 = 3δH(2a + H + δ) += 6δH²   (δ = w − 1, H = h·w)

A gap of m ≤ 4 is stepped m times; a larger gap (or a key's first prefix) seeds. Measured over a whole partition:

| shape | slots | seeds | steps / slot | gap 1 / 2 / 3 / 4 |
|---|---|---|---|---|
| b60 1e16 | 5,073,848 | 2.3 % | 1.43 | 66 / 21 / 8.1 / 2.6 % |
| b62 1e17 slice 0 | 4,745,415 | 4.7 % | 1.38 | 65 / 21 / 6.9 / 2.7 % |
| b62 1e17 slice 6 | 2,821,561 | 4.6 % | 1.39 | 63 / 23 / 6.9 / 2.5 % |
| b60 1e14 (8 partitions) | 471,378 | 3.0 % | 1.41 | |
| b62 1e14 (8 partitions) | 402,908 | 4.3 % | 1.40 | |

The GPU's order (a batch of consecutive partitions, h = 1) is also measured below for comparison; it needs no gaps but
seeds once per batch, and on the CPU it would need several partitions' bottoms and tops alive per thread.

### 3.2 The prototype (`common/src/l42_fd.rs`, ~480 lines with the division-free `cert_df` of §5)

- **State** (per thread, ~350 bytes): SQ, DS, CU, DC, DDC as packed base-b digits, 8 a `u64`, stepped with
  `detailed_fd`'s biased add (runtime bias); d2, d3, Δ3 as `W4`.
- **Certificate** (`TopFdSetup::cert`): `Base::cert`'s scan from the stepped digits (digit at position pos is
  `X[pos − j·f0]`, zero below). c0 = max(k, ndig(d)) with **ndig from a bit-length table and one compare** (#237's
  `ndig_fast` idea; exact: d ∈ [2^(L−1), 2^L) has ndig(2^(L−1)) or one more digits). The carry test
  (a^j mod b^c0) + d ≥ b^c0 is **screened in f64**: R/b^(k−2) ∈ [r, r + 1) for r the top two digits of
  R = P^j mod b^(c0 − j·f0), and d/b^(c0−2) in f64 is within 1e−12 of the truth (< b²); outside a 1e−9 margin the
  answer is certain, inside it (≈ 1/b² of calls) the exact remainder is built from the packed digits (three multiplies
  per 8 digits) and compared in `W4`. The run of (b − 1)s, the domains and `close_certificate` are `Base::cert`'s.
- **Seed:** exact `W4` products, converted to digits without a hardware division (`Div64` by b^8, by b^4, then the
  48-bit reciprocal multiply per digit): ~540 ns (the `digits_w` conversion took ~1000 ns).
- **Clipped blocks** (only P = plo, phi of a slice) and out-of-range P take `Base::cert` and leave the state alone.
- **In `tops()`** (`L42_FD=1`): one `Option<TopFd>` per call, `prev_p0`; step while `s.p < p` if the gap is ≤ 4 key
  spaces, else seed. No u128 division added.

### 3.3 Exactness

- `l42_fdbench`: FD equals `Base::cert` on **every slot** of: b60 1e16 (5.07 M, four times across builds), b62 1e17
  slices 0 and 6 (4.75 M + 2.82 M), b60 / b62 1e14 (8 partitions each), b64 1e14 and 1e16 (0.34 M + 3.05 M), and b60
  1e16 and b62 1e17 in the GPU's consecutive-partition order (0.81 M + 1.90 M). The division-free `cert_df` (§5) equals
  it on the same slots from the second build on (all but the first b60 runs).
- In place with `L42_FD_CHECK=1` (asserts FD = `Base::cert` at every unclipped slot): **the whole b60 1e14 field (3600
  partitions) and the whole b62 1e14 field (3844)**, and 16 sampled partitions each of b60 1e16, b62 1e16, b62 1e17
  slices 0 and 6. No assertion, and the survivor / checked counts equal the baseline's to the last digit
  (b60 1e14 1,326,103,590 / 84,383,498; b62 1e14 1,470,093,637 / 87,495,922; b60 1e16 16-partition sample
  549,719,536 / 34,926,644; b62 1e17 s0 550,916,180 / 32,806,057).
- The crate's `cpu_join` unit tests (`raw/unit-tests.txt`) with `L42_FD=1 L42_LEAN=3 L42_FD_CHECK=1` and with
  `L42_LEAN=2`: **7 passed** (reference join on the b10–b64 test windows with both ends clipped, all three scans, stride
  agreement on whole windows, slices, the field prune, b10's 69). The opt-in `cpu_join_matches_the_reference_on_production_fields`
  (`NICE_TEST_CPU_JOIN_REF=3`, b42/b50/b57/b60/b62/b64 plans, `raw/unit-tests-prodref.txt`): **ok**, with FD at b64 too.
  (To run them I made the scratch `Phases` counters compare equal; they are not part of the result.)
- The opt-in whole-field test (`NICE_TEST_JOIN_FULL_FIELD=1`, `raw/unit-tests-fullfield.txt`) with FD + lean + self-check:
  **the whole b42 1e13 field through the CPU join equals the reference join over every partition and the stride path**:
  1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits (#240's counts); on 4 threads reference 85 s,
  join 16.2 s, stride 113.5 s.

### 3.4 Measurements

**The certificate alone** (`raw/fdbench-runs.txt`; ns per certified prefix, 3 rounds, all slots of a partition in
`tops()`'s order; "DF" = `Base::cert` with division-free digits, §5):

| shape | `Base::cert` | DF | FD, plain remainder | + f64 carry screen | + DF seed (= FD) | FD ratio | FD, pure stepped slot |
|---|---|---|---|---|---|---|---|
| b60 1e16 | 249–259 | 197–209 (×1.22–1.30) | 166–175 | 152–161 | **137–151** | **×1.67–1.89** | 107 ns |
| b62 1e17 s0 | 255–264 | 193–199 (×1.28–1.37) | 194–200 | 180–196 | **154–161** | **×1.60–1.71** | 104 ns |
| b62 1e17 s6 | 253–263 | 194–205 (×1.23–1.36) | 193–199 | 182–191 | **160–164** | **×1.54–1.62** | 103 ns |
| b60 1e14 | 252–269 | 195–206 (×1.26–1.31) | 170–201 | 157–160 | **139–142** | **×1.77–1.91** | 109 ns |
| b62 1e14 | 251–254 | 194–205 (×1.24–1.29) | 191–194 | 173–192 | **149–161** | **×1.58–1.68** | 114 ns |
| b62 1e17 s0, GPU order (8 consecutive partitions) | 250–256 | | | | 162–168 | ×1.49–1.55 | 89 ns |

The GPU's #240 kernel ratio was ×1.48–1.59 (×1.6 at b62 1e17); the CPU certificate gains a little more because
`Base::cert` pays hardware divisions the GPU never had. Seeds cost ~540 ns (2× a certificate), so b62's 4.7 % seeds
cost it ~25 ns a slot; that, not the steps, is why b62 trails b60.

**In place** (`raw/fd-field-runs.txt`, `fd-field-runs2.txt`; ms per partition-thread, one binary, modes interleaved,
mean of 2 rounds; counts identical in every mode):

| shape | threads (partitions) | base | FD | **FD ×** | FD + lean prefilter | **FD + lean ×** | first build (u32 `div` per gap): FD × / FD + lean × |
|---|---|---|---|---|---|---|---|
| b60 1e16 | 1 (4) | 3103 (3101, 3105) | 2616 (2592, 2640) | **×1.186** | 2407 (2384, 2429) | **×1.289** | ×1.180 / ×1.245 |
| b60 1e16 | 4 (16) | 3333 (3287, 3378) | 2787 (2779, 2795) | **×1.196** | 2576 (2582, 2570) | **×1.294** | ×1.155 / ×1.280 |
| b62 1e16 window | 1 (4) | 2339 (2306, 2373) | 2006 (2025, 1988) | **×1.166** | 1861 (1886, 1836) | **×1.257** | |
| b62 1e17 slice 0 | 1 (4) | 2916 (2897, 2936) | 2659 (2687, 2632) | **×1.097** | 2360 (2346, 2373) | **×1.236** | ×1.139 / ×1.255 |
| b62 1e17 slice 0 | 4 (16) | 3157 (3167, 3146) | 2694 (2700, 2689) | **×1.172** | 2555 (2443, 2667) | **×1.235** | ×1.131 / ×1.227 |
| b60 1e14 | 1 (400) | 45.08 (45.2, 44.9) | 39.83 (40.4, 39.3) | ×1.132 | 37.97 (38.1, 37.9) | ×1.187 | ×1.125 / ×1.196 |
| b62 1e14 | 1 (400) | 51.09 (51.1, 51.0) | 46.81 (47.1, 46.5) | ×1.091 | 44.35 (44.0, 44.7) | ×1.152 | ×1.085 / ×1.122 |

**FD alone: ×1.10–1.20 at production shapes (mean of the nine production rows of both builds ×1.16), ×1.09–1.13 at
1e14. FD + lean prefilter: ×1.23–1.29 at production shapes (mean ×1.26), ×1.12–1.20 at 1e14.** The same at 1 and 4
threads. That is what the split predicts: tops 43 % × (1 − 1/1.45) ≈ 13 % of the partition.

**Base 64** (`raw/fdbench-b64.txt`, certificate alone): on the CPU `digits_w` divides by the runtime base even at b64,
so `Base::cert` costs the same 263–291 ns there; FD ×1.41–1.64, DF ×1.22–1.37. b64's key slices have more gaps (9.3–9.5 %
seeds), so its FD ratio leans on the seed's cost. Unlike the GPU (#240 kept `top_kernel` at power-of-two bases), the CPU
should take FD at b64 too, subject to an in-place measurement.

**The split with FD + lean prefilter** (coarse rdtsc, `raw/final-runs.txt`, first build): b60 1e16 tops 36.4 % / scan +
survivors 60.8 % (1 thread), 36.7 / 60.6 (4); b62 1e17 s0 37.8 / 59.6 (1), 37.6 / 59.8 (4). In place the stepped
`tops()` costs ~450 TSC cycles per prefix against ~650: ×1.45, below the isolated ×1.8 because the loop's own work
(the u128 `p0·b^p + v`, the range tests, the kept tops' u128 `dm` and `pc`, the push) is unchanged.

## 4. Point 4

**(a) #215's field-certificate prune: present.** `FieldSetup::fc = cert(s, e − 1, k)`; `prune_bottoms` drops `bpre`
residues whose mask meets it; `CpuJoin::extend` and `CpuJoin::list` test `(mask | fc) & bits` for every digit they add
(the partition's fixed digits and the key digit). It landed in #215 itself (`cpu_join.rs` +91 lines there), and
`the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate` covers the CPU lists. What it prunes on these fields: `bpre` has 137,775 residues at b60 and
176,671 at b62 before the prune; after it, b60 1e14 47,560 (−65 %), b60 1e16 78,725 (−43 %), b62 1e14 75,372 (−57 %),
b62 1e16 window 90,315 (−49 %), b62 1e17 slice 0 90,199 (−49 %). The partition and key digits then drop more
(33.5 k extended bottoms a partition at b60 1e16).

**(b) A `TRANSPOSE`-style benefit in the AND loop: no.** #239's `TRANSPOSE` writes a batch of ≥ 192 tops digit-major
(`t_tr[c·64 + d]`: bit i set iff top 32c + i has digit d), so an entry's pass mask over 32 tops is the complement of the
OR of its 12 digits' words: 12 loads and ORs instead of 32 two-word tests, on a GPU whose join is ALU-bound. The CPU scan
is oriented the other way (one top's mask in a register against a contiguous class of ~325 bottom masks at b60 1e16)
and already wide: one `vptestnmq` tests 8 bottoms (AVX-512), four `vpand`/`vpcmpeqq`/`vmovmskpd` groups test 16 (AVX2).
Net of the survivors, an AND costs ~2.3 TSC cycles on ivory, of which the AND arithmetic is ~0.3 (≈ 1 instruction a
bottom at IPC ~3); the rest is the pop loop over pass bits, whose "does this 16-chunk hold a survivor" branch is taken
~40 % of the time at random, plus the per-class tails. The CPU analogue (bottoms bit-sliced per class, a top ORing its
~20 certificate digits' 256-bit words) would cut only the 0.3: ≤ 4 % of the join before the cost of building the copy,
and nothing off the extraction. The lever on that cost is branch-free compaction of the pass bits (§5), CPU-only.

**(c) The survivor prefilter is `walk_pf`'s arithmetic**, and L41's lean form ports:
- Same predicate and same inputs: x2 = (A2 + P2·D) mod b², x3 = (A3 + P3·D) mod b², A the carries (`Info.carries`),
  P2 = 2ρ and P3 = 3ρ² mod b² (`ext.p2/p3`), D the top's digits k..k2 (`Top.dm`), then the two digits of each against
  each other and against seen = bottom mask ∪ (seed ? top mask : ∅) (`prefilter`, `prefilter_digits`). L41 §3 derives
  `walk_pf` from this code.
- Ported (`CpuJoin::prefilter_lean`, `L42_LEAN=2`): FX (α̂ = A·⌈2^32/b²⌉, δ̂ = ⌈D·2^32/b²⌉ from a b²-entry table per top,
  F = α̂ + P·δ̂ mod 2^32, h = ⌊F·b/2^32⌋, g = ⌊(F·b mod 2^32)·b/2^32⌋; L41 §3.1's proof applies unchanged, mid = 2), MT
  (`(seen >> g) & 1` four times, six inequalities, all `&` — one branch per survivor instead of up to four), GM
  (`Top.gmask`, the seed-gated mask). RC (`L42_LEAN=1`): skip the residue gather and range test for unclipped tops.
- Measured (`raw/lean-runs.txt`, 1 thread, 2 rounds, counts identical): FX+MT+GM **×1.077 b60 1e16, ×1.050 b62 1e17
  s0, ×1.047 b60 1e14**; RC ×1.009 / ×0.987 (noise); all four ×1.066 / ×1.062. RC is not worth its branch on the CPU:
  the residue loads hit L2 and overlap the prefilter.

## 5. Other levers, ranked (production shapes)

| lever | from | measured / estimated | exactness | note |
|---|---|---|---|---|
| **FD top certificates (key-order stepping)** | #240 | **×1.10–1.20 measured** (prototype, mean ×1.16) | exact; self-checked | §3; more with the tuning in §6 |
| **lean prefilter FX + MT + GM** | L41 | **×1.05–1.08 measured** | exact by construction; counts identical | §4(c) |
| both | | **×1.23–1.29 measured** | | §3.4 |
| division-free digits in `Base::cert` (no FD) | #228 idea | cert ×1.22–1.37 isolated → ~×1.09–1.10 field (estimate) | exact; checked on all fdbench slots | the cheap fallback if FD is not wanted; subsumed by FD |
| kept tops' u128 `dm`, `pc` (and the setup's u128 `%` in the key sort comparator) | — | ≤ 1.4 % (perf) | trivial | `pc` steps by m (h ≡ 1 mod b − 1); `dm` by `Div64`; the setup (top layer and this sort) is 2–3 s a 1e16 slice, outside the partitions |
| branch-free survivor compaction in the scan | CPU-only | ~3–6 % (estimate from ~36 M pop-loop mispredictions a partition) | exact | not measured; AVX-512 has `vpcompressq`, AVX2 needs a 16-bit LUT |
| RC (residue test only on clipped tops) | L41 | ×1.00 measured | exact | drop |
| `powers_diff` from δ, `ndig_fast` (in `Base::cert`) | #237 | a few % of the cert | exact | subsumed by FD (it steps d and uses the table) |
| bit-sliced (transposed) AND | #239 | ≤ 4 % before its own cost (estimate) | exact | §4(b); not worth it |
| a third prefilter digit | — | ≈ break-even | | 34 M survivors × one more round vs. ~1 M fewer full checks |

## 6. Prototype plan (for a PR; CPU only, no GPU)

1. **`common/src/cpu_top_fd.rs`** (from `l42_fd.rs`): `TopFdSetup` per `CpuJoin` (built in `CpuJoin::new`; `None` when
   the arrays would not fit, then `Base::cert` as today), `TopFd` per `tops()` call.
   - Tighten the step: per-array word counts (DS is t + o + 1 digits, DDC t + 2o + 1, not the cube's), add the shorter
     array plus one word and ripple the rare carry (as `detailed_fd::ripple_words`): ~14 word-adds a step instead of 21.
   - Cheaper seed: derive DS, DC, DDC from the digits of P, P² by digit adds instead of converting five `W4` values
     (two conversions instead of five).
   - Kept tops: `pc` stepped with P (h ≡ 1 mod b − 1), `dm` via `Div64` (no `__udivti3`/`__umodti3`).
   - Expected: the in-place ratio of `tops()` from ×1.45 toward ×1.7, i.e. the field from ~×1.15 toward ~×1.2.
2. **`CpuJoin::tops`**: as in the scratch branch (step while `s.p < p` within 4 key spaces, else seed; clipped and
   out-of-range blocks through `Base::cert`). Power-of-two bases: keep FD unless measured otherwise — on the CPU `b64`'s
   `digits_w` still divides by a runtime base, unlike the GPU's comptime shifts (b64 measured for the certificate alone,
   ×1.41–1.64, §3.4; not in place).
3. **Tests**: (i) host test like #240's device test: for every partition of the test windows (clipping at both ends,
   small bases) and sampled partitions of the 1e14/1e16 `PLAN_FIELDS` and the first and last slices of a 1e17 plan,
   `tops()` with FD equals `tops()` with `Base::cert` (same `Top` list, field by field); (ii) the existing `cpu_join`
   tests unchanged (reference join, scans, stride agreement, slices); (iii) the opt-in production-field reference test.
4. **Lean prefilter** (second commit or PR): `prefilter_lean` as in the scratch branch under `mid == 2` and the
   production shape (`kb = bk = b2k = 0`), today's code otherwise; a host test of FX's digits against `SmallDiv`'s for
   every A, P, D < b² at a few bases (b² ≤ 4096, so exhaustive over two of the three inputs is cheap), plus the
   existing survivor/checked parity tests.
5. **Measure**: NiceMark's CPU nice-only scenarios and the `l42_prof`-style interleaved whole-partition timing at b58,
   b60 1e16 and b62 1e17 slices, 1 and N threads, on ivory (Zen 2) and an AVX-512 box (Zen 4: faster `div`, wider scan;
   the certificate's share and the FD gain will be lower there), and Anvil's EPYC (Zen 3) if the user wants that number.

## 7. Caveats

- One microarchitecture: Zen 2 (EPYC Rome), AVX2. Its 64-bit `div` is slow; on Zen 3/4 (Anvil, demoux) `Base::cert`'s
  division share is smaller, so both the certificate's share of the join and FD's ratio there are lower (FD also removes
  `divrem_w4` and the `W4` products, so it keeps a gain; DF-only would shrink most). With AVX-512 the scan is cheaper, so
  the certificate's share rises.
- In-place timings vary ±3 % run to run (one round of FD + lean at b60 1e16 1 thread differed 6 %); every comparison is
  interleaved in one binary and averaged over 2 rounds. NiceMark samples bit-reversed partitions, as the harness does; the
  FD gain does not depend on partition order (it steps inside a partition).
- The instrumented split adds no measurable cost (one counter per phase per key); the per-survivor variant costs ~10 %
  and was used only for unit costs. perf and the rdtsc split agree within 2 points.
- The 1e17 field is 7 slices on the CPU; slices 0 and 6 were measured (4.75 M and 2.82 M prefixes); the others lie
  between.

## Files

- `raw/l42-scratch.patch`: the scratch branch against `6f060a9` (instrumentation, `l42_fd.rs`, the FD and lean toggles in
  `cpu_join.rs`, the two harnesses). The worktree `.worktrees/l42-cpu-join-prof` keeps it uncommitted; its `target/` is
  removed. Build: `cargo build --release -p nice_common --example l42_prof [--features l42-prof|l42-prof-surv]` and
  `--example l42_fdbench`; toggles `L42_FD=1`, `L42_FD_CHECK=1`, `L42_LEAN=0..3`.
- `raw/scripts/`: the run scripts (they expect the harness binaries copied to `/tmp/l42/`, since removed).
- `raw/coarse-runs.txt` (§2.1), `raw/perf-runs.txt` and the two `perf-*-sample-offsets` files (§2.2), `raw/fdbench-*.txt`
  (§3.4), `raw/fd-field-runs*.txt` and `raw/final-runs.txt` (§3.4), `raw/lean-runs.txt` (§4c), `raw/unit-tests*.txt`
  (§3.3), `raw/build-release.log`, `raw/bench-pristine-4t.*` (§1).
