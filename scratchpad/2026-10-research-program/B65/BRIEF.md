# Base 65 on a card at home: where the time goes, and is the slow Vulkan run reproducible? (brief, 2026-11-26 06:00 UTC)

You are an engineer running measurements on a machine the project's maintainer has put at the research
program's disposal. Work alone (do not start subagents). **Hard stop for measurements 09:30 UTC; report by
10:00 UTC** (check `date -u`).

## Why this matters (new today)

The project ("nice": an exhaustive search for numbers whose square and cube together use every digit of a base
once) has a redesigned GPU search join, the **middle-out join** (fork branch `dev/mo-mode`, head `f61cf79e`;
design: `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md`). Base 64 runs through its *narrow*
device path (`common/src/midout/gpu.rs`), bases 65–70 through its *wide* path (`gpu_wide.rs`). A table made this
morning (`YIELD/yield.txt` under the research directory) shows that **base 65 holds about 73 % of the
probability still within reach and, at today's speeds, about 73 % of the remaining machine time** (about 150
days on the fastest card against 56 for base 64), because only one residue class in 64 can hold a nice number
there. So the wide path at base 65 is now the most valuable thing to make faster, and it is the less tuned of
the two. Two things are unknown:

1. **Where base 65's time goes at today's head**, stage by stage, on a card with a plain clock (the last stage
   table is from 2026-11-19, before the wide path was changed on 11-20: `G2/BUILD-NOTES-WIDE.md` §4, about
   lines 130–150: tops ≈ 2.6 ms per slice, parents 1.0, main kernel 6.4, expansion 1.1, check ≈ 2.0, on an
   RTX 3080; `G2/WIDE2-NOTES.md` has the 11-20 changes).
2. **Why the maintainer's RX 9070 XT (AMD, Vulkan through the direct SPIR-V compiler) ran base 65 at 4.8–4.9 fs
   per admissible n with the card at half clock on 2026-11-25, against 3.02 fs on 2026-11-19 with the trunk
   `66259bb0`** (`G2/WINDOW3-RESULTS.md`, task 3). Nobody could tell the code from the session, and that card is
   not available today. Since last night Vulkan works on NVIDIA cards on the machine you will use, so the same
   kernels can run through Vulkan at home: **if the head is slower than the trunk through Vulkan on an NVIDIA
   card too, the cause is in the code and can be found here.**

Paths below are relative to `~/projects/nice/scratchpad/2026-10-research-program/` on ivory (this machine) unless
they start with `~`.

## The machine: eventeo (read `README.md`, section "Machines the program may use", and the memory entry
`~/.claude/projects/-home-claude/memory/reference_eventeo_host.md` first; on the machine, `~/SYSTEM_STATE.md`)

- AMD FX-6300 (6 slow cores, **no AVX2**: build there, never copy optimised binaries in), 16 GB, **RTX 3060 12 GB =
  nvidia-smi index 1 (use this one), GTX 1060 3 GB = index 0**. `ssh claude@eventeo` (our own user, no sudo; only
  `/home/claude`). **It is powered off by default:** wake it from ivory with `~/.local/bin/wake-eventeo` (about
  45 s). When your work is done run `bash -l ~/research/scripts/off_if_idle.sh` there (it powers off unless the
  owner is logged in or something still runs) and confirm from ivory that ssh is gone.
- Non-interactive ssh has no cargo on PATH: scp a script and run it with `bash -l script </dev/null`; long jobs
  through `setsid nohup … &` with their output in a file, then poll. Never `pkill -f`/`pgrep -f`; kill only what
  you started, by recorded PID.
- Everything lives under `~/research`: `scripts/env.sh` (**source it in every script: it points the API address
  at a closed local port and fixes the CUDA device order; nothing may contact the production API**),
  `scripts/env_vulkan.sh` (source after it to make Vulkan see the NVIDIA cards; the wgpu adapter of the RTX 3060
  is `DiscreteGpu(1)`, set with `CUBECL_WGPU_DEFAULT_DEVICE`), `scripts/build_mo.sh BRANCH TAG` (how binaries were
  built last night: read it and reuse it; the head's binaries are in `bin/mo-mode/`, built with
  `cubecl-cuda,midout-bench`: CUDA, and Vulkan through WGSL), `scripts/run_mo.sh` (how runs are launched and the
  card sampled with nvidia-smi; the copies and last night's logs are in `EVENTEO/` here). Select the card for CUDA
  with `CUDA_VISIBLE_DEVICES=1` (PCI order is set by env.sh).
- Cold builds take 4–6 minutes each (6 jobs). Disk is plentiful; `/tmp` is RAM.
- The wall-power plug: Prometheus on shalash, `hassio_sensor_power_w{entity="sensor.0x282c02bfffec51b1_power"}`
  (see `EVENTEO/` for a query example); report the session's kWh.

## What to measure (base 65, wide path; fields 13731 as warm-up and 77777, the fields of both earlier sessions;
sampled CPU check off unless said, so that only the device path is compared; the card sampled beside every run)

1. **Builds:** the wide bench (`midout_wide_bench`) and the narrow bench (`midout_bench`) at the head
   (`dev/mo-mode` `f61cf79e`; its kernels are those of `dev/mo-clean` `66305ada`) with `cubecl-spirv,midout-bench`
   as well (the direct SPIR-V compiler, which the AMD card uses), and the wide bench at the **trunk `66259bb0`**
   (branch `dev/middle-out-join` on the fork; before the cleanup: feature names and the example's arguments
   differ: read `G2/build4s/window/` for how it was built and run on 2026-11-19) with `cubecl-cuda` and with
   `cubecl-spirv`.
2. **The A/B the AMD card could not give us, base 65:** head and trunk, alternating (trunk, head, trunk, head),
   through (a) CUDA, (b) Vulkan with the direct SPIR-V compiler. One more head run through Vulkan with WGSL.
   For every run: fs per admissible n of the warm field, the time outside device waits (total − "sync+reads"),
   counts (they must be equal between builds and equal to `G2/window_1125/out/w65_nc.log`), card utilisation,
   power and clock.
   - **If the head is slower than the trunk through Vulkan/SPIR-V by more than 10 % (and not through CUDA):**
     bisect on `common/src/midout/gpu_wide.rs` (`git log 66259bb0..66305ada -- common/src/midout/gpu_wide.rs`;
     start with `a82ad9db`, cleaned but before the 11-20 kernel changes, then `1d4d6920`, `64cf6c24`, `85185fef`,
     `10ddbf17`), one build and one warm-up-plus-field run per point; name the first slow commit and say from its
     diff what could do it. Do not fix it today.
   - **If head and trunk are within 10 % of each other on both runtimes:** say so plainly: then the AMD card's
     result was specific to that card or session, and only that card can answer.
3. **Stage profile at the head, base 65, through CUDA** (cumulative `MIDOUT_STOP` values as in
   `G2/BUILD-NOTES-WIDE.md` §4: 1 tops, 2 + parents, 3 + main kernel, 5 + expansion, then the whole field; one
   cold process each, field 77777 after the warm-up): ms per slice and fs per admissible n per stage, next to the
   11-19 table. The same for **base 64 through the narrow path** (`midout_bench`) as the reference, and base 64
   through the wide path (`midout_wide_bench --base 64`) if time allows. This CPU is slow: say for each stage
   whether the card was busy (utilisation) or waiting on the host, because a host-bound stage here is a
   candidate for the half clock on the AMD card.
4. **From the numbers, a short ranked list** of where base 65 could gain (per stage: its share, what bounds it,
   one concrete idea if you see one, what it would be worth on the whole field). No new kernel code today.

## Rules

- Nothing on the machine outside `/home/claude`. Never contact the production API. No pushes, no pull requests,
  no comments anywhere; code reaches eventeo by `git fetch` from the public fork (`build_mo.sh` shows how).
- Update `~/SYSTEM_STATE.md` on eventeo only if you change its state beyond adding binaries and runs under
  `~/research` (then one changelog line).
- If the machine does not wake, or the tooling denies something, do not work around it: stop and report.
- Kill criterion for the reproduction: three failed attempts to build the trunk in its old form → skip the A/B
  through SPIR-V, do the rest, and say so.

## Deliverables (by 10:00 UTC)

1. `B65/RESULTS.md`: the A/B table, the verdict on reproducibility, the bisection if any, the stage tables, the
   ranked list, what was not done, the session's energy, and confirmation that eventeo is off.
2. Raw logs copied to `B65/runs/` (rsync from `~/research/runs/`), your scripts to `B65/scripts/`.
3. A final report to me of at most 20 lines.
