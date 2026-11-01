# L32 SCOPING: wave padding in `join_kernel`, on the combined tree (#235 + #236), RTX 3080 at 180 W (2026-11-01)

Baseline: fork branch `exp/join-235-236` = `e9cdac4` (L30 COMBINED). Prototype: fork branch **`exp/join-padding`**, no PR:
- `2a681f6`: the tail switch (`NICE_EXP_JOIN_TAIL=1`) and an EPT knob. This is what every measurement in §1–§3 ran.
- head `ed8bc8c`: adds tail mode 2 (§3b), and the fmt and clippy fixes.

Raw logs: `raw/box/` (the box's `/root/pad`). Scripts: `raw/scripts/`. Analysis: `raw/analyze.py` (A/B, output `raw/analysis.txt`), `raw/acct.py` (padding accounting, `raw/acct.txt`), `raw/fit.py` (re-fit and off→tail differences, `raw/fit.txt`; run with `uv run --with numpy`).

## Summary

- **Where the padding is.** At b62 1e17 every live bucket fits in a single 512-lane wave. They hold 256–479 entries, and 78 % of the (top, bucket) pairs sit in buckets of 288–351.
  - Each wave therefore uses **64.8 %** of its lanes. 35.2 % are empty: 1.38e13 empty lane-pairs per field.
  - b60 1e16: 77–79 % used (21–23 % empty), with buckets of 384–447.
  - b62 1e16: 61 % and 79 % on the two fields.
  - b64 1e16: 55 %.
  - Under half a wave: 0.01 % of work items at b62 1e17; 0–8 % of work items (0–2.8 % of tops) at b60.
- **What padding costs now that survivors are cheap.** Re-fit over 12 profiled field-runs (6 fields, tail off and on):
  - `join = 1.64 ps × real lane-pair + 0.64 ps × empty lane-pair + 21 ps × AND survivor + 104 ps × top`. rms 1.2 %, max 2.3 %.
  - The survivor term was 61 ps before #236 and is now about 3× cheaper, so the empty lanes' share has grown.
  - Empty lanes cost **8.7 s per b62 1e17 field (5.1 % of device time)** and 1.0 s per b60 1e16 field (3.2 %).
  - Measured directly, the tail prototype removes 8.8 s of profiled join time at b62 1e17 and 0.45 s per field at b60.
- **Candidates.**
  - (a) **EPT 1 runs no fewer lanes.** Every bucket has more than 256 entries, so 256-entry waves need two waves per bucket and the per-top chunk pass is paid twice. Measured: **×0.92–0.95**. Rejected.
  - (b) **A bucket-sized tail wave** removes 86–93 % of the empty lanes. It also stops 3 of 8 planes per top from running the AND at all at b62 (1–2 at b60). Prototyped (below).
  - (c) **Packing two small buckets: not applicable.** No live field has buckets under half a wave in any number. Tops are per bucket in any case, so a wave across two buckets needs two top chunks and the cube's shared barriers.
  - (d) EPT 3 + tail ×1.044 and EPT 4 + tail ×0.973 at b62 1e16 (one run each), against ×1.051 for EPT 2 + tail. Two entries per thread stays best.
- **Prototype `NICE_EXP_JOIN_TAIL=1` (+86 / −12 lines including the EPT knob and comments).**
  - **How it works:** a partial wave spreads its entries over the fewest whole 32-lane planes. Each plane runs the AND on the slots it uses: both, the first only, or none. The branch is plane-uniform (`plane_any`).
  - **Exact:**
    - CUDA join parity passes, including the b50/b54 windows, with EPT 2 and with EPT 1.
    - Both dense fields match the CPU join.
    - COMPARE at 1e14 (b57/60/62/64) passes, with counts identical to the base binary.
    - Counts are identical to the base in every A/B run.
- **A/B against `e9cdac4`** (interleaved, device s per field, medians):

  | field | rounds | speed-up | per round | base → tail |
  |---|---|---|---|---|
  | **b62 1e17** | 5 (3 + 2 in §3b) | **×1.040** | ×1.036–1.050 (median ×1.041) | 163.4 → 157.1 s |
  | b62 1e16 | 4 | ×1.051 | ×1.035–1.064 | |
  | b60 1e16 | 4 | **×1.028** | ×1.022–1.037 | |
  | NiceMark nice-only | 3 | ×1.078 | ×1.071–1.086 | 5016 → 5406 |

- **Verdict:**
  - **The tail does not clear the 5 % bar at either live size.**
    - b62 1e17: ×1.040 raw over 5 rounds. The first 3 rounds alone gave ×1.049. Clock-normalised it is ×1.050, but on a power-capped card raw time is what counts.
    - b60 1e16: ×1.028.
    - b62 1e16 gives ×1.051, but it is not a live size for b62.
  - It is the only padding lever there is: it leaves 4–5 % of the executed slots empty. Nothing else on the padding side is left to add to it.
  - It is a small, exact, low-risk kernel change. A PR would be justified as "×1.04 at b62 1e17, ×1.03 at b60 1e16, ×1.08 NiceMark", not as a 5 % win.
  - One known cost to remove first: the prototype takes the join kernel from 40 to 41 registers on sm_86, which likely costs a resident cube per SM. §4 and §5 cover this and the rest of what the PR needs.

## 0. Setup

- **Box:** Vast 58629539 (`nice-research-padding`), machine **m139250**, the same machine as L29's and L30's A/Bs.
  - RTX 3080 10 GB, driver 580.159.03. **Power limit 180 W** (default 320 W on this card's report, `raw/box/power.txt`).
  - Under load the card ran at 1,450–1,525 MHz mean SM clock (≥ 90 % utilisation samples).
  - Xeon E5-2630 v4, cgroup quota 9.6 CPUs (`nproc.txt`).
  - Another research box (`nice-research-topcert2b`, 58629437) ran on the same host throughout, so host CPU was shared. The metric is device time.
- **Binaries.** Each was built on the box from a `git archive` of an ivory tree, toolchain 1.99.1, in one shared target dir with `cargo clean -p nice_common` before each build, one build at a time (`scripts/build.sh`, `buildclient.sh`, `chain_build*.sh`):

  | binary | source | md5 | use |
  |---|---|---|---|
  | `base` | `e9cdac4` | **8f421599** | A arm. Same md5 as L30's `both`: the combined tree reproduces |
  | `pad` | `2a681f6` (`exp/join-padding`) | 1302e3d3 | B arm (`NICE_EXP_JOIN_TAIL=1`), EPT arms, exactness |
  | `prof` | `2765e64`, local throwaway `exp/join-padding-prof` | cc3f21f8 | profile + padding accounting |
  | `client_pad` | `2a681f6`, `nice_client --features gpu` | 4e63ffe0 | NiceMark, tail off / on |
  | `pad_wgpu` | `2a681f6`, `--features cubecl` | b78564ac | WGSL lint |
  | `pad_spirv` | `2a681f6`, `--features cubecl-spirv` | b941e147 | SPIR-V block counts |
  | `pad2` | `ed8bc8c` (head) | d87978e8 | §3b: tail modes 1 and 2 |

  `prof` is `2a681f6` plus these commits, all local to ivory (worktree `nice/.worktrees/exp-join-padding-prof`):
  - `6be7bde`, the cherry-pick of `2ab1694` (`NICE_EXP_GPU_PROFILE`);
  - `0222243`, the cherry-pick of `32b84af` (`spilled=`);
  - `2765e64`, new: a `PAD_ACCT` line per field. From the per-slot work items and bucket counts it already reads, it gives the lanes and planes each variant would run, and a histogram of entries per bucket.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568), one untimed 1e14 warm-up field per process.
  - **Metric:** `device=`, the mean device seconds per field. 1e16 runs are 2 fields, 1e17 runs 1 field.
- **Order (box UTC):**
  - Builds 07:04–07:30.
  - Exactness 07:16–07:26, beside the `prof`/client builds.
  - Profile 1 (b62 1e17, b60 1e16) 07:26–07:34. The first run overlapped the wgpu build.
  - **A/B 07:34–08:10** (`chain_ab.sh`). Nothing else ran on the box.
  - NiceMark round 1 08:10–08:12, profile 2 (b62 1e16, b64 1e16) 08:12–08:14.
  - Extras 08:14–08:16: EPT 3 + tail, b62 1e16 round 4, the CUDA source dump.
  - Lints and SPIR-V dumps 08:16–08:24.
  - NiceMark rounds 2–3 and b60 1e16 round 4 08:22–08:27, beside the `pad2` build.
  - §3b's runs from 08:27.

## 1. Padding accounting after #236 (exact counts, `raw/acct.txt`)

Every quantity is weighted by tops: a bucket's lanes count once per top that scans it. "(top, bucket) pairs" is Σ over live work items of the tops in the item. A wave is `ENTRIES_PER_THREAD · JOIN_WG` = 512 entries.

| field | live work items | (top, bucket) pairs | mean entries per scanned bucket | **lanes used per wave** | empty lane-pairs | buckets > 512 entries | buckets < 256 (share of tops) |
|---|---|---|---|---|---|---|---|
| **b62 1e17** | 159.9 M | 7.63e10 | 331.7 | **64.8 %** | **1.376e13 (35.2 %)** | 0 | 0.01 % of items (0.01 %) |
| b62 1e16, field 1 | 14.5 M | 9.02e9 | 313.1 | 61.1 % | 1.79e12 (38.9 %) | 0 | 0 |
| b62 1e16, field 2 | 14.5 M | 3.76e9 | 405.5 | 79.2 % | 4.00e11 (20.8 %) | 0 | 0 |
| **b60 1e16**, field 1 | 25.5 M | 1.37e10 | 395.7 | **77.3 %** | 1.60e12 (22.7 %) | a handful (0.0 %) | 8.0 % of items (2.8 %) |
| b60 1e16, field 2 | 25.5 M | 1.38e10 | 405.3 | 79.2 % | 1.48e12 (20.8 %) | a handful (0.0 %) | 0 |
| b64 1e16 | 16.5 M | 3.09e10 | 281.0 | 54.9 % | 7.14e12 (45.1 %) | 0 | 0 |

Bucket sizes (share of (top, bucket) pairs). "Lanes used" is the bin's midpoint over 512. "Tail planes" is how many of the 8 planes run the AND for that size in the prototype:

| entries | lanes used | tail planes | b62 1e17 | b62 1e16 f1 | b62 1e16 f2 | b60 1e16 f1 | b60 1e16 f2 | b64 1e16 |
|---|---|---|---|---|---|---|---|---|
| 224–255 | 47 % | 4 | 0.0 % | 0 | 0 | 2.8 % | 0 | 4.9 % |
| 256–287 | 53 % | 5 | 3.4 % | 5.4 % | 0 | 12.4 % | 0.0 % | **61.4 %** |
| **288–319** | 59 % | 5 | **39.2 %** | **60.4 %** | 0 | 2.4 % | 2.2 % | **32.9 %** |
| **320–351** | 66 % | 6 | **39.2 %** | 33.3 % | 0.1 % | 0.0 % | 13.4 % | 0.7 % |
| 352–383 | 72 % | 6 | 6.2 % | 0.9 % | 10.9 % | 1.4 % | 6.5 % | 0 |
| **384–415** | 78 % | 7 | 8.1 % | 0 | **60.2 %** | **27.7 %** | **26.7 %** | 0 |
| **416–447** | 84 % | 7 | 3.7 % | 0 | 27.7 % | **45.9 %** | **44.0 %** | 0 |
| 448–479 | 91 % | 8 | 0.1 % | 0 | 1.0 % | 7.3 % | 7.0 % | 0 |

(Full bins, with work-item counts, are in `acct.txt`. b60 has a handful of buckets of 512–543 entries.)

- **One wave per bucket, everywhere that matters.** No bucket at b62 needs a second wave. At b60 only a handful do, under 0.01 % of the pairs.
- So the waste is entirely the **second slot of threads ≥ ne − 256**: in a 300-entry bucket, 212 of the 256 threads hold one entry and AND an empty slot against every top.
- **b62's buckets are smaller than b60's** (288–351 against 384–447). That is why b62 has 35 % empty lanes and b60 21–23 %.

### The cost of padding now (re-fit, `raw/fit.txt`)

Profiled runs on the `prof` binary, tail off and on, 6 fields: b62 1e17, b60 1e16 ×2, b62 1e16 ×2, b64 1e16. Weighted least squares on relative error. In the tail runs, "empty" is the AND slots the kernel actually runs minus the real pairs.

| fit | per real lane-pair | per empty lane-pair | per AND survivor | per top | rms / max |
|---|---|---|---|---|---|
| **off + tail, 12 field-runs** | **1.64 ps** | **0.64 ps** | 21 ps | 104 ps | 1.2 % / 2.3 % |
| off only, 6 field-runs (6 points, 4 terms) | 1.70 ps | 0.83 ps | 17 ps | 114 ps | 0.3 % / 0.5 % |
| PROFILE-3 (main before #235/#236, 12 runs) | 1.18 ps | 0.49 ps | 60.8 ps | 238 ps | 1.6 % / 3.2 % |

- **#236 made each survivor about 3× cheaper** (61 → 17–21 ps). The lane terms absorb some of that: pairs and survivors are collinear (survivors are 4.0–4.5 % of pairs), so the individual coefficients carry ±20 %, as PROFILE-3 noted.
- **The empty lanes now cost 0.64 ps each:**
  - **8.7 s per b62 1e17 field**: 5.1 % of profiled device time, 11–12 % of the join.
  - 1.0 s per b60 1e16 field: 3.2 % of the device, 6.5 % of the join.
  - Before #236 the same lanes were 6.7 s (2.8 %) at b62 1e17.
- **Measured directly, profiled off → tail on the same field:**

  | field | join off → tail | device (probe excl.) | per empty slot removed | per plane-top removed |
  |---|---|---|---|---|
  | b62 1e17 | 75.52 → 66.73 s (**−8.79 s**, −11.6 %) | 162.79 → 154.19 (×1.056) | 0.70 ps | 50 ps |
  | b62 1e16 f1 | 8.80 → 7.83 (−0.96, −10.9 %) | ×1.062 | 0.58 ps | 40 ps |
  | b62 1e16 f2 | 3.91 → 3.74 (−0.18, −4.5 %) | ×1.020 | 0.52 ps | 43 ps |
  | b60 1e16 f1 | 15.15 → 14.69 (−0.46, −3.0 %) | ×1.014 | 0.33 ps | 25 ps |
  | b60 1e16 f2 | 15.48 → 15.04 (−0.45, −2.9 %) | ×1.014 | 0.36 ps | 27 ps |
  | b64 1e16 | 27.74 → 23.26 (−4.48, −16.2 %) | ×1.132 | 0.67 ps | 48 ps |

- **The saving follows the idle planes more than the empty slots.**
  - At b62 the tail idles 2–3 of 8 planes per bucket: plane-tops ×0.71 at 1e17, ×0.67 on b62 1e16 field 1, ×0.62 at b64. There it saves 0.6–0.7 ps per removed slot.
  - At b60 (and on b62 1e16 field 2, which has b60-sized buckets) only 1 plane idles: plane-tops ×0.83–0.86. The rest of the removed slots come from planes that drop to one slot, and the saving falls to 0.33–0.52 ps per slot.
  - This matches PROFILE-2: at 1e14, EPT 1 halved the lanes but kept all 8 planes busy, and saved nothing. A plane that runs the AND at all pays the two shared loads and the loop per top. Within a cube, a plane with both slots still sets the barrier-to-barrier time; the idle planes' issue slots go to other resident cubes.
  - A 5-term fit with plane-tops as a term is ill-conditioned (negative per-slot terms), so it is not quoted.

## 2. Candidates

All lane counts come from `PAD_ACCT`, exact, at b62 1e17 / b60 1e16 (field 1). "×" is relative to real pairs: 1.000 would be no padding at all.

| candidate | AND slots run | planes running the AND per top | (top, wave) chunk passes | size | risk | measured (A/B, device) |
|---|---|---|---|---|---|---|
| main (EPT 2) | ×1.543 / ×1.294 | 8 | 1× | — | — | — |
| **(a) EPT 1** (256-entry waves) | ×1.543 / ×1.273: **no fewer lanes**, since every bucket has more than 256 entries | 8 (twice) | **×2.00 / ×1.97** | 0 lines (constant) | none | **×0.916** b62 1e17 (one run), ×0.949 b62 1e16, ×0.930 b60 1e16 |
| (a') EPT 1 + tail | ×1.048 (same slots as (b)) | 10.9 per top over 2 waves, against 5.7 for (b) | ×2.0 | (b) | (b) | ×1.004 b62 1e16 |
| **(b) bucket-sized tail** (prototype) | **×1.047 / ×1.039** (91 % / 87 % of the empty lanes gone) | **5–6 (×0.71) / 7 (×0.83)** | 1× | +86 / −12 incl. knob and comments; about +35 / −5 as a PR | low: plane-uniform branches. +1 register (40 → 41) and +14 SPIR-V blocks (§4) | **×1.040** b62 1e17 (5 rounds), **×1.051** b62 1e16, **×1.028** b60 1e16 |
| (b') per-plane slots only, stride 256 | ×1.047 / ×1.039 (the same slots) | 8 (none idle) | 1× | −10 lines from (b) | low | not run. From (a)/PROFILE-2, idle planes are where the time goes, so (b) dominates it |
| (c) two small buckets per wave | — | — | — | large (two top chunks, two lane groups, shared barriers and stage) | high | not applicable: 0.01 % (b62 1e17) and 0–2.8 % (b60) of pairs are in buckets under 256. Tops differ per bucket |
| (d) EPT 3 + tail | ×1.18–1.21 / ×1.13 (estimated from bin midpoints) | 4.0–4.9 per top | 1× | (b) + knob | more registers, 3 slots per plane | ×1.044 b62 1e16 (one run; (b) ×1.051) |
| (d) EPT 4 + tail | ×1.203 / ×1.221 | 3.0–3.9 per top, with 4 slots each | 1× | (b) + knob | more registers, longer barrier-to-barrier path | ×0.973 b62 1e16 (one run) |

- **(a) EPT 1 is strictly worse at live sizes.** The buckets are 256–479 entries, so a 256-entry wave count doubles and the lanes stay put: EPT-1 lanes are ×0.9999 of EPT 2's at b62 1e17. #216's rationale (fewer, fuller waves) still holds after #236.
- **(b) the tail is the whole padding lever.** It leaves 4–5 % of the run slots empty, which is about 0.5 s at b62 1e17 by the fit. No other wave arrangement runs fewer slots without longer per-plane paths, and (d) shows those cost more than they save.
- **(c) has nothing to pack.** At 1e14 (NiceMark-sized fields) buckets are 180–220 entries (PROFILE-2), and packing could matter there. But the tail already idles 4 of 8 planes for those, which is where NiceMark's ×1.08 comes from (§3).
- **Other things the code suggests, not pursued:**
  - Round the tail's stride to `PLANE_DIM` instead of 32, for 64-wide planes (AMD). It is correct either way, since the per-plane test uses the real plane width.
  - The 2-word top loads (`t_lo`, `t_hi`) every plane pays per top could be one 64-bit shared load. That is a separate, non-padding lever, and the evidence above says the per-plane cost is what matters.

## 3. The prototype: exactness and A/B

**Code** (`2a681f6`, `common/src/cubecl_join.rs`):
- `join_kernel` gets `#[comptime] tail`.
- When the wave is partial (`ne − ws < 512`), `stride` = ⌈⌈left / ept⌉ / 32⌉ · 32. A thread's slots are `ws + t + j·stride`, valid when `t < stride` and the entry exists.
- After the slots load, each plane computes `some = plane_any(slot 0 valid)` and `multi = plane_any(slot 1 valid)`. The 32-top AND loop then runs on all slots (`multi`), on slot 0 only (`some`), or not at all. A thread's slots fill in order, so this is exact for any EPT.
- The walk, the stage and the flush are untouched. Every (top, entry) pair is still tested exactly once.
- Unset, the comptime `tail = false` path is the old loop. The `pad` binary with the switch off ran ×1.007 against `base` at b62 1e16 (one run, within the base's 1.3 % spread).
- Host: `NICE_EXP_JOIN_TAIL`, plus `NICE_EXP_JOIN_EPT` (1–4) replacing `ENTRIES_PER_THREAD` at launch.

**Exactness** (CUDA, `pad`, `raw/box/x_*.log`, `cmp_*.log`):

| check | tail | result |
|---|---|---|
| `cubecl_cuda_join_matches_the_cpu_reference`: base 10, windows b20–b64 incl. **b50, b54**, b57 frontier partitions, tight and refused layouts, slices, production shape | on | ok (80 s) |
| the same | on, EPT 1 | ok (74 s) |
| the same | off, EPT 1 | ok (73 s) |
| dense b58 1e15, 32 partitions | on | ok: 254,938,965 / 14,396,829, equal to the CPU join (= L30) |
| dense b62 1e16, 4 partitions | on | ok: 120,013,475 / 7,355,827, equal to the CPU join (= L30) |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14, b57/60/62/64 | on, and `base` | both pass (join = stride, 0 hits). **Counts identical**: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759 (= L30) |
| every A/B and profile run, every arm | all | survivors / checked identical to base: b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404. 0 hits, `spilled=0` |
| NiceMark whole-field scenarios | on | b58 MSD-weak 33,590,315,220 / 1,894,592,860, b58 MSD-strong 4,027,773,430 / 226,773,299: identical to off (= L30) |

**A/B** (`raw/analysis.txt`). Order per round: A B, B A, A B. Device s per field. Clock is the mean SM MHz over ≥ 90 % utilisation samples.

| field | A: base `e9cdac4` (rounds) | B: tail (rounds) | **speed-up (medians)** | per round | saving per field | other arms (×, vs base median) |
|---|---|---|---|---|---|---|
| **b62 1e17** | 163.14, 164.75, 164.69; §3b: 163.35, 162.96 (163.35, spread 1.1 %) | 157.05, 157.17, 156.84; §3b: 156.88, 157.35 (157.05, 0.3 %) | **×1.040** (first 3 rounds alone: ×1.049) | 1.039, 1.048, 1.050, 1.041, 1.036; clock-normalised 1.050, 1.051, 1.054, 1.042, 1.049 | **−6.3 s** | EPT 1: 178.42 (×0.916) |
| b62 1e16, 2 fields | 13.702, 13.633, 13.810, 13.775 (13.739, 1.3 %) | 13.187, 13.174, 12.981, 12.952 (13.078, 1.8 %) | **×1.051** | 1.039, 1.035, 1.064, 1.064 | −0.66 s | EPT 1 ×0.949 (5.7 % spread); EPT 1 + tail ×1.004; EPT 3 + tail ×1.044; EPT 4 + tail ×0.973; switch off ×1.007 |
| b60 1e16, 2 fields | 30.558, 30.599, 30.663, 30.231 (30.578, 1.4 %) | 29.903, 29.512, 29.914, 29.591 (29.747, 1.4 %) | **×1.028** | 1.022, 1.037, 1.025, 1.022 | −0.83 s | EPT 1 ×0.930 |

- The base medians agree with L30's combined tree on this machine: 163.4 against 166.2 s, 13.74 against 14.05 s, 30.58 against 31.09 s.
- **The tail is the steadier arm at b62 1e17** (156.8–157.4 s over 5 runs). The base moved 163.0–164.8, so the ratio depends on which base rounds are counted: ×1.036–1.050 per round.
- **Unprofiled savings are 72 % of the profiled ones at b62 1e17** (6.3 against 8.8 s). At b60 they are larger than profiled (0.83 against 0.45 s per field). Profiled single runs at b60 resolve about ±0.3 s.
- **Rounds 4 (1e16) were added after the main chain.**
  - b62 1e16 r4 ran on a quiet box (08:15).
  - b60 1e16 r4's tail run overlapped the last ~45 s of the `pad2` build. That would slow the tail, not the base.

**NiceMark nice-only** (`client_pad`, tail off / on, `--benchmark-secs 150`, `NICE_API_BASE=http://127.0.0.1:9`, `raw/box/nm_*.json`):

| | off | tail | speed-up |
|---|---|---|---|
| **score**, rounds (median, spread) | 4927.2, 5055.6, 5016.1 (5016.1, 2.6 %) | 5349.4, 5412.9, 5405.8 (5405.8, 1.2 %) | **×1.078** (per round ×1.086, ×1.071, ×1.078) |
| b58 MSD-weak (whole field), n/s, medians | 2.230e14 | 2.430e14 | ×1.089 |
| b58 MSD-strong (whole field) | 1.273e15 | 1.353e15 | ×1.063 |
| b60 MSD-weak (sampled) | 4.244e14 | 4.599e14 | ×1.084 |
| b62 MSD-weak (sampled) | 5.569e14 | 5.916e14 | ×1.062 |

- Round 1 ran on a quiet box (08:10). Rounds 2–3 (tail, off, off, tail, 08:22–08:25) overlapped the `pad2` build on the host CPU, equally for both arms. That is why the off score spreads 2.6 %.
- The off score is at L30's combined NiceMark (4871, spread 1.5 %).
- NiceMark gains more than the live fields because its fields are small (1e14-scale scenarios): buckets of 180–220 entries, where the tail idles 4 of 8 planes.

## 3b. Tail mode 2 (votes per chunk) and two more b62 1e17 rounds

The prototype took the join kernel from 40 to 41 registers (§4). Head `ed8bc8c` adds `NICE_EXP_JOIN_TAIL=2`. It is the same tail, but the two `plane_any` votes are taken before each 32-top chunk's AND, so they are not live across the walk. Binary `pad2` (md5 d87978e8).

| | registers (offline ptxas, sm_86, b62) | b62 1e17 device s (r1, r2) | vs base, same rounds |
|---|---|---|---|
| base (`e9cdac4`) | 40 | 163.35, 162.96 (mean 163.16) | — |
| tail 1 (= the prototype) | 41 | 156.88, 157.35 (157.11) | ×1.039 |
| tail 2 | **48** | 156.29, 158.40 (157.34) | ×1.037 |

Order: base, t1, t2, t2, t1, base (08:27–08:45, quiet box). b60 1e16, tail 2, one run: 30.07 s (×1.017 against the base's 4-round median).

- **Mode 2 is no better and uses 7 more registers.** It is not the way back to 40.
- The two extra rounds bring the b62 1e17 A/B to 5 rounds (§3).
- **Can the tail fit 40 registers?** Offline, `__launch_bounds__(256, 6)` on the tail kernel's CUDA source gets 40 registers with an 8-byte spill (`regs_tail_lb6.txt`). That is a 6-cubes-per-SM occupancy target. CubeCL emits `__launch_bounds__(256)` with no minimum-blocks argument, so this was not testable end to end here.
- Counts are identical to the base in every run.

## 4. Lints, blocks, registers

| check | tail off | tail on | logs |
|---|---|---|---|
| WGSL lint as CI runs it: `wgsl_dump_for_lint` on lavapipe (Mesa llvmpipe), `scripts/wgsl-lint.py` with CI's 13 `--require`s | 15 shaders, 0 flagged, rc 0; JoinKernel b57 has 34 constant divisions | 15 shaders, **0 flagged**, rc 0; JoinKernel b57 has **35** (the tail's `/ ept`, a power of two) | `wgsl_lint_{off,tail}.log`, `wgsl_{off,tail}.log.gz` |
| SPIR-V blocks (`cubecl-spirv` dump of the same test, `blocks.py` from L29) | JoinKernel b57: 109 | JoinKernel b57: **123** (+14). The largest kernel is still TopKernel b57 at 478, unchanged | `spv_blocks_{off,tail}.txt` |
| CUDA registers (CubeCL's CUDA source from `CUBECL_DEBUG_LOG`, b62; offline `nvcc 12.8 -arch=sm_86 -O3 --resource-usage`) | **40**, 0 spills | **41**, 0 spills | `regs_{off,tail}.txt`, `join_{off,tail}.cu` |
| `cargo fmt --all --check` on `2a681f6` | | **fails**: one line too long in the slot-0 AND loop | `lint_fmt.log` |
| clippy `-D warnings` on `2a681f6` (gpu, default) | | **fails**: `struct_excessive_bools`. `tail: bool` made JoinDevice's fourth bool | `lint_clippy_{gpu,default}.log` |
| fmt + clippy (`nice_client/gpu` and default) on head **`ed8bc8c`** (tail is a `u32`, line wrapped) | | **all clean** | `lint2_*.log` |

- **Registers: 40 → 41 crosses an occupancy step on sm_86** (if the driver JIT allocates as offline ptxas does).
  - Registers are allocated in 256-register units per warp. At 40 a 256-thread cube takes 10,240 registers and 6 cubes fit (also the thread cap). At 41 it takes 12,288, and only 5 fit.
  - So the measured ×1.04 is plausibly with one resident cube fewer per SM. Getting back to 40 is the first thing to try in a PR (§3b).
- The fmt and clippy failures are prototype-only and are fixed on the branch head `ed8bc8c`.

## 5. Verdict, and what a PR would need

- **Against the 5 % bar:**
  - **b62 1e17: ×1.040** (5 rounds, per round ×1.036–1.050). Below, by about one point.
  - **b60 1e16: ×1.028** (4 rounds). Below.
  - b62 1e16: ×1.051, but b62 runs at 1e17 in production. NiceMark: ×1.078.
  - The padding was 35 % of the lanes at b62. It turns out to be worth about 4 % of the field there and 3 % at b60, because b60's buckets fill 77–79 % of their wave.
  - The one open upside is occupancy. The +1 register (40 → 41) likely costs a resident cube per SM, and 40 is reachable with a launch bound and an 8-byte spill. That could move b62 1e17 over the bar, but it is unmeasured.
- **It is the only padding lever.**
  - EPT 1 is ×0.92–0.95.
  - Packing has nothing to pack.
  - Wider EPT with the tail is no better.
  - After the tail, 4–5 % of the slots run empty, worth about 0.5 s at b62 1e17. There is nothing further to take from padding.
- **What a PR would need:**
  1. **Make it unconditional:**
     - Drop the comptime `tail` and the old loop, keeping the stride rule and the per-plane slot dispatch.
     - Drop the EPT knob.
     - Update the `ENTRIES_PER_THREAD` doc comment: buckets of 256–479 entries, one wave, and the tail idles the planes it does not need.
     - About +35 / −5 lines.
  2. **Registers.** Get the tail back to 40 registers on sm_86 so that 6 cubes fit per SM, then re-measure. Options:
     - a minimum-blocks launch bound, if CubeCL can emit one;
     - restructuring the dispatch, though not by mode 2, which is 48.
  3. **Correctness on the other backends.**
     - Done here: the WGSL lint and the SPIR-V block count, with the tail on (§4).
     - CI's lavapipe parity steps (naga and cubecl-spirv).
     - Metal parity on the M4. The change adds no division of a shifted value (the new division is by `ept`, a power of two).
  4. **Timing on a second card** (e.g. the 4090 or the 9070 XT through Vulkan), plus NiceMark ×3. If the plane width is 64, round the stride to `PLANE_DIM` instead of 32.
  5. **A one-line CHANGELOG entry.**
  - The existing join parity test already covers partial waves of every size: small fields have buckets under 256 entries, production fields 256–479.
