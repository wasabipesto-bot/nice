# B65 results: base 65 on eventeo's RTX 3060 (2026-11-26, 05:49–08:00 UTC)

Brief: `BRIEF.md`. Machine: eventeo, RTX 3060 12 GB (nvidia-smi 1, wgpu `DiscreteGpu(1)`), FX-6300, driver 550.163.
Every process sourced `~/research/scripts/env.sh` (API on a closed local port); nothing contacted the production API.
Raw logs: `runs/` (`b65-ab`, `b65-load`, `b65-loadvk`, `b65-stage`; per run `.log`, `.gpu` = nvidia-smi every 0.5 s,
`.cpu` = vmstat 1 s). Scripts: `scripts/` (`build_b65.sh`, `run_b65.sh`, `runs_*.sh`, `analyze.py`, `energy.py`).
All numbers are field t 77777 after the warm-up field in the same process (13731 at b65, 4095 at b64), sampled CPU
check off. "Outside" = field time − "sync+reads" = host time spent queuing launches (device waits excluded).

## Verdict

**The AMD card's slow base-65 run is not a regression from trunk to head.** Head `f61cf79e` is *faster* than trunk
`66259bb0` on this card through both runtimes (CUDA −10 %, Vulkan/SPIR-V −13 %), so there was nothing to bisect.
**What does reproduce the pattern is host CPU load through Vulkan:** with 6 busy threads on the host (every core),
base 65 on the wide path goes from 6.34 to 14.6 fs per admissible n (×2.3) with the card at 24 % busy and 87 W,
while the narrow path at base 64 loses 5 % and CUDA loses ≤ 3.4 % on either path. That matches the 11-25 run on
the RX 9070 XT (wide 3.02 → 4.8–4.9 fs, narrow −6 to −10 %, the owner's desktop in use); it is the likely
explanation there, not tested on that card. The mechanism is in code that trunk and head share: the wide driver reads
every small result buffer of a group one at a time after the sync (~7 blocking reads per slice, ~29,600 per field),
while the narrow driver reads a group's buffers in one batched read. Under wgpu each read is a hand-off to cubecl's
poll thread and back, so it waits for a timeslice whenever the host is contended. The decisive cell: with
`MIDOUT_STOP=5` (all kernels up to the expansion, no reads) the same 6 busy threads cost 0.0 %. Details are in section 3.

## 1. Builds (all rc 0; `~/research/logs/b65/rc.txt` on eventeo)

| tag | commit | features | binary md5 (wide / narrow) | time |
|---|---|---|---|---|
| `mo-mode` (last night) | `f61cf79e` | `cubecl-cuda,midout-bench` (CUDA; Vulkan via WGSL) | `fa186085` / `d71eea24` | — |
| `head-spv` | `f61cf79e` | `cubecl-spirv,midout-bench` | `edacca49` / `a2e77f37` | 208 s |
| `trunk-cuda` | `66259bb0` | `cubecl-cuda` | `4d1af4c7` | 306 s |
| `trunk-spv` | `66259bb0` | `cubecl-spirv` | `2bda8055` | 198 s |

Trunk built first time in its old form (old features, same example arguments `--base --fields --group`; its wide
bench has the check off by default as the head's does). Both SPIR-V binaries sometimes segfault **at exit, after the
TOTAL line** (rc 139: `spv_trunk1`, `vn64_q`); the timings and counts are printed before it. Not investigated.

## 2. A/B, base 65, wide path (alternating trunk, head, trunk, head)

| run | fs per adm. n (77777) | warm-up 13731 | outside | card (field 77777): util median / ≥ 90 %, power, clock |
|---|---|---|---|---|
| cu_trunk1 | 6.9802 | 7.1853 | 19.19 s | 100 % / 99 %, 165 W, 1,867 MHz (P2) |
| cu_head1 | **6.3006** | 6.5387 | 17.54 s | 99 % / 100 %, 166 W, 1,830 MHz |
| cu_trunk2 | 7.1231 | 7.3529 | 19.51 s | 100 % / 100 %, 163 W, 1,822 MHz |
| cu_head2 | **6.4350** | 6.6345 | 17.94 s | 100 % / 100 %, 163 W, 1,785 MHz |
| spv_trunk1 | 7.3273 | 7.4436 | 3.36 s | 99 % / 70 %, 157 W, 1,867 MHz (P0) |
| spv_head1 | **6.3180** | 6.4516 | 3.90 s | 93 % / 85 %, 162 W, 1,860 MHz |
| spv_trunk2 | 7.2530 | 7.4151 | 3.53 s | 100 % / 85 %, 158 W, 1,867 MHz |
| spv_head2 | **6.3576** | 6.5145 | 3.72 s | 94 % / 78 %, 161 W, 1,852 MHz |
| wgsl_head1 | 6.5648 | 6.6509 | 4.07 s | 92 % / 85 %, 161 W, 1,845 MHz |

- **CUDA: head/trunk = 6.368 / 7.052 = 0.903 (head 9.7 % faster). Vulkan/SPIR-V: 6.338 / 7.290 = 0.869 (13 %
  faster). WGSL (head) 6.565, 3.6 % behind SPIR-V.** Pairs agree within 2 %.
- **Counts:** every b65 run, both fields, equals `G2/window_1125/out/w65_nc.log` (slices, survivors, checked, tops,
  children, chunks, flat, kept) — all builds and runtimes.
- The card runs into its 170 W power cap on CUDA (throttle reason SW power cap; ~1.8 GHz of 2.1). Under Vulkan the
  host's queuing time is small (wgpu records the launches and submits at the sync), and the "≥ 90 % busy" share is
  lower (70–85 %): the card waits for the host more often there even on a quiet host.
- **Reproducibility:** the head is not slower than the trunk on this NVIDIA card through either runtime (the brief's
  second case: within 10 % or better on both). So the 11-25 result on the RX 9070 XT is not a code regression that
  shows here; the bisection was not run. What does reproduce the AMD pattern is host load through Vulkan (next section).

## 3. Host CPU load (coordinator's addition), RTX 3060

Busy threads = `sh -c 'while :; do :; done'` started by the script, PIDs in `runs/*/busy.pids`, killed by PID after each
run. 6 busy threads = every core of the FX-6300. b64 narrow ran `--threads 5` unless stated.

| path, runtime | cell | fs per adm. n | vs quiet | outside | card util median / ≥ 90 %, power |
|---|---|---|---|---|---|
| b65 wide, CUDA | quiet (`w65_q`) | 6.3593 | — | 17.73 s | 99 % / 100 %, 164 W |
| | 3 busy | 6.4200 | +1.0 % | 17.92 s | 99 % / 100 %, 165 W |
| | 6 busy | 6.5741 | +3.4 % | 25.49 s | 97 % / 95 %, 162 W |
| | 6 busy at nice 19 | 6.4394 | +1.3 % | 21.38 s | 99 % / 100 %, 163 W |
| b64 narrow, CUDA | quiet (`n64_q`) | 3.2399 | — | 5.00 s | 100 % / 99 %, 160 W |
| | 3 busy | 3.2667 | +0.8 % | 5.09 s | 100 % / 99 %, 159 W |
| | 6 busy | 3.3125 | +2.2 % | 13.13 s | 98 % / 99 %, 159 W |
| | 6 busy, `--threads 2` | 3.3246 | +2.6 % | 13.60 s | 98 % / 99 %, 158 W |
| | 6 busy at nice 19 | 3.2968 | +1.8 % | 6.38 s | 100 % / 99 %, 158 W |
| **b65 wide, Vulkan/SPIR-V** | quiet (`vw65_q`) | 6.3399 | — | 4.31 s | 94 % / 91 %, 161 W |
| | **6 busy** | **14.6175** | **×2.31** | 10.39 s | **24 % / 19 %, 87 W** |
| b64 narrow, Vulkan/SPIR-V | quiet (`vn64_q`) | 3.1878 | — | 4.31 s | 97 % / 98 %, 158 W |
| | 6 busy | 3.3435 | +4.9 % | 11.43 s | 92 % / 90 %, 154 W |

Follow-up cells through Vulkan/SPIR-V (`runs_vk2.sh`, b65 wide, head):

| cell | fs per adm. n | vs quiet (6.3399) | outside | card util median / ≥ 90 %, power |
|---|---|---|---|---|
| `MIDOUT_STOP=5` (every kernel but the check; **no reads**), quiet | 6.1061 | (−3.7 %) | — | |
| **`MIDOUT_STOP=5`, 6 busy** | **6.1077** | **+0.0 % against its quiet run** | — | |
| full, 6 busy at nice 19 | 8.7283 | +38 % | 2.93 s | 82 % / 44 %, 123 W |
| full, 3 busy | 6.5119 | +2.7 % | 2.53 s | 94 % / 72 %, 158 W |
| full, 6 busy, `--group 64` | 13.8127 | ×2.18 (group 16: ×2.31) | 18.00 s | 18 % / 44 %, 81 W |

- **The stop-5 pair is the decisive cell:** with every kernel stage up to the expansion but no result reads (the
  timing stop's `finish_group` returns right after the sync), 6 busy threads cost nothing. So the whole ×2.3 sits in
  what stage 6 adds: the check kernel (0.15 ms per slice on CUDA) and the ~29,600 serial reads.
- Quiet, the reads and check cost 3.7 % through Vulkan (6.106 → 6.340) and 0.6 % through CUDA.
- A 4× larger group barely helps (14.6 → 13.8): the cost is per read (7 per slice), not per sync.
- Lowering the competitors to nice 19 recovers only part (×2.31 → ×1.38): the hand-offs still wait.
- 3 busy threads (half the cores) cost 2.7 %: the large loss needs every core contended. The 9070 XT's 11-25 loss
  (×1.6) lies between the 3- and 6-thread cells here (not tested on that machine).

**Through CUDA, CPU load alone barely moves either path; through Vulkan it more than halves the wide path's speed and
leaves the narrow path within 5 %.** On the wide Vulkan run the extra 131 s per field is almost all inside
"sync+reads" (95.9 → 220.6 s) while the card sits idle (24 % busy): the host is late collecting results, not late
queuing work.

**What the wide driver's host thread does that the narrow one does not** (`gpu_wide.rs` at `f61cf79e`:
`run_field_wide` → `queue_slice` (= `queue_prep` + `queue_batch` + `queue_done`) ×16 → `finish_group`; `gpu.rs`:
`queue_dev` (= `queue_dev_prep` + `queue_batch` + `queue_done`) → `finish_group`). Both drivers are the same
synchronous loop: queue 16 slices, sync, read and check the accounts, then queue the next group (neither overlaps a
group's reads with the next group's work). The queuing side is comparable (wide per slice: 10 small uploads (`mk`),
9 allocations, ~12 launches; narrow: 14 uploads, 8 allocations, ~15 launches; at base 65 and 64 both have one launch
batch per slice). **The difference is the reads in `finish_group`:** the narrow path collects every small buffer of the
group (`cnt`; per ticket `scount`, `ran`, `stat`, `tstat`; per slice `acc`, `l5n`) into **one `read_async` per
group** (~260 per field); the wide path calls `self.rd()` = `client.read_one()` **once per buffer, serially**: `cnt`,
then per ticket `scount`, `ran`, `tstat`, `stat`, `est`, then per slice `acc` and `l5n` — 7 per slice, ~113 per group,
**~29,600 blocking reads per base-65 field**, all while the device is idle (the next group is not queued yet).
Through CUDA a read is a synchronous copy on the calling thread (cheap, and the card is power-capped anyway). Through
cubecl-wgpu each read flushes the queue, maps a staging buffer, unparks cubecl's poll thread (`compute/poll.rs`:
`device.poll(Wait)` then `yield_now`) and waits on a channel for it: two thread hand-offs per read. On a contended
host the extra time is 131 s / 29,600 ≈ 4.4 ms per read, consistent with each hand-off waiting for a scheduler
timeslice (inferred from the code and the timings, not traced). The same is the likely account of the AMD card's
11-25 time (outside 1.6 → 7.8 s and sync+reads 46 → 68 s per field with the owner's desktop running).

## 4. Stage profile at the head, CUDA (cumulative `MIDOUT_STOP`, one cold process each, field 77777)

Per slice = field time / slices (b65 4,225; b64 4,096); stage = difference to the previous stop; fs per admissible
n of the stage likewise. Full field (b65) = mean of `cu_head1`, `cu_head2`, `w65_q` (100.59 s). Card: median util
over the run (after init), median power.

**Base 65, wide path** (11-19 = RTX 3080, first code, `G2/BUILD-NOTES-WIDE.md` §4):

| stage | cum. field s | ms/slice | fs/adm | share | card | 11-19 3080 ms/slice (fs) |
|---|---|---|---|---|---|---|
| tops | 10.86 | 2.57 | 0.687 | 10.8 % | 99 %, 149 W (below cap) | ≈ 2.6 (0.69) |
| parents | 22.79 | 2.82 | 0.755 | 11.9 % | 100 %, 147 W | 1.03 (0.27) |
| main kernel | 81.36 | 13.87 | 3.706 | 58.3 % | 100 %, 163 W (cap) | 6.37 (1.70) |
| expansion | 99.97 | 4.40 | 1.178 | 18.5 % | 100 %, 164 W (cap) | 1.13 (0.30) |
| check + accounts/reads (full field, other processes) | 100.59 | 0.15 | 0.04 | 0.6 % | 99–100 %, 164 W | ≈ 2.0 (0.54, no prefilter) |
| **total** | | **23.81** | **6.37** | | | ≈ 13.1 (3.5) |

**Base 64, narrow path (reference) and wide path** (n per field from the bench: 1.830e16 admissible):

| stage | narrow ms/slice | narrow fs | wide b64 ms/slice | wide b64 fs |
|---|---|---|---|---|
| tops | 0.38 | 0.086 | 0.43 | 0.096 |
| parents | 0.90 | 0.201 | 1.58 | 0.354 |
| main kernel | 11.22 | 2.511 | 11.25 | 2.518 |
| expansion | 2.00 | 0.449 | 2.58 | 0.578 |
| check + reads | 0.12 | 0.027 | 0.30 | 0.067 |
| **total** | **14.62** | **3.273** | **16.14** | **3.613** (+10.4 %) |

- **Host-bound or not (CUDA):** every stage kept the card ≥ 95 % busy (mean) with a quiet host; tops and parents ran
  below the power cap (147–149 W at b65, 103–148 W at b64: short, latency-bound kernels), the main kernel and
  expansion at the cap. On CUDA no stage is host-bound on this CPU. Through Vulkan the reads are the host-bound part
  (section 3), and they belong to no kernel stage: the stage runs skip them (`finish_group` returns after the sync).
- The check is now nearly free (0.15 ms per slice, 0.6 %): the prefilter (`pf_w2`) leaves 526k checks per slice.
- Against the 3080 the 3060 is ×1.82 slower overall; tops take the same time on both cards (which
suggests they are latency-bound), parents
  ×2.7 and expansion ×3.9 (the 11-19 table's expansion is from first code; `64cf6c24` measured 2.0 ms on the 3080
  after the 11-20 change).

## 5. Where base 65 could gain (ranked)

Shares are of the b65 field on the RTX 3060 through CUDA (23.8 ms per slice); "worth" is on the whole field.

1. **The wide driver's result reads (host, Vulkan only): 0.6 % quiet on CUDA, 3.7 % quiet through Vulkan, ×2.3 under
   full host load through Vulkan.** Bound by thread hand-offs in cubecl-wgpu's read path, ~29,600 per field.
   Idea: read a group's small buffers in one `read_async`, as the narrow `finish_group` already does (~260 reads per
   field; host code only, no kernel change). Worth: up to ~3 % on a quiet Vulkan host (3.7 % for reads + check, of which
the check kernel is ~0.6 %); on a loaded one it removes the
   ×1.4–2.3 cliff, which is the most plausible cause of the 9070 XT's 4.8 fs against 3.02 (×1.6). Since demoux does
   ~81 % of the fields through Vulkan on the owner's desktop, this is the cheapest and largest item. A further step,
   for both paths, is to queue group k + 1 before reading group k (double buffering), so the reads never idle the card.
2. **Main kernel: 58 % (13.9 ms per slice, 3.71 fs).** Power-capped compute on CUDA (163 W at the 170 W cap). Per
   admissible n it is ×1.47 of the base-64 wide kernel's (13.87 ms over 3.74e12 n per slice against 11.25 over
   4.47e12). Any gain here is kernel work (not today); every 10 % on it is 5.8 % on the field.
3. **Expansion: 18.5 % (4.40 ms).** At the power cap. At base 64 the wide expansion costs 2.58 ms against the narrow
   one's 2.00 (+29 %); if the wide expansion matched the narrow one's per-record cost at b65 (×0.78), the field gains
   ~4 %.
4. **Parents: 11.9 % (2.82 ms).** Below the power cap (147 W): short, latency-bound kernels. The narrow path shares
   its depth-8 parent lists across digit 8 (parents 0.90 ms at b64) and the wide path does not (1.58 ms at b64).
   Porting the sharing to the wide path would save about the same fraction at b65: ~1.2 ms per slice, ~5 %.
5. **Tops: 10.8 % (2.57 ms).** Below the cap, and the same 2.6 ms as on the 3080 (×1.8 faster overall): latency- or
   launch-bound, not throughput-bound. Idea: queue the tops of several slices in one launch (or overlap them with the
   previous slice's main kernel) so the card fills; worth up to most of its 10.8 % on a bigger card, where it weighs
   more (3080: 20 % of the slice).
6. **Check: 0.6 % (0.15 ms).** Nothing to gain since the prefilter.

## Not done

- Bisection (not needed: the head is faster than the trunk on both runtimes).
- Stage profile through Vulkan (only CUDA was asked); stage runs under load other than `MIDOUT_STOP=5` through Vulkan.

## Energy

Prometheus (`hassio_sensor_power_w`, 30 s scrape) over 05:48:30–08:01 UTC: **0.545 kWh** (integral; the energy
counter says 0.72 → 1.26 = 0.54 kWh), mean 244 W, peak 317 W, i.e. about $0.10 at $0.177/kWh. The runs drew
157–166 W at the card by nvidia-smi.

## eventeo state

- Powered off at 08:00:28 UTC by `off_if_idle.sh` (nothing of ours running, nobody else logged in); ssh from ivory
  gone 5 s later (connection timed out on re-check). The plug read 2.1 W (standby) from 08:01 UTC.
- Added on eventeo: worktree `~/projects/nice/.worktrees/trunk` (66259bb0) and `~/research/t/trunk-rel` (1.3 GB);
  binaries `~/research/bin/{head-spv,trunk-cuda,trunk-spv}`; `~/research/b65/` (scripts, outputs, a copy of
  `SYSTEM_STATE.md` before the edit); `~/research/runs/b65-*`. One changelog line in `~/SYSTEM_STATE.md`.
- Every busy loop was killed by its recorded PID (`runs/*/busy.pids`); no `pkill`/`pgrep -f`. The one waiter I
  stopped early (`runs_load_vk.sh` 10305, when the Vulkan cells were moved before the stage profile) was killed by PID.
