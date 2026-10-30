# LAUNCH-RESULTS: bottom buffers sized by the pruned list, more partitions per launch (2026-10-30)

Branch `pr/join-partitions-per-launch` on the fork, head `c4ac700`, two commits on upstream main `d1ff798`:
- `2451be1` test-only `NICE_TEST_JOIN_MAX_BUFFER` (stands in for the device's largest buffer in the join's tests, so the 20 GB card can plan as a 10 GB one);
- `c4ac700` the change: `Footprint` sizes the bottom-side buffers by the slice's pruned list (`fs.bp_r`), slices are still cut by the unpruned length, the cap goes 16 → 64, and a plan never exceeds the field's partitions; unit test `bottom_buffers_follow_each_slices_pruned_list`; CHANGELOG line.

Raw logs: `launch-raw/box/`. Scripts: `launch-raw/*.sh`, analysis `launch-raw/analyze.py` and `launch-raw/analyze_race.py` (`python3 launch-raw/analyze.py launch-raw/box`).

**Summary**
- **1e14 (production), 10 GB budget (primary):** ×0.881 / 0.868 / 0.793 / 0.832 device-wall per field at b58/60/62/64 (1.14–1.26× faster), 16 → 64 partitions per launch, 211–256 → 53–64 batches, plans 1.2–1.4 → 2.0–2.5 GiB of the 2.5 GiB budget. 20 GB budget: ×0.899 / 0.868 / 0.787 / 0.826.
- **Cap choice:** "as many as fit" (105–111 at the 10 GB budget, 171–177 at 4 GiB) was measured first and is 1–4 % slower than 64; the sweep 16 / 32 / 64 / 96 / 128 / max has its minimum at 64 at every base.
- **1e16:** no change beyond noise: ×0.999 / 1.011 / 1.003 / 0.992 (10 GB budget, 3 rounds), ×0.988 / 1.002 / 1.000 / 1.008 (20 GB, 2 rounds). Layouts are survivor-bound and identical, except b62 at 20 GB (16 → 22 per launch on one field); plans 3–11 % smaller.
- **NiceMark nice-only** (card's own budget): score 4688 → 4698 (×1.002); scenarios ×0.969 (b58 msd-weak 1e15, 16 → 50 per launch), ×1.046 (b58 msd-strong), ×0.982 (b60, identical layout), ×1.018 (b62). Checked with the harness on 1e15 fields (NiceMark's b58 scenarios are 1e15 at the A/B start): ×1.018 / 1.002 / 0.986 / 0.976 (10 GB) and ×1.012 / 0.998 / 0.985 / 1.005 (20 GB), i.e. neutral, with b58 1–2 % slower (32–51 per launch).
- **The extra full checks (the 0.4 % seen once at 64):** a race in `join_kernel`'s per-chunk flush decision, not stage overruns. Without a barrier between the read of the stage count and the next chunk's appends, a slow plane can decide alone to flush; the cube's barriers then pair at different call sites. 10 of the 98 base-runs at ≥ 64 partitions per launch without that barrier counted 0.4 M–77 M (0.01–2.1 %) full checks beyond what the overrun explains; 0 of the 18 base-runs at ≥ 64 with the barrier did (24 at any count), and the planes-per-flush counter never mismatched with it (it mismatched in 9 of 50 instrumented runs without it). More partitions per launch make it frequent because cubes start to grid-stride over several work items (above 16–19 per launch at b58–64), so the stage carries survivors across work items and the count is often near the flush level at a chunk boundary. The barrier's cost is within noise but not resolved: 0 to about 2.5 % at 1e14 (instrumented, 3 rounds: ×0.989–1.002; clean build, 2 rounds: ×0.998–1.025) and up to about 1.5 % at 1e16 (instrumented, 3 rounds: ×0.987–1.009 against the PR; clean build, 1 round: ×1.000–1.015).
- **Exactness** (final code `40d6a26`; the head `c4ac700` changes one doc comment): host tests 209 passed; CUDA parity (windows, tight layouts, slices, refusals, production shape; whole b42 field) pass; dense-field tests pass at b58 1e15 (64 partitions, 0 overran), b64 1e16 (8, 2.7e-5) and b64 1e14 (1024 partitions at 64 per launch, 5.7e-6); join = stride on 5 × 1e14 per base; counters equal main's to within the overrun in every A/B run; no hits anywhere (these fields hold none). fmt and clippy (default and `nice_client/gpu`) clean. The PR with the barrier (`rp/launch-with-barrier`, `4f153aa`) passes the CUDA parity test and the b58 1e15 / b64 1e14 dense-field tests too.

## 0. Setup

- **Box:** Vast 58361499 (`nice-research-l20-launch`), RTX 3080 **20 GB** (20480 MiB; the rental filter did not take 10 GB), driver 595.91.07, CUDA 12.8 toolkit. Power limit 320 W = default = max (`box/box-info.txt`): not capped by the host. Under load (15 s `nvidia-smi` samples, `*.smi`): 1845–1950 MHz, 308–318 W, 77–79 °C, throttle flag 0x4 (SW power cap). Host: Xeon E5-2682 v4, cgroup quota 15.4 CPUs (`cpu.max 1536000 100000`).
- **Budgets.** `JoinLimits::for_buffer(max_page_size)`; CubeCL's CUDA runtime reports `max_page_size` = a quarter of `cuDeviceTotalMem`. This card: 5 GiB → budget 4 GiB (`JOIN_MEMORY_MAX`), list 1 GiB. **B10** = `NICE_TEST_JOIN_MAX_BUFFER=2684354560` (a 10 GB card's quarter, 2560 MiB) → budget 2.5 GiB, list 640 MiB. **B20** = the card's own. The override changes only the join's planning; CubeCL's own memory pools are still the 20 GB card's (so the `nvidia-smi` memory figures under B10 are not a 10 GB card's).
- **Trees and binaries** (`box/md5_*.txt`), all `cargo test --release -p nice_common --features gpu --no-run` / `cargo build --release -p nice_client --features gpu`:
  - **main** = `553082a` (upstream `d1ff798` + the harness commit `2451be1` cherry-picked): test `6b65c3c7`, client `9c72bca0`.
  - **pr64** = `e83133e` (the PR with the cap at 64; non-test code identical to the final head `c4ac700`, which adds only test prints, doc wording and the CHANGELOG): test `e6a3ced0`, client `0808e7ec`. Called "PR" below.
  - **prmax** = `84f58de` (first version: pruned sizing, cap 65,535, i.e. as many as fit): test `7a81e38c`, client `fb2e12f3`. The `e14_*_pr_*` logs.
  - **prfinal** = `40d6a26` (final code; built by `exact.sh`): test `fb43b359`, client `d929bedf`. **prb** = `4f153aa` (`40d6a26` + the barrier `61e6ba9`, fork `rp/launch-with-barrier`): test `12044c3c`.
  - **exp** = `c55bbb6` (`84f58de` + `766eb68`'s overrun counter + `NICE_EXP_SLOTS` cap, a planes-per-flush counter and `NICE_EXP_FLUSH_SYNC=1`, the barrier): test `d6d623bc`.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields`, after a 1e14 warm-up per base, the A/B starts (b58 104400216587923470200, b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568). `launch-raw/run.sh`:

  ```
  env [NICE_TEST_JOIN_MAX_BUFFER=2684354560] [NICE_EXP_...] NICE_TEST_JOIN_FIELDS={20|2} NICE_TEST_JOIN_SIZE={1e14|1e16} NICE_TEST_JOIN_BASES=58,60,62,64 \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    /root/bin/<tree>/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
  ```
  "s/field" is the harness's `per_field` (wall per field, two fields in flight); `dev` (device seconds) tracks it within 0.5 %.
- **Order** (all UTC): `ab14.sh` (prmax, 06:53–07:06), `sweep.sh` (07:06–07:18), `counters.sh` (07:18–07:24), `ab14b.sh` (pr64, 07:26–07:38), `race2.sh` (07:38–07:44), `ab16.sh B10` (main / pr / barrier, 07:44–08:28), `nicemark.sh` (08:28–08:33; each run took ~45 s: the 150 s is a budget the scenarios did not need), `ab16.sh B20 2` (08:33–08:52), `exact.sh pr` (build, then tests 08:58–09:11, lint beside it), `race3.sh` (09:11–09:16), `e15.sh` (09:16–09:25), `barrier2.sh` (build 08:59–09:11 beside the exactness tests; GPU 09:25–09:30), `prb_ab.sh` (09:30–09:44). Interleaved A B A B A B within each script. Chain scripts: `chain5.sh` (with `chain.sh`–`chain4.sh` its aborted predecessors).
- **Incidents:** the first chain started before the experiment binary was staged, and the counters script had a quoting bug (an expanded `NAME=value` ran as a command); both counter attempts (06:53, 07:06) failed instantly without GPU work, and the study ran at 07:18. No overlapping GPU runs. Builds ran while GPU runs were going only during the counter study (07:18–07:26, the pr64 build), which is not a timing comparison.

## 1. Layouts

| budget | base | main: per launch / batches / plan MiB | PR (cap 64) | first version (as many as fit) |
|---|---|---|---|---|
| 10 GB (2.5 GiB) | 58 | 16 / 211 / 1234 | 64 / 53 / 2049 | 109 / 36 / 2559 |
| 10 GB | 60 | 16 / 214 / 1226 | 64 / 54 / 2536 | 106 / 37 / 2557 |
| 10 GB | 62 | 16 / 241 / 1381 | 64 / 61 / 2176 | 111 / 42 / 2559 |
| 10 GB | 64 | 16 / 256 / 1426 | 64 / 64 / 2236 | 107 / 46 / 2556 |
| 20 GB (4 GiB) | 58 | 16 / 211 / 1618 | 64 / 53 / 2433 | 175 / 22 / 4095 |
| 20 GB | 60 | 16 / 214 / 1610 | 64 / 54 / 3153 | 171 / 23 / 4095 |
| 20 GB | 62 | 16 / 241 / 1765 | 64 / 61 / 2560 | 177 / 26 / 4095 |
| 20 GB | 64 | 16 / 256 / 1810 | 64 / 64 / 2620 | 171 / 28 / 4095 |

1e14, 20 fields per base; plan MiB is the largest of the 20 fields' first-slice plans. Process GPU memory (`nvidia-smi` peak, includes the stride pipeline and CubeCL's pools): B10 main 6945 MiB, PR 7137, first version 7361; B20 main 8225, PR 8385, first version 8993.

Unit test (`join_plan::tests::bottom_buffers_follow_each_slices_pruned_list`, the `PLAN_FIELDS` 1e14 fields, 10 GB budget): 64 per launch at b57/60/62/64 in 1750 / 1752 / 1831 / 2114 MiB, where the unpruned sizing fits 54 / 55 / 41 / 39. With the 1 GiB budget (`production_fields_get_the_full_layout`): 64 (b42), 29 (b50), 51 / 51 / 48 / 38 (b57/60/62/64). Kept bottoms (pruned / unpruned `bpre`) on those fields: b57 54,885 / 133,645 (41 %), b60 66,634 / 137,775 (48 %), b62 65,394 / 176,671 (37 %), b64 78,784 / 180,003 (44 %).

## 2. 1e14 A/B (production size)

**The PR (cap 64) against main**, 3 interleaved rounds per budget (`ab14b.sh`, logs `f14_{B10,B20}_{main,pr64}_r{1,2,3}`). Spread = (max − min) / median.

#### 10 GB budget (primary)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **0.705** (0.674, 0.705, 0.708) | 4.8 % | **0.621** (0.625, 0.620, 0.621) | 0.8 % | **×0.881** | 16 → 64 | 211 → 53 | 1234 → 2049 |
| 60 | **0.597** (0.593, 0.600, 0.597) | 1.2 % | **0.518** (0.514, 0.520, 0.518) | 1.2 % | **×0.868** | 16 → 64 | 214 → 54 | 1226 → 2536 |
| 62 | **0.579** (0.569, 0.579, 0.582) | 2.2 % | **0.459** (0.459, 0.458, 0.460) | 0.4 % | **×0.793** | 16 → 64 | 241 → 61 | 1381 → 2176 |
| 64 | **0.686** (0.682, 0.688, 0.686) | 0.9 % | **0.571** (0.576, 0.565, 0.571) | 1.9 % | **×0.832** | 16 → 64 | 256 → 64 | 1426 → 2236 |

Peak nvidia-smi memory.used (MiB) per run: main: [6945, 6945, 6945]; pr64: [7137, 7137, 7137]

Counters (survivors / checked / found) per run:

- b58 main: 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0
- b58 pr64: 65276511371 / 3681958713 / 0; 65276511410 / 3681958676 / 0; 65276511384 / 3681958702 / 0
- b60 main: 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0
- b60 pr64: 45679550365 / 3059973005 / 0; 45679550365 / 3059972974 / 0; 45679550365 / 3059972985 / 0
- b62 main: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b62 pr64: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b64 main: 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0
- b64 pr64: 65747000631 / 4000027504 / 0; 65747001408 / 4000026675 / 0; 65747001500 / 4000026687 / 0

#### 20 GB budget (this card)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **0.700** (0.700, 0.692, 0.705) | 1.9 % | **0.629** (0.629, 0.630, 0.629) | 0.2 % | **×0.899** | 16 → 64 | 211 → 53 | 1618 → 2433 |
| 60 | **0.597** (0.605, 0.597, 0.596) | 1.5 % | **0.518** (0.518, 0.520, 0.516) | 0.8 % | **×0.868** | 16 → 64 | 214 → 54 | 1610 → 3153 |
| 62 | **0.581** (0.585, 0.574, 0.581) | 1.9 % | **0.457** (0.459, 0.452, 0.457) | 1.5 % | **×0.787** | 16 → 64 | 241 → 61 | 1765 → 2560 |
| 64 | **0.688** (0.686, 0.688, 0.689) | 0.4 % | **0.568** (0.577, 0.567, 0.568) | 1.8 % | **×0.826** | 16 → 64 | 256 → 64 | 1810 → 2620 |

Peak nvidia-smi memory.used (MiB) per run: main: [8225, 8225, 8225]; pr64: [8385, 8385, 8385]

Counters (survivors / checked / found) per run:

- b58 main: 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0
- b58 pr64: 65276511381 / 3681958701 / 0; 65276511361 / 3681958720 / 0; 65276511374 / 3681958709 / 0
- b60 main: 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0
- b60 pr64: 45679550365 / 3059972983 / 0; 45679550365 / 3059973002 / 0; 45679550365 / 3059972985 / 0
- b62 main: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b62 pr64: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b64 main: 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0
- b64 pr64: 65747001680 / 4000026538 / 0; 65747001107 / 4000026913 / 0; 65747000943 / 4000027363 / 0

**The first version (as many as fit) against main** (`ab14.sh`, logs `e14_{B10,B20}_{main,pr}_r*`), for the cap decision:

#### 10 GB budget

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **0.705** (0.673, 0.707, 0.705) | 4.8 % | **0.631** (0.623, 0.631, 0.632) | 1.4 % | **×0.895** | 16 → 109 | 211 → 36 | 1234 → 2559 |
| 60 | **0.599** (0.592, 0.602, 0.599) | 1.7 % | **0.525** (0.520, 0.525, 0.526) | 1.1 % | **×0.876** | 16 → 106 | 214 → 37 | 1226 → 2557 |
| 62 | **0.579** (0.578, 0.579, 0.588) | 1.7 % | **0.464** (0.462, 0.465, 0.464) | 0.6 % | **×0.801** | 16 → 111 | 241 → 42 | 1381 → 2559 |
| 64 | **0.684** (0.683, 0.686, 0.684) | 0.4 % | **0.576** (0.576, 0.571, 0.578) | 1.2 % | **×0.842** | 16 → 107 | 256 → 46 | 1426 → 2556 |

Peak nvidia-smi memory.used (MiB) per run: main: [6945, 6945, 6945]; pr: [7361, 7361, 7361]

Counters (survivors / checked / found) per run:

- b58 main: 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0
- b58 pr: 65276511274 / 3681958726 / 0; 65276511321 / 3681958760 / 0; 65276511300 / 3741336352 / 0
- b60 main: 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0
- b60 pr: 45679550530 / 3059972840 / 0; 45679550530 / 3059972838 / 0; 45679550530 / 3059972834 / 0
- b62 main: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b62 pr: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b64 main: 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0
- b64 pr: 65746997680 / 4000030080 / 0; 65746998212 / 4000029541 / 0; 65746998826 / 4000943449 / 0

#### 20 GB budget

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **0.704** (0.704, 0.693, 0.706) | 1.8 % | **0.636** (0.635, 0.637, 0.636) | 0.3 % | **×0.903** | 16 → 175 | 211 → 22 | 1618 → 4095 |
| 60 | **0.597** (0.594, 0.603, 0.597) | 1.5 % | **0.529** (0.531, 0.529, 0.527) | 0.8 % | **×0.886** | 16 → 171 | 214 → 23 | 1610 → 4095 |
| 62 | **0.574** (0.554, 0.579, 0.574) | 4.4 % | **0.476** (0.476, 0.475, 0.476) | 0.2 % | **×0.829** | 16 → 177 | 241 → 26 | 1765 → 4095 |
| 64 | **0.677** (0.677, 0.669, 0.691) | 3.2 % | **0.575** (0.581, 0.575, 0.573) | 1.4 % | **×0.849** | 16 → 171 | 256 → 28 | 1810 → 4095 |

Peak nvidia-smi memory.used (MiB) per run: main: [8225, 8225, 8225]; pr: [8993, 8993, 8993]

Counters (survivors / checked / found) per run:

- b58 main: 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0; 65276511454 / 3681958634 / 0
- b58 pr: 65276511312 / 3681958773 / 0; 65276511376 / 3681958707 / 0; 65276511182 / 3681958735 / 0
- b60 main: 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0; 45679552353 / 3059971138 / 0
- b60 pr: 45679550543 / 3059972820 / 0; 45679550543 / 3059972829 / 0; 45679550543 / 3059972825 / 0
- b62 main: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b62 pr: 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0; 24394574150 / 1494977611 / 0
- b64 main: 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0; 65747036999 / 3999993450 / 0
- b64 pr: 65746994352 / 4000033156 / 0; 65746994277 / 4000033286 / 0; 65746993737 / 4000715732 / 0

## 3. Partitions per launch: the sweep

`sweep.sh`: the exp binary with `NICE_EXP_SLOTS` = 16 / 32 / 64 / 96 / 128 / unset (as many as fit), 1e14, 20 fields per base, this card's budget (4 GiB, so every cap fits), 2 interleaved rounds, no barrier. Cells: median s/field (rounds; partitions per launch).

| cap | b58 s/field | b60 | b62 | b64 | planes mismatch (d) per base, r1; r2 | full checks beyond the overrun, r1; r2 |
|---|---|---|---|---|---|---|
| 16 | 0.704 (0.701, 0.706; 16) | 0.607 (0.604, 0.609; 16) | 0.574 (0.585, 0.563; 16) | 0.687 (0.682, 0.692; 16) | 0 0 0 0; 0 0 0 0 | +0 +0 +0 +0; +0 +0 +0 +0 |
| 32 | 0.645 (0.647, 0.644; 32) | 0.536 (0.539, 0.533; 32) | 0.481 (0.487, 0.476; 32) | 0.597 (0.595, 0.600; 32) | 0 0 0 0; 0 0 0 0 | -1 +0 +0 -1116; -1 +0 +0 -1142 |
| 64 | 0.626 (0.621, 0.631; 64) | 0.518 (0.519, 0.517; 64) | 0.460 (0.460, 0.459; 64) | 0.575 (0.572, 0.577; 64) | 0 0 0 0; 0 0 0 2 | -116 -156 +0 -2223; -1 -138 +0 -2251 |
| 96 | 0.631 (0.630, 0.633; 96) | 0.524 (0.523, 0.526; 96) | 0.466 (0.468, 0.464; 96) | 0.579 (0.581, 0.578; 96) | 6 0 0 0; 0 0 0 0 | +77336977 -158 +0 -2826; -5 -132 +0 -2591 |
| 128 | 0.627 (0.626, 0.627; 128) | 0.530 (0.530, 0.530; 128) | 0.474 (0.472, 0.477; 128) | 0.584 (0.583, 0.585; 128) | 0 0 0 3; 0 0 0 2 | -92 -149 +0 -3042; -10 -157 +0 +395523 |
| max | 0.639 (0.637, 0.640; 175) | 0.530 (0.530, 0.531; 171) | 0.478 (0.477, 0.479; 177) | 0.583 (0.583, 0.582; 171) | 0 0 0 0; 0 0 0 21 | -8 -121 +0 -2710; -11 -119 +0 +34473302 |

64 is the minimum at every base (b58 0.626, b60 0.518, b62 0.460, b64 0.575); 96 is +0.7–1.3 %, 128 +0.2–3.0 %, as many as fit +1.4–3.9 %. The pruned sizing alone (row 16) runs at main's speed (main at 16 under this budget, `f14_B20_main_*`: 0.700 / 0.597 / 0.581 / 0.688), so the slowdown above 64 is not allocation churn; it is not profiled. The uncapped A/B (section 2, second half) agrees: 1–4 % slower than the cap's.

## 4. 1e16 A/B

#### 10 GB budget: main against the PR (`ab16.sh B10`, 3 rounds)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **46.799** (46.799, 46.613, 47.030) | 0.9 % | **46.731** (45.941, 46.731, 46.758) | 1.7 % | **×0.999** | 5 → 5 | 1010 → 1010 | 1877 → 1823 |
| 60 | **34.703** (34.647, 35.266, 34.703) | 1.8 % | **35.092** (35.092, 35.140, 34.749) | 1.1 % | **×1.011** | 4 → 4 | 1350 → 1350 | 1596 → 1561 |
| 62 | **15.722** (15.722, 15.562, 15.769) | 1.3 % | **15.762** (15.833, 15.581, 15.762) | 1.6 % | **×1.003** | 13 → 13 | 532 → 532 | 2064 → 1843 |
| 64 | **43.235** (43.235, 42.179, 43.343) | 2.7 % | **42.906** (42.906, 42.075, 42.950) | 2.0 % | **×0.992** | 6 → 6 | 683 → 683 | 2169 → 2036 |

Peak nvidia-smi memory.used (MiB) per run: main: [8705, 8705, 8705]; pr: [8769, 8769, 8769]

Counters (survivors / checked / found) per run:

- b58 main: 606421851410 / 34236290957 / 0; 606421851415 / 34236290977 / 0; 606421851762 / 34236290637 / 0
- b58 pr: 606421850932 / 34236291394 / 0; 606421852988 / 34236289555 / 0; 606421850883 / 34236291370 / 0
- b60 main: 459055143226 / 32544427028 / 0; 459054795925 / 32544729685 / 0; 459055000961 / 32544557292 / 0
- b60 pr: 459056332840 / 32543318503 / 0; 459056224311 / 32543395060 / 0; 459056838712 / 32542841388 / 0
- b62 main: 163510221328 / 10030866323 / 0; 163510210324 / 10030876456 / 0; 163510210227 / 10030876940 / 0
- b62 pr: 163510217638 / 10030869812 / 0; 163510222778 / 10030865437 / 0; 163510217727 / 10030869508 / 0
- b64 main: 787562296233 / 47922118292 / 0; 787562316147 / 47922100201 / 0; 787562332046 / 47922086032 / 0
- b64 pr: 787562313739 / 47922101520 / 0; 787562292062 / 47922122514 / 0; 787562339099 / 47922078542 / 0

#### 10 GB budget: main against the PR with the barrier (the exp binary at cap 64 with `NICE_EXP_FLUSH_SYNC=1`, interleaved in the same rounds; "PR" columns = barrier)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **46.799** (46.799, 46.613, 47.030) | 0.9 % | **46.140** (46.152, 46.140, 46.123) | 0.1 % | **×0.986** | 5 → 5 | 1010 → 1010 | 1877 → 1823 |
| 60 | **34.703** (34.647, 35.266, 34.703) | 1.8 % | **35.405** (35.435, 34.883, 35.405) | 1.6 % | **×1.020** | 4 → 4 | 1350 → 1350 | 1596 → 1561 |
| 62 | **15.722** (15.722, 15.562, 15.769) | 1.3 % | **15.845** (15.776, 15.845, 15.909) | 0.8 % | **×1.008** | 13 → 13 | 532 → 532 | 2064 → 1843 |
| 64 | **43.235** (43.235, 42.179, 43.343) | 2.7 % | **43.103** (43.423, 42.336, 43.103) | 2.5 % | **×0.997** | 6 → 6 | 683 → 683 | 2169 → 2036 |

Peak nvidia-smi memory.used (MiB) per run: main: [8705, 8705, 8705]; barrier: [8769, 8769, 8769]

Counters (survivors / checked / found) per run:

- b58 main: 606421851410 / 34236290957 / 0; 606421851415 / 34236290977 / 0; 606421851762 / 34236290637 / 0
- b58 barrier: 606421849911 / 34236292413 / 0; 606421851714 / 34236290735 / 0; 606421852325 / 34236290114 / 0
- b60 main: 459055143226 / 32544427028 / 0; 459054795925 / 32544729685 / 0; 459055000961 / 32544557292 / 0
- b60 barrier: 459056338435 / 32543314161 / 0; 459056018037 / 32543607153 / 0; 459056045506 / 32543586972 / 0
- b62 main: 163510221328 / 10030866323 / 0; 163510210324 / 10030876456 / 0; 163510210227 / 10030876940 / 0
- b62 barrier: 163510204505 / 10030882770 / 0; 163510215808 / 10030871943 / 0; 163510220112 / 10030867748 / 0
- b64 main: 787562296233 / 47922118292 / 0; 787562316147 / 47922100201 / 0; 787562332046 / 47922086032 / 0
- b64 barrier: 787562283720 / 47922130744 / 0; 787562300356 / 47922114018 / 0; 787562329852 / 47922087213 / 0

#### 10 GB budget: the PR against the PR with the barrier ("main" columns = PR, "PR" columns = barrier)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **46.731** (45.941, 46.731, 46.758) | 1.7 % | **46.140** (46.152, 46.140, 46.123) | 0.1 % | **×0.987** | 5 → 5 | 1010 → 1010 | 1823 → 1823 |
| 60 | **35.092** (35.092, 35.140, 34.749) | 1.1 % | **35.405** (35.435, 34.883, 35.405) | 1.6 % | **×1.009** | 4 → 4 | 1350 → 1350 | 1561 → 1561 |
| 62 | **15.762** (15.833, 15.581, 15.762) | 1.6 % | **15.845** (15.776, 15.845, 15.909) | 0.8 % | **×1.005** | 13 → 13 | 532 → 532 | 1843 → 1843 |
| 64 | **42.906** (42.906, 42.075, 42.950) | 2.0 % | **43.103** (43.423, 42.336, 43.103) | 2.5 % | **×1.005** | 6 → 6 | 683 → 683 | 2036 → 2036 |

Peak nvidia-smi memory.used (MiB) per run: pr: [8769, 8769, 8769]; barrier: [8769, 8769, 8769]

#### 20 GB budget: main against the PR (`ab16.sh B20 2`, 2 rounds; the third round was given up for the 1e15 runs)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **47.209** (47.066, 47.351) | 0.6 % | **46.621** (46.651, 46.590) | 0.1 % | **×0.988** | 5 → 5 | 673 → 673 | 2775 → 2721 |
| 60 | **34.841** (34.650, 35.032) | 1.1 % | **34.924** (34.675, 35.173) | 1.4 % | **×1.002** | 6 → 6 | 600 → 600 | 2664 → 2611 |
| 62 | **15.494** (15.495, 15.493) | 0.0 % | **15.491** (15.506, 15.476) | 0.2 % | **×1.000** | 16 → 22 | 334 → 302 | 2858 → 3039 |
| 64 | **42.870** (43.523, 42.216) | 3.0 % | **43.209** (43.362, 43.055) | 0.7 % | **×1.008** | 10 → 10 | 410 → 410 | 3533 → 3312 |

Peak nvidia-smi memory.used (MiB) per run: main: [9473, 9473, None]; pr: [10881, 10881, None]

Counters (survivors / checked / found) per run:

- b58 main: 606421855717 / 34236286947 / 0; 606421854366 / 34236288163 / 0
- b58 pr: 606421857379 / 34236285282 / 0; 606421856454 / 34236286298 / 0
- b60 main: 459031057930 / 32566889861 / 0; 459030387368 / 32567504795 / 0
- b60 pr: 459031230419 / 32566730026 / 0; 459030899417 / 32567035419 / 0
- b62 main: 163510219750 / 10030867935 / 0; 163510224153 / 10030863520 / 0
- b62 pr: 163510220072 / 10030867632 / 0; 163510234454 / 10030854282 / 0
- b64 main: 787562509707 / 47921918218 / 0; 787562505613 / 47921923487 / 0
- b64 pr: 787562481766 / 47921944361 / 0; 787562526194 / 47921903256 / 0

The `barrier` tree is the exp binary (PR + counters + knobs) with `NICE_EXP_SLOTS=64 NICE_EXP_FLUSH_SYNC=1`; its counters showed planes entered = expected at every base (`e16_B10_barrier_r*.log`, `EXP_FLUSH`). Its cost against the PR, ×0.987 / 1.009 / 1.005 / 1.005, includes the instrumentation's extra atomics per flush, so it is an upper bound.

## 4b. 1e15 A/B (`e15.sh`)

NiceMark's b58_msd_weak moved ×0.969, so the same comparison ran in the harness on 1e15 fields: 2 per base at the A/B starts (the same range as the twenty 1e14 fields), main / pr interleaved, both budgets, 3 rounds (09:16–09:25). This replaced a third 1e16 round under the card's own budget.

#### 10 GB budget

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **5.071** (5.030, 5.071, 5.163) | 2.6 % | **5.163** (5.069, 5.188, 5.163) | 2.3 % | **×1.018** | 16 → 32 | 211 → 108 | 1709 → 2303 |
| 60 | **3.432** (3.460, 3.431, 3.432) | 0.8 % | **3.438** (3.438, 3.455, 3.412) | 1.3 % | **×1.002** | 16 → 43 | 225 → 91 | 1561 → 2362 |
| 62 | **2.503** (2.486, 2.503, 2.530) | 1.8 % | **2.468** (2.469, 2.467, 2.468) | 0.1 % | **×0.986** | 16 → 50 | 241 → 79 | 1646 → 2540 |
| 64 | **3.733** (3.723, 3.760, 3.733) | 1.0 % | **3.643** (3.716, 3.632, 3.643) | 2.3 % | **×0.976** | 16 → 48 | 256 → 89 | 1679 → 2558 |

Peak nvidia-smi memory.used (MiB) per run: main: [7585, 7585, 7585]; pr: [8673, 8673, 8673]

Counters (survivors / checked / found) per run:

- b58 main: 65276511289 / 3681958787 / 0; 65276511228 / 3681958846 / 0; 65276511367 / 3681958717 / 0
- b58 pr: 65276511318 / 3681958768 / 0; 65276511272 / 3681958805 / 0; 65276511255 / 3681958816 / 0
- b60 main: 45579363262 / 3153440195 / 0; 45579574532 / 3153240892 / 0; 45579432164 / 3153375355 / 0
- b60 pr: 45573927492 / 3158510423 / 0; 45573827813 / 3158599923 / 0; 45573746437 / 3158676815 / 0
- b62 main: 24394169884 / 1495356858 / 0; 24394173176 / 1495353579 / 0; 24394173239 / 1495353755 / 0
- b62 pr: 24394190552 / 1495337468 / 0; 24394198181 / 1495330453 / 0; 24394196031 / 1495332309 / 0
- b64 main: 65746974368 / 4000052236 / 0; 65746975808 / 4000050905 / 0; 65746974129 / 4000052552 / 0
- b64 pr: 65746966112 / 4000060056 / 0; 65746966686 / 4000059500 / 0; 65746964801 / 4000061227 / 0

#### 20 GB budget

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | partitions per launch main → PR | batches main → PR | plan MiB main → PR |
|---|---|---|---|---|---|---|---|---|
| 58 | **5.177** (5.181, 5.177, 5.149) | 0.6 % | **5.240** (5.240, 5.253, 5.227) | 0.5 % | **×1.012** | 16 → 51 | 211 → 67 | 2093 → 3666 |
| 60 | **3.448** (3.448, 3.494, 3.429) | 1.9 % | **3.441** (3.478, 3.441, 3.417) | 1.8 % | **×0.998** | 16 → 64 | 225 → 60 | 1945 → 3591 |
| 62 | **2.519** (2.519, 2.478, 2.522) | 1.7 % | **2.480** (2.483, 2.480, 2.438) | 1.8 % | **×0.985** | 16 → 64 | 241 → 61 | 2030 → 3454 |
| 64 | **3.639** (3.787, 3.632, 3.639) | 4.3 % | **3.659** (3.786, 3.658, 3.659) | 3.5 % | **×1.005** | 16 → 64 | 256 → 64 | 2063 → 3749 |

Peak nvidia-smi memory.used (MiB) per run: main: [8833, 8833, 8833]; pr: [10785, 10785, 10785]

Counters (survivors / checked / found) per run:

- b58 main: 65276511263 / 3681958814 / 0; 65276511306 / 3681958773 / 0; 65276511271 / 3681958812 / 0
- b58 pr: 65276511286 / 3681958795 / 0; 65276511318 / 3681958761 / 0; 65276511201 / 3681958872 / 0
- b60 main: 45579426560 / 3153381302 / 0; 45579542215 / 3153270013 / 0; 45579616086 / 3153201311 / 0
- b60 pr: 45574303055 / 3158158325 / 0; 45574420950 / 3158050565 / 0; 45574253638 / 3158206250 / 0
- b62 main: 24394175208 / 1495352140 / 0; 24394174005 / 1495352888 / 0; 24394170370 / 1495356421 / 0
- b62 pr: 24394201729 / 1495327029 / 0; 24394199440 / 1495329100 / 0; 24394199617 / 1495329197 / 0
- b64 main: 65746973541 / 4000053025 / 0; 65746974453 / 4000052132 / 0; 65746972688 / 4000053843 / 0
- b64 pr: 65746964251 / 4000061686 / 0; 65746966162 / 4000059925 / 0; 65746966234 / 4000059790 / 0

At 1e15 the change is neutral: within ±2.4 % at every base and budget, and inside the rounds' spreads except b58 at 20 GB (×1.012, spreads 0.5–0.6 %). A 1e15 field's work items are about 10× heavier than a 1e14 field's, so 211 launches × 0.5 ms are only 2 % of a b58 field, and spreading heavier, uneven work items over grid-striding cubes (32–64 per launch) costs about as much. b60's overrun grows by 5.4 M survivors at 43–64 per launch (main's own at 1e15 is about 100 M, 2.2e-3): +0.16 % full checks.

## 5. NiceMark nice-only

`nicemark.sh`: `RUST_LOG=info nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, main / pr interleaved × 3 (`nm_r*_{main,pr}.{json,err,smi}`), this card's own budget (the override is test-only). Not uploaded.

| scenario | main rates (median) | PR rates (median) | **PR / main** | partitions per launch main → PR | routes |
|---|---|---|---|---|---|
| b58_msd_weak | 1.996e+14, 2.044e+14, 2.050e+14 (**2.044e+14**, 2.6 %) | 1.982e+14, 1.975e+14, 2.017e+14 (**1.982e+14**, 2.1 %) | **×0.969** | [16] → [50] | ['join'] / ['join'] |
| b58_msd_strong | 1.168e+15, 1.219e+15, 1.230e+15 (**1.219e+15**, 5.1 %) | 1.273e+15, 1.275e+15, 1.293e+15 (**1.275e+15**, 1.6 %) | **×1.046** | [16] → [64] | ['join'] / ['join'] |
| b60_msd_weak | 4.017e+14, 4.048e+14, 4.060e+14 (**4.048e+14**, 1.1 %) | 3.965e+14, 3.975e+14, 3.993e+14 (**3.975e+14**, 0.7 %) | **×0.982** | [6] → [6] | ['join'] / ['join'] |
| b62_msd_weak | 5.111e+14, 5.124e+14, 5.164e+14 (**5.124e+14**, 1.0 %) | 5.214e+14, 5.119e+14, 5.219e+14 (**5.214e+14**, 1.9 %) | **×1.018** | [9] → [9] | ['join'] / ['join'] |

score main: [4598.41698286986, 4687.822130276921, 4714.081027553852]

score pr: [4697.907631245166, 4677.55411979803, 4747.421923519457]


Per-scenario details (`run_secs`, sample sizes, counters) are in the JSON; b60's sample (450–462 of 3600 partitions) and counters match between trees to within one survivor, and its rate still moves 1.8 %, so ±2–3 % per scenario is this benchmark's noise here. The harness check of the b58 case on 1e15 fields is in section 4b.

## 6. The extra full checks: a race in the flush decision

**What was asked:** PROFILE-2 section 5a saw one 64-slot b64 run count 16.5 M (0.4 %) more full checks, with survivors equal to within 247 and a 35 k overrun. Is it more survivors per flush and so more stage overruns?

**Answer: no. It is a race in `join_kernel`'s per-chunk flush decision.** The stage overrun does grow with partitions per launch (b64: 0 / 18 k / 35 k / 42 k overrun survivors per 20 fields at 16 / 32 / 64 / 171), but it is deterministic in size up to the top-fill order and its cost is −0.06 full checks per overrun survivor relative to "one check each" (the excess column below sits at −1 k … −3 k in every clean run). The anomalies are 10²–10⁴ times larger and appear in some runs of a layout and not in others.

**Mechanism** (`common/src/cubecl_join.rs`, `join_kernel`, the block after the walk):

```
sync_cube();
let sc = s_cnt[0].load();
if sc >= SURV_FLUSH { flush_survivors(..., sc, ...); sync_cube(); }
jc += 32u32;   // next chunk: AND, then the walk appends with s_cnt.fetch_add
```

No barrier separates a thread's load of `s_cnt` from other planes' appends in the next chunk. A fast plane reads the count, runs the next chunk's AND and walk and appends; a slow plane that had not yet done its load now reads a larger count. If the count at the barrier was below 512 and the slow plane's is at or above it, that plane alone calls `flush_survivors`. From then on the cube's `sync_cube()`s pair at different call sites (the lone plane's flush barriers against the others' chunk barriers) for the rest of the cube. In the flush, each round sums `plane_tot` entries the other planes did not write for that round, thread 0 reserves `all` list entries from those sums with `out_count.fetch_add`, and planes write their passing survivors at `s_base + off + idx` with `s_base` and `off` from other rounds; thread 0's `s_cnt.store(0)` can land while out-of-phase planes are still appending. Consequences: (1) list ranges reserved and never written in this batch: the check kernel fully checks stale entries of earlier batches (the extra checks, which can be large because a garbage `all` reserves many entries at once); (2) list entries reserved by one flush overwritten by another plane's writes, and stage entries dropped by the early reset: survivors that are never fully checked. (2) cannot be seen in these counters (no field here holds a nice number), but it follows from the code.

On wgpu (Vulkan, Metal) the same divergence puts `workgroupBarrier` in non-uniform control flow, which those APIs leave undefined.

**Why more partitions per launch make it frequent.** Up to ⌊65,535 / b(b−1)⌋ = 19 / 18 / 17 / 16 partitions per launch at b58/60/62/64, the join grid has one cube per (partition, bucket) work item and the stage starts empty in every cube; a 1e14 work item has 7–27 tops on average (mostly one chunk) and 80–300 survivors, so the stage seldom nears 512 at a chunk boundary inside a cube. (The decision after a work item's last chunk is not racy at all: the barrier at the end of the tops loop comes before any later append. Only decisions between chunks or waves of one work item are.) A grid-striding cube (2 work items per cube at 32, 4 at 64, 10 at 171 for b64) carries its stage from work item to work item, so the count is often just under 512 at a chunk boundary, which is when a late reader can disagree. At 1e16 a work item holds 440–2,360 tops (14–74 chunks), so per-chunk decisions happen in main's own layouts too, though there a chunk adds about 300–600 survivors (buckets of 280–420 entries × 32 tops × a 3–4.5 % AND pass), so the stage passes 512 within a chunk or two and flushes, and counts just under the level at a boundary are rarer. `race3.sh`, the exp binary without the barrier in main's 1e16 layouts (`NICE_EXP_SLOTS=16`, 10 GB budget: 5 / 4 / 13 / 6 per launch, one cube per work item), 2 fields per base: d = 0 at every base (`race_e16_sync0_r1.log`). The race is possible there by the code but was not observed in that run.

**Instrumentation** (`exp` binary): `staged[2]` counts each plane's lane 0 entering `flush_survivors`, `staged[3]` adds 8 for every flush thread 0 enters; `d` = entered − expected per 20 fields. `NICE_EXP_FLUSH_SYNC=1` adds `sync_cube()` right after the load (the candidate fix, also on fork branch `rp/join-flush-barrier`, `61e6ba9`, on main). "Excess" = checked − main's checked − (main's survivors − survivors), i.e. full checks beyond one per overrun survivor; clean runs sit at −0.06 × overrun.


#### Counter study (`counters.sh`): b64 1e14, 20 fields, this card's budget, experiment binary, 3 reps

| cap | barrier | s/field (reps) | overran (reps) | planes mismatch d (reps) | full checks beyond the overrun (reps) |
|---|---|---|---|---|---|
| 16 (16) | no | 0.680, 0.694, 0.697 | 0, 0, 0 | 0, 0, 0 | +0, +0, +0 |
| 16 (16) | yes | 0.696, 0.697, 0.690 | 0, 0, 0 | 0, 0, 0 | +0, +0, +0 |
| 32 (32) | no | 0.592, 0.596, 0.599 | 18795, 18174, 18281 | 0, 0, 0 | -1126, -1068, -1082 |
| 32 (32) | yes | 0.599, 0.596, 0.597 | 18398, 18214, 18149 | 0, 0, 0 | -1143, -1143, -1113 |
| 64 (64) | no | 0.572, 0.582, 0.572 | 35815, 35225, 35559 | 1, 2, 0 | -2391, -2241, +12114031 |
| 64 (64) | yes | 0.573, 0.568, 0.581 | 35457, 35375, 35366 | 0, 0, 0 | -2232, -2163, -2208 |
| max (171) | no | 0.578, 0.573, 0.585 | 42849, 41890, 42604 | 2, 7, 0 | -2944, +2017566, -2639 |
| max (171) | yes | 0.583, 0.585, 0.578 | 42090, 42594, 41925 | 0, 0, 0 | -2614, -2665, -2591 |

#### Census of every 1e14 base-run (all scripts)

| tree | per launch | barrier | base-runs | with excess checks | planes counted | with a planes mismatch |
|---|---|---|---|---|---|---|
| main | <= 19 | no | 48 | 0 | 0 | 0 |
| other | <= 19 | no | 11 | 0 | 11 | 0 |
| other | <= 19 | yes | 3 | 0 | 3 | 0 |
| other | 20-63 | no | 11 | 0 | 11 | 0 |
| other | 20-63 | yes | 3 | 0 | 3 | 0 |
| other | >= 64 | no | 98 | 10 | 50 | 9 |
| other | >= 64 | yes | 18 | 0 | 18 | 0 |

Without the barrier, 12 of the 50 instrumented base-runs at ≥ 64 per launch show a signature (excess checks in 7, d ≠ 0 in 9, both in 4); with it, 0 of 18. If the barrier changed nothing, P(0 of 18) = 0.76¹⁸ ≈ 0.7 %. The plane counter misses some events (3 of the 7 instrumented anomalies have d = 0): once a cube is out of phase, every plane can still enter as many flushes as thread 0 expects.

#### Every 1e14 base-run with excess full checks above 1e5 per 20 fields

| run | base | partitions per launch | barrier | d | full checks beyond the overrun | share of the full checks |
|---|---|---|---|---|---|---|
| cnt_s64_sync0_r3 | 64 | 64 | no | 0 | +12,114,031 | 0.30 % |
| cnt_smax_sync0_r2 | 64 | 171 | no | 7 | +2,017,566 | 0.05 % |
| e14_B10_pr_r3 | 58 | 109 | no | n/a | +59,377,564 | 1.59 % |
| e14_B10_pr_r3 | 64 | 107 | no | n/a | +911,826 | 0.02 % |
| e14_B20_pr_r3 | 64 | 171 | no | n/a | +679,020 | 0.02 % |
| race_e14_sync0_r2 | 58 | 64 | no | 0 | +24,164,760 | 0.65 % |
| race_e14_sync0_r3 | 64 | 64 | no | 0 | +1,377,824 | 0.03 % |
| sweep_s128_r2 | 64 | 128 | no | 2 | +395,523 | 0.01 % |
| sweep_s96_r1 | 58 | 96 | no | 6 | +77,336,977 | 2.06 % |
| sweep_smax_r2 | 64 | 171 | no | 21 | +34,473,302 | 0.85 % |

(192 base-runs scanned.)

#### The barrier's cost at 1e14 (`race2.sh`: 10 GB budget, cap 64, exp binary, 3 interleaved rounds)

| base | no barrier s/field (rounds) | barrier (rounds) | **barrier / none** | d without; with | excess checks without; with |
|---|---|---|---|---|---|
| 58 | 0.628 (0.620, 0.628, 0.631) | 0.621 (0.631, 0.621, 0.620) | **×0.989** | 0,0,0; 0,0,0 | -4,+24164760,-5; -3,-5,-3 |
| 60 | 0.520 (0.520, 0.520, 0.522) | 0.519 (0.512, 0.522, 0.519) | **×0.998** | 0,0,0; 0,0,0 | -140,-142,-146; -141,-146,-135 |
| 62 | 0.459 (0.459, 0.459, 0.458) | 0.455 (0.452, 0.455, 0.460) | **×0.991** | 0,0,0; 0,0,0 | +0,+0,+0; +0,+0,+0 |
| 64 | 0.577 (0.571, 0.578, 0.577) | 0.578 (0.580, 0.570, 0.578) | **×1.002** | 0,0,0; 0,0,0 | -2230,-2261,+1377824; -2239,-2093,-2192 |

At 1e16 the barrier ran inside `ab16.sh B10` as the third tree (section 4): ×0.987 / 1.009 / 1.005 / 1.005 against the PR, ×0.986 / 1.020 / 1.008 / 0.997 against main, with d = 0 at every base in all 3 rounds. The exp binary's extra atomics (8 lane-0 adds and one thread-0 add per flush, on two global words) are in that figure, so it bounds the barrier's cost from above.

## 7. Exactness

`exact.sh pr` (log `exact_pr.out`) on the final code `40d6a26` (built on the box as `prfinal`: test `fb43b359`, client `d929bedf`; the head `c4ac700` only rewords one doc comment):

- `nice_common_test --test-threads 12` (host tests, `--features gpu` build): **209 passed**, 33 ignored.
- `join_plan` tests, verbose: 8 passed, including the new `bottom_buffers_follow_each_slices_pruned_list`. Printed: 64 per launch at the 10 GB budget at b57/60/62/64, in 1750 / 1752 / 1831 / 2114 MiB, where the unpruned sizing fits 54 / 55 / 41 / 39; kept bottoms 54,885 / 66,634 / 65,394 / 78,784 of 133,645 / 137,775 / 176,671 / 180,003. At the 1 GiB budget: 64 (b42), 29 (b50), 51 / 51 / 48 / 38 (b57/60/62/64). Slices: b58 1e15 1, b60 1e16 7, b62 1e17 53 on that test's device (2.5 GiB binding, 1 GiB budget); the cut uses the unpruned length as on main, so slicing is main's by construction.
- `cubecl_cuda_join_matches_the_cpu_reference`: **ok** (every window, tight layouts with re-runs and splits, 5 windows whole and in slices, refused layouts with ceilings, the b57 production shape), 75 s.
- `cubecl_cuda_join_matches_the_reference_on_a_whole_field` (`NICE_TEST_JOIN_FULL_FIELD=1`, b42): **ok**.
- Dense fields against the CPU join (`NICE_TEST_JOIN_DENSE`, `NICE_TEST_JOIN_DENSE_FIELD`), the card's own budget:
  - b58 102121216587923470200 +1e15, 64 partitions: **ok**, 0 survivors overran;
  - b64 41242006262957161709568 +1e16, 8 partitions: **ok**, 20,534 overran (2.7e-5);
  - b64 41242006262957161709568 +1e14, 1024 partitions (64 per launch, grid-striding): **ok**, 8,078 overran (5.7e-6).
- `NICE_TEST_JOIN_COMPARE=1`, 5 × 1e14 per base at the A/B starts, 10 GB budget: join = stride at b58/60/62/64 (found 0 on both; the stride pipeline took 10–22 s per field).
- Lint (`lint_*.log`): `cargo fmt --all --check` exit 0; `cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings` exit 0; the same with `--features nice_client/gpu` exit 0.
- Counters per tree: sections 2, 4, 4b. Main's 1e14 counts are identical to the last digit in all 12 runs. The PR's differ from main's only by the overrun (Δchecked ≈ −0.94 Δsurvivors) in all its 24 base-runs at 1e14. Hits: 0 everywhere; these fields hold none.

**The PR with the barrier** (`barrier2.sh`, `rp/launch-with-barrier` = `40d6a26` + `61e6ba9` = `4f153aa`, test `12044c3c`): `cubecl_cuda_join_matches_the_cpu_reference` ok; dense b58 1e15 (64 partitions) ok, 0 overran; dense b64 1e14 (1024 partitions) ok, 7,846 overran (5.5e-6); 1e14 at the 10 GB budget: counters within the overrun band (b64 4,000,027,100 checks). **The barrier's cost without instrumentation** (`prb_ab.sh`, 10 GB budget, the PR `pr64` against `prb`, logs `g14_B10_{pr,prb}_r*`; r1 of prb is `f14_B10_prb_r1` from `barrier2.sh`, not interleaved):

| base | PR r2, r3 | PR + barrier r2, r3 (r1) | × (medians of r2–r3) |
|---|---|---|---|
| 58 | 0.602, 0.619 | 0.622, 0.630 (0.610) | ×1.025 |
| 60 | 0.507, 0.515 | 0.517, 0.521 (0.502) | ×1.016 |
| 62 | 0.446, 0.459 | 0.457, 0.454 (0.450) | ×1.007 |
| 64 | 0.566, 0.578 | 0.572, 0.570 (0.563) | ×0.998 |

The PR alone moved 2.8 % between these two rounds at b58, and prb's own r1 is the fastest of its three. With the 3-round instrumented comparison (×0.989 / 0.998 / 0.991 / 1.002), the barrier's cost at 1e14 is between 0 and about 2.5 %; it is not resolved at this noise level. At 1e16 (one round each, `g16_B10_{pr,prb}_r1`, 09:34–09:44): 46.00 → 46.70, 35.22 → 35.27, 15.54 → 15.55, 42.81 → 43.33 s per field (×1.015 / 1.002 / 1.000 / 1.012), against the PR's own 3-round spreads of 1.1–2.0 %.

## 8. Not done / caveats

- **No real 10 GB card.** The box was a 20 GB RTX 3080. The 10 GB layouts come from the test-only override, which changes the join's plan but not CubeCL's memory pools (their page sizes follow the device: 5 GiB here, 2.5 GiB on a 10 GB card). The plans fit the 2.5 GiB budget (largest 2536 MiB, b60), but the process total on a real 10 GB card was not measured.
- **The cap of 64 was measured on this card only.** Why 96–177 are slower than 64 is not profiled. The overrun is far too small to explain it, and allocation churn does not explain it either: the pruned sizing alone, at 16 per launch, runs at main's speed (sweep row 16 against main). Candidates are TLB reach over a 3–4 GiB working set, and the longer tail of a grid-striding launch.
- **The barrier is not in the PR branch** (brief: kernels unchanged). It is on fork branches `rp/join-flush-barrier` (`61e6ba9`, on main) and `rp/launch-with-barrier` (`4f153aa`, on the PR).
- **Lost survivors are inferred from the code, not observed.** No field here holds a nice number, and the counters only show the stale-entry half of the race. A list-content comparison against the CPU join at a grid-striding layout (`check_window`-style, on a production field) would show it. Not run.
- **NiceMark ran at the card's own budget only.** The override exists in test builds only.
- **Main's exactness suite was not re-run here.** Main's counters come from the A/B runs, identical to the last digit in every 1e14 run.

