# G2 on the RX 9070 XT: operating point, preparation fixed, two protocols (demoux, 2026-11-18 13:36–14:30 UTC)

Brief: `G2/DEMOUX-BRIEF.md`. Raw logs: `G2/port/raw/window_1118b/` (measurement stretch in `m/`, the analysis in
`an_b_m.txt`, scripts in `scripts/`). The window run this follows: `G2/port/raw/window_1118/`.
Code: branch `g2-cubecl-local`, `4170a781` → **`ef54ed59`** (two commits, bundle `G2/port/g2-cubecl-demoux.bundle`,
ivory's worktree fast-forwarded, `G2/port/g2_cubecl.rs` a copy). Timed binary `g2z` (md5 `8801a739`); main's binary
is the window's (`e100c468`). Card: RADV GFX1201, Mesa 26.1.6, power cap 304 W (`power1_cap`).

**Labels.** [M] measured on the card today. Every time carries its clock / power: median sclk and power over the
0.5 s samples at ≥ 80 % busy, with the count of such samples.

## Results in one table

Ratio = main base mean / (G2 + tops and survivor checks), the window's formula. Main base mean 4.707 fs (the window's
ten fields; fields 2 and 6 re-run in this stretch, below); checks 0.115 × 4.707 / 6.347 = 0.085 fs.

| protocol | variant | G2 fs/adm (median of 4; min) | ratio (median; min) | clock, power (busy samples) |
|---|---|---|---|---|
| **pre-registered** (`t_`: GPU prep + full, synced per launch, 400 reps, the window's flags) | **D** | **0.9105** (0.9082) | **×4.73** (×4.74) | 2,773–2,852 MHz, 278–303 W (8 each) |
| | A | 0.9548 (0.9516) | ×4.53 (×4.54) | 2,481–2,855 MHz, 176–302 W (6–8) |
| same, 5 s warm-up, 3 s per mode, 2,000 reps (`wp_`, one run each) | D | 0.8866 | ×4.84 | 2,845 MHz, 303 W (58; 44 at ≥ 270 W) |
| | A | 0.9252 | ×4.66 | 2,867 MHz, 302 W (61; 43 at ≥ 270 W) |
| **pipelined** (`pp_`: 3,000 super-units' prep + full kernel with records queued, one sync, buffers reused, after 5 s warm-up) | **D** | **0.7692** (0.7675) | **×5.51** (×5.52) | 2,850–2,852 MHz, 303–304 W (62–63; 59–60 at ≥ 270 W) |
| | A | 0.8054 (0.8048) | ×5.28 (×5.29) | 2,866–2,872 MHz, 303 W (63–65; 59–61 at ≥ 270 W) |

- Main drifted **+1.2 %** this afternoon (fields 2 and 6 below). With the base mean scaled to 4.765 fs: pre-registered
  D ×4.78, pipelined D ×5.57.
- The window's numbers for comparison: D 1.114 fs → ×3.92 (prep 1.84 ms, full 3.13 ms, off point).
- Both protocols put D above the ×4.0 stop line; the pre-registered one by 18 %.
- **Which a client sees: the pipelined one.** A client queues super-units and synchronises rarely, so it pays
  neither the ~0.12 ms per synchronisation nor the clock dips of a card that idles between launches. Not in the
  pipelined number: the host's upload of each super-unit's tops (≈ 1.9 MB, ≈ 0.1 ms over PCIe, overlappable) and a
  cold first read of each super-unit's data (every super-unit here is the same one, so ~20 MB of tops/parents may be
  warm in the 64 MB Infinity Cache; ≈ 0.03 ms at DRAM bandwidth). Records stay on the card, as the formula assumes
  (their consumers are the 0.085 fs).

## The operating point [M]

- **Under G2 the card is power-limited, not clock-limited.** Every sustained G2 load (pipelined, warm synced) sits at
  **2,850–2,870 MHz and 303–304 W**, the 304 W cap; main sits at 3,111–3,150 MHz at the same 304 W. G2 draws more
  power per clock. So "≥ 97 % of 3,150 MHz" (3,055) is not reachable for G2 on this card: 10–12 samples per pipelined
  run reach it, at the start of the warm-up. **The brief's criterion is met in power (59–61 samples ≥ 270 W per
  pipelined run), and 2.85 GHz at the cap is the card's real operating point for this kernel.** Main's four fields:
  176–192 samples each at ≥ 3,055 MHz and ≥ 270 W.
- **The kernel's time does depend on the clock.** One run (`w1_D`, after a 6 s warm-up and the synced per-launch
  profiling) dropped to **1,560 MHz, ~82 W, busy ~80 %** and stayed there for the remaining ~45 s of synced launches: full
  7.04 ms, skip-off 7.44, probes-off 3.40, against 3.14 / 3.51 / 1.91 at 2.85 GHz (×2.2 for ×1.83 of clock; the
  memory clock probably dropped too). The window's "times barely move with the clock" came from short bursts whose
  few samples did not describe the launches timed.
- **Governor behaviour:** a phase of many short synchronised launches (the per-launch profiling) can leave the card in
  that low state (BOOTUP_DEFAULT profile, `power_dpm_force_performance_level` auto) even under the sustained load that
  follows. A warm-up of queued work (`--warm`) did not; the `wp_` runs held 2.85 GHz for 2,000 synced reps.

## What a launch costs [M] (`lat1.log`, `m/lat2.log`; trivial kernel, one cube of 64)

| | 1 binding | 12 bindings |
|---|---|---|
| launch + `client.sync()`, wall | 112–122 µs | 115–125 µs |
| queued (2,000 launches, one sync), wall per launch | 8.2–8.7 µs | 6.8–7.1 µs |
| device (timestamp queries), one launch | 1.0 µs | 1.2–1.3 µs |
| `client.sync()` with nothing queued | 10 µs | |

- A synchronised launch costs ~0.12 ms of wall clock on CubeCL/wgpu/RADV; a queued launch ~7–9 µs of host time,
  ~1 µs on the device. **The five launches of the preparation are not the problem**; in the synced protocol each rep
  carries one ~0.12 ms synchronisation.
- CubeCL's device-timestamp span over many submissions is not usable on this stack: it read 0.016 ms per super-unit
  for a 3.4 ms pipelined super-unit. Per-launch spans agree with wall clock (chain of 5: device 768 µs, queued
  788 µs).

## The preparation: what the 1.84 ms was, what it is [M]

Per launch, each synced alone, device timestamps (µs; `pp_p0.log`, `pp_p1.log`, `pp4_r2.log`). These ran at the low
state the synced profiling leaves the card in (~1,560–1,590 MHz), so they are 1.8× the operating-point cost; the
proportions hold.

| launch | window (`4170a781`) | now (`ef54ed59`) | what changed |
|---|---|---|---|
| tdig (+ zeroing) | 17.9 | 18.0 | also zeroes the bucket counts, the list count and a slab counter (`--prep3 1`): no host upload per preparation |
| hist (one root pass + list) | 342 | 341 | unchanged (9.3M roots × `parent()`; the model's 0.17 ms at 3.1 GHz fits) |
| scan (one cube) | 45.9 | 29.2 | 1,008 threads × 16 buckets instead of 256 × 63 (`--scan 1`) |
| scatter | 75.4 | 76.2 | unchanged |
| **bucket sort** | **1,146** | **301** | **`--rsort 2`: one cube of 256 per bucket; rank sort from shared memory 4 keys per step for ≤ 256 parents, a bitonic sort of (r4, index) above** |
| chain of 5 | 1,658 | 768 | |

- **The 1.84 ms was device work, and 62 % of it the per-bucket rank sort**: n² compares per bucket in one cube of 64
  (178M compares in all; 34 of the 16,128 buckets hold ≥ 512 parents, the largest 573), latency-bound in a single
  wave. Not launches, not a host round trip: nothing is read back between the five launches; the host's only acts were
  two buffer uploads before each preparation, outside the timed span (now done on the device).
- Bucket sizes (super-unit 712012851): < 8: 2,333; < 16: 2,239; < 32: 3,276; < 64: 2,694; < 128: 3,321; < 256: 1,771;
  < 512: 460; ≥ 512: 34. `--rsort 1` (bitonic for all) gave 430 µs; the hybrid 301 µs.
- **At the operating point (queued, 2.85 GHz, 304 W): 0.416–0.427 ms per preparation**, inside the model's
  0.15–0.45 ms. Synced: 0.93 ms in the pre-registered runs (first GPU work of the process, cold card, plus the
  ~0.12 ms sync), 0.55 ms after a 5 s warm-up, 0.81–0.82 ms in the `wp_` runs.
- What is left: the root pass (≈ 0.19 ms at the operating point, ≈ 45 %) and the sort (≈ 0.17 ms).

## Components at the operating point [M] (pipelined, each queued ~1,060 times, one sync; ms per launch, median of 4 runs)

| variant | prep | probes off | skip off | full, no records | full | pipe (prep + full) |
|---|---|---|---|---|---|---|
| D | 0.425 | 0.928 | 3.295 | 2.718 | 3.035 | 3.436 = 0.769 fs |
| A | 0.426 | 1.098 | 3.475 | 2.884 | 3.191 | 3.598 = 0.805 fs |

- Counts equal K × the CPU reference in every component run, and K × a single unit's (equal to the CPU's) in every
  pipe run.
- The model's kernel bound was 2.15 ms at 3.1 GHz, 2.9 ms at its central efficiency 0.75. Measured full 3.04 ms at
  2.85 GHz ≈ 2.79 ms at 3.1 GHz clock-scaled: efficiency ≈ 0.77, central. The ×6.4 prediction missed by the clock
  (−8 % at the power cap) and by efficiency, not by the preparation any more.
- D (`--tdig 1`) beats A by 0.17 ms, all of it before the probes (probes-off 0.93 against 1.10); the model said
  −0.07 ms. **D is the client's form on this card.**
- **Records cost 0.32 ms (full − full without records) and that is DRAM write bandwidth**: 10.93M records × 16 B =
  175 MB per super-unit, 0.32 ms ≈ 550 GB/s against the card's 640 GB/s. Halving the record (8 B: unit/probe 16 bits,
  parent index 20 bits, one word half and a bit position, …) would save ≈ 0.15 ms ≈ 0.034 fs (≈ +4 % of ratio); it
  changes what the survivor-check kernels read, so it is a design decision, not a tweak. Not built.

## Main's bracket [M] (`m/main_f*.log`)

| field | morning (window) | 14:06 | 14:23 | clock, power |
|---|---|---|---|---|
| 2 | 90.83 s | 92.29 s | 92.45 s | 3,134–3,150 MHz, 304 W |
| 6 | 100.41 s | 100.31 s | 102.17 s | 3,111–3,116 MHz, 304 W |

Survivors and checked equal the window's in all four. Sum of the means +1.24 % against the morning: within main's
noise band in the plan (±8 % for the mix), so 4.707 fs is kept as the base; the scaled 4.765 fs gives the ratios
in the note under the table.

## Exactness [M]

- **Card (W = 64), build `g2y` (= `g2z` minus the pipe's counter split): `x_A_su1`, `x_A_su2`, `x_D_su1`, `x_D_su2`
  ALL CHECKS PASSED** with the new preparation: every unit's survivor set equals the prototype's, counts equal the
  CPU's, the GPU preparation's records, order, class segments and top digits equal the CPU's (both super-units: the
  largest buckets 573 and 554 go through the bitonic path).
- Every timing run of the stretch (32 G2 runs) passed its count checks; every pipelined run checked K × counts.
- `--rsort 1` and `--prep3 0` / `--rsort 0` also exact on the card (`pp3_p1`, `pp4_r1`, `pp_p0`).
- **lavapipe on demoux (Mesa 26.1.6, W = 8, `lvp_icd.json`): GPU preparation equal to the CPU's, 128 jobs' sets and
  counts equal (`x_lvp_su1.log`).** So the new prep kernels are proven at W = 8 and 64; W = 16 / 32 not re-run (the
  main kernel is unchanged).

## What is not proven

- The pipelined number repeats one super-unit; per-super-unit uploads and cold reads are estimated (≈ 0.1 ms,
  overlappable), not measured.
- The operating point is the power cap at 2.85 GHz; nothing here says how G2 behaves on a card with a different
  power limit, or in a case running warmer than 45–56 °C.
- The pre-registered protocol is still short bursts (8 busy samples per run); its ratio is reported as the rule
  requires, beside the warm and the pipelined ones.
- Second super-unit timed only in the short pipelined check (`x_Dpipe_su2`: 3.435 ms, same as the first).

## Distinct super-units (demoux, 2026-11-18 14:37–14:56 UTC)

Follow-up task from the director. Raw logs in `G2/port/raw/window_1118d/` (`an_b_d.txt` is the table,
`per_unit_checks.txt` has the per-unit checks, `meta/` has the 16 units' meta files; no staged data went to ivory).
Code: `51a386f` (`--multi LIST`, `scatter3_kernel`) and `1313018a` (`--no-upload`), bundle re-created, ivory's
worktree fast-forwarded. The binaries were `g2m` (`08fb75ce`) and `g2n` (`612ada0a`, the same plus `--no-upload`).
The same-unit pipe used `g2z` (`8801a739`), as before.

**Staging [M].** I added `g2proto dumptops b f0 k pip dir` to a copy of `G2/bases/proto` in the workspace. It is
dumpsu without the bottoms and the scalar join; the source is in `scripts/g2proto_main_with_dumptops.rs`. It takes
2.5 s per super-unit. Its tops are byte-identical to the staged `su64_712012851` and `su64_391856203`.
- **N = 16 distinct base-64 super-units:** the two staged ones plus 14 π′ drawn with distinct digits, one per leading
  digit band 2, 7, 11, …, 61 of π′ (seed 20261118).
- Every unit has 238,347–239,698 tops and 1,040,227–1,044,431 parents. Survivors per unit range over
  11,742,386–11,806,353.
- **Per-unit CPU reference counts** come from the binary's own CPU reference (`cpu_job`), the same reference every
  earlier run checked against. They are not the prototype's survivor sets, which were not dumped. Only the two staged
  units also have prototype-verified sets (earlier runs).

**The client-like run (`--multi`).**
- One exactness cycle: per unit, its GPU preparation is checked against the host's (records, order, class segments,
  top digits, list count), then its counts are read back and checked against its CPU reference.
- A 5 s warm-up.
- 360 timed cycles over the 16 units, 5,760 super-units in all. For each unit the host uploads its input: top masks,
  top segments and key digits, 1.94 MB, as new buffers through `client.create`, because CubeCL 0.10 has no write into
  an existing buffer. It then queues the unit's preparation and the full kernel with records.
- One synchronisation per cycle, i.e. per 16 units. Every other buffer is allocated once.
- The scatter reads the list length on the device, so the host never needs a unit's parent count.
- Each unit's counters accumulate in its own buffer and are checked at the end against (1 + 360) × its CPU reference.

**Exactness [M]: every unit equal, in every run.** 9 multi runs × 16 units: the preparation is equal in all 144
exactness checks and the counts in all 144 single-pass checks. Every cumulative (1 + C) × check is equal. Kernel
error counters are 0.

| run (D unless marked) | units | per-unit upload | ms per super-unit | fs/adm | ratio (4.707 + 0.085) | clock, power (busy; ≥ 270 W) |
|---|---|---|---|---|---|---|
| **`mu16` r1 / r2 / r3** | **16 distinct** | **yes** | 3.710 / 3.705 / 3.738 | **0.8303** (median; 0.8294–0.8367) | **×5.14** | 2,899–2,916 MHz, 303 W (52; 49–50) |
| `mu1x16` r1 / r2 | 712012851 × 16 | yes | 3.699 / 3.704 | 0.8285 | ×5.15 | 2,901–2,902 MHz, 303 W (50–52; 49–50) |
| `nu16` r1 / r2 | 16 distinct | no (resident) | 3.453 / 3.463 | 0.7739 | ×5.48 | 2,847–2,858 MHz, 303–304 W (49; 47–48) |
| `nu1x16` r1 | 712012851 × 16 | no | 3.463 | 0.7752 | ×5.47 | 2,849 MHz, 304 W (49; 49) |
| `pp` r1 / r2 (same-unit pipe, as before, K = 6,000) | 712012851 | no | 3.447 / 3.449 | 0.7717 | ×5.49 | 2,843–2,845 MHz, 304 W (60–61; 57) |
| `mu16` A | 16 distinct | yes | 3.863 | 0.8647 | ×4.96 | 2,924 MHz, 303 W (54; 51) |

Main field 6, in the same stretch: 100.44 s at 3,135 MHz and 304 W. Today's earlier runs were 100.41, 100.31,
102.17 and 101.44 s, so the base mean stays at 4.707.

- **Distinct units cost the same as one unit repeated.** With inputs resident, 16 distinct units run at 0.7739 fs
  against 0.7717 fs for the same-unit pipe, +0.3 %. With uploads, distinct and repeated units give the same number.
  Cache warmth is not a factor.
- **The per-unit upload is what costs: +0.26–0.29 ms per super-unit (+7 %), ×5.49 → ×5.14.**
  - The host spends 0.62–0.73 ms per unit in `client.create` for 1.94 MB, and 0.75–0.83 ms per unit in all its
    queueing, against 3.7 ms of GPU time. So the host keeps up, and the cost is on the device side.
  - The copy goes through wgpu's staging write in the same queue, ahead of the unit's kernels, so it does not overlap
    compute. The card idles slightly: its clock rises from about 2,850 to 2,900–2,920 MHz at the same 303 W.
  - 1.94 MB in 0.27 ms is about 7 GB/s, far below the PCIe link.
- **Which number a client would see:** ×5.14 for a CubeCL client written this way (create per unit, one queue).
  About ×5.48 for a client that hides the upload: a separate transfer queue or a mapped double buffer, which CubeCL
  0.10 does not expose. The difference is one engineering item for the client, not a property of the kernel.
- A is ×4.96 on distinct units with uploads, 0.034 fs behind D, as on the single unit.
- Not shown: survivor *sets* on the 14 new units (counts only, as asked); `--multi` with `--tdig 0` / other plane
  widths (D and A at W = 64 only).
