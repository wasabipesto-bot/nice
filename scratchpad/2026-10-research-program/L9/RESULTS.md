# L9: H100 SXM and L40S on the nice client (2026-11-01, agent)

**Verdict: neither card is worth renting at these prices.** The L40S is the fastest single
card measured in this program: NiceMark nice-only 10,245, and b62 1e17 in 80 s, 2.85× a
180 W RTX 3080. But at $0.539/h it gets 0.58–0.79× a 3080's numbers per dollar, and
0.74–0.88× a 4090's NiceMark per dollar. It breaks even with a 3080 at about $0.31–0.43/h.
The H100 SXM is *slower* than the L40S (NiceMark 8,349, b62 1e17 in 104 s). At $2.14/h it gets
0.11–0.15× a 3080's numbers per dollar, 6.5–8.8× worse. Both boxes were power-capped by the host below
the card default (H100 500 of 700 W, L40S 300 of 350 W), and both sat at that cap under load.
Even with the clocks at maximum, the verdict stands (see "Odd things").

- Tree: upstream main **fae7398** (`fae739874a4e`, "Changelog: link PRs on entries back to v3.2.0 (#234)"), client v3.4.8-dev,
  rustc 1.99.1, CUDA toolkit 12.8.93 (image `nvidia/cuda:12.8.1-devel-ubuntu24.04`). `auto` picked
  **CubeCL CUDA** on both cards (`GPU initialized: CubeCL CUDA device 0`), and every nice-only scenario took the join.
- **Nothing was uploaded.** All 14 sweeps print "Not uploading (non-interactive ...)"; stdin was `/dev/null`, no `--benchmark-upload`.
- **One test-only change, for logging:** the throughput harness `cubecl_cuda_join_throughput_fixed_fields` got
  `#[test_log::test]` instead of `#[test]` (`raw/*/test_patch.diff`), so the join's per-field debug line
  (slices, partitions, batches × slots, MiB) prints with `RUST_LOG=nice_common::cubecl_join=debug`. The
  client binary was built first, from the unmodified tree.
- Order per box (`raw/l9.sh`, then `raw/extras.sh`): build → niceonly ×3 → detailed ×2 → joins (b60 1e16, b62 1e16 ×2,
  b62 1e17 on the H100) → extras (2-field 1e16 at b60/62/64 for a like-for-like with the 3080's L29 runs, b62 1e17
  (a second run on the H100, the first on the L40S), 2 niceonly sweeps with `--benchmark-json` for the layout). Then an L40S b62 1e17 repeat.
  Nothing else ran on either GPU. Timelines: `raw/*/phases.log`.

## Hardware

| | H100 SXM (58603645) | L40S (58603651) |
|---|---|---|
| GPU | NVIDIA H100 80GB HBM3 (Hopper), VBIOS 96.00.74.00.01, PCIe gen5 x16 | NVIDIA L40S (Ada), 46,068 MiB, VBIOS 95.02.66.00.02, PCIe gen4 x16 |
| driver / CUDA (driver) | 595.71.05 / 13.2 | 580.126.20 / 13.0 |
| power limit (current = enforced / default / max) | **500 W** / 700 W / 700 W | **300 W** / 350 W / 350 W |
| max SM clock | 1980 MHz | 2520 MHz (application clocks 2520 / 9001) |
| ECC / MIG / mode | ECC enabled, MIG disabled, pass-through, persistence on | ECC enabled, MIG N/A, pass-through, persistence on |
| host CPU | AMD EPYC 9454, 24 vCPU (1 thread/core, KVM), 92 GB RAM | Intel Xeon Gold 6438Y+, 64 vCPU (KVM) |
| Vast price | $2.140/h | $0.539/h |

Raw: `raw/h100_hw.txt`, `raw/h100_hw2.txt`, `raw/l40s_hw.txt` (`nvidia-smi -q -d POWER,CLOCK`, `lscpu`, ...),
`raw/*/after_perf.txt` (throttle counters after the runs).

## 1. NiceMark nice-only (`niceonly --gpu --benchmark --benchmark-secs 150`, 3 runs)

Each sweep took about 30 s: the scenarios do not need the 150 s budget (L29 saw the same on the 3080).

| scenario | H100 median (runs) | spread | L40S median (runs) | spread | L40S / H100 |
|---|---|---|---|---|---|
| b58_msd_weak | 3.724e14 (3.749, 3.688, 3.724) | 1.6 % | 4.465e14 (4.514, 4.454, 4.465) | 1.3 % | 1.20 |
| b58_msd_strong | 2.171e15 (2.201, 2.171, 2.168) | 1.5 % | 2.378e15 (2.472, 2.378, 2.360) | 4.7 % | 1.10 |
| b60_msd_weak | 7.082e14 (7.082, 7.050, 7.118) | 1.0 % | 9.226e14 (9.195, 9.507, 9.226) | 3.4 % | 1.30 |
| b62_msd_weak | 9.077e14 (9.137, 9.077, 9.045) | 1.0 % | 1.185e15 (1.185, 1.171, 1.198) | 2.3 % | 1.31 |
| **NiceMark** | **8349** (8405, 8318, 8349) | 1.0 % | **10245** (10325, 10245, 10213) | 1.1 % | 1.23 |

- Join layout in the sweeps (from `--benchmark-json`, identical on both cards): b58 1 slice / 3364 partitions / 16 slots
  (all sampled); b60 1 slice / 3600 / 6 slots (sampled 648–990); b62 1 slice / 3844 / 9 slots (sampled 1161–1971). The
  sample is time-budgeted, so the sampled count varies run to run.
- The two extra `--benchmark-json` sweeps scored 8148 / 8213 (H100) and 10045 / 10193 (L40S). They are not in the medians.

## 2. NiceMark detailed GPU (`detailed --gpu --benchmark --benchmark-secs 120`, 2 runs)

| scenario | H100 median (runs) | spread | L40S median (runs) | spread | L40S / H100 |
|---|---|---|---|---|---|
| b40_detailed | 6.654e10 (6.702, 6.605) | 1.5 % | 8.826e10 (8.851, 8.802) | 0.6 % | 1.33 |
| b50_detailed | 5.912e10 (5.945, 5.879) | 1.1 % | 7.746e10 (7.807, 7.685) | 1.6 % | 1.31 |
| **detailed score** | **33,056** (33,268, 32,843) | 1.3 % | **43,579** (43,810, 43,348) | 1.1 % | 1.32 |

## 3. Fixed join fields (`cubecl_cuda_join_throughput_fixed_fields`)

Starts: b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568. Each base gets a 1e14
warm-up first (untimed). "per field" is the harness's wall ÷ fields with 2 in flight. Slots = partitions per launch.

**Protocol (1 field):**

| field | card | per field (s) | rate (n/s) | setup / device (s) | slices × partitions | batches × slots | plan MiB | survivors | checked | found |
|---|---|---|---|---|---|---|---|---|---|---|
| b60 1e16 | H100 | 20.10 | 4.98e14 | 1.13 / 18.97 | 1 × 3600 | 600 × 6 | 2655 | 226,717,051,590 | 15,869,342,739 | 0 |
| b60 1e16 | L40S | 16.42 | 6.09e14 | 1.59 / 14.83 | 1 × 3600 | 600 × 6 | 2655 | 226,707,509,476 | 15,878,255,180 | 0 |
| b62 1e16 (2 runs) | H100 | 12.71, 12.72 | 7.87e14 | 0.86 / 11.86 | 1 × 3844 | 428 × 9 | 2858 | 117,141,275,114 / ...269,157 | 7,182,748,404 / ...754,292 | 0 |
| b62 1e16 (2 runs) | L40S | 10.56, 10.58 | 9.46e14 | 1.32–1.38 / 9.19–9.24 | 1 × 3844 | 428 × 9 | 2858 | 117,140,694,350 / ...690,293 | 7,183,293,005 / ...296,772 | 0 |
| **b62 1e17** (2 runs) | H100 | **103.84, 103.52** | 9.65e14 | 7.15–7.17 / 102.3–102.6 | 7 × 3844 | 3785 × 6 | 2594 | 1,020,747,882,005 / ...723,727 | 62,674,418,502 / ...569,351 | 0 |
| **b62 1e17** (2 runs, extra) | L40S | **81.40, 79.53** | 1.24e15 | 10.9–11.8 / 77.9–79.8 | 7 × 3844 | 3785 × 6 | 2594 | 1,020,737,015,457 / ...994,995 | 62,684,605,394 / ...630,456 | 0 |

**Like-for-like with the 3080 (2 fields per base, as L29 ran them; extra):**

| base, 1e16 × 2 | H100 per field | L40S per field | RTX 3080 180 W, L29 main 9bde4a8 (median of 3) | batches × slots (field 1 / 2) | plan MiB |
|---|---|---|---|---|---|
| b60 | 19.69 s | 15.69 s | 43.71 s | 600 × 6 / 600 × 6 | 2664 |
| b62 | 8.87 s | 7.37 s | 19.75 s | 428 × 9 / 241 × 16 | 2858 |
| b64 | 22.51 s | 18.60 s | 54.85 s | 410 × 10 / 410 × 10 | 3533 |

- L29's main (9bde4a8) differs from fae7398 by one changelog commit only, so the comparison is code-for-code.
- At 1e17, survivors and checks match the 3080's L29 b62 1e17 field (1,020,728,374,812 / 62,692,716,764) to 4–5 figures. These counts
  vary run to run on main at 1e16/1e17 (the stage overrun, as L29 notes); every run found 0 and re-ran 0 partitions.
- The 25-minute condition held: the H100's protocol 1e17 run started at 02:14, 62 min before the 03:16 cut-off.

## 4. Power, clocks, utilisation under load

`nvidia-smi dmon -s puc -o T -d 5` and a 5 s `--query-gpu` log (with throttle reasons) ran through every phase
(`raw/*/dmon*.log`, `raw/*/smi*.csv`). Summary, samples with ≥ 50 % utilisation (`raw/smi_h100.md`, `raw/smi_l40s.md`):

| phase | H100 SM MHz / W / max °C / flags | L40S SM MHz / W / max °C / flags |
|---|---|---|
| niceonly sweeps | 1400–1740 / 494–498 / 44 / SW power cap | 2180–2250 / 296–299 / 49 / SW power cap |
| detailed sweeps | 1845–1875 / 499 / 60 / SW power cap | 2520 (max) / 292–295 / 68 / none or SW power cap |
| b60/b62/b64 1e16 joins | 1575–1628 / 498–500 / 60 / SW power cap | 2115–2228 / 298–301 / 68 / SW power cap |
| **b62 1e17** (106 s / 84 s; dmon 21 / 16 samples) | **1552–1605 / 499 / 60**, sm 99 % | **2145–2190 / 299 / 69**, sm 98 % |

## Comparison: numbers per second and per dollar

Prices: H100 $2.140/h, L40S $0.539/h (listed), RTX 3080 $0.11–0.15/h, RTX 4090 $0.37–0.375/h. The 3080 join numbers
are L29 main on a 180 W-capped 3080. The 3080 NiceMark is 3711 (L29 main, 180 W; the 320 W card gave ~3705 on the L1 prune tree).
The 4090 numbers are 8086–9494 (L1.4, 330 W cap, older trees) and detailed 42,296 (L3.3, FD tree).
Detailed on a 320 W 3080 with FD (now main): 16,624 (L3.2).

| | H100 SXM | L40S | RTX 3080 | RTX 4090 |
|---|---|---|---|---|
| NiceMark nice-only | 8,349 | **10,245** | 3,711 (≈ 3700–4000) | 8,086–9,494 |
| NiceMark per $/h | 3,900 | 19,000 | **24,700–33,700** | 21,600–25,700 |
| NiceMark detailed | 33,056 | **43,579** | 16,624 (320 W) | 42,296 |
| detailed per $/h | 15,400 | 80,900 | **111,000–151,000** | 113,000 |
| b62 1e17: s per field | 103.7 | **80.5** | 229.3 (213 with #235) | – |
| b62 1e17: numbers/s | 9.65e14 | **1.24e15** | 4.36e14 | – |
| b62 1e17: numbers per $ | 1.62e18 | 8.30e18 | **1.05–1.43e19** | – |
| b62 1e17: $ per field | $0.0616 | $0.0120 | **$0.0070–0.0096** | – |
| b62 1e16 (2 fields): numbers per $ | 1.90e18 | 9.07e18 | 1.21–1.66e19 | – |
| b60 1e16 (2 fields): numbers per $ | 8.5e17 | 4.26e18 | 5.5–7.5e18 | – |
| b64 1e16 (2 fields): numbers per $ | 7.5e17 | 3.59e18 | 4.4–6.0e18 | – |
| per $ vs 3080 (b62 1e17) | 0.11–0.15× | 0.58–0.79× | 1 | – |
| break-even price vs a $0.11–0.15 3080 (b62 1e17) | $0.24–0.33/h | $0.31–0.43/h | – | – |

## Odd things

- **Host power caps on both boxes.** The H100 is limited to 500 W (default/max 700 W). It sat at 498–500 W in every loaded
  sample, flag 0x4 (SW power cap), with SM clocks 1550–1650 MHz in the join (max 1980). Its SW-power-capping counter
  was already ~55 h over its 6.4 days of uptime. It grew 640 s (10.7 min) between my snapshots at 02:04:52 and ~02:22, which is the whole loaded time.
  The L40S is limited to 300 W (default/max 350 W): 298–301 W and 2115–2230 MHz in the join (max 2520). It reached
  2520 MHz only in the detailed kernel. The most an uncapped card could gain is clock-bound:
  ≤ 1980/1600 ≈ 1.24× (H100) and ≤ 2520/2160 ≈ 1.17× (L40S). Neither closes the per-dollar gap. The 3080 reference was itself
  capped at 180 W, so an uncapped 3080 widens the gap.
- **No thermal limits:** max 60 °C (H100) and 69 °C (L40S); no HW/thermal slowdown counters. ECC is on for both (normal for these
  parts). MIG is disabled on the H100.
- **The H100 loses to the L40S** by 1.23× (NiceMark), 1.29× (b62 1e17) and 1.32× (detailed). The join and the detailed kernel are
  integer-ALU bound. At the cap, the H100 runs 132 SMs at ~1.6 GHz and the L40S 142 SMs at ~2.15 GHz (1.45× the SM-clocks).
  HBM3 bandwidth does not help here.
- **Big memory goes unused.** The join budget stops at `JOIN_MEMORY_MAX` = 4 GiB (`common/src/join_plan.rs`). Both cards
  plan the same layouts as any ≥ 16 GiB CUDA card (≤ 3.5 GiB; b62 1e17 = 7 slices, 3785 batches × 6 slots, 2594 MiB),
  while 46 / 80 GB sit idle. A larger cap on big cards would mean fewer slices at 1e17. Going from 5–7 slices to 1 at 1e16 was
  worth 1.07–1.17× per the constant's comment. **Untested here; a candidate, not a finding.**
- The L40S's host setup per 1e17 field is 10.9–11.8 s, against 7.2 s on the H100's EPYC. The L40S host's load average was 11.7
  with 70 runnable while our box was idle (co-tenants). Setup overlaps the device, so device ≈ wall, and it did not cost time here.
- b58_msd_strong is a 0.5 s scenario; its spread on the L40S (4.7 %) is the largest in the tables.

## Not done

- No uncapped-power runs: the host sets the limit, and I did not try `nvidia-smi -pl`.
- No 4090 b62 1e17 or 1e16 absolute times on file to compare with; the 4090 comparison is NiceMark only.
- Boxes were left running (idle since ~02:24 UTC). They self-destroy 1.5 h after creation, about 03:30.
